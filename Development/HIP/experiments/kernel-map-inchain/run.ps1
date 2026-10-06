# kernel-map-inchain-20261001: current installed Stellar modules + evprof (origin/main 640493c9 + event-profile-v4 host patch,
# KEV lines: per-dispatch begin->end and begin->next-begin). 300 frames per case; SWIN_RUN 1 (production) and 0 (C256 middle as separate launches).
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\kernel-map-inchain-20261001';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall'}){throw 'game running'}
New-Item -ItemType Directory -Force "$root\flat"|Out-Null;Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\flat" -Force
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash)"|Set-Content "$root\installed.txt"
Get-ChildItem "$root\flat"|ForEach-Object{"$($_.Name) $((Get-FileHash $_.FullName).Hash)"}|Add-Content "$root\installed.txt"
& "$root\lock.ps1" take;if($LASTEXITCODE){exit 1}
try{
foreach($h in 900,1080){foreach($sw in 1,0){foreach($prof in 1,0){
 $tag="h$h-sw$sw-p$prof"
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$h",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1',"DLSS5_HIP_SWIN_RUN=$sw",'DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_HIP_SPAN_PROBE=1')
 if($prof){$flags+='DLSS5_MAP_PROFILE=1';$env:DLSS5_MAP_PROFILE='1'}else{Remove-Item Env:DLSS5_MAP_PROFILE -EA 0}
 $env:DLSS5_HIP_SPAN_PROBE='1'
 $ft="$root\$tag-flags.txt";[IO.File]::WriteAllLines($ft,$flags)
 $ErrorActionPreference='Continue';& "$root\evprof.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' $ft "$r\live-menu-before.f16" "$root\$tag" 300 0 "$root\flat" 0 1 0 0 > "$root\$tag.log" 2> "$root\$tag.err";$ErrorActionPreference='Stop'
 "$tag exit=$LASTEXITCODE kev=$(@(Select-String -Path "$root\$tag.log" -Pattern '^KEV,').Count)"
}}}
}finally{Remove-Item Env:DLSS5_MAP_PROFILE -EA 0;& "$root\lock.ps1" drop}
Get-ChildItem $root -Recurse -Include *.f16,*.ppm|Where-Object{$_.DirectoryName -ne "$root\flat"}|Remove-Item -Force
'RUN_DONE'
