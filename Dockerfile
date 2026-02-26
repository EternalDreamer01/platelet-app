
ARG NODE_VERSION=24

# =========================
# Stage 0 - base image
# =========================
FROM node:$NODE_VERSION-bookworm AS base

ARG PROCESSORS=16
ARG DEPS_PATH=/opt

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get upgrade -y --no-install-recommends
RUN apt-get install -y --no-install-recommends \
		build-essential \
		cmake \
		ninja-build \
		ccache \
		curl \
		ca-certificates \
		git \
		gcc g++ \
		bison flex \
		sumo sumo-tools \
		automake autoconf libtool \
		python3 python3-dev python3-venv \
		libxml2-dev \
		zlib1g-dev \
		libssl-dev \
		pkg-config \
		qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
		libqt5opengl5-dev \
		libboost1.74-dev \
		libboost-date-time1.74-dev \
		libboost-system1.74-dev \
		libboost-filesystem1.74-dev \
		libboost-program-options1.74-dev \
		libcrypto++-dev \
		libgeographiclib-dev \
		gdb

ENV OMNETPP_HOME=${DEPS_PATH}/omnetpp \
	ARTERY_HOME=$DEPS_PATH/artery \
	SUMO_HOME=/usr/share/sumo

ENV LD_LIBRARY_PATH=$OMNETPP_HOME/lib:/usr/local/lib \
	SUMO_DATA=${SUMO_HOME}/data \
	PATH=/usr/local/bin:$PATH

ENV	CMAKE_PREFIX_PATH=/usr/local \
	MAKEFLAGS=-j${PROCESSORS}

# --------------------
# HARD FAIL if sumo data files missing
# --------------------
RUN ls \
	$SUMO_DATA/typemap/osmNetconvert.typ.xml \
	$SUMO_DATA/xsd/additional_file.xsd \
	$SUMO_DATA/xsd/routes_file.xsd \
	$SUMO_DATA/xsd/net_file.xsd

# --------------------
# ccache setup
# --------------------
ENV CCACHE_DIR=/ccache
ENV CCACHE_MAXSIZE=10G
# ENV CCACHE_BASEDIR=${DEPS_PATH}
ENV CCACHE_NOHASHDIR=1
RUN mkdir -p $CCACHE_DIR

SHELL ["/bin/bash", "-c"]

WORKDIR ${DEPS_PATH}

# =========================
# Stage 1 - OMNeT++
# =========================
FROM base AS omnetpp
WORKDIR ${DEPS_PATH}

ARG OMNETPP_VERSION=5.6.3
RUN curl -fL https://github.com/omnetpp/omnetpp/releases/download/omnetpp-${OMNETPP_VERSION}/omnetpp-${OMNETPP_VERSION}-src-linux.tgz \
 | tar xz

RUN mv omnetpp-${OMNETPP_VERSION} omnetpp

WORKDIR ${OMNETPP_HOME}

RUN source ${OMNETPP_HOME}/setenv \
	&& ./configure \
        WITH_QTENV=yes \
        WITH_TKENV=no \
        WITH_OSG=no \
        WITH_OSGEARTH=no \
	&& make -j${PROCESSORS}


# =========================
# Stage 2 - lightpcapng
# =========================
FROM base AS lightpcapng

WORKDIR ${DEPS_PATH}
RUN git clone --depth=1 https://github.com/Technica-Engineering/LightPcapNg.git lightpcapng
WORKDIR ${DEPS_PATH}/lightpcapng
RUN CFLAGS="-fPIC" cmake --preset Release
RUN CFLAGS="-fPIC" cmake --build --preset Release

# RUN ls -l build && exit 1
# RUN find /opt /usr -name '*pcapng.so*' -ls && exit 1

# =========================
# Stage 3 - Artery, Omnetpp, lightpcapng
# =========================
FROM base AS artery

# --------------------
# HARD FAIL if sumo data files missing
# --------------------
RUN ls \
	$SUMO_DATA/typemap/osmNetconvert.typ.xml \
	$SUMO_DATA/xsd/additional_file.xsd \
	$SUMO_DATA/xsd/routes_file.xsd \
	$SUMO_DATA/xsd/net_file.xsd

WORKDIR ${DEPS_PATH}
RUN git clone --recurse-submodules --depth=1 -j${PROCESSORS} https://gitlab.com/Matk3z/artery.git

WORKDIR ${ARTERY_HOME}

COPY --from=lightpcapng ${DEPS_PATH}/lightpcapng/build/liblight_pcapng.a /usr/lib/liblight_pcapng.a
COPY --from=lightpcapng ${DEPS_PATH}/lightpcapng/include /usr/include
COPY --from=omnetpp $CCACHE_DIR $CCACHE_DIR
COPY --from=omnetpp $OMNETPP_HOME $OMNETPP_HOME

RUN sed -Ei \
	's/"\/home\/mathi\/artery\/scenarios\/paris_openrit\/certificate\/"/boost::filesystem::current_path() \/ "certificate"/g' \
	src/artery/application/platelet/StaticCertificateProvider.cc

RUN rm -rf scenarios/
RUN find . \( -type d -name .git -prune \) -o -type f -print0 \
	| xargs -0 sed -i ' \
		s/\/home\/mathi\/artery/\/opt\/artery/g; \
		s/\/home\/mathi\/omnetpp-5.5.2/\/opt\/omnetpp/g'
# --------------------
# Artery (FORCED to include CERTIFY from Vanetza)
# --------------------
RUN source ${OMNETPP_HOME}/setenv \
	&& cmake -S . -B build -G Ninja \
		-DCMAKE_PREFIX_PATH=/usr/local \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_CERTIFY=ON \
		-DBUILD_TESTS=OFF \
		-DBUILD_BENCHMARK=OFF \
		-DCMAKE_C_COMPILER_LAUNCHER=ccache \
		-DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
	&& cmake --build build --parallel ${PROCESSORS}
# RUN cmake --install build


# =========================
# Stage 4 - runtime image
# =========================
FROM base AS runtime

RUN apt-get install -y --no-install-recommends \
	capnproto libcapnp-dev \
	libwebkit2gtk-4.0-dev \
	libjavascriptcoregtk-4.0-dev \
	libgtk-3-dev \
	dbus-x11
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PLATELET_HOME=/app
ENV PLATELET_TAURI_HOME=$PLATELET_HOME/src-tauri
ENV PATH=$OMNETPP_HOME/bin:$SUMO_HOME/bin:/root/.cargo/bin:$PATH

# --------------------
# Rust
# --------------------
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
RUN mkdir -p $HOME/.cargo \
	&& printf "[build]\njobs = %d" $PROCESSORS > $HOME/.cargo/config.toml

# --------------------
# Cache dependencies
# --------------------
WORKDIR $PLATELET_TAURI_HOME
COPY src-tauri/Cargo.toml src-tauri/Cargo.lock ./
# dummy build to get the dependencies cached.
RUN mkdir -p src && echo "// dummy file" > src/lib.rs && cargo build


WORKDIR $PLATELET_HOME
# RUN curl -o- https://fnm.vercel.app/install | bash
# RUN source /root/.bashrc && fnm install 24 && node -v && npm -v
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install

COPY --from=omnetpp $OMNETPP_HOME $OMNETPP_HOME
COPY --from=lightpcapng ${DEPS_PATH}/lightpcapng/build/liblight_pcapng.a /usr/lib/liblight_pcapng.a
COPY --from=lightpcapng ${DEPS_PATH}/lightpcapng/include /usr/include
COPY --from=artery $CCACHE_DIR $CCACHE_DIR
COPY --from=artery $ARTERY_HOME $ARTERY_HOME
RUN mv $ARTERY_HOME/build/extern/vanetza/bin/certify /usr/local/bin/

# --------------------
# HARD FAIL if CERTIFY missing or not working (exit code > 1)
# --------------------
RUN which certify && certify || [ $? -le 1 ]

# Clean (large) unused directories...
WORKDIR ${ARTERY_HOME}
RUN rm -rf .git/
WORKDIR ${OMNETPP_HOME}
RUN rm -rf .git/ ide/ out/ doc/

# --------------------
# Build project
# --------------------
WORKDIR $PLATELET_HOME
COPY . .

WORKDIR $PLATELET_TAURI_HOME
RUN cargo build

WORKDIR $PLATELET_HOME

ENV NO_AT_BRIDGE=1 \
	RUST_BACKTRACE=1 \
	CI=true \
	LIBGL_ALWAYS_SOFTWARE=1 \
	XDG_RUNTIME_DIR=/tmp/runtime \
	LD_LIBRARY_PATH="$ARTERY_HOME/build/extern/vanetza/lib:$LD_LIBRARY_PATH"

ENV PATH="/usr/lib/ccache:$PATH"

CMD ["pnpm", "tauri", "dev"]
