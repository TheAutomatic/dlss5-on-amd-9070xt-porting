#!/usr/bin/env bash
# results/pdl-1080-20261002. $1 = worktree at the base commit, $2 = candidate worktree, $3 = output dir.
set -euo pipefail
base=${1:?};cand=${2:?};out=${3:?};mkdir -p "$out"
B(){ (cd "$1" && x86_64-w64-mingw32-g++ -w -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -I src -I Development/HIP "$3" -o "$out/$2.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid); }
B "$base" benchmark-base Development/HIP/benchmark_vit_reuse.cpp
B "$cand" benchmark-P Development/HIP/benchmark_vit_reuse.cpp
(cd "$base" && bash scripts/build-runtime.sh "$out/rt-old");(cd "$cand" && bash scripts/build-runtime.sh "$out/rt-new")
sha256sum "$out"/*.exe "$out"/rt-*/*.dll | sed "s#$out/##"
