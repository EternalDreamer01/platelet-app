FROM node:24-bookworm

ENV SUMO_HOME=/usr/share/sumo
ENV PATH="$SUMO_HOME/bin:/root/.cargo/bin:$PATH"
ENV CI=true
ENV RUST_BACKTRACE=1

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y
RUN apt-get install -y \
	sumo sumo-tools \
	libwebkit2gtk-4.0-dev \
	libjavascriptcoregtk-4.0-dev \
	build-essential \
	pkg-config \
	curl \
	wget \
	file \
	cmake \
	libsoup2.4-dev \
	libssl-dev \
	ca-certificates \
	libgtk-3-dev \
	libayatana-appindicator3-dev \
	librsvg2-dev \
	curl \
	python3


# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

WORKDIR /app
COPY . .

# Pre-build Tauri application
WORKDIR /app/src-tauri
RUN cargo build
WORKDIR /app

# Install pnpm (preferred package manager)
RUN npm install -g pnpm

# Install dependencies
RUN pnpm install

EXPOSE 3000

# ARG UNAME=user
# ARG UID=1000
# ARG GID=1000
# RUN groupadd -g $GID -o $UNAME
# RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME
# RUN chown -R $UNAME:$UNAME .
# USER $UNAME
CMD ["pnpm", "tauri", "dev"]
