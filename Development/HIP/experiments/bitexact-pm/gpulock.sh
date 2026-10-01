#!/bin/bash
# usage: gpulock.sh <task> <remote powershell file> [args...]  -- acquire D:\DLSSNR-Lab\gpu.lock (wait <=30 min), run, release
task=$1;shift
for i in $(seq 1 31); do
 out=$(ssh amd9070 "if exist D:\DLSSNR-Lab\gpu.lock (type D:\DLSSNR-Lab\gpu.lock) else (echo $task %DATE% %TIME% > D:\DLSSNR-Lab\gpu.lock & echo LOCKED)")
 echo "$(date +%T) $out"
 if echo "$out" | grep -q LOCKED; then
  if ssh amd9070 "tasklist | findstr /I \"SB-Win64 LOP-Win64 Onimusha re9 SandFall\""; then ssh amd9070 "del D:\DLSSNR-Lab\gpu.lock"; echo GAME; exit 1; fi
  ssh amd9070 "powershell -NoProfile -ExecutionPolicy Bypass -File $*"; rc=$?
  ssh amd9070 "del D:\DLSSNR-Lab\gpu.lock"; echo "DONE rc=$rc"; exit $rc
 fi
 sleep 60
done
echo GAVEUP; exit 2
