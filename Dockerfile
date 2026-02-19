
ARG NODE_VERSION=24

# =========================
# Stage 1 - builder image
# =========================
FROM node:$NODE_VERSION-bookworm AS runtime

ARG PROCESSORS=16
ARG DEPS_PATH=/opt
ARG OMNETPP_VERSION=5.6.3

ENV DEBIAN_FRONTEND=noninteractive \
    OMNETPP_HOME=${DEPS_PATH}/omnetpp-${OMNETPP_VERSION} \
    SUMO_HOME=/usr/share/sumo \
	ARTERY_HOME=$DEPS_PATH/artery \
    CMAKE_PREFIX_PATH=/usr/local \
    MAKEFLAGS=-j${PROCESSORS} \
	PLATELET_HOME=/app
ENV PLATELET_TAURI_HOME=$PLATELET_HOME/src-tauri \
	PATH=$OMNETPP_HOME/bin:$SUMO_HOME/bin:/root/.cargo/bin:/usr/local/bin:$PATH \
	LD_LIBRARY_PATH=$OMNETPP_HOME/lib:/usr/local/lib \
	SUMO_DATA=${SUMO_HOME}/data \
	NO_AT_BRIDGE=1 \
	RUST_BACKTRACE=1 \
	CI=true \
	LIBGL_ALWAYS_SOFTWARE=1

SHELL ["/bin/bash", "-c"]

# --------------------
# Dependencies
# --------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ninja-build \
    ccache \
    git \
    curl \
    ca-certificates \
    gcc g++ \
    bison flex \
    python3 python3-dev python3-venv \
    libxml2-dev \
    zlib1g-dev \
    automake autoconf libtool \
    libboost-all-dev \
    libssl-dev \
    libcrypto++-dev \
    libgeographiclib-dev \
    pkg-config \
	libwebkit2gtk-4.0-dev \
	libjavascriptcoregtk-4.0-dev \
	libgtk-3-dev \
    sumo sumo-tools \
	gdb \
	dbus-x11
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

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
ENV CC="ccache gcc" \
    CXX="ccache g++" \
    CCACHE_DIR=/ccache

RUN mkdir -p /ccache && ccache --set-config=max_size=10G

# --------------------
# OMNeT++
# --------------------
WORKDIR ${DEPS_PATH}

RUN curl -fL https://github.com/omnetpp/omnetpp/releases/download/omnetpp-${OMNETPP_VERSION}/omnetpp-${OMNETPP_VERSION}-src-linux.tgz \
 | tar xz

WORKDIR ${OMNETPP_HOME}

RUN source ${OMNETPP_HOME}/setenv \
	&& ./configure \
        WITH_QTENV=no \
        WITH_TKENV=no \
        WITH_OSG=no \
        WITH_OSGEARTH=no \
	&& make -j${PROCESSORS}

# --------------------
# Artery (FORCED to include CERTIFY from Vanetza)
# --------------------
WORKDIR ${DEPS_PATH}
RUN git clone --recurse-submodules --depth=1 -j${PROCESSORS} https://github.com/riebl/artery.git

WORKDIR ${ARTERY_HOME}

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
RUN mv ./build/extern/vanetza/bin/certify /usr/local/bin/

# --------------------
# HARD FAIL if CERTIFY missing
# --------------------
RUN which certify && certify || [ $? -le 1 ]

# --------------------
# Rust + Node deps (build only)
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
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install

# Clean (large) unused directories...
WORKDIR ${ARTERY_HOME}
RUN rm -rf build/ .git/
WORKDIR ${OMNETPP_HOME}
RUN rm -rf build/ .git/ ide/ out/ doc/

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
	LD_LIBRARY_PATH="/root/platelet/build/artery/extern/vanetza/lib:$LD_LIBRARY_PATH"

CMD ["pnpm", "tauri", "dev"]
