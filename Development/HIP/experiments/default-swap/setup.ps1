# default-swap (2026-10-03, results/default-swap-20261003) setup: harness from fast-numeric-20261003. flat-I = installed Stellar gfx1201
# (incl. the two -fast modules, SUMS F3EFDC16); bench = benchmark-F (the installed add-on's host, DLSS5_FAST_NUMERIC). regression-cmp.ps1
# gets -BaseExtra (flags appended on the base side only) so the PSNR reference can be B (no skip, bit-exact) instead of the release default.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\default-swap-20261003';$s='D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
New-Item -ItemType Directory -Force $root|Out-Null
foreach($f in 'regression.ps1','summarize.ps1','p99m.ps1','regression-cmp.ps1','psnr.ps1'){(Get-Content "$s\$f" -Raw).Replace('fast-numeric-20261003','default-swap-20261003')|Set-Content "$root\$f"}
$t=Get-Content "$root\regression-cmp.ps1" -Raw
$o1='[string[]]$CandidateExtra=@(),';$o2=' if($candidate){$flags += $CandidateExtra}'
if(!$t.Contains($o1) -or !$t.Contains($o2)){throw 'cmp patch anchors'}
Set-Content "$root\regression-cmp.ps1" $t.Replace($o1,$o1+'[string[]]$BaseExtra=@(),').Replace($o2,$o2+'else{$flags += $BaseExtra}')
if(!(Test-Path "$root\assets-base")){Copy-Item "$s\assets-base" "$root\assets-base" -Recurse}
Remove-Item "$root\flat-I" -Recurse -Force -EA 0;Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201" "$root\flat-I" -Recurse
Copy-Item "$s\benchmark-F.exe" $root -Force
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8)) sums $((Get-FileHash "$game\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS").Hash.Substring(0,8)) flatI $(@(gci "$root\flat-I" -Filter *.hsaco).Count) fast $(@(gci "$root\flat-I" -Filter *-fast.hsaco).Count)"
"benchmark-F $((Get-FileHash "$root\benchmark-F.exe").Hash.Substring(0,8)); flatI vs fast-numeric flat-F: $(@(Compare-Object (gci "$root\flat-I" -Filter *.hsaco|%{(Get-FileHash $_.FullName).Hash}) (gci "$s\flat-F" -Filter *.hsaco|%{(Get-FileHash $_.FullName).Hash})).Count) diffs"
'SETUP_DONE'
