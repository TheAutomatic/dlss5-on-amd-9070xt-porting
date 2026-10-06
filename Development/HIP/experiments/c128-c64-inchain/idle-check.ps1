param([switch]$KnobOnly)
# DLSS5_VIT_ADAPTIVE_IDLE_MS check. (1) env=0 (reset every frame on the new host; base host ignores the env): AE CSV must differ -> the knob works.
# (2) env unset and env=1e9: full.ps1 19 groups, new host vs base host, same modules -> default and regression setting change nothing.
$root='D:\DLSSNR-Lab\hip-backend\c128-c64-inchain-20261001'
& "$root\setup.ps1"|Out-Null
$t=Get-Content "$root\regression.ps1" -Raw;$t=$t.Replace('|^rtc_compile','');Set-Content "$root\regression.ps1" $t
Get-ChildItem $root -Directory -Filter 'runtime-regression-*'|Remove-Item -Recurse -Force
New-Item -ItemType Directory -Force "$root\flat-IDLE"|Out-Null;Copy-Item "$root\flat-A\*.hsaco" "$root\flat-IDLE" -Force
$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
# knob via the candidate's flags (overrides the pinned 1e9 because flags are applied in order, later wins? -> checked by the result)
& "$root\regression.ps1" -Set IDLE -Adaptive 1 -BenchName benchmark-base.exe -Base A -CandidateBenchName benchmark-P.exe -CandidateExtra @('DLSS5_VIT_ADAPTIVE_IDLE_MS=0') -CorrectnessOnly -Only @('900-static') -Batch knob *> "$root\idle-knob.log"
$d="$root\runtime-regression-IDLE-knob\900-static";"knob=0: images $((Select-String -Path "$root\idle-knob.log" -Pattern '^SAME').Count) SAME, csv diff lines $(@(Compare-Object (Get-Content "$d-False\adaptive.csv") (Get-Content "$d-True\adaptive.csv")).Count)"
if($KnobOnly){Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force;return}
$full=(Get-Content "$root\full.ps1" -Raw)
foreach($mode in '1e9'){
 Get-ChildItem $root -Directory -Filter 'runtime-regression-IDLE-*'|Remove-Item -Recurse -Force
 try{& "$root\full.ps1" -Set IDLE -Rounds 1 *> "$root\full-IDLE-$mode.log";"$mode FULL OK"}catch{"$mode FULL FAIL $_"}
 "$mode SAME-count: $((Select-String -Path "$root\full-IDLE-$mode.log" -Pattern '^SAME|AE CSV SAME').Count)"
 & "$root\summarize.ps1" -Sets IDLE
}
Get-ChildItem $root -Recurse -Include *.f16,*.ppm | Where-Object {$_.FullName -match 'runtime-regression'} | Remove-Item -Force
