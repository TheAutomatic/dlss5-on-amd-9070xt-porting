# build NF (C512_COMPACT_NOF 1 + C512_COMPACT_RCP 1) + prod, bit-exact + 3 ABBA rounds
$root='D:\DLSSNR-Lab\hip-backend\c512-av-f-20260930'
& "$root\run.ps1" -Name NF -Module c512-m32-mh -Defs 'C512_COMPACT_NOF 1,C512_COMPACT_RCP 1' -Rounds 3 *> "$root\go-NF.log"
'GO_DONE'
