#!/usr/bin/env bash
set -euo pipefail
out=${1:?isolated staging directory}
python3 "$(dirname "$0")/prepare-runner.py" "$out/runner"
for mode in 0 1 2; do
 name=base
 if [ "$mode" = 1 ]; then name=fused; fi
 if [ "$mode" = 2 ]; then name=tier; fi
 x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -DC256_WHOLE_BLOCK="$mode" -I "$out/runner/src" -I "$out/runner/Development/HIP" "$out/runner/Development/HIP/benchmark_vit_reuse.cpp" -o "$out/benchmark-$name.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
done

# Optional dispatch trace; never use the instrumented binary for timing.
x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -DC256_WHOLE_BLOCK=1 -DC256_TRACE=1 -I "$out/runner/src" -I "$out/runner/Development/HIP" "$out/runner/Development/HIP/benchmark_vit_reuse.cpp" -o "$out/benchmark-trace.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
