$ErrorActionPreference='Stop';$root=$PSScriptRoot
$games=@('C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64','C:\XboxGames\Onimusha- Way of the Sword\Content')
foreach($g in $games){$g;foreach($n in 'default-config.txt','custom-config.txt','native-game-flags.txt'){"CONFIG $n";Get-Content "$g\DLSS5-AMD\$n"|Select-String -Pattern '^DLSS5_(PRE_UPSCALE|MULTI_PASS|FAST_NUMERIC|SKIP_BLOCKS)='};foreach($n in 'dlss5-amd.addon64','LmxxfNrRuntime.dll','_storage_\LmxxfNrRuntime.dll'){if(Test-Path "$g\$n"){Get-FileHash "$g\$n"|Format-List Path,Hash}}}
& 'D:\DLSSNR-Lab\fast-tier\switch.ps1' -Tier status
Get-PSDrive D|Format-Table Name,Used,Free
'AUDIT_DONE'
