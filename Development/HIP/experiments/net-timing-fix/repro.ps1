# repro.ps1 (net-timing-fix #3): TheAutomatic's call order with rt_timing RT_AFTER_WAIT=1 (GetTimings once before the first frame;
# per frame EnqueueHip -> output list -> queue wait -> GetTimings -> Retire, serial ABI1 host), old vs new runtime,
# PDL 1/0 x 720/900/1080 x 1000 frames; then the default order (read right after EnqueueHip) on new, 1000 frames.
# Reads collapsed = raw ms < 0.01. Needs rt\runtime-old / runtime-new from rt.ps1.
param([int]$Frames=1000,[string[]]$Sides=@('old','new'),[string[]]$Pdls=@('1','0'),[int[]]$Heights=@(720,900,1080))
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\net-timing-fix-20261002';$rt="$root\rt"
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
Remove-Item Env:DLSS5_HIP_SPAN_PROBE,Env:DLSS5_NET_TIMING,Env:RT_PIPE,Env:HIP_LAUNCH_BLOCKING,Env:AMD_SERIALIZE_KERNEL,Env:AMD_SERIALIZE_COPY -EA 0
function Med($v){if(!$v.Count){return 0};$s=@($v|Sort-Object);$s[[int]($s.Count/2)]}
function RunOne($side,$pdl,$h,$after,$tag){$d="$rt\runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders";$env:DLSS5_HIP_PDL=$pdl;$env:DLSS5_NETWORK_HEIGHT="$h";$env:RT_AFTER_WAIT=$after
 $log="$rt\repro-$tag-$side-p$pdl-$h.log";$ErrorActionPreference='Continue';& "$root\bin\rt_timing.exe" "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' $Frames 1 *> $log;$ec=$LASTEXITCODE;$ErrorActionPreference='Stop'
 $all=@(Select-String -Path $log -Pattern '^timing frame=(\d+) valid=(\d) ms=([0-9.]+)'|%{$_.Matches[0]})
 $t=@($all|?{$_.Groups[2].Value -eq '1'}|%{[double]$_.Groups[3].Value});$c=@($t|?{$_ -lt 0.01})
 $first=@($all|?{$_.Groups[2].Value -eq '1' -and [double]$_.Groups[3].Value -lt 0.01}|Select-Object -First 1|%{$_.Groups[1].Value})
 "REPRO $tag $side pdl=$pdl $h exit=$ec valid=$($t.Count)/$($all.Count) collapsed=$($c.Count) first_collapsed=$first med=$((Med $t).ToString('F3')) min=$((($t|Measure-Object -Minimum).Minimum)) $((Select-String -Path $log -Pattern '^lag_mismatch.*').Line) $([regex]::Match((Get-Content $log -Raw),'pdl=[0-9/]+').Value) hash=$([regex]::Match((Get-Content $log -Raw),'hash=([0-9a-f]+)').Groups[1].Value)"}
foreach($pdl in $Pdls){foreach($h in $Heights){foreach($side in $Sides){RunOne $side $pdl $h '1' 'after'}}}
foreach($h in $Heights){RunOne 'new' '1' $h '0' 'default'}
'REPRO_DONE'
