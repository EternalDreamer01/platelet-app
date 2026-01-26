FROM node:24-bookworm

ENV SUMO_HOME=/usr/share/sumo
ENV PATH="/app/vanetza/build/bin:$SUMO_HOME/bin:/root/.cargo/bin:$PATH"
ENV CI=true
ENV RUST_BACKTRACE=1

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y
RUN apt-get install -y \
	sumo sumo-tools \
	libwebkit2gtk-4.0-dev \
	libjavascriptcoregtk-4.0-dev \
	libboost-all-dev \
	libcrypto++-dev \
	libgeographiclib-dev geographiclib-tools \
	build-essential \
	pkg-config \
	curl \
	wget \
	file \
	cmake \
	automake \
	libtool \
	autoconf \
	git \
	libsoup2.4-dev \
	libssl-dev \
	ca-certificates \
	libgtk-3-dev \
	libayatana-appindicator3-dev \
	librsvg2-dev \
	python3


# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

WORKDIR /app
COPY . .

# Pre-build Tauri application
WORKDIR /app/src-tauri
RUN cargo build
WORKDIR /app


# Build and install Vanetza from source
RUN git clone --depth=1 https://github.com/riebl/vanetza.git
WORKDIR /app/vanetza
RUN mkdir -p build \
	&& cd build \
	&& cmake -D BUILD_CERTIFY=ON .. \
	&& make -j4
WORKDIR /app

# Install pnpm (preferred package manager)
RUN npm install -g pnpm

# Install dependencies
RUN pnpm install

EXPOSE 3000

CMD ["pnpm", "tauri", "dev"]
