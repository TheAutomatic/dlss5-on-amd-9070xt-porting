#!/usr/bin/env bash
# results/geom-1088-20260930. $1 = worktree at the base commit, $2 = worktree with the 1088 patch, $3 = output dir.
set -euo pipefail
base=${1:?};cand=${2:?};out=${3:?};mkdir -p "$out"
B(){ (cd "$1" && x86_64-w64-mingw32-g++ -w -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -DHIP_SWIN_PERSISTENT=1 $3 -I src -I Development/HIP Development/HIP/benchmark_vit_reuse.cpp -o "$out/benchmark-$2.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid); }
B "$base" base "";B "$cand" P "";B "$cand" Proll "-DHIP_SWIN_PERSISTENT_DIAGNOSTICS=1"
(cd "$base" && bash scripts/build-runtime.sh "$out/rt-old");(cd "$cand" && bash scripts/build-runtime.sh "$out/rt-new")
