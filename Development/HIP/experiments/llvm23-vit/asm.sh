#!/bin/bash
# asm.sh in.s out.hsaco : assemble with LLVM23 (true16 off) and link
B=$HOME/work/llvm-build-23/bin
$B/clang -cc1as -triple amdgcn-amd-amdhsa -target-cpu gfx1201 -target-feature -real-true16 -filetype obj "$1" -o "${2%.hsaco}.o" && $B/ld.lld --no-undefined -shared -plugin-opt=mcpu=gfx1201 "${2%.hsaco}.o" -o "$2"
