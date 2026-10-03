# default-c (2026-10-03) post-install checks, run in the default-swap lab (same harness, host benchmark-F = installed add-on's host).
# Phase R (add-on replay, 900/1080, 20 frames): flags = the INSTALLED Stellar flags file + bench lines; flat-INST = installed gfx1201
#   modules. inst must equal "inst + SKIP_BLOCKS= + FAST_NUMERIC=1" (= group C), differ from "+ SKIP_BLOCKS=42,43,46" and from
#   "+ FAST_NUMERIC=0"; inst on flat-X (junk -fast files) must fail = the -fast modules are opened.
# Phase T (RE9 runtime, rt_bench 1707x961, installed Onimusha modules): old = previous runtime DBAB5E88, new = installed 838A8B97.
#   old/nofile == new/file{42,43,46} (only the default changed); new/installed-oni-flags == new/env FAST=1 no file (default = no skip);
#   new/file{SKIP=,FAST=0} differs; skip= and flags lines printed; runtime-smoke on new.
# Phase A (ABBA, 1 round, 1000 frames): base = release default A, candidate = the SKIP/FAST lines read from the installed Stellar file.
param([string[]]$Phases=@('R','T','A'))
$ErrorActionPreference='Stop';$root='D:\DLSSNR-Lab\hip-backend\default-swap-20261003';$r='D:\DLSSNR-Lab\hip-backend';$L='D:\DLSSNR-Lab\gpu.lock'
$game='C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64';$oni='C:\XboxGames\Onimusha- Way of the Sword\Content';$hip='DLSS5-AMD\native-game-tiled-assets\HIP'
$out="$root\default-c";New-Item -ItemType Directory -Force $out|Out-Null
if(Get-Process|?{$_.ProcessName -match 'Shipping|Stellar|^re9$|^Onimusha|^SandFall|^Magpie|LOP-Win64'}){'GAME RUNNING';exit 1}
if(Test-Path $L){"LOCKED BY $(Get-Content $L)";exit 1}
"default-c $(Get-Date -Format s)"|Out-File -Encoding ascii $L
try{$Phases=@($Phases|%{$_ -split ","}|?{$_})
$inst=@(Get-Content "$game\DLSS5-AMD\native-game-flags.txt");$two=@($inst|?{$_ -match '^DLSS5_(SKIP_BLOCKS|FAST_NUMERIC)='});"installed stellar lines: $($two -join ' | ')"
foreach($n in 'INST','X'){Remove-Item "$root\flat-$n" -Recurse -Force -EA 0;Copy-Item "$game\$hip\gfx1201" "$root\flat-$n" -Recurse}
foreach($m in 'c32-wave1-fast','c64-wave2-fast'){[IO.File]::WriteAllBytes("$root\flat-X\$m.hsaco",[byte[]](1..64))}
if('R' -in $Phases){foreach($h in 900,1080){$hs=@{}
 foreach($run in @(@{n='inst';x=@();s='INST'},@{n='C';x=@('DLSS5_SKIP_BLOCKS=','DLSS5_FAST_NUMERIC=1');s='INST'},@{n='skip3';x=@('DLSS5_SKIP_BLOCKS=42,43,46');s='INST'},@{n='fn0';x=@('DLSS5_FAST_NUMERIC=0');s='INST'},@{n='junkfast';x=@();s='X'})){
  $tag="R-$($run.n)-$h";$flags=$inst+@('DLSS5_HIP_MH_FEATURE_BYTE=1','DLSS5_HIP_MH_PROJ_DIAG_FB=1','DLSS5_HIP_MH_BYTE_STREAM=1','DLSS5_HIP_DECODER_BYTE=1','DLSS5_HIP_VIT_BYTE_STREAM=0','DLSS5_HIP_VIT_STREAM=3','DLSS5_HIP_MH_FFN_FRAG256=1','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_HIP_GRAPH=0','DLSS5_SHOW_FPS=0','DLSS5_PRE_UPSCALE=0',"DLSS5_NETWORK_HEIGHT=$h",'DLSS5_VIT_ADAPTIVE=0','DLSS5_VIT_ADAPTIVE_LOG=','DLSS5_RESIDUAL_SEQUENCE=0','DLSS5_RESIDUAL_RGB=0','DLSS5_HIP_PDL=1','DLSS5_HIP_WAVE_OWNED=1','DLSS5_HIP_C512_M32=1','DLSS5_HIP_VIT_PROJ_N64=1','DLSS5_HIP_SWIN_RUN=1','DLSS5_MAKE_RESIDENT_EVERY=60','DLSS5_VIT_ADAPTIVE_IDLE_MS=1000000000')+$run.x
  [IO.File]::WriteAllLines("$out\$tag-flags.txt",$flags)
  $ErrorActionPreference='Continue';& "$root\benchmark-F.exe" "$root\assets-base" "$out\$tag-flags.txt" "$r\live-menu-before.f16" "$out\$tag" 20 0 "$root\flat-$($run.s)" 0 1 0 0 > "$out\$tag.log" 2> "$out\$tag.err";$ec=$LASTEXITCODE;$ErrorActionPreference='Stop'
  $hs[$run.n]=if(Test-Path "$out\$tag.f16"){(Get-FileHash "$out\$tag.f16").Hash.Substring(0,8)}else{'-'}
  $e=(Get-Content "$out\$tag.err" -EA 0|Select-String 'FAST_NUMERIC|hsaco|rror'|Select-Object -First 1)
  "ROUTE $tag exit=$ec out=$($hs[$run.n]) $e";Remove-Item "$out\$tag*.f16","$out\$tag*.ppm" -Force -EA 0}
 "ROUTE $h inst==C $(if($hs.inst -ne '-' -and $hs.inst -eq $hs.C){'YES'}else{'NO'}) inst!=skip3 $(if($hs.inst -ne $hs.skip3){'YES'}else{'NO'}) inst!=fn0 $(if($hs.inst -ne $hs.fn0){'YES'}else{'NO'}) junkfast-fails $(if($hs.junkfast -eq '-'){'YES'}else{'NO'})"}}
if('T' -in $Phases){$tr="$out\rt";$lab='D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003'
 $sides=[ordered]@{'old-nofile'=@{dll="D:\DLSSNR-Lab\default-c-backups\20261003-082157\LmxxfNrRuntime.dll";file=$null;env=$null}
  'new-skip3'=@{dll="$oni\LmxxfNrRuntime.dll";file=@('DLSS5_SKIP_BLOCKS=42,43,46');env=$null}
  'new-inst'=@{dll="$oni\LmxxfNrRuntime.dll";file=@(Get-Content "$oni\DLSS5-AMD\native-game-flags.txt");env=$null}
  'new-envfast'=@{dll="$oni\LmxxfNrRuntime.dll";file=$null;env='1'}
  'new-fn0'=@{dll="$oni\LmxxfNrRuntime.dll";file=@('DLSS5_SKIP_BLOCKS=','DLSS5_FAST_NUMERIC=0');env=$null}}
 foreach($k in $sides.Keys){$d="$tr\$k";Remove-Item -Recurse -Force $d -EA 0;New-Item -ItemType Directory -Force "$d\modules","$d\shaders"|Out-Null
  foreach($a in 'gfx1200','gfx1201'){Copy-Item "$oni\$hip\$a" "$d\modules\$a" -Recurse};Copy-Item "$oni\$hip\SHA256SUMS" "$d\modules\"
  Copy-Item 'D:\DLSSNR-Lab\hip-backend\fusion-round3\shaders\*' "$d\shaders" -Force;Copy-Item $sides[$k].dll "$d\LmxxfNrRuntime.dll" -Force
  if($sides[$k].file){New-Item -ItemType Directory -Force "$d\DLSS5-AMD"|Out-Null;[IO.File]::WriteAllLines("$d\DLSS5-AMD\native-game-flags.txt",[string[]]$sides[$k].file)}}
 $env:LMXXF_WEIGHTS_DIR='D:\DLSSNR-Lab\zero-copy-io-20260928\assets';$env:DLSS5_HIP_PDL='1';$env:DLSS5_HIP_VIT_STREAM='3';$env:DLSS5_VIT_ADAPTIVE='0';$env:DLSS5_HIP_SWIN_RUN='1'
 Remove-Item Env:\DLSS5_SKIP_BLOCKS,Env:\DLSS5_FAST_NUMERIC -EA 0
 foreach($height in 900,1080){$h=@{};foreach($k in $sides.Keys){$d="$tr\$k";$env:DLSS5_NETWORK_HEIGHT="$height";$env:LMXXF_SHADER_DIR="$d\shaders"
  if($sides[$k].env){$env:DLSS5_FAST_NUMERIC=$sides[$k].env}else{Remove-Item Env:\DLSS5_FAST_NUMERIC -EA 0}
  & 'D:\DLSSNR-Lab\re9-runtime-flags-20260926\in\rt_bench.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" '1707x961' 12 1 *> "$tr\$k-$height.log";if($LASTEXITCODE){throw "rt_bench $k $height"}
  $t=Get-Content "$tr\$k-$height.log" -Raw;$h[$k]=[regex]::Match($t,'hash=([0-9a-f]+)').Groups[1].Value
  "RT $height $k hash=$($h[$k]) mean=$([regex]::Match($t,'mean_ms=([0-9.]+)').Groups[1].Value) $([regex]::Match($t,'skip=\d+').Value) $([regex]::Match($t,'\| flags: [^\r\n]*').Value)"}
  Remove-Item Env:\DLSS5_FAST_NUMERIC -EA 0
  "RT $height old==new-skip3 $(if($h.'old-nofile' -and $h.'old-nofile' -eq $h.'new-skip3'){'YES'}else{'NO'}) inst==envfast $(if($h.'new-inst' -and $h.'new-inst' -eq $h.'new-envfast'){'YES'}else{'NO'}) inst!=fn0 $(if($h.'new-inst' -ne $h.'new-fn0'){'YES'}else{'NO'}) inst!=old $(if($h.'new-inst' -ne $h.'old-nofile'){'YES'}else{'NO'})"}
 $d="$tr\new-inst";$env:LMXXF_SHADER_DIR="$d\shaders"
 & 'D:\DLSSNR-Lab\re9-presr\runtime-smoke.exe' "$d\LmxxfNrRuntime.dll" "$d\modules" *> "$tr\smoke.log";"SMOKE exit=$LASTEXITCODE";Get-Content "$tr\smoke.log" -Tail 3}
if('A' -in $Phases){$env:SP_CHANNELS='4';$env:SP_SIDES='3';$env:SP_FORCE_TIMEOUT='0';$env:SP_VALIDATE='0';$env:SP_TRACE='0';$env:SP_TICKET_LIMIT='4294967295';$env:SP_TICKET_START='0'
 Get-ChildItem $root -Directory -Filter 'runtime-regression-INST-*'|Remove-Item -Recurse -Force
 & "$root\regression.ps1" -Set INST -BenchName benchmark-F.exe -Base I -CandidateBenchName benchmark-F.exe -CandidateExtra $two -TimingOnly -TimingFrames 1000 -Batch timing-1 *> "$out\timing-INST.log"
 if($LASTEXITCODE -or (Select-String -Path "$out\timing-INST.log" -Pattern 'Exception|failed|throw' -Quiet)){'TIMING FAIL';Get-Content "$out\timing-INST.log" -Tail 5}
 & "$root\summarize.ps1" -Sets INST|Tee-Object "$out\abba-INST.txt"}
} catch {"VERIFY FAIL $_"} finally {Get-ChildItem $root -Recurse -Include *.f16,*.ppm -EA 0|?{$_.FullName -match 'runtime-regression|default-c'}|Remove-Item -Force -EA 0
 if((Test-Path $L) -and ((Get-Content $L) -match 'default-c')){Remove-Item $L -Force};'LOCK DROPPED'}
'VERIFY_DONE'
