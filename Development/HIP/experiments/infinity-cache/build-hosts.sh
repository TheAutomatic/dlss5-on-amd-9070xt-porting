#!/usr/bin/env bash
# results/infinity-cache-20260930: apply pool-hot.patch first (git apply), run from repo root; $1 = output dir
set -euo pipefail; out=${1:?}
for v in "A:" "P:-DHIP_POOL_HOT=1" "Aroll:-DHIP_SWIN_PERSISTENT_DIAGNOSTICS=1" "Proll:-DHIP_POOL_HOT=1 -DHIP_SWIN_PERSISTENT_DIAGNOSTICS=1"; do n=${v%%:*}; d=${v#*:}
 x86_64-w64-mingw32-g++ -w -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -DHIP_SWIN_PERSISTENT=1 $d -I src -I Development/HIP Development/HIP/benchmark_vit_reuse.cpp -o "$out/benchmark-$n.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid; done
