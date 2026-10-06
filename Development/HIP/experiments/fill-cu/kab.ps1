# Kernel-level A/B: original export vs split variants on the same job (synthetic fixture); prints output hashes and median us.
param([string]$Jobs='o900-023:split_mix_blocked_h16w_m32:c512-m32-deep,o1080-021:split_mix_blocked_h16w_m32:c512-m32-deep,o900-027:mh_attention_project_frag_c512:multihead-fast-padded-wave-packed,o1080-025:mh_attention_project_frag_c512:multihead-fast-padded-wave-packed',[string]$Cand='n2',[int]$Rounds=3,[string]$Vars='')
$ErrorActionPreference='Stop';$r='D:\DLSSNR-Lab\hip-backend\fill-cu-20260930';$d="$r\kab";New-Item -ItemType Directory -Force $d|Out-Null
if(!$Vars){$Vars="orig,$($Cand):_n2:64:1,$($Cand)g:_n2g:32:2"}
function Run($id,$sym,$mod,$bx,$gm,$tag){
 if(Get-Process|?{$_.ProcessName -match 'Shipping|^re9$|^Onimusha|^SandFall|^benchmark|^Magpie'}){throw 'GPU busy'}
 foreach($n in 'JB_SYMBOL','JB_MODULE','JB_BLOCKX','JB_GRIDMUL','JB_GRIDX'){Remove-Item "Env:$n" -EA 0}
 if($sym){$env:JB_SYMBOL=$sym;$env:JB_MODULE=$mod;$env:JB_BLOCKX=$bx;$env:JB_GRIDMUL=$gm}
 $p=Start-Process "$r\jobbench-grid.exe" -ArgumentList @("$r\jobs\$id.bin",$r,'128','7') -NoNewWindow -PassThru -RedirectStandardOutput "$d\$id-$tag.log" -RedirectStandardError "$d\$id-$tag.err"
 if(!$p.WaitForExit(60000)){$p.Kill();throw "Timeout"};$p.WaitForExit()
 $L=Get-Content "$d\$id-$tag.log";$res=($L|?{$_ -like 'RESULT,*'}) -split ',';$h=(($L|?{$_ -like 'HASH,*'})|%{($_ -split ',')[2]}) -join '/'
 if(!$res){"$id,$tag,FAIL,$(Get-Content "$d\$id-$tag.err")"}else{"$id,$tag,$($res[2]),$h"}}
foreach($round in 1..$Rounds){foreach($j in $Jobs.Split(',')){$id,$sym,$m=$j.Split(':')
 foreach($v in $Vars.Split(',')){ if($v -eq 'orig'){Run $id $null $null 0 1 "orig$round"}else{$c,$suf,$bx,$gm=$v.Split(':');Run $id "$sym$suf" "cand-$($c -replace 'g$','')/$m.hsaco" $bx $gm "$c$round"}}}}
'KAB_DONE'
