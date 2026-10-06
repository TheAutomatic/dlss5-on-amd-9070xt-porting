$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\sync-network-gap1080-20261006';$base='D:\DLSSNR-Lab\history-trial-041a-20261006'
$assets=@(Get-ChildItem "$base\assets" -File | ForEach-Object {@{name=$_.Name;bytes=$_.Length;sha256=(Get-FileHash $_.FullName).Hash}})
$assets|ConvertTo-Json -Depth 4|Set-Content "$r\asset-hashes.json"
$raw=@();foreach($directory in Get-ChildItem $r -Directory | Where-Object {$_.Name -match '^(1088|1152)-[0-9][0-9]-'}){$label=$directory.Name
 foreach($name in 'first.rgb32f','last.rgb32f','final.rgba32f'){$p=Join-Path "$r\$label" $name;if(Test-Path -LiteralPath $p){$f=Get-Item -LiteralPath $p;$raw+=@(@{name="$label/$name";bytes=$f.Length;sha256=(Get-FileHash -LiteralPath $p).Hash})}}
}
$raw|ConvertTo-Json -Depth 4|Set-Content "$r\large-raw-hashes.json"
# These are only this experiment's outputs. Preserve fixture inputs, old model/SPV, logs and receipts.
foreach($f in $raw){Remove-Item -LiteralPath (Join-Path $r $f.name) -Force}
@{lock_absent=!(Test-Path D:\DLSSNR-Lab\gpu.lock);raw_outputs_cleaned=$raw.Count;asset_count=$assets.Count;D_free=(Get-PSDrive D).Free}|ConvertTo-Json|Set-Content "$r\final-status.json"
'CPU_RECEIPT_SAVED; only own raw outputs cleaned'
