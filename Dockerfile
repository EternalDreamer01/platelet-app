
ARG NODE_VERSION=24

# =========================
# Stage 1 - builder image
# =========================
FROM node:$NODE_VERSION-bookworm AS builder

ARG PROCESSORS=16
ARG DEPS_PATH=/opt
ARG OMNETPP_VERSION=5.6.3

ENV DEBIAN_FRONTEND=noninteractive \
    OMNETPP_HOME=${DEPS_PATH}/omnetpp-${OMNETPP_VERSION} \
    SUMO_HOME=/usr/share/sumo \
    CMAKE_PREFIX_PATH=/usr/local \
    MAKEFLAGS=-j${PROCESSORS} \
	LD_LIBRARY_PATH=/usr/local/lib

SHELL ["/bin/bash", "-c"]

# --------------------
# Build dependencies
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
    sumo \
 && rm -rf /var/lib/apt/lists/*

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

ENV PATH=${OMNETPP_HOME}/bin:$PATH \
    LD_LIBRARY_PATH=${OMNETPP_HOME}/lib:$LD_LIBRARY_PATH

# --------------------
# Artery (FORCED to include CERTIFY from Vanetza)
# --------------------
WORKDIR ${DEPS_PATH}
RUN git clone --recurse-submodules --depth=1 -j${PROCESSORS} https://github.com/riebl/artery.git

WORKDIR ${DEPS_PATH}/artery

RUN source ${OMNETPP_HOME}/setenv \
	&& cmake -S . -B build -G Ninja \
      -DCMAKE_PREFIX_PATH=/usr/local \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_CERTIFY=ON \
      -DBUILD_TESTS=OFF \
      -DBUILD_BENCHMARK=OFF \
	&& cmake --build build --parallel ${PROCESSORS} \
	&& cmake --install build
RUN mv ./build/extern/vanetza/bin/certify /usr/local/bin/

# --------------------
# HARD FAIL if CERTIFY missing
# --------------------
RUN which certify

# Clean (large) unused directories...
RUN rm -rf build/ .git/

WORKDIR ${OMNETPP_HOME}
RUN rm -rf build/ .git/ ide/ out/ doc/


# =========================
# Stage 2 - runtime image
# =========================
FROM node:$NODE_VERSION-bookworm AS runtime

ARG PROCESSORS=16
ARG DEPS_PATH=/opt
ARG OMNETPP_VERSION=5.6.3
ENV OMNETPP_HOME=$DEPS_PATH/omnetpp-${OMNETPP_VERSION} \
	SUMO_HOME=/usr/share/sumo \
	ARTERY_HOME=$DEPS_PATH/artery \
	PLATELET_HOME=/app \
	PLATELET_TAURI_HOME=/app/src-tauri
ENV PATH=$OMNETPP_HOME/bin:$SUMO_HOME/bin:/root/.cargo/bin:/usr/local/bin:$PATH \
    LD_LIBRARY_PATH=$OMNETPP_HOME/lib:/usr/local/lib \
    NO_AT_BRIDGE=1 \
    RUST_BACKTRACE=1 \
    CI=true

RUN apt-get update && apt-get install -y \
		sumo \
		libwebkit2gtk-4.0-dev \
		libjavascriptcoregtk-4.0-dev \
		libgtk-3-dev \
		libboost-all-dev \
		libcrypto++-dev \
		libgeographiclib-dev \
		build-essential \
		libxml2-dev \
		zlib1g-dev \
		libssl-dev \
		python3 \
		curl \
		cmake \
	&& rm -rf /var/lib/apt/lists/*

# --------------------
# Rust + Node deps (build only)
# --------------------
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
RUN mkdir -p $HOME/.cargo \
	&& printf "[build]\njobs = %d" $PROCESSORS > $HOME/.cargo/config.toml

RUN apt-get remove -y curl && apt-get autoremove -y && apt-get clean

COPY --from=builder $OMNETPP_HOME $OMNETPP_HOME
COPY --from=builder $ARTERY_HOME $ARTERY_HOME
COPY --from=builder /usr/local /usr/local

WORKDIR $PLATELET_TAURI_HOME
COPY src-tauri/Cargo.toml src-tauri/Cargo.lock ./
# dummy build to get the dependencies cached.
RUN mkdir -p src && echo "// dummy file" > src/lib.rs && cargo build


WORKDIR $PLATELET_HOME
EXPOSE 3000
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install

COPY . .

WORKDIR $PLATELET_TAURI_HOME
RUN cargo build

WORKDIR $PLATELET_HOME

CMD ["pnpm", "tauri", "dev"]
