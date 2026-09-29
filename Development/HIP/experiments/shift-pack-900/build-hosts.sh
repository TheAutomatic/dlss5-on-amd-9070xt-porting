#!/usr/bin/env bash
# Benchmark hosts for results/shift-pack-900-20260930 (run from repo root; $1 = output dir).
set -euo pipefail
out=${1:?output dir}
for v in "A:-DHIP_C512_PAD16=0" "P:" "Pp:-DHIP_C512_PAD16_POISON=1" "Proll:-DHIP_SWIN_PERSISTENT_DIAGNOSTICS=1" "Pproll:-DHIP_C512_PAD16_POISON=1 -DHIP_SWIN_PERSISTENT_DIAGNOSTICS=1"; do
 n=${v%%:*}; d=${v#*:}
 x86_64-w64-mingw32-g++ -w -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -DHIP_SWIN_PERSISTENT=1 $d -I src -I Development/HIP Development/HIP/benchmark_vit_reuse.cpp -o "$out/benchmark-$n.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
done
