$s='D:\DLSSNR-Lab\competitor-timing-20260930\ours.ps1'
foreach($r in 1,2){foreach($c in @(@(900,1152),@(1080,1152),@(1080,1088))){
 & $s -Height $c[0] -Rows $c[1] -Tag "span$r" -Span 1
 & $s -Height $c[0] -Rows $c[1] -Tag "wall$r" -Span 0 }}
