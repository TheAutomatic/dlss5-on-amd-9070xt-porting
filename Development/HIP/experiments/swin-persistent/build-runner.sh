#!/usr/bin/env bash
set -euo pipefail
out=${1:?output directory}
python3 "$(dirname "$0")/prepare.py" --out "$out"
for mode in 0 1; do
  name=base
  if [ "$mode" = 1 ]; then name=sp; fi
  x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 \
    -DHIP_SWIN_PERSISTENT="$mode" -I "$out/runner/src" -I "$out/runner/Development/HIP" \
    "$out/runner/Development/HIP/benchmark_vit_reuse.cpp" -o "$out/benchmark-$name.exe" \
    -ld3d12 -ldxgi -ld3dcompiler -ldxguid
done
