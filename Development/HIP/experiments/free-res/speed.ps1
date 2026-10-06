# Network span (DLSS5_HIP_SPAN_PROBE, median after 2 warm-up frames) per size: free (F) vs tier (T, base host); and slow toggles at 1080 as a flag-effect control.
param([int]$Frames=40,[string]$Sizes='1280x720,1366x768,1600x900,1706x960,1920x1080,2560x1440,3440x1440,3840x2160',[string]$Tag='spd')
$root='D:\DLSSNR-Lab\hip-backend\free-res-20261002'
& "$root\smoke.ps1" -Sizes $Sizes -Base 1 -Tag $Tag -Frames $Frames -Span 1
& "$root\smoke.ps1" -Sizes '1920x1080,2560x1440' -Base 0 -Tag "$Tag-slow" -Frames $Frames -Span 1 -Extra 'DLSS5_HIP_PDL=0;DLSS5_HIP_WAVE_OWNED=0;DLSS5_HIP_C512_M32=0;DLSS5_HIP_VIT_PROJ_N64=0;DLSS5_HIP_VIT_STREAM=0'
