$r='D:\DLSSNR-Lab\hip-backend\fast-tier-20261001'
& "$r\build.ps1" -Name ks -Module deep_fast-packed -Defs 'HIP_VIT_ATTN_KSPLIT 1'
& "$r\build.ps1" -Name f8w -Module deep_fast-packed -Defs 'HIP_DEC_F8W 1'
& "$r\build.ps1" -Name ksf8 -Module deep_fast-packed -Defs 'HIP_VIT_ATTN_KSPLIT 1,HIP_DEC_F8W 1'
