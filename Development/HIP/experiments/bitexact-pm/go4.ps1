# steps 2+3 on the new installed base (DEC_WIDE deep_fast-packed; add-on unchanged): base = benchmark-base (main) + flat-A; candidates: SIP (swin-persistent SP_INIT_PAIR 1), PFT (c32 CW_POST_FULL_TILE 1),
# W16S (c64-wave2 W2_FFN_W16_SMALL 3), VT (c512-m32-mh C512_COMPACT_VT 1). Each 19 groups + 3 ABBA.
$root='D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001'
& "$root\setup.ps1"|Select-Object -Last 4
& "$root\assets.ps1"|Select-Object -First 2
$b=@(@{n='SIP';m='swin-persistent';d='SP_INIT_PAIR 1'},@{n='PFT';m='c32-wave1';d='CW_POST_FULL_TILE 1'},@{n='W16S';m='c64-wave2';d='W2_FFN_W16_SMALL 3'},@{n='VT';m='c512-m32-mh';d='C512_COMPACT_VT 1'})
foreach($x in $b){& "$root\build.ps1" -Name $x.n -Module $x.m -Defs $x.d|Select-Object -First 1;& "$root\build.ps1" -Name "prod-$($x.m)" -Module $x.m|Select-Object -First 1;"installed $((Get-FileHash "$root\flat-A\$($x.m).hsaco").Hash.Substring(0,8))"}
foreach($x in $b){"== $($x.n)";& "$root\cand.ps1" -Set $x.n -Module $x.m -Build $x.n -CandHost P3 -RollHost P3roll}
'GO4_DONE'
