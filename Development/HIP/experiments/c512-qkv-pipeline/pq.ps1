Get-CimInstance Win32_Process | ?{$_.CommandLine -match 'q\.ps1|benchmark-'} | %{"$($_.ProcessId) $($_.CommandLine)"}
