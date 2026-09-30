# prod rebuilds (must equal installed) + candidates. G = gather fold (two modules), T = C512 t8 without the dead f32 store.
$r='D:\DLSSNR-Lab\hip-backend\gap-fusion-20260930'
& "$r\build.ps1" -Name prod-deep -Module deep_fast-packed
& "$r\build.ps1" -Name prod-mh -Module multihead-fast-padded-wave-packed
& "$r\build.ps1" -Name Gd -Module deep_fast-packed -Defs 'HIP_VIT_GATHER_FOLD 1'
& "$r\build.ps1" -Name Gm -Module multihead-fast-padded-wave-packed -Defs 'HIP_VIT_GATHER_FOLD 1'
& "$r\build.ps1" -Name T -Module deep_fast-packed -Defs 'C512_T8_NO_F32 1'
& "$r\build.ps1" -Name GTd -Module deep_fast-packed -Defs 'HIP_VIT_GATHER_FOLD 1','C512_T8_NO_F32 1'
'B1_DONE'
