#!/bin/bash
ssh amd9070 "powershell -NoProfile -ExecutionPolicy Bypass -File D:\\DLSSNR-Lab\\multi-pass-predict-20261004\\${1:-export}.ps1" > /tmp/mp-predict-run.log 2>&1 &
pid=$!
while kill -0 "$pid" 2>/dev/null; do
 ssh amd9070 'powershell -NoProfile -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\game-check.ps1 Stellar Onimusha Magpie Forza Cyberpunk' >/tmp/mp-predict-game.log 2>&1
 rc=$?
 if [ "$rc" != 1 ]; then
  ssh amd9070 'taskkill /F /IM benchmark-predict.exe & taskkill /F /IM benchmark-base.exe & taskkill /F /IM rt_bench.exe & taskkill /F /IM runtime-smoke.exe' >/dev/null 2>&1
  wait "$pid"; echo GAME_ABORT; exit 1
 fi
 sleep 15
done
wait "$pid"
