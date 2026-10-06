$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\vit960-20261004';$compiler='D:\DLSSNR-Lab\multi-pass-predict-20261004\rtc_compile.exe'
Remove-Item Env:RTC_EXTRA_OPTS -ErrorAction SilentlyContinue
foreach($target in 'gfx1201','gfx1200'){
 New-Item -ItemType Directory -Force "$root\$target"|Out-Null
 foreach($fast in 0,15){foreach($name in 'baseline','candidate'){
  & $compiler "$root\$target\$name-$fast.hsaco" "$root\$name-$fast.generated.hip" comgr $target *> "$root\$target\$name-$fast.compile.log"
  if($LASTEXITCODE -ne 0){Get-Content "$root\$target\$name-$fast.compile.log";throw "compile failed $target $name $fast"}
  "$target $name-$fast $((Get-FileHash "$root\$target\$name-$fast.hsaco").Hash)"
 }}
}
