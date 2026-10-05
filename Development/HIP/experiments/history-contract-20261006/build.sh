#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
: "${CUDA_INCLUDE:=/usr/local/cuda/include}"
: "${MINHOOK_INCLUDE:=/home/lmxxf/work/tmp-test/minhook.KmbJvO/repo/include}"
: "${MINHOOK_OBJECTS:=/home/lmxxf/work/tmp-test/dlssnr-oracle-build}"
: "${NGX_INCLUDE:=/tmp/gh-pristine/OptiScaler-DLSSNR-PreSR-Multipass-main/external/nvngx_dlss_sdk}"
: "${PROBE_OUTPUT:=/tmp/history-contract-20261006/ngx-history-contract.exe}"
mkdir -p "$(dirname -- "$PROBE_OUTPUT")"
x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode \
 -I"$CUDA_INCLUDE" -I"$MINHOOK_INCLUDE" -I"$NGX_INCLUDE" \
 "$script_dir/ngx_history_contract.cpp" \
 "$MINHOOK_OBJECTS/buffer.o" "$MINHOOK_OBJECTS/hook.o" \
 "$MINHOOK_OBJECTS/trampoline.o" "$MINHOOK_OBJECTS/hde64.o" \
 -ld3d12 -ldxgi -o "$PROBE_OUTPUT"
