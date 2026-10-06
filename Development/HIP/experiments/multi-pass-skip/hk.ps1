# hk.ps1 (multi-pass-skip): hotkey file logic without a key press (hk_test.exe calls NativeHotFlags::CycleMultiPass, waits 1.1 s and
# polls the hot reload). No GPU. Each case: fresh copy of hk_test.exe in its own folder with a DLSS5-AMD config folder.
$ErrorActionPreference='Continue';$root='D:\DLSSNR-Lab\hip-backend\multi-pass-skip-20261003\hk';Remove-Item $root -Recurse -Force -EA 0
$bom=New-Object Text.UTF8Encoding($true);$nobom=New-Object Text.UTF8Encoding($false)
function Case($name,$cur,$files,$envv,$hotkey){$d="$root\$name";New-Item -ItemType Directory -Force "$d\DLSS5-AMD\logs"|Out-Null;Copy-Item "$root\..\bin\hk_test.exe" $d
 foreach($k in $files.Keys){[IO.File]::WriteAllText("$d\DLSS5-AMD\$k",$files[$k][0],$(if($files[$k][1]){$bom}else{$nobom}))}
 if($envv){$env:DLSS5_MULTI_PASS=$envv}else{Remove-Item Env:\DLSS5_MULTI_PASS -EA 0};if($hotkey){$env:DLSS5_MULTI_PASS_HOTKEY=$hotkey}else{Remove-Item Env:\DLSS5_MULTI_PASS_HOTKEY -EA 0}
 $out=& "$d\hk_test.exe" $cur 2>"$d\err.txt";"== $name : $out";Get-Content "$d\err.txt"|%{"  stderr: $_"}
 foreach($k in 'custom-config.txt','native-game-flags.txt'){$p="$d\DLSS5-AMD\$k";if(Test-Path $p){$b=[IO.File]::ReadAllBytes($p);"  $k bom=$($b.Length -ge 3 -and $b[0] -eq 0xEF) crlf=$([Text.Encoding]::UTF8.GetString($b).Contains("`r`n")) :: $(([Text.Encoding]::UTF8.GetString($b) -replace "`r",'\r' -replace "`n",'\n'))"}}
 Get-Content "$d\DLSS5-AMD\logs\native-game-oneshot.txt" -EA 0|%{"  log: $_"}}
Case 'no-custom' 1 @{'native-game-flags.txt'=@("# old`r`nDLSS5_STYLE=1`r`n",$false)} $null $null
Case 'replace-crlf-bom' 2 @{'custom-config.txt'=@("# mine`r`nDLSS5_STYLE=0`r`nDLSS5_MULTI_PASS=2`r`n# end`r`n",$true)} $null $null
Case 'append-no-final-nl' 3 @{'custom-config.txt'=@("DLSS5_STYLE=0",$false)} $null $null
Case 'native-has-key' 1 @{'custom-config.txt'=@("DLSS5_MULTI_PASS=1`n",$false);'native-game-flags.txt'=@("DLSS5_SKIP_BLOCKS=`nDLSS5_MULTI_PASS=1`n",$false)} $null $null
Case 'env-override' 1 @{'custom-config.txt'=@("DLSS5_MULTI_PASS=1`n",$false)} '1' $null
Case 'hotkey-0' 1 @{'custom-config.txt'=@("DLSS5_MULTI_PASS_HOTKEY=0`n",$false)} $null $null
Case 'hotkey-F10' 1 @{'custom-config.txt'=@("x`n",$false)} $null 'F10'
Case 'hotkey-0x77' 1 @{'custom-config.txt'=@("x`n",$false)} $null '0x77'
Case 'hotkey-bad' 1 @{'custom-config.txt'=@("x`n",$false)} $null 'Q'
Remove-Item Env:\DLSS5_MULTI_PASS,Env:\DLSS5_MULTI_PASS_HOTKEY -EA 0
'HK_DONE'
