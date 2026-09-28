param([string]$Set='C',[string]$CandidateBenchName='benchmark-production.exe')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fusion-round3'
foreach($round in 'cumulative1','cumulative2'){
 & "$r\regression.ps1" -Set $Set -Base 035 -BenchName benchmark-035.exe -CandidateBenchName $CandidateBenchName -Batch $round -TimingOnly -BaseAssets 'D:\給網友打包\OptiScaler-DLSS5-AMD-0.35\DLSS5-AMD\native-game-tiled-assets' -CandidateAssets 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
 if($LASTEXITCODE){throw 'cumulative timing'}
}
