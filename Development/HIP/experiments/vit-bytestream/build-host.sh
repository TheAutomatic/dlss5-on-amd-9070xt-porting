#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../../.."
out=/tmp/vit-bytestream-20260927
mkdir -p "$out"
x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -I src -I Development/HIP Development/HIP/benchmark_vit_reuse.cpp -o "$out/benchmark.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
bash scripts/build-addon-oneclick.sh "$out/dlss5-amd.addon64" --hip
bash scripts/build-runtime.sh "$out/runtime"
