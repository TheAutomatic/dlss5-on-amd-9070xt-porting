#!/bin/bash
set -euo pipefail
base=${1:?baseline worktree at d02b423c};cand=${2:?candidate worktree};out=${3:?output dir}
mkdir -p "$out"
for side in A C; do
 root=$base;[ "$side" = C ] && root=$cand
 (cd "$root" && x86_64-w64-mingw32-g++ -w -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -I src -I Development/HIP Development/HIP/benchmark_vit_reuse.cpp -o "$out/benchmark-$side.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid)
done
(cd "$cand" && x86_64-w64-mingw32-g++ -w -std=c++17 -O2 -static -municode -DDLSS5_BENCH_BRIDGE_ISOLATE -D_WIN32_WINNT=0x0A00 -I src -I Development/HIP Development/HIP/experiments/native-1440/bench.cpp -o "$out/ngx-timing.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid)
(cd "$cand" && LMXXF_GXX=x86_64-w64-mingw32-g++-posix bash scripts/build-runtime.sh "$out")
sha256sum "$out"/*.exe "$out"/*.dll
