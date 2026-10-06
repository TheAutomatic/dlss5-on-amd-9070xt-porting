#!/bin/bash
ssh amd9070 "powershell -NoProfile -ExecutionPolicy Bypass -File D:\\DLSSNR-Lab\\skin-protect-20261004\\${1:-export}.ps1" > /tmp/skin-protect-run.log 2>&1 &
pid=$!
while kill -0 "$pid" 2>/dev/null; do
 ssh amd9070 'powershell -NoProfile -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\game-check.ps1 Stellar Onimusha Magpie Forza Cyberpunk' >/tmp/skin-protect-game.log 2>&1
 rc=$?
 if [ "$rc" != 1 ]; then
  ssh amd9070 'taskkill /F /IM benchmark.exe & taskkill /F /IM benchmark-prod.exe & taskkill /F /IM rt_bench.exe & taskkill /F /IM runtime-smoke.exe & taskkill /F /IM pending-probe.exe' >/dev/null 2>&1
  wait "$pid"; echo GAME_ABORT; exit 1
 fi
 sleep 15
done
wait "$pid"
