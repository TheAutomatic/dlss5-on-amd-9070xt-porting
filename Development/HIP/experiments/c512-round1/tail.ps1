param([int[]]$Heights=@(900,1080))
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend';$d="$r\c512-round1";$a='D:\DLSSNR-Lab\Magpie-DLSS5-AMD-0.23\DLSS5-AMD';$m="$r\c512-round1\modules-A\gfx1201";$cap="$r\network-timeline"
foreach($height in $Heights){
 if(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^benchmark'}){throw 'GPU busy'}
 $f="$d\$height-tail";New-Item -ItemType Directory -Force $f|Out-Null
 $flags=@(Get-Content "$a\native-game-flags.txt")+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_HIP_GRAPH=0','DLSS5_VIT_ADAPTIVE=0',"DLSS5_NETWORK_HEIGHT=$height",'DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1')
 [IO.File]::WriteAllLines("$f\flags.txt",$flags)
 $w=if($height -eq 900){1600}else{1920};$h=if($height -eq 900){960}else{1152}
 Push-Location $f
 try{& "$d\ledger-tail.exe" "$a\native-game-tiled-assets" $m "$f\flags.txt" "$cap\$height\input.f32" "$cap\$height\expected.f32" $w $h *> run.log;if($LASTEXITCODE){throw "ledger failed $height"}}finally{Pop-Location}
}
'LEDGER_DONE'
