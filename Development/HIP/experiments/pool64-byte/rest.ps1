$ErrorActionPreference='Stop'
foreach($n in 'compat','fallback','rt'){& "$PSScriptRoot\$n.ps1" *> "$PSScriptRoot\$n-phase.log";if(!$?){throw "phase $n failed"};Get-Content "$PSScriptRoot\$n-phase.log" -Tail 3}
