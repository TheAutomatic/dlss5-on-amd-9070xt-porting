$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c256-fusion'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU busy'}
& "$r\hip-production\build-modules.ps1" -SourceDir "$r\hip-production" -Compiler 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' -OutputDir "$r\production" -Only c64-wave2
if($LASTEXITCODE){throw 'production compile'}
& "$r\build.ps1" -Arch gfx1200 -Sets @('Z','B')
if($LASTEXITCODE){throw 'gfx1200 controls'}
