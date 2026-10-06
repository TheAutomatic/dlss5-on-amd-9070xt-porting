$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\swin-small-20260929'
foreach($pair in @(@(2,1),@(2,2),@(1,1),@(1,2))){
 $env:SP_SMALL_CHANNELS="$($pair[0])";$env:SP_SMALL_SIDES="$($pair[1])"
 $tag="c$($pair[0])-s$($pair[1])"
 foreach($mode in 'roll','timeout'){
  $env:SP_VALIDATE=if($mode -eq 'roll'){'1'}else{'0'};$env:SP_TRACE=$env:SP_VALIDATE
  $env:SP_FORCE_TIMEOUT=if($mode -eq 'timeout'){'1'}else{'0'}
  $env:SP_TICKET_LIMIT=if($mode -eq 'roll'){'1024'}else{'4294967295'}
  $env:SP_TICKET_START=if($mode -eq 'roll'){'4294967290'}else{'0'}
  foreach($adaptive in 0,1){
   & "$root\regression.ps1" -Set P -Adaptive $adaptive -BenchName benchmark-base.exe -CandidateBenchName benchmark-small.exe -CorrectnessOnly -Only @('900-history','1080-history') -Batch "$tag-$mode-$adaptive"
   if(!$?){throw 'Pressure failed'}
  }
 }
}
