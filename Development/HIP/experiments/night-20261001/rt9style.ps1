# rt9style.ps1: RE9 runtime DLSS5_STYLE from the flags file. old = installed runtime (DC2D445E), new = whitelist fix; same installed modules.
# Cases (tag: runtime, flags-file line, env): d_old/d_new default (no file), f1_new file STYLE=1, f0_new file STYLE=0, e0_new env 0, e0_old env 0, f0_old file 0.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\night-20261001\rt9';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
$cases=@(@('d_old','old','',''),@('d_new','new','',''),@('f1_new','new','1',''),@('f0_new','new','0',''),@('e0_new','new','','0'),@('e0_old','old','','0'),@('f0_old','old','0',''))
foreach($c in $cases){$d="$root\$($c[0])";Remove-Item -Recurse -Force $d -EA 0;New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders","$d\DLSS5-AMD"|Out-Null
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$oni\$hip\$a\*.hsaco" "$d\modules\$a" -Force}
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item $(if($c[1] -eq 'old'){"$oni\LmxxfNrRuntime.dll"}else{"$root\LmxxfNrRuntime-new.dll"}) "$d\LmxxfNrRuntime.dll" -Force
 if($c[2]){[IO.File]::WriteAllLines("$d\DLSS5-AMD\native-game-flags.txt",@("DLSS5_STYLE=$($c[2])"))}
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)}
"old runtime $((Get-FileHash "$oni\LmxxfNrRuntime.dll").Hash.Substring(0,8)) new $((Get-FileHash "$root\LmxxfNrRuntime-new.dll").Hash.Substring(0,8))"
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
foreach($height in 900,1080){foreach($c in $cases){
 Remove-Item Env:DLSS5_STYLE -EA 0;if($c[3]){$env:DLSS5_STYLE=$c[3]}
 $env:DLSS5_NETWORK_HEIGHT="$height";$d="$root\$($c[0])";$env:LMXXF_SHADER_DIR="$d\shaders"
 & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$root\$($c[0])-$height.log"
 if($LASTEXITCODE){throw "rt_bench failed $($c[0]) $height"}
 $log=Get-Content "$root\$($c[0])-$height.log" -Raw
 "RUNTIME $height $($c[0]) hash=$([regex]::Match($log,'hash=([0-9a-f]+)').Groups[1].Value) $([regex]::Match($log,'flags:[^\r\n]*').Value)"}}
Remove-Item Env:DLSS5_STYLE -EA 0
$d="$root\d_new";$env:LMXXF_SHADER_DIR="$d\shaders"
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$root\runtime-smoke.log"
"SMOKE exit=$LASTEXITCODE";Get-Content "$root\runtime-smoke.log" -Tail 3
