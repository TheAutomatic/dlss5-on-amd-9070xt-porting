# Module-only swap: c32-wave1 with CW_DIAG_ONLY 1 (both arches) into Stellar Blade and Onimusha. Host/runtime/flags untouched.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\c32-align-20260930'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content'
$hipRel='DLSS5-AMD\native-game-tiled-assets\HIP'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^rtc_compile|^Magpie'}){throw 'busy'}
function Sums($hip){$u=New-Object Text.UTF8Encoding($false);$l=@(Get-ChildItem $hip -Recurse -Filter '*.hsaco'|Sort-Object FullName|ForEach-Object{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($hip.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$hip\SHA256SUMS",$l,$u);$l.Count}
$stamp=Get-Date -Format yyyyMMdd-HHmmss
foreach($t in @(@{b=$game;k="$root\backups\stellar-$stamp-c32skip"},@{b=$oni;k="D:\DLSSNR-Lab\onimusha-backups\$stamp-c32skip"})){
 $flags=Get-Content "$($t.b)\DLSS5-AMD\native-game-flags.txt" -Raw -ErrorAction SilentlyContinue
 foreach($rel in @("$hipRel\gfx1200\c32-wave1.hsaco","$hipRel\gfx1201\c32-wave1.hsaco","$hipRel\SHA256SUMS")){$d="$($t.k)\$rel";New-Item -ItemType Directory -Force (Split-Path $d)|Out-Null;Copy-Item "$($t.b)\$rel" $d}
 foreach($a in 'gfx1200','gfx1201'){Copy-Item "$root\build-final\$a\c32-wave1.hsaco" "$($t.b)\$hipRel\$a\c32-wave1.hsaco" -Force;if((Get-FileHash "$($t.b)\$hipRel\$a\c32-wave1.hsaco").Hash -ne (Get-FileHash "$root\build-final\$a\c32-wave1.hsaco").Hash){throw 'readback'}}
 $n=Sums "$($t.b)\$hipRel";if($flags -and (Get-Content "$($t.b)\DLSS5-AMD\native-game-flags.txt" -Raw) -cne $flags){throw 'flags'}
 "$($t.b) backup=$($t.k) modules=$n"}
foreach($f in Get-ChildItem "$game\$hipRel" -Recurse -File){if((Get-FileHash $f.FullName).Hash -ne (Get-FileHash $f.FullName.Replace($game,$oni)).Hash){throw "oni mismatch $f"}}
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash) oniRuntime $((Get-FileHash "$oni\LmxxfNrRuntime.dll").Hash)"
