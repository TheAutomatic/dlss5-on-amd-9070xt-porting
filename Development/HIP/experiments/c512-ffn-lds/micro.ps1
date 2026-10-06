param([string]$Batch='micro1',[string]$OnlyPrefix='',[string]$Match='.*')
$ErrorActionPreference='Stop'
if(!(Test-Path "D:\DLSSNR-Lab\hip-backend\c512-ffn-lds-20260930\jobbench.exe")){Copy-Item D:\DLSSNR-Lab\hip-backend\vit-qkv-20260929\jobbench.exe D:\DLSSNR-Lab\hip-backend\c512-ffn-lds-20260930\}
$root='D:\DLSSNR-Lab\hip-backend\c512-ffn-lds-20260930'
New-Item -ItemType Directory -Force "$root\$Batch","$root\golden"|Out-Null
foreach($job in (Get-Content "$root\jobs.json" -Raw|ConvertFrom-Json)){
 if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^rtc_compile|^Magpie'}){throw 'GPU busy'}
 $id=$job.id;if($id -notmatch $Match){continue};if($OnlyPrefix -and !$id.StartsWith($OnlyPrefix)){continue}
 if($id -like 'ours-*'){$parts=$id.Split('-');$env:JOB_GOLDEN="$root\golden\$($parts[0])-$($parts[1])"}else{$env:JOB_GOLDEN=$null}
 $env:JOB_WRITE_GOLDEN=if($id -like '*-base'){'1'}else{$null}
 & "$root\jobbench.exe" "$root\jobs\$id.bin" $root 128 7 > "$root\$Batch\$id.log" 2> "$root\$Batch\$id.err"
 if($LASTEXITCODE){Get-Content "$root\$Batch\$id.err";throw "Failed $id"}
 Get-Content "$root\$Batch\$id.log"|Select-String '^RESULT,|^EXACT,'
}
Compress-Archive "$root\$Batch\*" "$root\$Batch.zip" -Force
