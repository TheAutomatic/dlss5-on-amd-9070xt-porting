#!/usr/bin/env bash
set -euo pipefail
out=${1:?isolated output directory}
here=$(cd "$(dirname "$0")" && pwd)
python3 "$here/prepare-runner.py" "$out/fusion"
for variant in base fused; do
 mode=0
 if [ "$variant" = fused ]; then mode=1; fi
 x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -DC512_QKV_ATTN_EXPERIMENT="$mode" -DC512_FUSED_WAVES=2 -I "$out/fusion/src" -I "$out/fusion/Development/HIP" "$out/fusion/Development/HIP/benchmark_vit_reuse.cpp" -o "$out/benchmark-$variant.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
done
for mode in M W; do
 python3 "$here/prepare-extra-host.py" "$mode" "$out/$mode"
 define=C512_T8_M32_HOST
 name=m32
 if [ "$mode" = W ]; then define=C256_WAVE16_EXPERIMENT; name=wave16; fi
 x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -D"$define"=1 -I "$out/$mode/src" -I "$out/$mode/Development/HIP" "$out/$mode/Development/HIP/benchmark_vit_reuse.cpp" -o "$out/benchmark-$name.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
done
