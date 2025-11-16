## Building WASM files

Ensure Docker is installed


### 2. (Recommended) Using the pre-built Docker image


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
