# 1080p: 1920x1088 (mochizuki walk, step 64) vs 1920x1152 (captured, step 128) against NVIDIA, Style 0.
$root='D:\DLSSNR-Lab\hip-backend\free-res-20261002'
foreach($sk in 'none','42,43,46'){& "$root\smoke.ps1" -Sizes '1920x1080' -Base 0 -Tag "g$($sk.Length)-1920x1088" -Style 0 -Skip $sk -Extra "DLSS5_NETWORK_FREE_PAD=1920x1088"}
& "$root\smoke.ps1" -Sizes '1920x1080' -Base 0 -Tag "g4-1920x1088-slow" -Style 0 -Skip none -Extra "DLSS5_NETWORK_FREE_PAD=1920x1088;DLSS5_HIP_PDL=0;DLSS5_HIP_WAVE_OWNED=0;DLSS5_HIP_C512_M32=0;DLSS5_HIP_VIT_PROJ_N64=0;DLSS5_HIP_VIT_STREAM=0"
