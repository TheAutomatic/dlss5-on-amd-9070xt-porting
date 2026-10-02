# fast-tier switch for Stellar Blade + Onimusha. -Tier fast|exact|status. Backs up before every change.
param([ValidateSet('fast','exact','status')][string]$Tier='status')
$ErrorActionPreference='Stop';$R='D:\DLSSNR-Lab\fast-tier'
$games=[ordered]@{stellar='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';oni='C:\XboxGames\Onimusha- Way of the Sword\Content'}
$hip='DLSS5-AMD\native-game-tiled-assets\HIP';$mods='c32-wave1','c64-wave2','deep_fast-packed','c32-wave1-rtz';$arches='gfx1200','gfx1201'  # c32-wave1-rtz (2026-10-03): 1080-tier C32 module; fast\ holds a copy of fast c32-wave1
$block="# fast-tier (lossy): added by to-fast.ps1, removed by to-exact.ps1`r`nDLSS5_NETWORK_1080_ROWS=1088`r`n"
function Hsh($f){(Get-FileHash $f).Hash}
function Sums($h){$u=New-Object Text.UTF8Encoding($false);$l=@(Get-ChildItem $h -Recurse -Filter '*.hsaco'|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($h.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$h\SHA256SUMS",$l,$u)}
function State($g){$d=$games[$g];$e=0;$f=0
 foreach($a in $arches){foreach($m in $mods){$x=Hsh "$d\$hip\$a\$m.hsaco";if($x -eq (Hsh "$R\exact\$a\$m.hsaco")){$e++}elseif($x -eq (Hsh "$R\fast\$a\$m.hsaco")){$f++}}}
 $fl=[IO.File]::ReadAllText("$d\DLSS5-AMD\native-game-flags.txt");$rows=$fl.Contains($block)
 $sums=(Hsh "$d\$hip\SHA256SUMS") -eq (Hsh "$R\exact\$g-SHA256SUMS")
 $n=$arches.Count*$mods.Count
 if($e -eq $n -and !$rows -and $sums){'EXACT'}elseif($f -eq $n -and $rows){'FAST'}else{"MIXED(exact=$e fast=$f rows1088=$rows exactSums=$sums)"}}
function Report{foreach($g in $games.Keys){$d=$games[$g];$extra=if($g -eq 'stellar'){"addon $((Hsh "$d\dlss5-amd.addon64").Substring(0,8))"}else{"runtime $((Hsh "$d\LmxxfNrRuntime.dll").Substring(0,8))"}
 "$g : $(State $g)   $extra flags $((Hsh "$d\DLSS5-AMD\native-game-flags.txt").Substring(0,8)) sums $((Hsh "$d\$hip\SHA256SUMS").Substring(0,8))"
 foreach($a in $arches){"   $a "+(($mods|%{"$_ $((Hsh "$d\$hip\$a\$_.hsaco").Substring(0,8))"}) -join '  ')}}}
if($Tier -eq 'status'){Report;return}
if(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^LOP-Win'}){throw '游戏还开着，先关游戏 / game running, close it first'}
foreach($a in $arches){foreach($m in $mods){foreach($t in 'exact','fast'){if(!(Test-Path "$R\$t\$a\$m.hsaco")){throw "missing $t\$a\$m"}}}}
$stamp=Get-Date -Format yyyyMMdd-HHmmss
foreach($g in $games.Keys){$d=$games[$g];$b="$R\backups\$stamp-to-$Tier\$g";New-Item -ItemType Directory -Force $b|Out-Null
 Copy-Item "$d\DLSS5-AMD\native-game-flags.txt","$d\$hip\SHA256SUMS" $b
 foreach($a in $arches){New-Item -ItemType Directory -Force "$b\$a"|Out-Null;foreach($m in $mods){Copy-Item "$d\$hip\$a\$m.hsaco" "$b\$a\"}}
 foreach($a in $arches){foreach($m in $mods){Copy-Item "$R\$Tier\$a\$m.hsaco" "$d\$hip\$a\$m.hsaco" -Force;if((Hsh "$d\$hip\$a\$m.hsaco") -ne (Hsh "$R\$Tier\$a\$m.hsaco")){throw "copy check $g $a $m"}}}
 $ff="$d\DLSS5-AMD\native-game-flags.txt";$fl=[IO.File]::ReadAllText($ff)
 if($Tier -eq 'fast'){if(!$fl.Contains($block)){if($fl -match '(?m)^\s*DLSS5_NETWORK_1080_ROWS\s*='){throw "$g flags already set DLSS5_NETWORK_1080_ROWS by hand; edit it yourself"};if($fl.Length -and !$fl.EndsWith("`n")){$fl+="`r`n"};[IO.File]::WriteAllText($ff,$fl+$block)}
  Sums "$d\$hip"}
 else{if($fl.Contains($block)){[IO.File]::WriteAllText($ff,$fl.Replace($block,''))}
  Copy-Item "$R\exact\$g-SHA256SUMS" "$d\$hip\SHA256SUMS" -Force}
 "backup -> $b"}
Report
$want=$Tier.ToUpper();foreach($g in $games.Keys){$s=State $g;if($s -ne $want){throw "$g is $s, expected $want"}}
"==> 当前档位 / current tier: $want"
