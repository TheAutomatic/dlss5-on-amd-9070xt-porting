# c512 FFN F8W install: Stellar add-on (HEAD + HIP_C512_FFN_F8W host) + c512-m32-deep both arches; Onimusha RE9 runtime + modules mirrored; flags untouched; backups first. Then RE9 replay (old backup / new / fallback) + smoke.
$ErrorActionPreference='Stop';$mine='D:\DLSSNR-Lab\hip-backend\c512-qkv-pipeline-20261001'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
if(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^LOP-Win'}){throw 'game running'}
$flags=Get-Content "$game\DLSS5-AMD\native-game-flags.txt" -Raw
foreach($e in 'DLSS5_DIRECT_IO=3','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_HIP_SWIN_RUN=1'){if($flags -notmatch "(?m)^\s*$e\s*$"){throw "flag $e"}}
$stamp=Get-Date -Format yyyyMMdd-HHmmss
function Sums($h){$u=New-Object Text.UTF8Encoding($false);$l=@(Get-ChildItem $h -Recurse -Filter '*.hsaco'|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($h.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$h\SHA256SUMS",$l,$u);$l.Count}
$sb="$mine\backups\stellar-$stamp-ffnf8w";$ob="D:\DLSSNR-Lab\onimusha-backups\$stamp-ffnf8w"
New-Item -ItemType Directory -Force $sb|Out-Null;Copy-Item "$game\dlss5-amd.addon64" $sb;Copy-Item "$game\$hip\SHA256SUMS" $sb
foreach($a in 'gfx1200','gfx1201'){New-Item -ItemType Directory -Force "$sb\$a"|Out-Null;Copy-Item "$game\$hip\$a\c512-m32-deep.hsaco" "$sb\$a\"}
New-Item -ItemType Directory -Force $ob|Out-Null;Copy-Item "$oni\LmxxfNrRuntime.dll" $ob;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){New-Item -ItemType Directory -Force "$ob\_storage_"|Out-Null;Copy-Item "$oni\_storage_\LmxxfNrRuntime.dll" "$ob\_storage_\"}
Copy-Item "$oni\$hip" "$ob\HIP" -Recurse
Copy-Item "$mine\dlss5-amd.addon64" "$game\dlss5-amd.addon64" -Force
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$mine\build-final2\$a\c512-m32-deep.hsaco" "$game\$hip\$a\" -Force;Copy-Item "$mine\build-final2\$a\c512-m32-deep.hsaco" "$oni\$hip\$a\" -Force}
Copy-Item "$mine\LmxxfNrRuntime.dll" "$oni\LmxxfNrRuntime.dll" -Force;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$mine\LmxxfNrRuntime.dll" "$oni\_storage_\LmxxfNrRuntime.dll" -Force}
"stellar $(Sums "$game\$hip") oni $(Sums "$oni\$hip")"
if((Get-Content "$game\DLSS5-AMD\native-game-flags.txt" -Raw) -cne $flags){throw 'flags changed'}
foreach($a in 'gfx1200','gfx1201'){"$a deep stellar $((Get-FileHash "$game\$hip\$a\c512-m32-deep.hsaco").Hash.Substring(0,8)) oni $((Get-FileHash "$oni\$hip\$a\c512-m32-deep.hsaco").Hash.Substring(0,8))"}
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)) runtime $((Get-FileHash "$oni\LmxxfNrRuntime.dll").Hash.Substring(0,8)) backups $sb $ob"
# RE9 replay: old = backup runtime + backup modules, new = installed, fallback = new runtime + old modules
$root="$mine\rt";$bkhip="$ob\HIP"
foreach($side in 'old','new','fallback'){
 $d="$root\runtime-$side";Remove-Item -Recurse -Force $d -EA 0;New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders"|Out-Null
 $msrc=if($side -eq 'new'){"$oni\$hip"}else{$bkhip}
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$msrc\$a\*.hsaco" "$d\modules\$a" -Force}
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item $(if($side -eq 'old'){"$ob\LmxxfNrRuntime.dll"}else{"$oni\LmxxfNrRuntime.dll"}) "$d\LmxxfNrRuntime.dll" -Force
 $lines=@(Get-ChildItem "$d\modules" -Filter '*.hsaco' -Recurse|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring(("$d\modules\").Length).Replace('\','/'))"});[IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
foreach($height in 900,1080){foreach($side in 'old','new','fallback'){
 $env:DLSS5_NETWORK_HEIGHT="$height";$d="$root\runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders"
 & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$root\runtime-$side-$height.log"
 if($LASTEXITCODE){throw "rt_bench failed $side $height"}}
 $h=@('old','new','fallback'|%{[regex]::Match((Get-Content "$root\runtime-$_-$height.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value})
 "RUNTIME $height old=$($h[0]) new=$($h[1]) fallback=$($h[2]) $(if($h[0] -and $h[0] -eq $h[1] -and $h[0] -eq $h[2]){'SAME'}else{'MISMATCH'})"}
$d="$root\runtime-new";$env:LMXXF_SHADER_DIR="$d\shaders"
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$root\runtime-smoke.log"
"SMOKE exit=$LASTEXITCODE";Get-Content "$root\runtime-smoke.log" -Tail 3
