# free-res smoke: lock + game check, each size with free=1 (and the tier reference free=0), 1 frame Style 1.
param([string]$Sizes='1920x1080,1280x720,1706x960,1366x768,1600x900,2560x1440,3440x1440,3840x2160',[string]$Tag='smoke',[int]$Frames=1,[string]$Style='1',[string]$Skip='42,43,46',[int]$Span=0,[int]$Base=1,[string]$Extra='')
$ex=@($Extra.Split(';')|?{$_})
$root='D:\DLSSNR-Lab\hip-backend\free-res-20261002';$L='D:\DLSSNR-Lab\gpu.lock'
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"free-res $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{foreach($r in $Sizes.Split(',')){
 & "$root\ngx.ps1" -Exe ngx-F.exe -Assets assets-cand -Res $r -Free 1 -Style $Style -Skip $Skip -Frames $Frames -Tag "$Tag-F" -Span $Span -Extra $ex
 if($Base){& "$root\ngx.ps1" -Exe ngx-base.exe -Assets assets-base -Res $r -Free 0 -Style $Style -Skip $Skip -Frames $Frames -Tag "$Tag-T" -Span $Span -Extra $ex}
}}finally{if((Test-Path $L) -and ((Get-Content $L) -match 'free-res')){Remove-Item $L -Force};'LOCK DROPPED'}
