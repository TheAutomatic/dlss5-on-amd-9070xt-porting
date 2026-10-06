param([string]$OnlyCase='')
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$r='C:\DLSSNR-Oracle\temporal-20261005\post-only';$lock='D:\DLSSNR-Oracle\gpu.lock';$owner='post-only-gate-20261005'
if([IO.DriveInfo]::new('C:\').AvailableFreeSpace -lt 100GB){throw 'C free<100GB'}
$env:CUDA_CACHE_PATH="$r\cache";$env:TEMP="$r\cache";$env:TMP=$env:TEMP;New-Item -ItemType Directory -Force $env:TEMP|Out-Null
$p=$null
Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match 'SB-Win64|Onimusha|re9|SandFall|Magpie'} | ForEach-Object {throw 'game running'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$b=[Text.Encoding]::UTF8.GetBytes($owner);$f.Write($b,0,$b.Length);$f.Close()
try {
$cases=@('closed-history','zero-motion','one-pixel-motion','subpixel-diagonal');if($OnlyCase){if($OnlyCase -notin $cases){throw 'unknown case'};$cases=@($OnlyCase)}
foreach($case in $cases){
 if($case -eq 'closed-history'){Remove-Item Env:DLSS5_POST_HISTORY_RGBA,Env:DLSS5_POST_MOTION_RGBA -ErrorAction SilentlyContinue}
 else {$env:DLSS5_POST_HISTORY_RGBA="$r\history.f32";$env:DLSS5_POST_MOTION_RGBA=if($case -eq 'zero-motion'){"$r\motion-zero.f32"}elseif($case -eq 'one-pixel-motion'){"$r\motion-one-pixel.f32"}else{"$r\motion-subpixel-diagonal.f32"}}
 $args=@("$r\dlssnr-00.cubin",'cc_tinlayout_fused_post_block_swin_1h_32_fp8',"$r\main.fp8","$r\skip.fp8","$r\weights.bin","$r\blend.bin","$r\color.f32","$r\$case-output.f32",'16','16','1','1','0.03125','native')
 $p=Start-Process "$r\original-post-history-oracle.exe" -ArgumentList $args -WorkingDirectory $r -PassThru -RedirectStandardOutput "$r\$case.log" -RedirectStandardError "$r\$case.err"
 $h=$p.Handle;if(!$p.WaitForExit(15000)){Stop-Process -Id $p.Id -Force;throw '15s probe watchdog'};$p.WaitForExit()
 Get-Content "$r\$case.log";Get-Content "$r\$case.err";if($p.ExitCode -ne 0){throw "case $case exit $($p.ExitCode)"}
}
'POST_ONLY_DONE'
}finally{if($p -and !$p.HasExited){Stop-Process -Id $p.Id -Force};if((Test-Path $lock) -and ((Get-Content $lock -Raw).Contains($owner))){Remove-Item $lock -Force};'LOCK_RELEASED'}
