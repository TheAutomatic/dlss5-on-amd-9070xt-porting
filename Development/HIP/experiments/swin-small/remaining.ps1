$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-small-20260929'
foreach($pair in @(@(2,2),@(1,1),@(1,2))){
 & "$root\screen.ps1" -Channel $pair[0] -Side $pair[1]
 if(!$?){throw 'Stage screen failed'}
}
