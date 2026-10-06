param([int]$Height=900,[string]$Exe='recorder.exe',[string]$Tag='record',[int]$Frames=1,[int]$Profile=0)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\kernel-map-v3-20260930';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^recorder|^jobbench|^Magpie|^km3'}){throw 'GPU busy'}
$syn="$root\synthetic-$Height";New-Item -ItemType Directory -Force $syn|Out-Null;$env:MAP_DIR=$syn
$flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$Height",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60')
if($Profile){$flags+='DLSS5_MAP_PROFILE=1';$env:DLSS5_MAP_PROFILE='1'}else{Remove-Item Env:DLSS5_MAP_PROFILE -ErrorAction SilentlyContinue}
$ft="$root\$Tag-flags-$Height.txt";[IO.File]::WriteAllLines($ft,$flags)
& "$root\$Exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' $ft "$r\live-menu-before.f16" "$root\$Tag-$Height" $Frames 0 "$root\flat-A" 0 $(if($Frames -gt 1){1}else{0}) 0 0 > "$root\$Tag-$Height.log" 2> "$root\$Tag-$Height.err"
"exit $LASTEXITCODE jobs=$(@(Select-String -Path "$root\$Tag-$Height.log" -Pattern '^JOB ').Count) kev=$(@(Select-String -Path "$root\$Tag-$Height.log" -Pattern '^KEV,').Count)"
if($Frames -gt 1){$rows=@(Import-Csv "$root\$Tag-$Height.csv");"wall_mean=$(($rows|Where-Object{[int]$_.frame -ge 200}|Measure-Object wall_ms -Average).Average)"}
