#!/bin/bash
# guard.sh <remote ps1 args...> (multi-pass): wait for no game (5 min polls), run; watcher every 15 s, on a game kills bench + drops lock, reruns.
G='SB-Win64 StellarBlade Onimusha re9.exe SandFall LOP-Win64'
game(){ ssh amd9070 "powershell -NoProfile -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\game-check.ps1 \"$G\"" >/dev/null 2>&1; }
while true; do
 while game; do echo "$(date +%T) game running, wait"; timeout 300 tail -f /dev/null; done
 ssh amd9070 "powershell -NoProfile -ExecutionPolicy Bypass -File $*" & pid=$!
 aborted=0
 while kill -0 $pid 2>/dev/null; do
  if game; then echo "$(date +%T) GAME -> abort"; aborted=1
   ssh amd9070 "taskkill /F /IM benchmark-base.exe & taskkill /F /IM benchmark-M.exe & taskkill /F /IM benchmark-Mroll.exe & taskkill /F /IM rt_bench.exe & taskkill /F /IM runtime-smoke.exe & del D:\DLSSNR-Lab\gpu.lock" >/dev/null 2>&1
   wait $pid; break; fi
  timeout 15 tail -f /dev/null
 done
 wait $pid 2>/dev/null
 [ $aborted = 0 ] && { echo GUARD_DONE; exit 0; }
done
