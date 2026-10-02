# lockrun.ps1 <script> [args]: GPU lock + game check around one lab script.
$L='D:\DLSSNR-Lab\gpu.lock';if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1};if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"net-timing $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{$s=$args[0];$rest=@($args|Select-Object -Skip 1);& $s @rest}catch{"FAIL $_"}finally{if((Test-Path $L) -and ((Get-Content $L) -match 'net-timing')){Remove-Item $L -Force};'LOCK DROPPED'}
