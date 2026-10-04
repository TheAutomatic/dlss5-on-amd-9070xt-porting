$ErrorActionPreference='Stop';$root=$PSScriptRoot
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes('multipass-direct-rgba-20261004');$f.Write($b,0,$b.Length);$f.Close()
try{
foreach($a in 'gfx1200','gfx1201'){Copy-Item "D:\DLSSNR-Lab\skin-protect-20261004\HIP\$a\*.hsaco" "$root\HIP\$a" -Exclude 'c32-wave1.hsaco','c32-wave1-rtz.hsaco','c32-wave1-fast.hsaco','multi-pass-predict.hsaco','multi-pass-skin.hsaco' -Force}
New-Item -ItemType Directory -Force "$root\flat-R"|Out-Null;Copy-Item "$root\HIP\gfx1201\*.hsaco" "$root\flat-R" -Force
$s=Get-Content "$root\regression.ps1" -Raw;$s=$s.Replace("'DLSS5_FAST_NUMERIC=0'","'DLSS5_FAST_NUMERIC=1','DLSS5_SKIP_BLOCKS='")
foreach($case in @(@{p=2;pred=0;skin=0},@{p=3;pred=0;skin=0},@{p=3;pred=1;skin=0},@{p=3;pred=0;skin=1},@{p=3;pred=1;skin=1})){
$n="p$($case.p)-predict$($case.pred)-skin$($case.skin)";$s2=$s.Replace("'DLSS5_MULTI_PASS=1'","'DLSS5_MULTI_PASS=$($case.p)','DLSS5_MULTI_PASS_PREDICT=$($case.pred)','DLSS5_MULTI_PASS_SKIN_PROTECT=$($case.skin)'");[IO.File]::WriteAllText("$root\regression-case.ps1",$s2)
& "$root\regression-case.ps1" -Set R -Base A -BenchName benchmark-F.exe -CandidateBenchName benchmark-R.exe -CorrectnessOnly -Only @('900-motion','1080-history') -Batch $n *> "$root\$n.log";if(!$?){throw "case failed $n"}
}
foreach($pred in 0,1){$s2=$s.Replace("'DLSS5_MULTI_PASS=1'","'DLSS5_MULTI_PASS=3','DLSS5_MULTI_PASS_PREDICT=$pred','DLSS5_MULTI_PASS_SKIN_PROTECT=0'");[IO.File]::WriteAllText("$root\regression-case.ps1",$s2);& "$root\regression-case.ps1" -Set R -Base A -BenchName benchmark-F.exe -CandidateBenchName benchmark-R.exe -TimingOnly -TimingFrames 180 -Batch "short-$pred" *> "$root\short-$pred.log";if(!$?){throw 'short timing failed'}}
'RGBA_SHORT_DONE'
}finally{if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'multipass-direct-rgba-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}}
