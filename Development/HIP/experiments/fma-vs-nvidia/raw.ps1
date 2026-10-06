$ErrorActionPreference='Stop'
$r='D:\DLSSNR-Lab\hip-backend\fma-vs-nvidia'
$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD\native-game-tiled-assets'
foreach($set in 'A','F','H'){
 if(Get-Process | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark$'}){throw 'GPU busy'}
 & "$r\raw-network.exe" $a "$r\flat-$set" "$r\input.f32" "$r\raw-$set.f32" > "$r\raw-$set.log"
 if($LASTEXITCODE){throw "raw $set"}
}
