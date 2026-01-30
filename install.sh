#!/bin/bash


_cpus=$(nproc)
PROCESSORS=$(( _cpus * 2 / 3 ))
DEPS_PATH="$PWD"
OMNETPP_VERSION=5.6.3

DEBIAN_FRONTEND=noninteractive
OMNETPP_HOME="${DEPS_PATH}/omnetpp-${OMNETPP_VERSION}"
SUMO_HOME=/usr/share/sumo
CMAKE_PREFIX_PATH=/usr/local
MAKEFLAGS=-j${PROCESSORS}
LD_LIBRARY_PATH=/usr/local/lib

sudo=
if [ "$EUID" -ne 0 ]; then
	sudo=sudo
fi

# System dependencies
$sudo apt-get update -y
$sudo apt-get install -y \
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
	curl \
	cmake \
    ninja-build \
    ccache \
    git \
    ca-certificates \
    gcc g++ \
    bison flex \
    python3 python3-dev python3-venv \
    automake autoconf libtool \
    pkg-config

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y


# Install Node
# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 24

# Verify the versions:
node -v # Should print "v24.13.0".
npm -v # Should print "11.6.2".

# Use pnpm as Node package manager
npm install -g pnpm

# Install OMNeT++
cd "${DEPS_PATH}"
curl -fL https://github.com/omnetpp/omnetpp/releases/download/omnetpp-${OMNETPP_VERSION}/omnetpp-${OMNETPP_VERSION}-src-linux.tgz \
 | tar xz

cd ${OMNETPP_HOME}
source ./setenv
./configure \
	WITH_QTENV=no \
	WITH_TKENV=no \
	WITH_OSG=no \
	WITH_OSGEARTH=no
make -j${PROCESSORS}

# Install Artery
cd "${DEPS_PATH}"
git clone --recurse-submodules --depth=1 -j${PROCESSORS} https://github.com/riebl/artery.git

cd "${DEPS_PATH}/artery"
cmake -S . -B build -G Ninja \
	-DCMAKE_PREFIX_PATH=/usr/local \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_CERTIFY=ON \
	-DBUILD_TESTS=OFF \
	-DBUILD_BENCHMARK=OFF
cmake --build build --parallel ${PROCESSORS}
$sudo cmake --install build
mv ./build/extern/vanetza/bin/certify /usr/local/bin/

# --------------------
# HARD FAIL if CERTIFY missing
# --------------------
which certify || { echo "FATAL: 'certify' not found in PATH after build!"; exit 1; }

cd "${DEPS_PATH}" && pnpm install
cd "${DEPS_PATH}/src-tauri" && cargo build
