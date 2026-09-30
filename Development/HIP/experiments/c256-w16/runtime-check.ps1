# RE9 runtime: old runtime (Onimusha fd4b2c0c) + installed modules  vs  new runtime + W16 c64-wave2/swin-persistent; new runtime + old modules = fallback.
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\c256-w16-20260930'
function Idle {if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile|^runtime-smoke|^jobbench|^Magpie'}){throw 'GPU lab busy'}}
Idle
$oldRt='C:\XboxGames\Onimusha- Way of the Sword\Content\LmxxfNrRuntime.dll'
foreach($side in 'old','new','fallback'){
 $d="$root\runtime-$side";New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders"|Out-Null
 foreach($arch in 'gfx1200','gfx1201'){Copy-Item "$root\baseline\$arch\*.hsaco" "$d\modules\$arch" -Force;if($side -eq 'new'){Copy-Item "$root\build-final\$arch\*.hsaco" "$d\modules\$arch" -Force}}
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item $(if($side -eq 'old'){$oldRt}else{"$root\LmxxfNrRuntime.dll"}) "$d\LmxxfNrRuntime.dll" -Force
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|ForEach-Object{$name=$_.FullName.Substring(("$d\modules\").Length).Replace('\','/');"$((Get-FileHash $_.FullName).Hash.ToLower())  $name"})
 [IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)
}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
foreach($height in 900,1080){foreach($side in 'old','new','fallback'){
 Idle;$env:DLSS5_NETWORK_HEIGHT="$height";$d="$root\runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders"
 & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$root\runtime-$side-$height.log"
 if($LASTEXITCODE){throw "Runtime replay failed $side $height"}
}
 $h=@('old','new','fallback'|ForEach-Object{[regex]::Match((Get-Content "$root\runtime-$_-$height.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value})
 if(!$h[0] -or $h[0] -ne $h[1] -or $h[0] -ne $h[2]){throw "Runtime hash mismatch $height $($h -join ' ')"};"RUNTIME SAME $height $($h[0])"}
Idle;$d="$root\runtime-new";$env:LMXXF_SHADER_DIR="$d\shaders"
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$root\runtime-smoke.log"
if($LASTEXITCODE){throw 'Runtime smoke failed'}
"RUNTIME $((Get-FileHash "$root\LmxxfNrRuntime.dll").Hash)"
'RUNTIME_DONE'
