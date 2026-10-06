$r='D:\DLSSNR-Lab\hip-backend\hoist-loads-20260930'
"SAME CU: "+(Select-String "$r\full-CU.log" -Pattern '^SAME').Count+" "+((Select-String "$r\full-CU.log" -Pattern 'AE CSV|FULL_DONE')|%{$_.Line})
& "$r\final.ps1" -Modules 'c64-wave2,c32-wave1'
"h15 "+(Get-FileHash "$r\cand-h15\c64-wave2.hsaco").Hash; "u3 "+(Get-FileHash "$r\cand-u3\c32-wave1.hsaco").Hash
& "$r\run.ps1" -Name HCU -Builds final -Rounds 3 -NoBuild *> "$r\go-HCU.log"; Get-Content "$r\go-HCU.log"
& "$r\p99m.ps1" -Set HC; & "$r\p99m.ps1" -Set CU; & "$r\p99m.ps1" -Set HCU
