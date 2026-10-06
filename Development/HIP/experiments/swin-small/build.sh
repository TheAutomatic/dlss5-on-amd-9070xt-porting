#!/usr/bin/env bash
set -euo pipefail
out=${1:?external output directory}
python3 "$(dirname "$0")/prepare.py" --out "$out"
for variant in small trace; do
  defines=(-DHIP_SWIN_PERSISTENT_DIAGNOSTICS=1)
  if [[ $variant == trace ]]; then defines+=(-DHIP_SWIN_PERSISTENT_TRACE=1); fi
  x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 "${defines[@]}" \
    -I "$out/runner/src" -I "$out/runner/Development/HIP" \
    "$out/runner/Development/HIP/benchmark_vit_reuse.cpp" -o "$out/benchmark-$variant.exe" \
    -ld3d12 -ldxgi -ld3dcompiler -ldxguid
done
repo=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -I "$repo/Development/HIP" \
  "$(dirname "$0")/occupancy.cpp" -o "$out/occupancy.exe"
