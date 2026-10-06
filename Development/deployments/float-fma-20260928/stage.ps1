$ErrorActionPreference='Stop'
$r='D:\DLSSNR-Lab\hip-backend\float-fma';$d='D:\DLSSNR-Lab\float-fma-20260928'
foreach($arch in 'gfx1200','gfx1201'){
 New-Item -ItemType Directory -Force "$d\payload\$arch"|Out-Null
 $src=if($arch -eq 'gfx1201'){"$r\flat-P"}else{"$r\production-gfx1200"}
 $m=Get-Content "$d\payload.json" -Raw|ConvertFrom-Json
 foreach($f in $m.files|Where-Object{$_.arch -eq $arch}){
  Copy-Item "$src\$($f.module)" "$d\payload\$arch\$($f.module)" -Force
  if((Get-FileHash "$d\payload\$arch\$($f.module)").Hash -ne $f.candidate){throw 'payload hash'}
 }
}
Write-Output 'Payload staged; no game changes'
