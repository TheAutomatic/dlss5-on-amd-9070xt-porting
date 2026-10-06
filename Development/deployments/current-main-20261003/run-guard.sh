#!/bin/bash
set -u
stage=${1:-verify}
ssh amd9070 "powershell -NoProfile -ExecutionPolicy Bypass -File D:\\DLSSNR-Lab\\current-main-20261003\\$stage.ps1" > "/tmp/current-main-$stage.log" 2>&1 &
pid=$!
while kill -0 "$pid" 2>/dev/null; do
 ssh amd9070 'powershell -NoProfile -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\game-check.ps1 Stellar Onimusha Magpie Forza Cyberpunk' >/tmp/current-main-game.log 2>&1
 rc=$?
 if [ "$rc" != 1 ]; then
  ssh amd9070 'taskkill /F /IM benchmark-main.exe & taskkill /F /IM benchmark-approved.exe & taskkill /F /IM rt_bench.exe & taskkill /F /IM runtime-smoke.exe' >/dev/null 2>&1
  wait "$pid"; echo GAME_ABORT; exit 1
 fi
 sleep 15
done
wait "$pid"
