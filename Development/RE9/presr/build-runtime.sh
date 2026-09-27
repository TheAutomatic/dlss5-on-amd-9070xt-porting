#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../.."
host=/tmp/re9-upstream-bridge-review
runtime="$host/OptiScaler-DLSSNR-PreSR-Multipass-main/OptiScaler/dlssnr/backend/lmxxf_runtime"
mkdir -p /tmp/re9-presr-build
python3 Development/RE9/presr/prepare-host.py
# Build the canonical runtime; the pinned upstream runtime is a historical patch fixture.
bash scripts/build-runtime.sh /tmp/re9-presr-build
x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode "$host/tests/lmxxf_nr_gpu.cpp" -o /tmp/re9-presr-build/runtime-smoke.exe -ld3d12 -ldxgi -ldxguid
