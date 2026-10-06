$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\c512-activation-lut-20261004'
$compiler='D:\DLSSNR-Lab\multi-pass-predict-20261004\rtc_compile.exe'
$env:RTC_EXTRA_OPTS='-mllvm=-amdgpu-sched-strategy=max-ilp'
foreach($target in 'gfx1201','gfx1200'){
 New-Item -ItemType Directory -Force "$root\$target"|Out-Null
 foreach($name in 'baseline','macro0','candidate'){
  & $compiler "$root\$target\$name.hsaco" "$root\$name.generated.hip" comgr $target *> "$root\$target\$name.compile.log"
  if($LASTEXITCODE -ne 0){Get-Content "$root\$target\$name.compile.log";throw "compile $target $name failed"}
  "$target $name $((Get-FileHash "$root\$target\$name.hsaco").Hash)"
 }
}
Remove-Item Env:RTC_EXTRA_OPTS
