#!/usr/bin/env bash
# results/free-res-20261002. $1 = worktree at the base commit, $2 = worktree with the free-res patch, $3 = output dir.
# benchmark-{base,F}.exe = benchmark_vit_reuse.cpp (regression / ABBA harness), ngx-{base,F}.exe = bench_ngx.cpp (any BENCH_WxBENCH_H input),
# rt-{old,new} = RE9 runtime.
set -euo pipefail
base=${1:?};cand=${2:?};out=${3:?};mkdir -p "$out"
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
B(){ (cd "$1" && x86_64-w64-mingw32-g++ -w -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -I src -I Development/HIP "$3" -o "$out/$2.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid); }
B "$base" benchmark-base Development/HIP/benchmark_vit_reuse.cpp
B "$cand" benchmark-F Development/HIP/benchmark_vit_reuse.cpp
B "$base" ngx-base "$here/bench_ngx.cpp"
B "$cand" ngx-F "$here/bench_ngx.cpp"
(cd "$base" && bash scripts/build-runtime.sh "$out/rt-old");(cd "$cand" && bash scripts/build-runtime.sh "$out/rt-new")
sha256sum "$out"/*.exe "$out"/rt-*/*.dll | sed "s#$out/##"
