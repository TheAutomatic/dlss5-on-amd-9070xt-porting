# multi-pass (2026-10-03): DLSS5_MULTI_PASS runtime option (shared network layer, hip_reference_network.h). New add-on (Stellar Blade) and
# RE9 runtime (Onimusha, + _storage_ copy) that read the option; both flags files get the template's three lines (2 comments + DLSS5_MULTI_PASS=1)
# appended, keeping every other line and the file's line endings. Default 1 = one pass, output as before. Modules and SUMS untouched.
# Backups first; fast-tier exact\ snapshot flags re-synced. -RestoreBackup <stamp> puts the backed-up files back.
param([switch]$DryRun,[string]$RestoreBackup='')
$ErrorActionPreference='Stop';$P=$PSScriptRoot;$R='D:\DLSSNR-Lab\fast-tier';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content'
$add=@('# 中：叠层：整个网络每帧跑 N 遍（1/2/3），上一遍的输出图当下一遍的输入；风格逐遍加强，网络耗时约 N 倍；默认 1','# EN: Multi pass: run the whole network N times per frame (1/2/3), each pass fed the previous output; stronger style, ~N x network time; default 1','DLSS5_MULTI_PASS=1')
function Hs($f){(Get-FileHash $f).Hash.Substring(0,8)}
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^LOP-Win|^Magpie|^benchmark|^rt_bench|^runtime-smoke|^bench_ngx'}){throw 'game / benchmark running'}
if(Test-Path 'D:\DLSSNR-Lab\gpu.lock'){throw 'gpu.lock held'}
$flags=@("$game\DLSS5-AMD\native-game-flags.txt","$oni\DLSS5-AMD\native-game-flags.txt")
if($RestoreBackup){$b="D:\DLSSNR-Lab\multi-pass-backups\$RestoreBackup"
 Copy-Item "$b\dlss5-amd.addon64" "$game\" -Force;Copy-Item "$b\LmxxfNrRuntime.dll" "$oni\" -Force;if(Test-Path "$b\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$b\_storage_\LmxxfNrRuntime.dll" "$oni\_storage_\" -Force}
 Copy-Item "$b\stellar-flags.txt" $flags[0] -Force;Copy-Item "$b\oni-flags.txt" $flags[1] -Force;Copy-Item "$b\exact-stellar-flags.txt" "$R\exact\stellar-flags.txt" -Force;Copy-Item "$b\exact-oni-flags.txt" "$R\exact\oni-flags.txt" -Force
 'RESTORE_DONE';return}
$want=Get-Content "$P\payload.txt"|?{$_ -match '^\w'}|%{$k,$v=$_ -split ' ';@{k=$k;v=$v}}
foreach($w in $want){if((Hs "$P\$($w.k)") -ne $w.v){throw "payload hash $($w.k)"}};"payload ok: $(($want|%{"$($_.k)=$($_.v)"}) -join ' ')"
foreach($f in $flags){if(!(Test-Path $f)){throw "missing $f"};if((Get-Content $f) -match '^\s*DLSS5_MULTI_PASS\s*='){throw "$f already has DLSS5_MULTI_PASS"}}
"before: addon $(Hs "$game\dlss5-amd.addon64") runtime $(Hs "$oni\LmxxfNrRuntime.dll") SUMS $(Hs "$game\$hip\SHA256SUMS")/$(Hs "$oni\$hip\SHA256SUMS") flags $(Hs $flags[0])/$(Hs $flags[1])"
if($DryRun){'DRYRUN_OK';return}
$stamp=Get-Date -Format yyyyMMdd-HHmmss;$b="D:\DLSSNR-Lab\multi-pass-backups\$stamp";New-Item -ItemType Directory -Force $b|Out-Null
Copy-Item "$game\dlss5-amd.addon64","$oni\LmxxfNrRuntime.dll" $b;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){New-Item -ItemType Directory -Force "$b\_storage_"|Out-Null;Copy-Item "$oni\_storage_\LmxxfNrRuntime.dll" "$b\_storage_\"}
Copy-Item $flags[0] "$b\stellar-flags.txt";Copy-Item $flags[1] "$b\oni-flags.txt";Copy-Item "$R\exact\stellar-flags.txt" "$b\exact-stellar-flags.txt";Copy-Item "$R\exact\oni-flags.txt" "$b\exact-oni-flags.txt"
"backup $b  (restore: install.ps1 -RestoreBackup $stamp)"
foreach($f in $flags){$t=[IO.File]::ReadAllText($f);$nl=if($t.Contains("`r`n")){"`r`n"}else{"`n"};if($t.Length -and !$t.EndsWith("`n")){$t+=$nl};$raw=[IO.File]::ReadAllBytes($f);$bom=$raw.Length -ge 3 -and $raw[0] -eq 0xEF -and $raw[1] -eq 0xBB -and $raw[2] -eq 0xBF;[IO.File]::WriteAllText($f,$t+(($add -join $nl)+$nl),(New-Object Text.UTF8Encoding($bom)))}
Copy-Item "$P\dlss5-amd.addon64" "$game\dlss5-amd.addon64" -Force
Copy-Item "$P\LmxxfNrRuntime.dll" "$oni\LmxxfNrRuntime.dll" -Force;if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Copy-Item "$P\LmxxfNrRuntime.dll" "$oni\_storage_\LmxxfNrRuntime.dll" -Force}
Copy-Item $flags[0] "$R\exact\stellar-flags.txt" -Force;Copy-Item $flags[1] "$R\exact\oni-flags.txt" -Force
& "$R\switch.ps1" -Tier status
"after: addon $(Hs "$game\dlss5-amd.addon64") runtime $(Hs "$oni\LmxxfNrRuntime.dll") storage $(if(Test-Path "$oni\_storage_\LmxxfNrRuntime.dll"){Hs "$oni\_storage_\LmxxfNrRuntime.dll"}else{'none'}) SUMS $(Hs "$game\$hip\SHA256SUMS")/$(Hs "$oni\$hip\SHA256SUMS") flags $(Hs $flags[0])/$(Hs $flags[1])"
'INSTALL_DONE'
