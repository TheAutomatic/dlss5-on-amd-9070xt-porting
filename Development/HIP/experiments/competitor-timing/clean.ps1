$r='D:\DLSSNR-Lab\competitor-timing-20260930'
Get-ChildItem $r -Recurse -File | ? {$_.Length -gt 5MB} | select FullName,Length | ft -auto | out-string -width 200
Get-ChildItem $r -Recurse -File -Include *.f16,*.ppm,dlssnr.bin,pc.bin,logs.tar | Remove-Item -Force
"left MB " + [int]((Get-ChildItem $r -Recurse -File | Measure-Object Length -Sum).Sum/1MB)
& D:\DLSSNR-Lab\daniel-051\swap.ps1 status | select -first 1
$g='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
"dxgi $((Get-FileHash "$g\dxgi.dll").Hash) addon $((Get-FileHash "$g\dlss5-amd.addon64").Hash)"
