# NVIDIA single-frame comparison (mochizuki ngx-verification inputs, Style 0 like NVIDIA's run): free vs tier, release skip and all blocks;
# 1440p also with the extra step on no axis / on the height (DLSS5_NETWORK_FREE_EXTRA) to test NVIDIA's padding rule. Then the free smoke again.
$root='D:\DLSSNR-Lab\hip-backend\free-res-20261002'
foreach($sk in '42,43,46','none'){
 & "$root\smoke.ps1" -Sizes '1920x1080,2560x1440,3840x2160' -Base 1 -Tag "nv$($sk.Length)" -Style 0 -Skip $sk
 & "$root\smoke.ps1" -Sizes '2560x1440' -Base 0 -Tag "nv$($sk.Length)-x0" -Style 0 -Skip $sk -Extra 'DLSS5_NETWORK_FREE_EXTRA=0'
 & "$root\smoke.ps1" -Sizes '2560x1440' -Base 0 -Tag "nv$($sk.Length)-xh" -Style 0 -Skip $sk -Extra 'DLSS5_NETWORK_FREE_EXTRA=h'
}
& "$root\smoke.ps1" -Base 0 -Tag smoke2
