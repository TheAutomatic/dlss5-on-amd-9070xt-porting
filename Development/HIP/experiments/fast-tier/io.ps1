$r='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001'
& "$r\mkset.ps1" IO ''
& "$r\lock.ps1" take fast-tier-IO; if($LASTEXITCODE){exit 1}
try{
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
foreach($b in 'qa','qb'){Get-ChildItem $r -Directory -Filter "runtime-regression-IO-$b"|Remove-Item -Recurse -Force}
"== new decode shader (assets-cand) + IO_FUSE"
& "$r\regression.ps1" -Set IO -Adaptive 0 -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-P.exe -CandidateAssets 'D:\DLSSNR-Lab\hip-backend\input-slim-20261001\assets-cand' -CandidateExtra 'DLSS5_IO_FUSE=1' -CorrectnessOnly -Batch qa | Select-String 'CMP'
"== old decode shader (assets-base) + IO_FUSE"
& "$r\regression.ps1" -Set IO -Adaptive 0 -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-P.exe -CandidateExtra 'DLSS5_IO_FUSE=1' -CorrectnessOnly -Only '900-static' -Batch qb | Select-String 'CMP'
Select-String -Path "$r\runtime-regression-IO-qa\900-static-True\run.log" -Pattern 'io_fuse' -Encoding Unicode | Select-Object -First 1
}finally{& "$r\lock.ps1" drop fast-tier-IO; Get-ChildItem $r -Directory -Filter 'runtime-regression-IO-*'|Remove-Item -Recurse -Force}
