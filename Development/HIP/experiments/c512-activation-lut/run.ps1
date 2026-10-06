$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\c512-activation-lut-20261004';$lock='D:\DLSSNR-Lab\gpu.lock';$owner='c512-activation-lut-20261004'
if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'}
& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'Game running/check failure'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes("$owner $(Get-Date -Format s)");$f.Write($b,0,$b.Length);$f.Close()
$p=$null
try {
 & D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'Game started before probe'}
 $weights="$root\block23-ffwd.f32"
 if(!(Test-Path $weights)){throw "weights missing $weights"}
 $p=Start-Process -FilePath "$root\c512-activation-lut-probe.exe" -ArgumentList @("$root\gfx1201\baseline.hsaco","$root\gfx1201\candidate.hsaco",$weights) -WorkingDirectory $root -PassThru -RedirectStandardOutput "$root\probe.log" -RedirectStandardError "$root\probe.err"
 $retainedHandle=$p.Handle
 $last=Get-Date
 while(!$p.WaitForExit(250)) {
  if(((Get-Date)-$last).TotalSeconds -ge 15){
   & D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie'
   if($LASTEXITCODE -ne 1){Stop-Process -Id $p.Id -Force;throw 'Game started; stopped probe only'}
   $last=Get-Date
  }
 }
 $p.WaitForExit();Get-Content "$root\probe.log";Get-Content "$root\probe.err";if($p.ExitCode -ne 0){throw "probe exit $($p.ExitCode)"}
 'PROBE_DONE'
} finally {
 if($p -and !$p.HasExited){Stop-Process -Id $p.Id -Force}
 if((Test-Path $lock) -and ((Get-Content $lock -Raw).Contains($owner))){Remove-Item $lock -Force}
 'LOCK_RELEASED'
}
