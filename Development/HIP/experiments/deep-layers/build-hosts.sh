#!/usr/bin/env bash
set -euo pipefail
out=${1:?isolated directory}
here=$(cd "$(dirname "$0")" && pwd)
for variant in R V C; do python3 "$here/prepare-source.py" "$out/runner-$variant" --variant "$variant"; done
for variant in R RF V C; do
 case $variant in
 R) sub=R;defs=(-DC512_REGISTER_MODE=1);;
 RF) sub=R;defs=(-DC512_REGISTER_MODE=2);;
 V) sub=V;defs=(-DVIT_EXPAND_CONSUMER_FLOAT_HOST=1);;
 C) sub=C;defs=(-DC512_COMPACT_HOST=1);;
 esac
 x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 "${defs[@]}" -I "$out/runner-$sub/src" -I "$out/runner-$sub/Development/HIP" "$out/runner-$sub/Development/HIP/benchmark_vit_reuse.cpp" -o "$out/benchmark-$variant.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
done
