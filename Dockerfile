FROM node:24-bookworm


ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y
RUN apt-get install -y \
	libwebkit2gtk-4.0-dev \
	libjavascriptcoregtk-4.0-dev \
	build-essential \
	pkg-config \
	curl \
	wget \
	file \
	libsoup2.4-dev \
	libssl-dev \
	libgtk-3-dev \
	libayatana-appindicator3-dev \
	librsvg2-dev \
	curl

# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install pnpm (preferred package manager)
RUN npm install -g pnpm

WORKDIR /app
COPY . .

# Install dependencies
ENV CI=true
RUN pnpm install

# Pre-build Tauri application
WORKDIR /app/src-tauri
RUN cargo build
WORKDIR /app

EXPOSE 3000

# ARG UNAME=user
# ARG UID=1000
# ARG GID=1000
# RUN groupadd -g $GID -o $UNAME
# RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME
# RUN chown -R $UNAME:$UNAME .
# USER $UNAME
ENV RUST_BACKTRACE=1
CMD ["pnpm", "tauri", "dev"]
