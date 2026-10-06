# C1: mh_attention_project_frag_c512 residual-init hoist (HIP_C512_HOIST_RES 1), only multihead-fast-padded-wave-packed; host unchanged.
$root='D:\DLSSNR-Lab\hip-backend\fill-cu-20260930'
& "$root\run.ps1" -Name HR -Builds hr -Rounds 3 -NoBuild *> "$root\go-HR.log"
'GO_DONE'
