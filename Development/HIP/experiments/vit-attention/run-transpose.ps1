$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\vit-attention-20260929'
& "$root\micro.ps1" -Batch micro7 -Match '^ours-.*-(base|native|pair|transpose|pair_transpose)$'
if(!$?){throw 'AV transpose test failed'}
