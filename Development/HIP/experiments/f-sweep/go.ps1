# f-sweep: one candidate per module group (source default 0, recipe 1), each vs flat-A: bit-exact + rollover + 3 ABBA rounds.
$root='D:\DLSSNR-Lab\hip-backend\f-sweep-20260930'
& "$root\run.ps1" -Name D -Module deep_fast-packed -Defs 'HIP_BYTE_F_ADD0 1,HIP_VIT_ATTN_RCP 1' -Rounds 3 *> "$root\go-D.log"
& "$root\run.ps1" -Name V -Module vit-stream -Defs 'HIP_BYTE_F_ADD0 1' -Rounds 3 *> "$root\go-V.log"
& "$root\run.ps1" -Name M -Module multihead-fast-padded-wave-packed -Defs 'HIP_Q8_ADD0 1' -Rounds 3 *> "$root\go-M.log"
& "$root\build.ps1" -Name prod-c64-wave2 -Module c64-wave2 *> "$root\go-W.log"
& "$root\build.ps1" -Name prod-swin-persistent -Module swin-persistent *>> "$root\go-W.log"
& "$root\build.ps1" -Name W64 -Module c64-wave2 -Defs 'W2_UP_ADD0 1' *>> "$root\go-W.log"
& "$root\build.ps1" -Name W256 -Module swin-persistent -Defs 'W2_UP_ADD0 1' *>> "$root\go-W.log"
& "$root\run.ps1" -Name W -Builds W64,W256 -Rounds 3 -NoBuild *>> "$root\go-W.log"
'GO_DONE'
