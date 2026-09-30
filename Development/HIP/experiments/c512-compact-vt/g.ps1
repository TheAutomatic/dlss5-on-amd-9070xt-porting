Select-String -Path D:\DLSSNR-Lab\hip-backend\c512-compact-vt-20260930\full-*.log -Pattern 'FULL_DONE','FAIL','SAME','changed','Exception' | ForEach-Object {$_.Filename+': '+$_.Line}
