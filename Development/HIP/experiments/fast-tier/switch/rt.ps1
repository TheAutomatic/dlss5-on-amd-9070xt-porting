$R='D:\DLSSNR-Lab\fast-tier';$ErrorActionPreference='Stop'
$before=Get-ChildItem "$R\manifest-*.txt"|Sort-Object Name|Select-Object -Last 1
"== to-fast";& "$R\to-fast.ps1"
"== fast SUMS lines (stellar)";(Get-Content 'C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP\SHA256SUMS').Count
"== to-exact";& "$R\to-exact.ps1"
Start-Sleep 1;& "$R\snap.ps1"|Out-Null
$after=Get-ChildItem "$R\manifest-*.txt"|Sort-Object Name|Select-Object -Last 1
$d=Compare-Object (Get-Content $before.FullName) (Get-Content $after.FullName)
"ROUNDTRIP $($before.Name) vs $($after.Name): $(if($d){'DIFF'}else{'IDENTICAL'}) ($((Get-Content $after.FullName).Count) files)";$d
# Sums() format check: regenerate SUMS over a copy of the exact HIP tree, compare to the shipped file
$t="$env:TEMP\ft-sums";Remove-Item $t -Recurse -Force -EA 0;Copy-Item 'C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64\DLSS5-AMD\native-game-tiled-assets\HIP' $t -Recurse
$u=New-Object Text.UTF8Encoding($false);$l=@(Get-ChildItem $t -Recurse -Filter '*.hsaco'|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($t.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$t\SUMS2",$l,$u)
"SUMS regen matches shipped: $((Get-FileHash "$t\SUMS2").Hash -eq (Get-FileHash "$t\SHA256SUMS").Hash)";Remove-Item $t -Recurse -Force
