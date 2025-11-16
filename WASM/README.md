## Building WASM (Webassembly) files

1. Ensure Docker is installed


2. (Recommended) Use the pre-built Docker image to build a WASM file

Build any C++ file with: 
```sh
docker run -v `pwd`:/src -w /src ghcr.io/webassembly/wasi-sdk /opt/wasi-sdk/bin/clang \
--target=wasm32-wasi \
-o <out-filename> \
<filename>
```
The `--target=wasm32-wasi` flag adds support for I/O functionality.

Examples:
```sh
docker run -v `pwd`:/src -w /src ghcr.io/webassembly/wasi-sdk /opt/wasi-sdk/bin/clang++ --target=wasm32-wasi -o slam_main.wasm slam_main.cpp
```


```sh
docker run -v `pwd`:/src -w /src ghcr.io/webassembly/wasi-sdk /opt/wasi-sdk/bin/clang --target=wasm32 -O2 -nostdlib \
  -Wl,--no-entry \
  -Wl,--export=reset_poses \
  -Wl,--export=set_pose \
  -Wl,--export=draw_pose_map \
  -Wl,--export=get_image_width \
  -Wl,--export=get_image_height \
  -Wl,--export=get_image_pixel_u32 \
  -Wl,--export=log_pose_f32 \
  -o map.wasm map.cpp
```

3. Run the file using [Wasmer](https://docs.wasmer.io/runtime) or another runtime

```sh
wasmer run slam_main.wasm
```