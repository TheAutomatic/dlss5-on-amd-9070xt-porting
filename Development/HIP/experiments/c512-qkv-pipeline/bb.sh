#!/bin/bash
# bb.sh name defs  -> build on 9070, fetch, disasm
S=/tmp/claude-1000/-home-lmxxf-work-ai-theorys-study/129f068a-8529-42b4-b98b-08071124e161/scratchpad; R='D:\DLSSNR-Lab\hip-backend\c512-qkv-pipeline-20261001'; cd $S
scp -q /home/lmxxf/work/dlss5-c512-qkvpipe/hip/c512_qkv_attention_compact.inc amd9070:"D:/DLSSNR-Lab/hip-backend/c512-qkv-pipeline-20261001/src/"
for c in "$@"; do n=${c%%:*}; ssh amd9070 "powershell -ExecutionPolicy Bypass -Command \"& $R\b.ps1 -Name $n -Defs '${c#*:}'\"" >/dev/null; scp -q amd9070:"D:/DLSSNR-Lab/hip-backend/c512-qkv-pipeline-20261001/build-$n/gfx1201/c512-m32-mh.hsaco" $n.hsaco; /home/lmxxf/work/llvm-build-dlss5-gfx12/bin/llvm-objdump -d --mcpu=gfx1201 --disassemble-symbols=c512_qkv_attention_compact $n.hsaco | sed 's#//.*##' > $n.s; python3 isa.py $n.hsaco; done
