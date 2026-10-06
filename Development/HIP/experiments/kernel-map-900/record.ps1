param([int]$Height=900)
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\kernel-map-900-20260930'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^recorder|^jobbench|^Magpie'}){throw 'GPU busy'}
$syn="$root\synthetic-$Height";New-Item -ItemType Directory -Force $syn|Out-Null;$env:MAP_DIR=$syn
$flags=@(Get-Content "$root\run-plain-$Height\flags.txt")
[IO.File]::WriteAllLines("$root\record-flags-$Height.txt",$flags)
& "$root\recorder-v3.exe" 'D:\DLSSNR-Lab\zero-copy-io-20260928\assets' "$root\record-flags-$Height.txt" 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16' "$root\record-$Height" 1 0 "$root\flat-P" 0 0 0 0 > "$root\record-$Height.log" 2> "$root\record-$Height.err"
"exit $LASTEXITCODE jobs=$(@(Select-String -Path "$root\record-$Height.log" -Pattern '^JOB ').Count) files=$(@(Get-ChildItem $syn).Count)"
