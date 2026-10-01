$r='D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001'
& "$r\ngx.ps1" -Style 7 -Skip '42,43,46' -Tag s7-rel
& "$r\ngx.ps1" -Style 2 -Skip '42,43,46' -Tag s2-rel
& "$r\ngx.ps1" -Style 1.5 -Skip '42,43,46' -Tag s15-rel
'NGX_DONE'
