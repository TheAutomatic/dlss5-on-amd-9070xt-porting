foreach($d in 'multi-pass-skip-20261003','config-layers-20261003','fast-numeric-20261003','multi-pass-20261003','input-slim-20261001','bitexact-pm-20261001'){
 $p="D:\DLSSNR-Lab\hip-backend\$d\assets-base"
 if(Test-Path "$p\block0-ffn.f16"){"$d COMPLETE"}
 elseif(Test-Path $p){"$d INCOMPLETE entries=$((Get-ChildItem $p | Measure-Object).Count)"}
 else{"$d no-assets-base"}
}
$z='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
if(Test-Path "$z\block0-ffn.f16"){'zero-copy COMPLETE'}else{'zero-copy incomplete'}
