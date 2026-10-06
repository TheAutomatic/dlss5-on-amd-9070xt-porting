# product-fmt (2026-09-30): colour-format fallback + hot reload smoke on the 9070. Lab D:\DLSSNR-Lab\product-fmt-20260930 (setup copies
# regression.ps1 + flat-F from c32-align). Waits for an idle GPU (10 min steps, 2 h max). Nothing is installed into any game.
param([int]$MaxWaitMin=120,[switch]$SkipHost)
$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\product-fmt-20260930';$c32='D:\DLSSNR-Lab\hip-backend\c32-align-20260930'
function Busy{[bool](Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^Magpie|^rt_bench|^rt_fmt|^runtime-smoke|^jobbench|^rtc_compile|^microbench'})}
$waited=0;while(Busy){if($waited -ge $MaxWaitMin){'GPU_BUSY_TIMEOUT';exit 3};"busy, waiting ($waited min)";Start-Sleep 600;$waited+=10}
Copy-Item "$c32\regression.ps1" $root -Force
if(!(Test-Path "$root\flat-F")){Copy-Item "$c32\flat-F" "$root\flat-F" -Recurse}
# 1) add-on host: HEAD vs candidate, same modules, 7 cases x EXACT/AE x 12 frames (168 per mode) + AE CSV
if(!$SkipHost){foreach($ae in 0,1){
 & "$root\regression.ps1" -Set F -Base F -Adaptive $ae -BenchName benchmark-hbase.exe -CandidateBenchName benchmark-fmt.exe -CorrectnessOnly -Batch "fmt-$ae"
 if(!$?){throw 'host regression failed'}
}
foreach($slot in Get-ChildItem "$root\runtime-regression-F-fmt-1" -Directory -Filter '*-True'){$base=$slot.FullName.Substring(0,$slot.FullName.Length-4)+'False'
 if([IO.File]::ReadAllText("$base\adaptive.csv") -cne [IO.File]::ReadAllText("$($slot.FullName)\adaptive.csv")){throw 'AE decisions changed'}};'AE CSV SAME'}
# 2) RE9 runtime: HEAD vs new, RGBA16F colour, 900/1080
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
New-Item -ItemType Directory -Force "$root\shaders"|Out-Null;Copy-Item "$c32\runtime-new\shaders\*" "$root\shaders" -Recurse -Force  # runtime finds shaders beside the DLL
$mods="$c32\runtime-new\modules"
foreach($h in 900,1080){$env:DLSS5_NETWORK_HEIGHT="$h";$env:RT_COLOR_FORMAT='10';Remove-Item Env:RT_DUMP -ErrorAction SilentlyContinue
 $hs=foreach($rt in 'LmxxfNrRuntime-head.dll','LmxxfNrRuntime.dll'){& "$root\rt_fmt.exe" "$root\$rt" $mods '1707x961' 12 1 *> "$root\rt-$rt-$h.log";if($LASTEXITCODE){throw "rt $rt $h"};[regex]::Match((Get-Content "$root\rt-$rt-$h.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value}
 if(!$hs[0] -or $hs[0] -ne $hs[1]){throw "RE9 runtime hash changed $h $($hs -join ' ')"};"RUNTIME SAME $h $($hs[0])"}
$ErrorActionPreference='Continue' # the HEAD runtime rejects new formats on stderr by design
# 3) RE9 runtime, fallback formats (900), output dumped; HEAD runtime shown for the old behaviour
$env:DLSS5_NETWORK_HEIGHT='900';New-Item -ItemType Directory -Force "$root\dumps"|Out-Null
foreach($f in 67,88,92,24,2,6,13,31,85,86,115){$env:RT_COLOR_FORMAT="$f"
 $env:RT_DUMP="$root\dumps\new-$f.raw";& "$root\rt_fmt.exe" "$root\LmxxfNrRuntime.dll" $mods '1707x961' 6 1 *> "$root\fmt-new-$f.log";"NEW fmt=$f exit=$LASTEXITCODE $((Get-Content "$root\fmt-new-$f.log"|Select-String 'hash=|FAIL|rejected|Prepare').Line)"
 $env:RT_DUMP="$root\dumps\head-$f.raw";& "$root\rt_fmt.exe" "$root\LmxxfNrRuntime-head.dll" $mods '1707x961' 6 1 *> "$root\fmt-head-$f.log";"HEAD fmt=$f exit=$LASTEXITCODE $((Get-Content "$root\fmt-head-$f.log"|Select-String 'hash=|FAIL|rejected|Prepare').Line)"}
$env:RT_COLOR_FORMAT='10';$env:RT_DUMP="$root\dumps\new-10.raw";& "$root\rt_fmt.exe" "$root\LmxxfNrRuntime.dll" $mods '1707x961' 6 1 *> "$root\fmt-new-10.log";"NEW fmt=10 $((Get-Content "$root\fmt-new-10.log"|Select-String 'hash=').Line)"
# 4) add-on conversion pass on real D3D12
& "$root\convert_smoke.exe" "$root\native_format_convert.hlsl"
if($LASTEXITCODE){throw 'convert smoke failed'}
'PRODUCT_FMT_DONE'
