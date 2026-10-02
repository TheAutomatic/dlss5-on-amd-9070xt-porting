# Generic-path cross-check: each free size with the bit-exact fast paths off (slow) and a repeat of the default (rep); outputs must equal smoke-F.
$root='D:\DLSSNR-Lab\hip-backend\free-res-20261002'
& "$root\smoke.ps1" -Sizes '1920x1080,1706x960,1366x768,2560x1440,3440x1440,3840x2160' -Base 0 -Tag slow -Extra 'DLSS5_HIP_PDL=0;DLSS5_HIP_WAVE_OWNED=0;DLSS5_HIP_C512_M32=0;DLSS5_HIP_VIT_PROJ_N64=0;DLSS5_HIP_VIT_STREAM=0'
& "$root\smoke.ps1" -Sizes '1706x960,1366x768,2560x1440,3440x1440,3840x2160' -Base 0 -Tag rep
