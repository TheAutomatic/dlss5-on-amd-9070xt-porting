$ErrorActionPreference='Stop';$root=$PSScriptRoot
& 'D:\DLSSNR-Lab\game-check.ps1' Stellar Onimusha Magpie Forza Cyberpunk;if($LASTEXITCODE -ne 1){throw 'game active'}
$f=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes('multipass-direct-rgba-20261004');$f.Write($b,0,$b.Length);$f.Close()
try{
foreach($n in 'A','F'){New-Item -ItemType Directory -Force "$root\flat-$n"|Out-Null;Copy-Item 'D:\DLSSNR-Lab\skin-protect-20261004\HIP\gfx1201\*.hsaco' "$root\flat-$n" -Force}
$s=Get-Content "$root\regression.ps1" -Raw;$s=$s.Replace("'DLSS5_FAST_NUMERIC=0'","'DLSS5_FAST_NUMERIC=1','DLSS5_SKIP_BLOCKS='").Replace("'DLSS5_MULTI_PASS=1'","'DLSS5_MULTI_PASS=3','DLSS5_MULTI_PASS_SKIN_PROTECT=0'");[IO.File]::WriteAllText("$root\regression-mp.ps1",$s)
foreach($pred in 0,1){[IO.File]::WriteAllText("$root\regression-mp.ps1",$s.Replace("'DLSS5_MULTI_PASS_SKIN_PROTECT=0'","'DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_MULTI_PASS_PREDICT=$pred'"));& "$root\regression-mp.ps1" -Set F -BenchName benchmark-F.exe -CandidateBenchName benchmark-F.exe -CandidateExtra @('DLSS5_LAB_FEED_DUP=9',"DLSS5_MULTI_PASS_PREDICT=$pred") -TimingOnly -TimingFrames 120 -Batch "feed-$pred" *> "$root\feed-$pred.log";if(!$?){throw 'feed timing failed'}}
'FEED_COST_DONE'
}finally{if((Get-Content 'D:\DLSSNR-Lab\gpu.lock' -Raw).Trim() -eq 'multipass-direct-rgba-20261004'){Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force}}
