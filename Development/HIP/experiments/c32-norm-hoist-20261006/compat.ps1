param([ValidateSet('Full','Remaining')][string]$Phase='Full')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\c32-norm-hoist-compat-20261006';$base='D:\DLSSNR-Lab\history-trial-041a-20261006';$games='Shipping|SB-Win64|Onimusha|^re9$|Magpie|SandFall|Wuthering|Client-Win64|Genshin|YuanShen'
function Idle{& D:\DLSSNR-Lab\game-check.ps1 'SB-Win64 Onimusha re9.exe SandFall Magpie';if($LASTEXITCODE -ne 1){throw 'game busy/failure'};if(Get-Process|?{$_.ProcessName -match $games -or $_.ProcessName -eq 'rtc_compile'}){throw 'game/RTC running'}}
function One($tag,$height,$sequence,$temporal,$adaptive,$side,$roll=0,$seed=0,$fast=1,$mp=1){
 Idle;$dir="$r\out\$tag-$side";if(Test-Path $dir){throw 'No overwrite measured gate'};New-Item -ItemType Directory $dir|Out-Null
 $flags=@(Get-Content "$r\base.flags")+@("DLSS5_NETWORK_HEIGHT=$height",'DLSS5_NETWORK_1080_ROWS=1152','DLSS5_DIRECT_IO=3','DLSS5_BENCH_PLAIN=1','DLSS5_NET_TIMING=0','DLSS5_HIP_INPUT_POLL=0','DLSS5_HIP_SPAN_PROBE=0','DLSS5_GAME_PROBE=0','DLSS5_BLACK_PROBE=0',"DLSS5_FAST_NUMERIC=$fast","DLSS5_MULTI_PASS=$mp",'DLSS5_MULTI_PASS_PREDICT=0','DLSS5_MULTI_PASS_SKIN_PROTECT=0','DLSS5_TEMPORAL_HISTORY_EXPERIMENT=0','DLSS5_SKIP_BLOCKS=',"DLSS5_VIT_ADAPTIVE=$adaptive","DLSS5_VIT_ADAPTIVE_LOG=$dir\adaptive.csv","DLSS5_RESIDUAL_SEQUENCE=$sequence",'DLSS5_RESIDUAL_RGB=1')
 [IO.File]::WriteAllLines("$dir\flags.txt",$flags)
 $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=if($roll){"$r\benchmark-roll.exe"}else{"$r\benchmark.exe"};$psi.Arguments="$base\assets $dir\flags.txt D:\DLSSNR-Lab\hip-backend\live-menu-before.f16 $dir\rgb 12 $temporal $r\modules-$side 0 0 $seed 0";$psi.WorkingDirectory=$r;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 foreach($key in @($psi.EnvironmentVariables.Keys)){if($key.StartsWith('DLSS5_') -or $key.StartsWith('NR_') -or $key.StartsWith('SP_')){$psi.EnvironmentVariables.Remove($key)}}
 foreach($key in 'TEMP','TMP','HIP_CACHE_DIR'){$psi.EnvironmentVariables[$key]="$r\cache"}
 $psi.EnvironmentVariables['SP_CHANNELS']='4';$psi.EnvironmentVariables['SP_SIDES']='3';$psi.EnvironmentVariables['SP_FORCE_TIMEOUT']='0';$psi.EnvironmentVariables['SP_VALIDATE']="$roll";$psi.EnvironmentVariables['SP_TRACE']="$roll";$psi.EnvironmentVariables['SP_TICKET_LIMIT']=if($roll){'1024'}else{'4294967295'};$psi.EnvironmentVariables['SP_TICKET_START']=if($roll){'4294967290'}else{'0'}
 $p=[Diagnostics.Process]::new();$p.StartInfo=$psi;$p.Start()|Out-Null;$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync();$start=[DateTime]::UtcNow;$next=$start.AddSeconds(15)
 while(!$p.HasExited){Start-Sleep -Milliseconds 100;if([DateTime]::UtcNow -ge $next){if(Get-Process|?{$_.ProcessName -match $games}){$p.Kill();throw 'game started own corrector stopped'};$next=[DateTime]::UtcNow.AddSeconds(15)};if(([DateTime]::UtcNow-$start).TotalSeconds -gt 90){$p.Kill();throw 'own gate timeout'}}
 $p.WaitForExit();$o.Result|Set-Content "$dir\stdout.log";$e.Result|Set-Content "$dir\stderr.log";if($p.ExitCode){throw "gate failed $tag-$side exit$($p.ExitCode)"}
 $rows=@(Import-Csv "$dir\rgb.csv");if($rows.Count -ne 12 -or @($rows|?{[int]$_.invalid -ne 0 -or $_.checked -ne '1'}).Count){throw 'nonfinite/missing frame'}
 $log=$e.Result;if($side -eq 'H' -and $height -eq 900 -and $fast -eq 1 -and $mp -eq 1){if($log -notmatch 'c32_norm900 scope=1 loaded=1 selected=c32-wave1-fast-norm900.hsaco'){throw 'H not actually selected'}}else{if($log -match 'selected=c32-wave1-fast-norm900.hsaco' -and $side -ne 'G'){throw 'H selected outside requested scope'}}
 if($side -eq 'B' -and $log -notmatch 'load_status=0 missing_export=c32_wave1_post_b8_features'){throw 'valid missing-export fallback not proved'}
 if($roll -and $o.Result -notmatch 'rollover=[1-9]'){throw 'rollover not executed'}
 "CASE $tag-$side finite12 actualroute_checked=1"
}
function Same($tag,$side='H'){
 $a="$r\out\$tag-A";$h="$r\out\$tag-$side";$files=@(Get-ChildItem $a -Filter '*frame-*.f16');if($files.Count -ne 12){throw 'missing12 rawframes'}
 foreach($f in $files){if((Get-FileHash $f.FullName -Algorithm SHA256).Hash -ne (Get-FileHash "$h\$($f.Name)" -Algorithm SHA256).Hash){throw "raw difference $tag/$side"}}
 "SAME $tag $side frames12"
}
Idle;if([IO.DriveInfo]::new('D:\').AvailableFreeSpace -lt 100GB){throw 'D free<100GB'};New-Item -ItemType Directory -Force "$r\out","$r\cache"|Out-Null
foreach($pair in @(@("D:\DLSSNR-Lab\c32-norm-hoist-20261006\expected-assets.json","$base\assets"),@("D:\DLSSNR-Lab\c32-norm-hoist-20261006\expected-modules.json","$base\modules\gfx1201"))){foreach($item in (Get-Content $pair[0] -Raw|ConvertFrom-Json)){$path=Join-Path $pair[1] $item.name;if((Get-Item $path).Length -ne $item.bytes -or (Get-FileHash $path -Algorithm SHA256).Hash -ne $item.sha256){throw "stock changed $path"}}}
if((Get-FileHash "$r\H.hsaco" -Algorithm SHA256).Hash -ne '6E3E51BBC21595C5132F42A78B9667C528B53410C61EF5515B0B31D2664DE7F4'){throw 'candidate different from testedH'}
if((Get-Item 'D:\DLSSNR-Lab\hip-backend\live-menu-before.f16').Length -ne 7464960){throw 'HDR footprint'}
foreach($side in 'A','H','M','G','B'){New-Item -ItemType Directory -Force "$r\modules-$side"|Out-Null;Copy-Item "$base\modules\gfx1201\*.hsaco" "$r\modules-$side" -Force}
Copy-Item "$r\H.hsaco" "$r\modules-H\c32-wave1-fast-norm900.hsaco" -Force
Copy-Item "$base\modules\gfx1201\c32-wave1-fast.hsaco" "$r\modules-G\c32-wave1-fast-norm900.hsaco" -Force
Copy-Item "$base\modules\gfx1201\c32-wave1.hsaco" "$r\modules-B\c32-wave1-fast-norm900.hsaco" -Force
$owner=[IO.File]::Open('D:\DLSSNR-Lab\gpu.lock',[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 $cases=@(@{n='900-static';h=900;s=0;t=0},@{n='900-motion';h=900;s=1;t=0},@{n='1080-static';h=1080;s=0;t=0},@{n='1080-motion';h=1080;s=1;t=0},@{n='720-motion';h=720;s=1;t=0},@{n='900-history';h=900;s=5;t=1},@{n='1080-history';h=1080;s=5;t=1})
 if($Phase -eq 'Full'){foreach($ae in 0,1){foreach($case in $cases){$tag="$($case.n)-AE$ae";foreach($side in 'A','H'){One $tag $case.h $case.s $case.t $ae $side};Same $tag;if($ae){$a="$r\out\$tag-A\adaptive.csv";$h="$r\out\$tag-H\adaptive.csv";if((Get-Content $a -Raw) -cne (Get-Content $h -Raw)){throw 'adaptive decisions changed'}}}}
 'AE CSV SAME aggregate'
 }
 foreach($ae in 0,1){foreach($h in 900,1080){$tag="roll-actual-$h-AE$ae";foreach($side in 'A','H'){One $tag $h 5 1 $ae $side 1};Same $tag}}
 foreach($seed in 37,65535){$tag="seed-$seed";foreach($side in 'A','H'){One $tag 900 1 0 0 $side 0 $seed};Same $tag}
 foreach($side in 'M','G','B'){One "fallback-$side" 900 0 0 0 'A';One "fallback-$side" 900 0 0 0 $side;Same "fallback-$side" $side}
 foreach($mp in 2,3){$tag="MP$mp-fallback";foreach($side in 'A','H'){One $tag 900 0 0 0 $side 0 0 1 $mp};Same $tag}
 foreach($h in 900,1080){$tag="FAST0-$h";foreach($side in 'A','H'){One $tag $h 0 0 0 $side 0 0 0 1};Same $tag}
 'COMPAT19_AND_SCOPE_DONE no_performance_claim=1'
}finally{$owner.Dispose();Remove-Item 'D:\DLSSNR-Lab\gpu.lock' -Force;'LOCK_RELEASED'}
