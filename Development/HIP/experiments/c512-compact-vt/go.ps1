# build VT (C512_COMPACT_VT 1) + bit-exact + 3 ABBA rounds
$root='D:\DLSSNR-Lab\hip-backend\c512-compact-vt-20260930'
& "$root\run.ps1" -Name VT -Module c512-m32-mh -Defs 'C512_COMPACT_VT 1' -Rounds 3 -NoBuild *> "$root\go-VT.log"
'GO_DONE'
