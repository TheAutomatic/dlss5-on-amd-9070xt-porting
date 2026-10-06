# 1440p padding candidates against NVIDIA (Style 0, all blocks and release skip), DLSS5_NETWORK_FREE_PAD diagnostic; x0 (2560x1536) fast/slow cross-check.
$root='D:\DLSSNR-Lab\hip-backend\free-res-20261002';$slow='DLSS5_HIP_PDL=0;DLSS5_HIP_WAVE_OWNED=0;DLSS5_HIP_C512_M32=0;DLSS5_HIP_VIT_PROJ_N64=0;DLSS5_HIP_VIT_STREAM=0'
foreach($sk in 'none','42,43,46'){foreach($p in '2560x1472','2624x1536','2688x1472','2560x1600','2560x1536'){
 & "$root\smoke.ps1" -Sizes '2560x1440' -Base 0 -Tag "g$($sk.Length)-$p" -Style 0 -Skip $sk -Extra "DLSS5_NETWORK_FREE_PAD=$p"}}
& "$root\smoke.ps1" -Sizes '2560x1440' -Base 0 -Tag 'g4-2560x1536-slow' -Style 0 -Skip none -Extra "DLSS5_NETWORK_FREE_PAD=2560x1536;$slow"
& "$root\smoke.ps1" -Sizes '2560x1440' -Base 0 -Tag 'g4-2560x1472-slow' -Style 0 -Skip none -Extra "DLSS5_NETWORK_FREE_PAD=2560x1472;$slow"
