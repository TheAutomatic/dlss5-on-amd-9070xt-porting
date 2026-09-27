#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../../.."
OUT="${1:-/tmp/re9-runtime-leak-build}"
mkdir -p "$OUT"
bash scripts/build-runtime.sh "$OUT"
for probe in semaphore module bridge; do
 x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -I src -I Development/HIP "Development/HIP/experiments/re9-runtime-leak/${probe}_probe.cpp" -o "$OUT/${probe}_probe.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid -lpsapi
done
