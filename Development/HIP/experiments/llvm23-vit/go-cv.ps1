# compiler versions per module (10-02): flat-<V><i> = flat-A (installed) + one module from compiler-sweep-20261001\<V>\gfx1201; 19 groups each (no timing).
param([string]$V='L22',[string]$Mods='c32-wave1,c64-wave2,swin-persistent,c512-m32-mh,c512-m32-deep,vit-stream,multihead-fast-padded-wave-packed,deep_fast-packed,vit-wide-deep')
$root='D:\DLSSNR-Lab\hip-backend\c128-c64-inchain-20261001';$src="D:\DLSSNR-Lab\hip-backend\compiler-sweep-20261001\$V\gfx1201";$L='D:\DLSSNR-Lab\gpu.lock'
function Test-Game { if(Test-Path 'D:\DLSSNR-Lab\compiler-sweep\ABORT'){throw 'ABORT game'}; if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){throw 'GAME RUNNING'} }
Test-Game
"compiler-sweep $V $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{
& "$root\setup.ps1" -PinIdle|Out-Null
$t=Get-Content "$root\regression.ps1" -Raw;$t=$t.Replace('|^rtc_compile','');Set-Content "$root\regression.ps1" $t
$i=0
foreach($m in $Mods -split ','){$i++;$Set="$V$i";Test-Game
 Get-ChildItem $root -Directory -Filter 'runtime-regression-*'|Remove-Item -Recurse -Force
 Remove-Item -Recurse -Force "$root\flat-$Set" -EA 0;New-Item -ItemType Directory -Force "$root\flat-$Set"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-$Set" -Force;Copy-Item "$src\$m.hsaco" "$root\flat-$Set" -Force
 $env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
 $log="$root\cv-$Set.log"
 try{
  foreach($ae in 0,1){& "$root\regression.ps1" -Set $Set -Adaptive $ae -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-P.exe -CorrectnessOnly -Batch $(if($ae){'adaptive'}else{'correct'}) *>> $log}
  foreach($slot in Get-ChildItem "$root\runtime-regression-$Set-adaptive" -Directory -Filter '*-True'){$b=$slot.FullName.Substring(0,$slot.FullName.Length-4)+'False';if([IO.File]::ReadAllText("$b\adaptive.csv") -cne [IO.File]::ReadAllText("$($slot.FullName)\adaptive.csv")){throw 'AE decisions changed'}};"AE CSV SAME $Set" *>> $log
  $env:SP_VALIDATE='1';$env:SP_TRACE='1';$env:SP_TICKET_LIMIT='1024';$env:SP_TICKET_START='4294967290'
  foreach($ae in 0,1){& "$root\regression.ps1" -Set $Set -Adaptive $ae -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-Proll.exe -CorrectnessOnly -Only @('900-history','1080-history') -Batch "roll-$ae" *>> $log}
  "$V $m SAME=$((Select-String -Path $log -Pattern '^SAME|AE CSV SAME').Count)"
 }catch{"$V $m FAIL after SAME=$((Select-String -Path $log -Pattern '^SAME|AE CSV SAME').Count): $($_.Exception.Message)"; if("$_" -match 'GAME|ABORT'){throw}}
 Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force
}
'CV_DONE'
} finally { Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force -EA 0; if((Test-Path $L) -and ((Get-Content $L) -match 'compiler-sweep')){Remove-Item $L -Force}; 'LOCK DROPPED' }
