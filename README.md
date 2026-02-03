# Platelet-App

The Platelet application greatly simplify configuration of secured scenario runned by the fork of the [Artery](https://artery.v2x-research.eu/) simulation framework provided by Platelet. This app is a [Tauri](https://tauri.app/) app with a Rust backend and a Nuxt frontend.

## Docker

### Pre-built
```sh
docker run --rm \
	-p 3000:3000 \
	-e DISPLAY=$DISPLAY \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	-v ./data:/root/platelet:rw \
	--device /dev/dri mikecod/platelet
```
*You might eventually change `./data` at line 5 to save in another directory.*

### Build
```sh
git clone --depth=1 https://github.com/EternalDreamer01/platelet-app
npm run docker:build
npm run docker:run
```

## Installation on Host

```sh
./install.sh
```
The script will setup and install the requirements :
- Compilers (i.e gcc, bison, ninja, cmake, autoconf)
- Python3 with venv
- [SUMO](https://eclipse.dev/sumo/)
- Node 20+ with [`nvm`](https://github.com/nvm-sh/nvm) and [`pnpm`](https://pnpm.io/)
- Rust
- [Artery](https://artery.v2x-research.eu/install/) which include [Vanetza](https://www.vanetza.org/)

You can now compile and run the platelet app using `pnpm tauri dev`.

To understand how to use the Platelet you can look up the two demo videos:
* https://youtu.be/WuIl59mwxi0
* https://youtu.be/v9YlUluFh-o