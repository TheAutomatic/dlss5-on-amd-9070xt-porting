# Module-only swap (both arches): c512-m32-deep + deep_fast-packed with C512_F_MASK 1 into Stellar Blade and Onimusha. Host/runtime/flags untouched; Onimusha _storage_ runtime backed up too (no modules live there).
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\composite-quant-c512-20260930'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content'
$hipRel='DLSS5-AMD\native-game-tiled-assets\HIP';$mods='c512-m32-deep','deep_fast-packed'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^rtc_compile|^Magpie'}){throw 'busy'}
function Sums($hip){$u=New-Object Text.UTF8Encoding($false);$l=@(Get-ChildItem $hip -Recurse -Filter '*.hsaco'|Sort-Object FullName|ForEach-Object{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($hip.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$hip\SHA256SUMS",$l,$u);$l.Count}
$stamp=Get-Date -Format yyyyMMdd-HHmmss
foreach($t in @(@{b=$game;k="$root\backups\stellar-$stamp-c512mask"},@{b=$oni;k="D:\DLSSNR-Lab\onimusha-backups\$stamp-c512mask"})){
 $flags=Get-Content "$($t.b)\DLSS5-AMD\native-game-flags.txt" -Raw -ErrorAction SilentlyContinue
 $rels=@("$hipRel\SHA256SUMS")+@(foreach($a in 'gfx1200','gfx1201'){foreach($m in $mods){"$hipRel\$a\$m.hsaco"}});if($t.b -eq $oni){$rels+='_storage_\LmxxfNrRuntime.dll','LmxxfNrRuntime.dll'}
 foreach($rel in $rels){$d="$($t.k)\$rel";New-Item -ItemType Directory -Force (Split-Path $d)|Out-Null;Copy-Item "$($t.b)\$rel" $d}
 foreach($a in 'gfx1200','gfx1201'){foreach($m in $mods){$s=(Get-ChildItem "$root\build-final\$a" -Recurse -Filter "$m.hsaco"|Select-Object -First 1).FullName;Copy-Item $s "$($t.b)\$hipRel\$a\$m.hsaco" -Force;if((Get-FileHash "$($t.b)\$hipRel\$a\$m.hsaco").Hash -ne (Get-FileHash $s).Hash){throw 'readback'}}}
 $n=Sums "$($t.b)\$hipRel";if($flags -and (Get-Content "$($t.b)\DLSS5-AMD\native-game-flags.txt" -Raw) -cne $flags){throw 'flags'}
 "$($t.b) backup=$($t.k) modules=$n"}
foreach($f in Get-ChildItem "$game\$hipRel" -Recurse -File){if((Get-FileHash $f.FullName).Hash -ne (Get-FileHash $f.FullName.Replace($game,$oni)).Hash){throw "oni mismatch $f"}}
$fl=Get-Content "$game\DLSS5-AMD\native-game-flags.txt" -Raw;foreach($e in 'DLSS5_DIRECT_IO=3','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_HIP_SWIN_RUN=1'){if($fl -notmatch "(?m)^\s*$e\s*$"){throw "Flag missing: $e"}}
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash) oniRuntime $((Get-FileHash "$oni\LmxxfNrRuntime.dll").Hash) oniStorage $((Get-FileHash "$oni\_storage_\LmxxfNrRuntime.dll" -ErrorAction SilentlyContinue).Hash)"
foreach($a in 'gfx1200','gfx1201'){foreach($m in $mods){"$a $m $((Get-FileHash "$game\$hipRel\$a\$m.hsaco").Hash)"}}
