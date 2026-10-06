$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\geom1088-20260930'
function Idle {if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile|^runtime-smoke|^jobbench|^Magpie'}){throw 'GPU lab busy'}}
Idle
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP'
foreach($side in 'old','new'){$d="$root\rt-$side";New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders"|Out-Null
foreach($arch in 'gfx1200','gfx1201'){Copy-Item "$game\$arch\*.hsaco" "$d\modules\$arch" -Force}
Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
$lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|ForEach-Object{$name=$_.FullName.Substring(("$d\modules\").Length).Replace('\','/');"$((Get-FileHash $_.FullName).Hash.ToLower())  $name"})
[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
foreach($c in @(@{n='old-1080';dll='old';h='1080';r=''},@{n='new-1080';dll='new';h='1080';r=''},@{n='new-1080-rows1152';dll='new';h='1080';r='1152'},@{n='new-1088';dll='new';h='1080';r='1088'},@{n='new-auto-1088';dll='new';h='auto';r='1088'},@{n='old-900';dll='old';h='900';r=''},@{n='new-900-rows1088';dll='new';h='900';r='1088'})){
 Idle;$d="$root\rt-$($c.dll)";$env:LMXXF_SHADER_DIR="$d\shaders";$env:DLSS5_NETWORK_HEIGHT=$c.h;if($c.r){$env:DLSS5_NETWORK_1080_ROWS=$c.r}else{Remove-Item Env:DLSS5_NETWORK_1080_ROWS -ErrorAction SilentlyContinue}
 $size=if($c.h -eq 'auto'){'1920x1080'}else{'1707x961'}
 & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$root\rt-$($c.dll)\LmxxfNrRuntime.dll" "$d\modules" $size 12 1 *> "$root\rt-$($c.n).log"
 if($LASTEXITCODE){throw "Runtime replay failed $($c.n)"}
 "$($c.n) hash=$([regex]::Match((Get-Content "$root\rt-$($c.n).log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value) $((Select-String -Path "$root\rt-$($c.n).log" -Pattern '1920x1088|1920x1152|1600x960' | select -first 1).Line)"
}
Remove-Item Env:DLSS5_NETWORK_1080_ROWS -ErrorAction SilentlyContinue
Idle;$d="$root\rt-new";$env:LMXXF_SHADER_DIR="$d\shaders";& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$root\rt-new\LmxxfNrRuntime.dll" "$d\modules" *> "$root\runtime-smoke.log"
if($LASTEXITCODE){throw 'Runtime smoke failed'};'SMOKE OK'
'RT_DONE'
