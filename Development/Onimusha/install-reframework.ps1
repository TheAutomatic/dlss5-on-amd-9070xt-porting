param([ValidateSet('Install','Restore')][string]$Action='Install',[string]$Backup='',[string]$Source='D:\給網友打包\OptiScaler-REFramework-DLSS5-AMD-0.33')
$ErrorActionPreference='Stop'
$game='C:\XboxGames\Onimusha- Way of the Sword\Content'
$source=$Source
# Left over from the 0.26.1 post-upscale package (ReShade + present add-on); the pre-SR host would process frames twice.
$obsolete='re9-present.addon64','dlss5-amd.addon64','ReShade64.dll','ReShade.ini','ReShadePreset.ini'
function Closed {if(Get-Process OnimushaWotS -ErrorAction SilentlyContinue){throw 'Exit Onimusha before replacing files'}}
Closed
if($Action -eq 'Restore'){
 if(!$Backup){throw 'Specify the install backup directory'}
 $rows=Get-Content "$Backup\inventory.json" -Raw|ConvertFrom-Json
 foreach($row in $rows){$target=Join-Path $game $row.rel;if($row.existed){Copy-Item (Join-Path "$Backup\files" $row.rel) $target -Force}else{Remove-Item $target -Force -ErrorAction SilentlyContinue}}
 Write-Output 'Restored original files; empty added directories may remain.';exit
}
if(!(Test-Path "$game\OnimushaWotS.exe")){throw 'Executable not found'}
$items=@()
foreach($line in Get-Content "$source\SHA256SUMS.txt"){
 if($line -notmatch '^([0-9a-fA-F]{64})\s+(.+)$'){throw 'Bad package inventory'}
 $hash=$matches[1];$rel=$matches[2].Replace('/','\')
 if([IO.Path]::IsPathRooted($rel) -or ($rel.Split('\') -contains '..')){throw 'Unsafe package path'}
 if((Get-FileHash (Join-Path $source $rel)).Hash -ne $hash){throw "Package mismatch $rel"}
 $target=Join-Path $game $rel
 $items+=[pscustomobject]@{rel=$rel;installed_sha=$hash;existed=(Test-Path $target);original_sha=$(if(Test-Path $target){(Get-FileHash $target).Hash}else{''})}
}
foreach($n in $obsolete){$t=Join-Path $game $n;if((Test-Path $t) -and !($items|Where-Object rel -eq $n)){$items+=[pscustomobject]@{rel=$n;installed_sha='';existed=$true;original_sha=(Get-FileHash $t).Hash}}}
$Backup='D:\DLSSNR-Lab\onimusha-backups\'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')
New-Item -ItemType Directory -Force "$Backup\files"|Out-Null
foreach($i in $items){if($i.existed){$p=Join-Path "$Backup\files" $i.rel;New-Item -ItemType Directory -Force (Split-Path $p)|Out-Null;Copy-Item (Join-Path $game $i.rel) $p;if((Get-FileHash $p).Hash -ne $i.original_sha){throw 'Backup hash mismatch'}}}
$items|ConvertTo-Json -Depth 4|Set-Content "$Backup\inventory.json" -Encoding UTF8
Closed
try{
 foreach($i in $items){$target=Join-Path $game $i.rel;if(!$i.installed_sha){Remove-Item $target -Force;continue};New-Item -ItemType Directory -Force (Split-Path $target)|Out-Null;Copy-Item (Join-Path $source $i.rel) $target -Force}
 foreach($i in $items|Where-Object installed_sha){if((Get-FileHash (Join-Path $game $i.rel)).Hash -ne $i.installed_sha){throw "Installed hash mismatch $($i.rel)"}}
}catch{foreach($i in $items){$target=Join-Path $game $i.rel;if($i.existed){Copy-Item (Join-Path "$Backup\files" $i.rel) $target -Force}else{Remove-Item $target -Force -ErrorAction SilentlyContinue}};throw}
[pscustomobject]@{target=$game;backup=$Backup;files=$items.Count;replaced=@($items|Where-Object existed|Select-Object -ExpandProperty rel)}|ConvertTo-Json
