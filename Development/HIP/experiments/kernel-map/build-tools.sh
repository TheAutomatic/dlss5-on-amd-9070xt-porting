#!/usr/bin/env bash
set -euo pipefail
out=${1:?isolated output directory}
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
python3 "$here/prepare-recorder.py" "$out/runner-map"
x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -I "$out/runner-map/src" -I "$out/runner-map/Development/HIP" "$out/runner-map/Development/HIP/benchmark_vit_reuse.cpp" -o "$out/recorder-v2.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -I "$repo/Development/HIP" "$here/jobbench.cpp" -o "$out/jobbench-v2.exe"
