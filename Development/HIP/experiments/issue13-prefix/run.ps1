$ErrorActionPreference='Stop';$base='D:\DLSSNR-Oracle\issue13';$lock='D:\DLSSNR-Oracle\issue13-prefix.lock'
if(Get-Process -EA 0|?{$_.ProcessName -match 'Shipping|Stellar|Onimusha|^re9$|Genshin|YuanShen|Wuthering|Client-Win64|^ngx-probe|^ngx-prefix'}){throw 'game/lab busy'}
$f=[IO.File]::Open($lock,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read);$f.Close()
try{New-Item -ItemType Directory -Force "$base\prefix-20261004"|Out-Null
$ErrorActionPreference='Continue';& 'D:\DLSSNR-Oracle\ngx-prefix.exe' "$base\core615\nvngx.dll" "$base\core615" "$base\inputs1152" "$base\prefix-20261004" > "$base\prefix-20261004\run.log" 2> "$base\prefix-20261004\stderr.log";$rc=$LASTEXITCODE;$ErrorActionPreference='Stop';if($rc){throw "prefix probe failed $rc"};Get-Content "$base\prefix-20261004\run.log" -Tail 8
}finally{Remove-Item $lock -Force}
