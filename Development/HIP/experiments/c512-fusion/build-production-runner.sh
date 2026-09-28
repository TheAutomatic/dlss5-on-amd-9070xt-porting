#!/usr/bin/env bash
set -euo pipefail
out=${1:?isolated output directory}
root=$(cd "$(dirname "$0")/../../../.." && pwd)
mkdir -p "$out"
x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -I "$root/src" -I "$root/Development/HIP" "$root/Development/HIP/benchmark_vit_reuse.cpp" -o "$out/benchmark-production.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
bash "$root/scripts/build-addon.sh" "$root/third_party/minhook" "$root/third_party/reshade/include" "$out/dlss5-amd.addon64" --hip
