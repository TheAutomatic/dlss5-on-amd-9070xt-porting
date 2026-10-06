#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
repo_root=${1:?Usage: build-microbench.sh /path/to/297 [output-directory]}
out_dir=${2:-$script_dir/build}
mkdir -p "$out_dir"
"${LMXXF_GXX:-x86_64-w64-mingw32-g++}" -std=c++17 -O2 -static -I "$repo_root/Development/HIP" -I "$script_dir" "$script_dir/microbench.cpp" -o "$out_dir/microbench.exe"
