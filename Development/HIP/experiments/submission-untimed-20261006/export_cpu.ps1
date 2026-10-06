$ErrorActionPreference='Stop';$p=Join-Path $env:WINDIR 'System32\amdhip64_7.dll';$b=[IO.File]::ReadAllBytes($p)
function U32($off){return [BitConverter]::ToUInt32($b,$off)}
$pe=U32 60;$count=[BitConverter]::ToUInt16($b,($pe+6));$optSize=[BitConverter]::ToUInt16($b,($pe+20));$opt=$pe+24
if([BitConverter]::ToUInt16($b,$opt) -ne 523){throw 'PE32+ expected'}
$sectionStart=$opt+$optSize
function Offset($rva){for($i=0;$i -lt $count;$i++){$s=$sectionStart+40*$i;$va=U32 ($s+12);$size=[Math]::Max((U32 ($s+8)),(U32 ($s+16)));if($rva -ge $va -and $rva -lt $va+$size){return (U32 ($s+20))+$rva-$va}};throw 'RVA outside sections'}
$export=Offset (U32 ($opt+112));$num=U32 ($export+24);$names=Offset (U32 ($export+32));$wanted=@('hipEventCreateWithFlags','hipEventCreate','hipEventRecord','hipEventElapsedTime','hipEventDestroy');$found=@()
for($i=0;$i -lt $num;$i++){$start=Offset (U32 ($names+4*$i));$end=$start;while($b[$end] -ne 0){$end++};$name=[Text.Encoding]::ASCII.GetString($b,$start,$end-$start);if($name -in $wanted){$found+=@($name)}}
[ordered]@{scope='CPU static PE parsing only; no LoadLibrary/HIP/API invocation';dll=$p;dll_sha256=(Get-FileHash $p).Hash.ToLower();file_version=(Get-Item $p).VersionInfo.FileVersion;exports=$found;create_with_flags_present=('hipEventCreateWithFlags' -in $found)}|ConvertTo-Json -Depth 4
