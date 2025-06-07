# Platelet-App

The Platelet application greatly simplify configuration of secured scenario runned by the fork of the Artery simulation framework provided by Platelet. This app is a Tauri app with a Rust backend and a Nuxt frontend.

## Requierements

### System dependencies

To run the Platelet App you need a couple system dependancies. You can install them using this command on debian based linux distributions.

```
sudo apt update
sudo apt install libwebkit2gtk-4.0-dev \
    build-essential \
    curl \
    wget \
    file \
    libssl-dev \
    libgtk-3-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev
```

### Rust

To build this app you will need the Rust toolchain. You can download and install the latest version of it using this command:

`curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh`

### Node.js

You can download Node.js on [the official website](https://nodejs.org/en) or using your distro package manager.

Be careful you need at least Node v20 and apt provides an older version. You can upgrade it using the `n` utility.

You also need a node package manager. Npm is the default one shipped with Node but I suggest you to use pnpm as it is much faster.

You can find all these informations and much more in the [Tauri documentation](https://tauri.app/v1/guides/getting-started/prerequisites).

## Usage

Before compiling the app you need to install node modules. You can do it using your node package manager.

`pnpm install`

You can now compile and run the platelet app using `pnpm tauri dev`.

To understand how to use the Platelet you can look up the two demo videos:

https://youtu.be/WuIl59mwxi0
https://youtu.be/v9YlUluFh-o