$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929'
function Idle {if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile|^runtime-smoke|^jobbench'}){throw 'GPU lab busy'}}
Idle
foreach($side in 'off','on','missing'){
 $d="$root\runtime-$side";New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders"|Out-Null
 foreach($arch in 'gfx1200','gfx1201'){
  Copy-Item "$root\baseline\$arch\*.hsaco" "$d\modules\$arch" -Force
  if($side -ne 'missing'){Copy-Item "$root\production\$arch\swin-persistent.hsaco" "$d\modules\$arch" -Force}
 }
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item "$root\LmxxfNrRuntime.dll" "$d\LmxxfNrRuntime.dll" -Force
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|ForEach-Object{$name=$_.FullName.Substring(("$d\modules\").Length).Replace('\','/');"$((Get-FileHash $_.FullName).Hash.ToLower())  $name"})
 [IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)
}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0'
foreach($height in 900,1080){foreach($side in 'off','on'){
 Idle;$env:DLSS5_NETWORK_HEIGHT="$height";$env:DLSS5_HIP_SWIN_RUN=$(if($side -eq 'on'){'1'}else{'0'})
 $d="$root\runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders"
 & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$root\runtime-$side-$height.log"
 if($LASTEXITCODE){throw 'Runtime replay failed'}
}}
foreach($height in 900,1080){$a=[regex]::Match((Get-Content "$root\runtime-off-$height.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value;$b=[regex]::Match((Get-Content "$root\runtime-on-$height.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value;if(!$a -or $a -ne $b){throw 'Runtime hash mismatch'};"RUNTIME SAME $height $a"}
Idle;$env:DLSS5_NETWORK_HEIGHT='900';$env:DLSS5_HIP_SWIN_RUN='1';$d="$root\runtime-missing";$env:LMXXF_SHADER_DIR="$d\shaders"
& 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$root\runtime-missing.log"
if($LASTEXITCODE){throw 'Missing-module replay failed'}
$a=[regex]::Match((Get-Content "$root\runtime-off-900.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value;$b=[regex]::Match((Get-Content "$root\runtime-missing.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value
if(!$b -or $a -ne $b){throw 'Missing-module output changed'}
Idle;$d="$root\runtime-on";$env:LMXXF_SHADER_DIR="$d\shaders"
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$root\runtime-smoke.log"
if($LASTEXITCODE){throw 'Runtime smoke failed'}
'RUNTIME_DONE (RE9 game unchanged)'
