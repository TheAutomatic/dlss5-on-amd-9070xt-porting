$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\c512-direct-pack-20261004';$cc='D:\DLSSNR-Lab\multi-pass-predict-20261004\rtc_compile.exe'
$env:RTC_EXTRA_OPTS='-mllvm=-amdgpu-sched-strategy=max-ilp'
foreach($arch in 'gfx1201','gfx1200'){
 New-Item -ItemType Directory -Force "$r\$arch"|Out-Null
 foreach($mode in 'base','0','1','2','3'){
  & $cc "$r\$arch\$mode.hsaco" "$r\$mode.generated.hip" comgr $arch *> "$r\$arch\$mode.compile.log"
  if($LASTEXITCODE -ne 0){Get-Content "$r\$arch\$mode.compile.log";throw "compile failed $arch $mode"}
  "$arch $mode $((Get-FileHash "$r\$arch\$mode.hsaco").Hash)"
 }
}
Remove-Item Env:RTC_EXTRA_OPTS
