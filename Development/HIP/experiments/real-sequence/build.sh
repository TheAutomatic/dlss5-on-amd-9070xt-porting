#!/usr/bin/env bash
set -euo pipefail
sequence_here=$(cd -- "$(dirname -- "$0")" && pwd)
sequence_root=$(cd -- "$sequence_here/../../../.." && pwd)
sequence_out=${1:?usage: build.sh OUTPUT_DIRECTORY MINHOOK_SOURCE RESHADE_INCLUDE}
sequence_minhook=${2:?minhook source required}
sequence_reshade=${3:?reshade include required}
python3 "$sequence_here/prepare.py" "$sequence_out"
ln -sf /usr/x86_64-w64-mingw32/include/windows.h "$sequence_out/Windows.h"
sequence_objects=()
for sequence_unit in hook trampoline buffer hde/hde64; do
 sequence_obj="$sequence_out/${sequence_unit##*/}.o"
 x86_64-w64-mingw32-gcc -O2 -I"$sequence_minhook/include" -I"$sequence_minhook/src" -c "$sequence_minhook/src/$sequence_unit.c" -o "$sequence_obj"
 sequence_objects+=("$sequence_obj")
done
x86_64-w64-mingw32-g++ -w -std=c++17 -O2 -shared -static -DNATIVE_ORDER_NEURAL -DDLSS5_USE_HIP=1 -I"$sequence_out" -I"$sequence_root/src" -I"$sequence_minhook/include" -I"$sequence_reshade" "$sequence_out/native_submission_order_probe.cpp" "${sequence_objects[@]}" -o "$sequence_out/real-sequence.addon64" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
sha256sum "$sequence_out/real-sequence.addon64"
