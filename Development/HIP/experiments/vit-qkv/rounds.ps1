param([int]$Rounds=3,[string]$Batch='micro3',[string]$Match='.*')
$root='D:\DLSSNR-Lab\hip-backend\vit-qkv-20260929'
for($r=1;$r -le $Rounds;$r++){& "$root\micro.ps1" -Batch "$Batch-r$r" -Match $Match | Select-String 'RESULT|different=[1-9]'}
