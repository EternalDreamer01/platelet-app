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
# RUN cargo --help

RUN npm install -g pnpm

WORKDIR /app
COPY . .

ENV CI=true
RUN pnpm install

# RUN ls -lA /root/.local && exit 1
EXPOSE 3000

CMD ["pnpm", "tauri", "dev"]
