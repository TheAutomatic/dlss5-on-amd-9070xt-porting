param([string]$Set='F',[string]$Arch='gfx1201')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\c512-fusion'
if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^rtc_compile'}){throw 'GPU busy'}
$d="$r\build-$Set-$Arch";New-Item -ItemType Directory -Force $d|Out-Null
& 'D:\DLSSNR-Lab\build-0927\rtc_compile.exe' "$d\c512-m32-mh.hsaco" "$r\c512-$Set.hip" comgr $Arch
if($LASTEXITCODE){throw 'compile'}
if($Arch -eq 'gfx1201'){
 New-Item -ItemType Directory -Force "$r\flat-$Set"|Out-Null
 Copy-Item "$r\flat-A\*.hsaco" "$r\flat-$Set" -Force
 Copy-Item "$d\c512-m32-mh.hsaco" "$r\flat-$Set\c512-m32-mh.hsaco" -Force
}
