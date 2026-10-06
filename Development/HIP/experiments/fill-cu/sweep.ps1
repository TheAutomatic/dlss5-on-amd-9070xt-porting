# Grid-fill sweep: time each C512/ViT kernel with grid.x truncated (JB_GRIDX) to get single-WG latency and the fill curve.
param([string]$Ids='o900-023,o900-024,o900-025,o900-026,o900-031,o900-027,o900-063,o900-064,o900-065,o900-066,o900-067,o900-068,o900-069,o900-070,o1080-021,o1080-022,o1080-023,o1080-024,o1080-025,o1080-061,o1080-064,o1080-065,o1080-066,o1080-073,o1080-068',[string]$Xs='1,2,8,32,64,128,192,256,384,512,768,1024,1536,99999')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fill-cu-20260930';$k='D:\DLSSNR-Lab\hip-backend\kernel-map-v3-20260930'
if(!(Test-Path "$r\jobs")){New-Item -ItemType Directory -Force $r|Out-Null;Copy-Item "$k\jobs","$k\synthetic-900","$k\synthetic-1080" $r -Recurse;Copy-Item 'D:\DLSSNR-Lab\hip-backend\hip-roofline-20260930\flat-C' "$r\flat-P" -Recurse}
$d="$r\sweep";New-Item -ItemType Directory -Force $d|Out-Null;$out="$r\sweep.csv";'id,gridx,us'|Set-Content $out
foreach($id in $Ids.Split(',')){foreach($x in $Xs.Split(',')){
 if(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^Magpie'}){throw 'GPU busy'}
 $env:JB_GRIDX=$x
 $p=Start-Process "$r\jobbench-grid.exe" -ArgumentList @("$r\jobs\$id.bin",$r,'64','5') -NoNewWindow -PassThru -RedirectStandardOutput "$d\$id-$x.log" -RedirectStandardError "$d\$id-$x.err"
 if(!$p.WaitForExit(60000)){$p.Kill();throw "Timeout $id"};$p.WaitForExit()
 $g=(Get-Content "$d\$id-$x.log"|?{$_ -like 'GRID,*'}) -split ','
 $res=(Get-Content "$d\$id-$x.log"|?{$_ -like 'RESULT,*'}) -split ','
 if(!$res){"$id,$x,FAIL"|Add-Content $out;continue}
 "$id,$($g[1]),$($res[2])"|Add-Content $out
 if([int]$g[1] -ge [int]($g[4] -replace 'orig=','')){break}}}
Remove-Item Env:JB_GRIDX;'SWEEP_DONE'
