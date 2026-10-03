#!/bin/bash
# usage: gpulock.sh <task> -- <remote powershell file> [args...]
# Acquires D:\DLSSNR-Lab\gpu.lock (wait <=30 min), refuses to run while a game is up
# (D:\DLSSNR-Lab\game-check.ps1, exit 0 = game running), runs, re-checks, releases.
task=$1;shift
[ "$1" = "--" ] && shift
GAMES="SB-Win64 LOP-Win64 Onimusha re9 SandFall Forza Cyberpunk BlackMyth"
for i in $(seq 1 31); do
 out=$(ssh amd9070 "if exist D:\DLSSNR-Lab\gpu.lock (type D:\DLSSNR-Lab\gpu.lock) else (echo $task %DATE% %TIME% > D:\DLSSNR-Lab\gpu.lock & echo LOCKED)")
 echo "$(date +%T) $out"
 if echo "$out" | grep -q LOCKED; then
  if ssh amd9070 "powershell -NoProfile -ExecutionPolicy Bypass -File D:\\DLSSNR-Lab\\game-check.ps1 $GAMES"; then
   ssh amd9070 "del D:\DLSSNR-Lab\gpu.lock"; echo GAME-RUNNING; exit 1
  fi
  ssh amd9070 "powershell -NoProfile -ExecutionPolicy Bypass -File $*"; rc=$?
  ssh amd9070 "powershell -NoProfile -ExecutionPolicy Bypass -File D:\\DLSSNR-Lab\\game-check.ps1 $GAMES"
  ssh amd9070 "del D:\DLSSNR-Lab\gpu.lock"; echo "DONE rc=$rc"; exit $rc
 fi
 sleep 60
done
echo GAVEUP; exit 2
