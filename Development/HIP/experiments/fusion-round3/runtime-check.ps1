$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fusion-round3'
function Idle {if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile|^runtime-smoke'}){throw 'GPU busy'}}
Idle
foreach($side in 'base','final'){
 $d="$r\re9-runtime-$side";New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders"|Out-Null
 Copy-Item "$r\baseline-gfx1200\*.hsaco" "$d\modules\gfx1200" -Force
 Copy-Item "$r\flat-A\*.hsaco" "$d\modules\gfx1201" -Force
 if($side -eq 'final'){foreach($arch in 'gfx1200','gfx1201'){Copy-Item "$r\production\$arch\*.hsaco" "$d\modules\$arch" -Force}}
 Copy-Item "$r\shaders\*" "$d\shaders" -Force
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|ForEach-Object{$name=$_.FullName.Substring(("$d\modules\").Length).Replace('\','/');"$((Get-FileHash $_.FullName).Hash.ToLower())  $name"})
 [IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)
}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0'
foreach($height in 900,1080){foreach($side in 'base','final'){
 Idle;$env:DLSS5_NETWORK_HEIGHT="$height";$d="$r\re9-runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders"
 & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$r\runtime-$side-$height.log"
 if($LASTEXITCODE){throw 'runtime replay failed'}
}}
foreach($height in 900,1080){$a=[regex]::Match((Get-Content "$r\runtime-base-$height.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value;$b=[regex]::Match((Get-Content "$r\runtime-final-$height.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value;if(!$a -or $a -ne $b){throw "Runtime output mismatch $height"};"RUNTIME SAME $height $a"}
Idle;$env:DLSS5_NETWORK_HEIGHT='900';$d="$r\re9-runtime-final";$env:LMXXF_SHADER_DIR="$d\shaders"
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$r\runtime-smoke.log"
if($LASTEXITCODE){throw 'runtime smoke failed'}
'RUNTIME_DONE (no game files changed)'
