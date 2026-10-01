# compiler-sweep GPU pass: per case = label|module|build|kernel-prefix ; build 'inst' = installed module. For each case run base span (no dup)
# and dup span (prefix x2) with that module swapped in. Host benchmark-S (= installed add-on source), modules = Stellar installed gfx1201.
# Rounds interleave all cases. Takes gpu.lock; aborts on D:\DLSSNR-Lab\compiler-sweep\ABORT (set by guard.sh) or a game process.
param([int]$Rounds=3,[int]$Frames=300,[string]$CaseFile='',[string]$Heights='900,1080',[string]$Tag='dup',[string]$Overlay='')
$ErrorActionPreference='Stop';$root="D:\DLSSNR-Lab\hip-backend\compiler-sweep-20261001\$Tag";$r='D:\DLSSNR-Lab\hip-backend';$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD'
$bs='D:\DLSSNR-Lab\hip-backend\compiler-sweep-20261001';$AB='D:\DLSSNR-Lab\compiler-sweep\ABORT'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$L='D:\DLSSNR-Lab\gpu.lock';$me="compiler-sweep $Tag"
function Test-Game { if(Test-Path $AB){throw 'ABORT game'}; if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){throw 'game running'} }
$t0=Get-Date
while(Test-Path $L){ if(((Get-Date)-(Get-Item $L).LastWriteTime).TotalMinutes -gt 40){Remove-Item $L -Force;"stale lock removed";break}
 if(((Get-Date)-$t0).TotalMinutes -gt 30){"LOCK TIMEOUT: $(Get-Content $L)";exit 1}; Start-Sleep 60}
Test-Game
"$me $(Get-Date -Format s)"|Out-File -Encoding ascii $L
$j=Start-Job -ScriptBlock {param($L,$me) while($true){Start-Sleep 300; if(Test-Path $L){"$me $(Get-Date -Format s) (refresh)"|Out-File -Encoding ascii $L}}} -ArgumentList $L,$me
try{
New-Item -ItemType Directory -Force "$root\flat","$root\inst"|Out-Null;Copy-Item "$game\DLSS5-AMD\native-game-tiled-assets\HIP\gfx1201\*.hsaco" "$root\inst" -Force
foreach($o in ($Overlay -split ','|?{$_})){$om,$od=$o -split '=';Copy-Item "$od\$om.hsaco" "$root\inst" -Force;"overlay $om <- $od $((Get-FileHash "$root\inst\$om.hsaco").Hash.Substring(0,8))"}
Copy-Item "$r\rebuild-baseline-20261001\benchmark-S.exe" "$root\bench.exe" -Force
"addon $((Get-FileHash "$game\dlss5-amd.addon64").Hash.Substring(0,8))"
$caseList=@(Get-Content $CaseFile|?{$_ -and $_ -notmatch '^#'})
foreach($round in 1..$Rounds){foreach($h in ($Heights -split ',')){foreach($cc in $caseList){$cn,$mod,$bn,$pre=$cc -split '\|'
 Test-Game
 Copy-Item "$root\inst\*.hsaco" "$root\flat" -Force
 if($bn -match '^L\d'){Copy-Item "$bs\$bn\gfx1201\$mod.hsaco" "$root\flat" -Force}elseif($bn -ne 'inst'){Copy-Item "$bs\build-$bn\gfx1201\$mod.hsaco" "$root\flat" -Force}
 $tag="r$round-h$h-$cn"
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$h",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_HIP_SPAN_PROBE=1','DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000','DLSS5_NETWORK_1080_ROWS=1152')
 if($pre -and $pre -ne 'base'){$flags+="DLSS5_HIP_DUP_PREFIX=$pre";$flags+='DLSS5_HIP_DUP_COUNT=2';$env:DLSS5_HIP_DUP_PREFIX=$pre;$env:DLSS5_HIP_DUP_COUNT='2'}else{Remove-Item Env:DLSS5_HIP_DUP_PREFIX,Env:DLSS5_HIP_DUP_COUNT -EA 0}
 $env:DLSS5_HIP_SPAN_PROBE='1'
 $ft="$root\$tag-flags.txt";[IO.File]::WriteAllLines($ft,$flags)
 $ErrorActionPreference='Continue';& "$root\bench.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' $ft "$r\live-menu-before.f16" "$root\$tag" $Frames 0 "$root\flat" 0 1 0 0 > "$root\$tag.log" 2> "$root\$tag.err";$ec=$LASTEXITCODE;$ErrorActionPreference='Stop'
 Test-Game
 $s=@(Select-String -Path "$root\$tag.err" -Pattern 'hip_span gpu_ms=([0-9.]+)'|%{[double]$_.Matches[0].Groups[1].Value}|Select-Object -Skip 60|Sort-Object)
 "SPAN $tag exit=$ec n=$($s.Count) med=$($s[[int]($s.Count/2)])"
 Get-ChildItem $root -Filter *.f16|Remove-Item -Force;Get-ChildItem $root -Filter *.ppm|Remove-Item -Force
}}}
'DUP_DONE'
} finally { Remove-Item Env:DLSS5_HIP_DUP_PREFIX,Env:DLSS5_HIP_DUP_COUNT -EA 0; Stop-Job $j; Remove-Job $j -Force; if((Test-Path $L) -and ((Get-Content $L) -match 'compiler-sweep')){Remove-Item $L -Force}; "LOCK DROPPED" }
