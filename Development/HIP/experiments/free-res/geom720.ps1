# 720p: the 720 tier (1280x768, both axes multiples of 256 = the case NVIDIA's host pads past) vs 1344x768 (NVIDIA plan walk) and 1280x832.
$root='D:\DLSSNR-Lab\hip-backend\free-res-20261002'
foreach($st in '0','1'){foreach($p in '1344x768','1280x832','1280x768'){& "$root\smoke.ps1" -Sizes '1280x720' -Base 0 -Tag "g720s$st-$p" -Style $st -Skip none -Extra "DLSS5_NETWORK_FREE_PAD=$p"}}
