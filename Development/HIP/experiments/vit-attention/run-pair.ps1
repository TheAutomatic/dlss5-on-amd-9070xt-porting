$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\vit-attention-20260929'
& "$root\micro.ps1" -Batch micro5 -Match '^ours-.*-(base|native|pair)$'
if(!$?){throw 'Pair test failed'}
& "$root\micro.ps1" -Batch micro6 -OnlyPrefix constv
if(!$?){throw 'V diagnostic repeat failed'}
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^rtc_compile|^Magpie'}){throw 'GPU busy'}
& "$root\occupancy.exe" $root > "$root\occupancy.csv"
if($LASTEXITCODE){throw 'Occupancy failed'}
