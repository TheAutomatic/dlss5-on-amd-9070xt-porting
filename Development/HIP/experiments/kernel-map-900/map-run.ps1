param([int]$Frames=60,[string]$Tag='prof',[int]$Profile=1,[int[]]$Heights=@(900,1080),[string]$Exe='benchmark-map.exe')
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\kernel-map-900-20260930';$q='D:\DLSSNR-Lab\hip-backend\vit-qkv-20260929';$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
function Idle { if(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile|^microbench|^runtime-smoke|^jobbench|^Magpie'}){throw 'GPU busy'} }
Idle
if(!(Test-Path "$root\flat-P")){Copy-Item "$q\flat-P" "$root\flat-P" -Recurse}
$mods="$root\flat-P";if(@(Get-ChildItem $mods -Filter '*.hsaco').Count -ne 31){throw 'module count'}
if((Get-FileHash "$mods\vit-stream.hsaco").Hash -ne (Get-FileHash "$q\build-prod\gfx1201\vit-stream.hsaco").Hash){Write-Output 'WARN vit-stream differs from build-prod'}
foreach($height in $Heights){
 Idle;$dir="$root\run-$Tag-$height";New-Item -ItemType Directory -Force $dir|Out-Null
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$height",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60')
 if($Profile){$flags+=@('DLSS5_MAP_PROFILE=1')}
 [IO.File]::WriteAllLines("$dir\flags.txt",$flags)
 if($Profile){$env:DLSS5_MAP_PROFILE='1'}else{Remove-Item Env:DLSS5_MAP_PROFILE -ErrorAction SilentlyContinue}
 & "$root\$Exe" "D:\DLSSNR-Lab\zero-copy-io-20260928\assets" "$dir\flags.txt" "$r\live-menu-before.f16" "$dir\rgb" $Frames 0 $mods 0 1 0 0 > "$dir\run.log" 2> "$dir\err.log"
 if($LASTEXITCODE){throw "run failed $height"}
 Remove-Item Env:DLSS5_MAP_PROFILE -ErrorAction SilentlyContinue
 $rows=@(Import-Csv "$dir\rgb.csv");$mean=($rows|Where-Object{[int]$_.frame -ge [math]::Min(200,[int]($Frames/4))}|Measure-Object wall_ms -Average).Average
 Write-Output "$Tag $height frames=$($rows.Count) wall_mean=$mean kev=$(@(Select-String -Path "$dir\run.log" -Pattern '^KEV,').Count) sha=$((Get-FileHash "$dir\rgb.f16").Hash)"
}
