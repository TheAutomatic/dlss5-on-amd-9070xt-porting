# Final free-res set on the shipped rule: (1) every size free vs tier, 40 frames (wall median), Style 1 release skip;
# (2) fast paths off (must equal 1); (3) NVIDIA single-frame, Style 0, release skip and all blocks.
$root='D:\DLSSNR-Lab\hip-backend\free-res-20261002';$slow='DLSS5_HIP_PDL=0;DLSS5_HIP_WAVE_OWNED=0;DLSS5_HIP_C512_M32=0;DLSS5_HIP_VIT_PROJ_N64=0;DLSS5_HIP_VIT_STREAM=0'
& "$root\smoke.ps1" -Base 1 -Tag fin -Frames 40
& "$root\smoke.ps1" -Base 0 -Tag finslow -Extra $slow
foreach($sk in '42,43,46','none'){& "$root\smoke.ps1" -Sizes '1920x1080,2560x1440,3840x2160' -Base 0 -Tag "finnv$($sk.Length)" -Style 0 -Skip $sk}
