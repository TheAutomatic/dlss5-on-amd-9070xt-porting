param([Parameter(Mandatory=$true)][ValidateSet('off','on','restore')][string]$Mode,[string]$PackageRoot=$PSScriptRoot,[string]$BackupReceipt='')
# The player runs this in an extracted 0.41-a regular package. Never hot-switch these settings.
$ErrorActionPreference='Stop'
$PackageRoot=[IO.Path]::GetFullPath($PackageRoot)
$lab=Join-Path $PackageRoot 'DLSS5-AMD'
$version=Join-Path $PackageRoot 'DLSS5-AMD-VERSION.txt'
if(!(Test-Path $version) -or (Get-Content $version -Raw) -notmatch '0\.41-a'){throw 'Run only against the extracted regular 0.41-a package (-PackageRoot).'}
if(!(Test-Path "$lab\default-config.txt")){throw 'Missing regular package configuration'}
if(Get-Process SB-Win64-Shipping,re9,OnimushaWotS,LOP-Win64-Shipping,Magpie,SandFall*,Cyberpunk2077,WoLong*,Forza* -ErrorAction SilentlyContinue){throw 'Close the game and Magpie before switching, then restart the game after this script.'}
$runningHere=@(Get-Process|Where-Object {try{$_.Path -and $_.Path.StartsWith($PackageRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)}catch{$false}})
if($runningHere.Count){throw ('Close processes launched from the package/game directory: '+($runningHere.Name -join ', '))}
if($Mode -eq 'restore'){
 if(!$BackupReceipt -or !(Test-Path -LiteralPath $BackupReceipt)){throw 'restore requires -BackupReceipt <history-test-backups/.../receipt.json>'}
 $receipt=Get-Content -LiteralPath $BackupReceipt -Raw|ConvertFrom-Json
 $allowed=@([IO.Path]::GetFullPath((Join-Path $lab 'custom-config.txt')),[IO.Path]::GetFullPath((Join-Path $lab 'native-game-flags.txt')))
 foreach($record in $receipt.files){
  $path=[IO.Path]::GetFullPath($record.path);if($path -notin $allowed){throw 'Restore receipt points outside allowed config files'}
  if(!(Test-Path -LiteralPath $path) -or (Get-FileHash -LiteralPath $path).Hash -ne $record.after_sha256){throw "Config changed after this backup; refusing overwrite: $path"}
  if($record.existed){$saved=[IO.Path]::GetFullPath($record.backup)
   if(!$saved.StartsWith((Join-Path $lab 'history-test-backups')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Backup outside package history-test-backups'}
   if(!(Test-Path -LiteralPath $saved) -or (Get-FileHash -LiteralPath $saved).Hash -ne $record.before_sha256){throw 'Backup SHA mismatch'}
  }
 }
 foreach($record in $receipt.files){if($record.existed){Copy-Item -LiteralPath $record.backup -Destination $record.path -Force}else{[IO.File]::Delete($record.path)}}
 Write-Output "Restored files recorded by $BackupReceipt. Restart the game."
 return
}
$settings=[ordered]@{
 DLSS5_TEMPORAL_HISTORY_EXPERIMENT=$(if($Mode -eq 'on'){'1'}else{'0'});
 DLSS5_TEMPORAL_MV_UNJITTERED='1';
 DLSS5_MULTI_PASS='1';DLSS5_MULTI_PASS_SKIN_PROTECT='0';
 DLSS5_VIT_ADAPTIVE='0';DLSS5_VIT_REUSE_HOTKEY='0';DLSS5_HIP_GRAPH='0';DLSS5_OVERLAP='0';
 DLSS5_FAST_TEMPORAL='0';DLSS5_HISTORY_GUARD='0';DLSS5_OUTPUT_SMOOTH='0';DLSS5_PRE_UPSCALE='auto'
}
foreach($key in $settings.Keys){foreach($target in 'Process','User','Machine'){
 $value=[Environment]::GetEnvironmentVariable($key,$target)
 if($null -ne $value){throw "Environment override $key=$value ($target) wins over files. Remove that override in your launch environment before testing; this script will not edit environment settings."}
}}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss-ffff'
$backup=Join-Path $lab "history-test-backups\$stamp"
New-Item -ItemType Directory $backup|Out-Null
$utf8=New-Object Text.UTF8Encoding($false)
$custom=Join-Path $lab 'custom-config.txt';$native=Join-Path $lab 'native-game-flags.txt'
$targets=@($custom);if(Test-Path $native){$targets+=@($native)}
$records=@();$plans=@()
foreach($path in $targets){
 $existed=Test-Path $path;$name=[IO.Path]::GetFileName($path)
 $beforeSha=$null;$bom=$false;$text=''
 if($existed){$bytes=[IO.File]::ReadAllBytes($path);$bom=$bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191
  if($bytes.Length -ge 2 -and (($bytes[0] -eq 255 -and $bytes[1] -eq 254) -or ($bytes[0] -eq 254 -and $bytes[1] -eq 255))){throw "UTF16 config unsupported; no conversion attempted: $path"}
  $beforeSha=(Get-FileHash $path).Hash;Copy-Item $path (Join-Path $backup $name);$strictUtf8=New-Object Text.UTF8Encoding($false,$true);$text=[IO.File]::ReadAllText($path,$strictUtf8)
 }
 $newline=$(if($text.Contains("`r`n")){"`r`n"}else{"`n"})
 foreach($key in $settings.Keys){$pattern='(?m)^[ \t]*'+[regex]::Escape($key)+'=[^\r\n]*';$replacement=$key+'='+$settings[$key]
  if([regex]::IsMatch($text,$pattern)){$text=[regex]::Replace($text,$pattern,$replacement)}else{if($text.Length -and !$text.EndsWith("`n")){$text+=$newline};$text+=$replacement+$newline}
 }
 $plans+=@([ordered]@{path=$path;existed=$existed;backup=$(if($existed){Join-Path $backup $name}else{$null});before_sha256=$beforeSha;text=$text;bom=$bom})
}
try {
 foreach($plan in $plans){$path=$plan.path;$encoding=New-Object Text.UTF8Encoding($plan.bom);[IO.File]::WriteAllText($path,$plan.text,$encoding)
  foreach($key in $settings.Keys){if(!(Select-String -LiteralPath $path -Pattern ('^'+[regex]::Escape($key)+'='+[regex]::Escape($settings[$key])+'$') -Quiet)){throw "Readback failed $key in $path"}}
  $records+=@([ordered]@{path=$path;existed=$plan.existed;backup=$plan.backup;before_sha256=$plan.before_sha256;after_sha256=(Get-FileHash $path).Hash})
 }
} catch {
 foreach($plan in $plans){if($plan.existed){Copy-Item -LiteralPath $plan.backup -Destination $plan.path -Force}else{if(Test-Path $plan.path){[IO.File]::Delete($plan.path)}}}
 throw
}
[IO.File]::WriteAllText((Join-Path $backup 'receipt.json'),([ordered]@{mode=$Mode;settings=$settings;files=$records;note='MV_UNJITTERED=1 is an explicit test assumption, not context-flag detection; other keys unchanged'}|ConvertTo-Json -Depth 6),$utf8)
Write-Output "Applied $Mode. Custom and existing native overrides agree. Backup: $backup"
Write-Output 'Restart the game. Test MP1 only; F9 switching from an MP3 startup is insufficient. Check temporal-history-experiment.txt and native-hip.txt for requested/active/reason.'
