#!/usr/bin/env bash
set -euo pipefail
out=${1:?isolated output directory}
here=$(cd "$(dirname "$0")" && pwd)
for variant in P Q U T D; do python3 "$here/prepare-source.py" "$out/runner-$variant" --variant "$variant"; done
for variant in P G Q R U T D; do
 case $variant in
 P) sub=P;defs=(-DVIT_PACK_STREAM_HOST=1);;
 G) sub=P;defs=(-DVIT_PACK_STREAM_HOST=1 -DVIT_GATHER_PACK_HOST=1);;
 Q) sub=Q;defs=(-DVIT_PACK_STREAM_HOST=1);;
 R) sub=Q;defs=(-DVIT_PACK_STREAM_HOST=1 -DVIT_GATHER_PACK_HOST=1);;
 U) sub=U;defs=(-DW2_UP_FUSED_HOST=1);;
 T) sub=T;defs=(-DCW_UP_FUSED_HOST=1);;
 D) sub=D;defs=(-DW2_DOWN_FUSED_HOST=1);;
 esac
 x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 "${defs[@]}" -I "$out/runner-$sub/src" -I "$out/runner-$sub/Development/HIP" "$out/runner-$sub/Development/HIP/benchmark_vit_reuse.cpp" -o "$out/benchmark-$variant.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
done
python3 "$here/prepare-source.py" "$out/host035" --revision 0.35
x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -I "$out/host035/src" -I "$out/host035/Development/HIP" "$out/host035/Development/HIP/benchmark_vit_reuse.cpp" -o "$out/benchmark-035.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
