# ROAMR: Really Opensource Autonomous Mobile Robot

Mobile phones and mobile robots have many common requirements:

- performant sensors (cameras, IMUs, LiDAR, GPS) and sensor fusion
- networking capabilities (WiFi, Bluetooth Low Energy, LTE)
- energy efficiency

What if we turned the iPhone into a robot?

## Architecture

iOS host app: 

- exposes the core sensor data through iOS APIs
- runs WASM bytecode using WAMR
- communicates with ESP32 over BLE to control motors

WASM module:

- multi-threaded application with autonomoy logic

ESP32 firmware:

- recieves commands over BLE and uses SimpleFOC to control motors

## Setup

```sh
pip install pre-commit
pre-commit
```

## Localization Demo

See [WASM/README.md](WASM/README.md)
