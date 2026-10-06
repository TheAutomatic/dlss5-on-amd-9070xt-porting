# step 1 package: final build (both arches, HIP_DEC_WIDE 1), then PK = DW module + new decode shader + IO_FUSE=1 on host P3, 19 groups + 3 ABBA
$root='D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001'
Remove-Item "$root\src" -Recurse -Force -EA 0;Expand-Archive "$root\src.zip" "$root\src" -Force;Remove-Item "$root\src.zip"
& "$root\build.ps1" -Name final -Defs 'HIP_DEC_WIDE 1' -Both
"== PK";& "$root\cand.ps1" -Set PK -Build final -CandAssets -Extra @('DLSS5_IO_FUSE=1') -CandHost P3 -RollHost P3roll
'GO2_DONE'
