$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\vit-bytestream'
$assets='D:\DLSSNR-Lab\re9-runtime-flags-20260926\new\DLSS5-AMD\native-game-tiled-assets'
if(Get-Process SB-Win64-Shipping,LOP-Win64-Shipping,OnimushaWotS,re9,benchmark,rt_bench -ErrorAction SilentlyContinue){throw 'GPU busy'}
foreach($set in 'V3','A'){
 $base="$r\modules-$set";$lines=@(Get-ChildItem $base -Recurse -Filter '*.hsaco'|ForEach-Object{$name=$_.FullName.Substring(($base+'\').Length).Replace('\','/');"$((Get-FileHash $_.FullName).Hash.ToLower())  $name"})
 [IO.File]::WriteAllLines("$base\SHA256SUMS",$lines)
}
# Copy the repo shaders/ beside this DLL before running: FindShaderDir uses DLL/shaders.
$env:LMXXF_WEIGHTS_DIR=$assets
$env:DLSS5_HIP_PDL='1';$env:DLSS5_NETWORK_HEIGHT='900';$env:DLSS5_VIT_ADAPTIVE='0'
foreach($mask in 0,3){
 $env:DLSS5_HIP_VIT_STREAM="$mask"
 & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$r\LmxxfNrRuntime.dll" "$r\modules-V3" '1707x961' 12 1 *> "$r\runtime-$mask.log"
 if($LASTEXITCODE){throw "runtime failed $mask"}
}
$env:DLSS5_HIP_VIT_STREAM='3'
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$r\LmxxfNrRuntime.dll" "$r\modules-V3" *> "$r\runtime-smoke.log"
if($LASTEXITCODE){throw 'smoke failed'}
& 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$r\LmxxfNrRuntime.dll" "$r\modules-A" *> "$r\runtime-missing-module.log"
if($LASTEXITCODE){throw 'missing module fallback failed'}
'RUNTIME_DONE'
