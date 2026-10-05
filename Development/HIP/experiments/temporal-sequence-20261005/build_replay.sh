#!/usr/bin/env bash
set -euo pipefail
replay_here="$(cd -- "$(dirname -- "$0")" && pwd)"
replay_root="$(cd -- "$replay_here/../../../.." && pwd)"
replay_out="${1:?usage: build_replay.sh OUTPUT_DIRECTORY}"
mkdir -p -- "$replay_out"
python3 "$replay_here/prepare_options.py" "$replay_out"
ln -sf /usr/x86_64-w64-mingw32/include/windows.h "$replay_out/Windows.h"
x86_64-w64-mingw32-g++ -w -std=c++17 -O1 -static -municode -I"$replay_out" -I"$replay_root/src" "$replay_here/replay_convert.cpp" -o "$replay_out/replay-convert.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
x86_64-w64-mingw32-g++ -w -std=c++17 -O2 -static -I"$replay_root/Development/HIP" "$replay_here/store_probe.cpp" -o "$replay_out/store-probe.exe"
x86_64-w64-mingw32-g++ -w -std=c++20 -O1 -static -I"$replay_root/Development/HIP" -I"$replay_root/src" -I"$replay_out" "$replay_here/sequence.cpp" -o "$replay_out/sequence.exe"
sha256sum "$replay_out/replay-convert.exe" "$replay_out/store-probe.exe" "$replay_out/sequence.exe"
