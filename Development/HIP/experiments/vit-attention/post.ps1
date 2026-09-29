$ErrorActionPreference='Stop'
$root='D:\DLSSNR-Lab\hip-backend\vit-attention-20260929'
function Idle {if(Get-Process|Where-Object{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^rt_bench|^jobbench|^rtc_compile|^Magpie|^runtime-smoke'}){throw 'GPU busy'}}
Idle
& "$root\occupancy.exe" $root > "$root\occupancy.csv"
if($LASTEXITCODE){throw 'Occupancy failed'}
foreach($side in 'base','candidate'){
 $d="$root\runtime-$side";New-Item -ItemType Directory -Force "$d\modules\gfx1200","$d\modules\gfx1201","$d\shaders"|Out-Null
 foreach($arch in 'gfx1200','gfx1201'){
  Copy-Item "$root\baseline\$arch\*.hsaco" "$d\modules\$arch" -Force
  if($side -eq 'candidate'){Copy-Item "$root\production-1\$arch\deep_fast-packed.hsaco" "$d\modules\$arch" -Force}
 }
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force
 Copy-Item 'D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929\LmxxfNrRuntime.dll' "$d\LmxxfNrRuntime.dll" -Force
 $lines=@(Get-ChildItem "$d\modules" -Recurse -Filter '*.hsaco'|ForEach-Object{$name=$_.FullName.Substring(("$d\modules\").Length).Replace('\','/');"$((Get-FileHash $_.FullName).Hash.ToLower())  $name"})
 [IO.File]::WriteAllLines("$d\modules\SHA256SUMS",$lines)
}
$env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets'
$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
foreach($height in 900,1080){foreach($side in 'base','candidate'){
 Idle;$env:DLSS5_NETWORK_HEIGHT="$height";$d="$root\runtime-$side";$env:LMXXF_SHADER_DIR="$d\shaders"
 & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$root\runtime-$side-$height.log"
 if($LASTEXITCODE){throw 'Runtime failed'}
}}
foreach($height in 900,1080){$a=[regex]::Match((Get-Content "$root\runtime-base-$height.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value;$b=[regex]::Match((Get-Content "$root\runtime-candidate-$height.log" -Raw),'hash=([0-9a-f]+)').Groups[1].Value;if(!$a -or $a -ne $b){throw 'Runtime mismatch'};"RUNTIME SAME $height $a"}
foreach($f in (Get-Content "$root\snapshot.json" -Raw|ConvertFrom-Json)){if((Get-FileHash $f.path).Hash -ne $f.sha256){throw 'Installed baseline changed'}}
'INSTALLED_SNAPSHOT_UNCHANGED=66'
