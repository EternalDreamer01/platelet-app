# Platelet-App

The Platelet application greatly simplify configuration of secured scenario runned by the fork of the Artery simulation framework provided by Platelet. This app is a Tauri app with a Rust backend and a Nuxt frontend.

## Docker

```sh
docker build . -t platelet
docker run \
	-p 3000:3000 \
	-e DISPLAY=$DISPLAY \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	--device /dev/dri \
	platelet
```

## Requirements

- Node 20+
- Rust

### System dependencies

To run the Platelet App you need a couple system dependancies. You can install them using this command on debian based linux distributions.

```sh
sudo apt-get update -y
sudo apt-get install -y \
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
```

### Rust

To build this app you will need the Rust toolchain. You can download and install the latest version of it using this command:

```sh
curl https://sh.rustup.rs -sSf | sh -s -- -y
```

### Node.js

```sh
# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 24

# Verify the Node.js version:
node -v # Should print "v24.13.0".

# Verify npm version:
npm -v # Should print "11.6.2".

npm install -g pnpm
```

You also need a node package manager. NPM is the default one shipped with Node but I suggest you to use pnpm as it is much faster.

You can find all these informations and much more in the [Tauri documentation](https://tauri.app/v1/guides/getting-started/prerequisites).

## Usage

Before compiling the app you need to install node modules. You can do it using your node package manager.

`pnpm install`

You can now compile and run the platelet app using `pnpm tauri dev`.

To understand how to use the Platelet you can look up the two demo videos:

https://youtu.be/WuIl59mwxi0
https://youtu.be/v9YlUluFh-o