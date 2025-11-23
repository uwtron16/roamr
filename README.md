# ROAMR: Really Opensource Autonomous Mobile Robot

Mobile phones and mobile robots have many common requirements:

- performant sensors (cameras, IMUs, LiDAR, GPS) and sensor fusion
- networking capabilities (WiFi, Bluetooth Low Energy, LTE)
- energy efficiency

What if we turned the iPhone into a robot?

## Architecture

### iOS host app:

- exposes the core sensor data through iOS APIs
    - Camera
    - LiDAR (iPhone Pro 12+)
    - IMU
- runs WASM bytecode using statically compiled WAMR iwasm
- communicates with ESP32 over BLE to control motors

- TODO: enable dynamic WASM loading through LocalSend

### WASM module:

- imports read sensor functions from iOS host
- multi-threaded application with autonomy logic
- compiled using WASI-SDK and threading
    - C++: https://github.com/WebAssembly/wasi-sdk

### ESP32:

- recieves commands over BLE and uses SimpleFOC to control motors

## Setup

```sh
pip install pre-commit
pre-commit
```

## Localization Demo

See [WASM/README.md](WASM/README.md)
