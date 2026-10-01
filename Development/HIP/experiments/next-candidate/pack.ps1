# pack.ps1: assemble D:\DLSSNR-Lab\next-candidate from next-candidate-20261002 (build-next 62 modules, bin add-on/runtime, install.ps1); writes SHA256SUMS.
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\next-candidate-20261002';$p='D:\DLSSNR-Lab\next-candidate'
Remove-Item $p -Recurse -Force -EA 0;New-Item -ItemType Directory -Force "$p\HIP\gfx1200","$p\HIP\gfx1201"|Out-Null
foreach($a in 'gfx1200','gfx1201'){Copy-Item "$root\build-next\$a\*.hsaco" "$p\HIP\$a\"}
Copy-Item "$root\bin\dlss5-amd.addon64","$root\bin\LmxxfNrRuntime.dll","$root\install.ps1","$root\README.txt" $p
$u=New-Object Text.UTF8Encoding($false);$l=@(Get-ChildItem $p -Recurse -File|?{$_.Name -notin 'SHA256SUMS','install.ps1','README.txt'}|Sort-Object FullName|%{"$((Get-FileHash $_.FullName).Hash.ToLower())  $($_.FullName.Substring($p.Length+1).Replace('\','/'))"});[IO.File]::WriteAllLines("$p\SHA256SUMS",$l,$u)
"files $($l.Count) SUMS $((Get-FileHash "$p\SHA256SUMS").Hash.Substring(0,8))"
