#!/bin/bash
set -euo pipefail
mh=${1:?MinHook source};sdk=${2:?NGX SDK include};out=${3:?output exe}
d=$(mktemp -d)
for u in hook trampoline buffer hde/hde64;do x86_64-w64-mingw32-gcc -O2 -I"$mh/include" -I"$mh/src" -c "$mh/src/$u.c" -o "$d/${u##*/}.o";done
x86_64-w64-mingw32-g++ -w -std=c++17 -O2 -static -municode -DORACLE_HEIGHT=1152 -I"$sdk" -I"$mh/include" "$(dirname "$0")/ngx_predown.cpp" "$d"/*.o -o "$out" -ld3d12 -ldxgi -ldxguid
