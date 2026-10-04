#!/bin/bash
stage=${1:?stage}
ssh amd9070 "powershell -NoProfile -ExecutionPolicy Bypass -File D:\\DLSSNR-Lab\\issue4-igpu-20261004\\$stage.ps1" > "/tmp/issue4-$stage.log" 2>&1 &
pid=$!
while kill -0 "$pid" 2>/dev/null; do
 ssh amd9070 'powershell -NoProfile -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\game-check.ps1 Stellar Onimusha Magpie Forza Cyberpunk' >/tmp/issue4-game.log 2>&1
 rc=$?;if [ "$rc" != 1 ]; then
  ssh amd9070 'taskkill /F /IM ngx-N.exe & taskkill /F /IM ngx-base.exe & taskkill /F /IM ngx-c256.exe & taskkill /F /IM ngx-timing.exe & taskkill /F /IM ngx-quality.exe & taskkill /F /IM benchmark-A.exe & taskkill /F /IM benchmark-N.exe & taskkill /F /IM rt_bench.exe & taskkill /F /IM runtime-smoke.exe' >/dev/null 2>&1
  wait "$pid";exit 1
 fi
 sleep 15
done
wait "$pid"
