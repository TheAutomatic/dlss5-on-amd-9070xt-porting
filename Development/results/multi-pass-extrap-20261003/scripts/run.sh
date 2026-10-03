#!/bin/bash
# run.sh: wait (blocking, one wait per 5 min, quiet) for no game + free gpu.lock, take it, run export.ps1 with a 15 s game watchdog, drop lock.
G='SB-Win64 StellarBlade Onimusha re9.exe SandFall LOP-Win64 Magpie'
D='/home/lmxxf/work/ai-theorys-study/wechat/assets/297/Development/results/multi-pass-extrap-20261003/scripts'
scp -q $D/export.ps1 amd9070:D:/DLSSNR-Lab/hip-backend/multi-pass-extrap-20261003/export.ps1 || { ssh amd9070 "mkdir D:\DLSSNR-Lab\hip-backend\multi-pass-extrap-20261003"; scp -q $D/export.ps1 amd9070:D:/DLSSNR-Lab/hip-backend/multi-pass-extrap-20261003/export.ps1; }
while true; do
 out=$(ssh amd9070 "powershell -NoProfile -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\game-check.ps1 \"$G\" >nul && (echo GAME) || (if exist D:\DLSSNR-Lab\gpu.lock (echo BUSY) else (echo multi-pass-extrap %DATE% %TIME% > D:\DLSSNR-Lab\gpu.lock & echo LOCKED))")
 [[ $out == *LOCKED* ]] && break
 timeout 300 tail -f /dev/null
done
echo "$(date +%T) lock taken"
ssh amd9070 "powershell -NoProfile -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\hip-backend\multi-pass-extrap-20261003\export.ps1" & pid=$!
while kill -0 $pid 2>/dev/null; do
 if ssh amd9070 "powershell -NoProfile -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\game-check.ps1 \"$G\"" >/dev/null 2>&1; then echo GAME_ABORT; ssh amd9070 "taskkill /F /IM benchmark-M.exe" >/dev/null 2>&1; break; fi
 timeout 15 tail -f /dev/null
done
wait $pid; rc=$?
ssh amd9070 "findstr multi-pass-extrap D:\DLSSNR-Lab\gpu.lock >/dev/null && del D:\DLSSNR-Lab\gpu.lock"; echo "DONE rc=$rc"
