$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\float-fma'
function Idle {if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark$'}){throw 'GPU busy'}}
Idle
$env:DLSS5_FAST_TEMPORAL='0'
& "$r\temporal-sample.exe" "$r\temporal-fixture\shaders" "$r\temporal-fixture" "$r\temporal-fixture\sampled-history.f32"
if($LASTEXITCODE){throw 'sample'}
$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD\native-game-tiled-assets'
foreach($set in 'A','P'){
 Idle
 & "$r\temporal-network.exe" $a "$r\flat-$set" "$r\temporal-fixture\input.f32" "$r\temporal-fixture\sampled-history.f32" "$r\oracle-$set" > "$r\oracle-$set.log"
 if($LASTEXITCODE){throw "oracle $set"}
}
