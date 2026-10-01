# Static sweep: build each hot module under each option set (gfx1201 only). Output: build-<opt>-<module>\gfx1201\<module>.hsaco, log line per build.
param([string]$Modules='c64-wave2,swin-persistent,c32-wave1,c512-m32-mh,c512-m32-deep,vit-stream,multihead-fast-padded-wave-packed,deep_fast-packed',[string]$Only='')
$ErrorActionPreference='Continue';$root='D:\DLSSNR-Lab\hip-backend\compiler-sweep-20261001'
$sets=[ordered]@{
 'ilp'='-mllvm=-amdgpu-sched-strategy=max-ilp'; 'mclause'='-mllvm=-amdgpu-sched-strategy=max-memory-clause'
 'itilp'='-mllvm=-amdgpu-sched-strategy=iterative-ilp'; 'itminreg'='-mllvm=-amdgpu-sched-strategy=iterative-minreg'; 'itmaxocc'='-mllvm=-amdgpu-sched-strategy=iterative-maxocc'
 'bias100'='-mllvm=-amdgpu-schedule-metric-bias=100'; 'bias0'='-mllvm=-amdgpu-schedule-metric-bias=0'; 'relaxocc'='-mllvm=-amdgpu-schedule-relaxed-occupancy'
 'nohirp'='-mllvm=-amdgpu-disable-unclustered-high-rp-reschedule'; 'nolowocc'='-mllvm=-amdgpu-disable-clustered-low-occupancy-reschedule'
 'trackers'='-mllvm=-amdgpu-use-amdgpu-trackers'; 'clause31'='-mllvm=-amdgpu-max-memory-clause=31'; 'clause4'='-mllvm=-amdgpu-max-memory-clause=4'
 'nocluster'='-mllvm=-misched-cluster=0'; 'topdown'='-mllvm=-misched-prera-direction=topdown'; 'bottomup'='-mllvm=-misched-prera-direction=bottomup'
 'nopostra'='-mllvm=-enable-post-misched=0'; 'postbidir'='-mllvm=-misched-postra-direction=bidirectional'; 'wavepri'='-mllvm=-amdgpu-set-wave-priority'
 'unroll600'='-mllvm=-unroll-threshold=600'; 'unroll1200'='-mllvm=-unroll-threshold=1200 -mllvm=-unroll-allow-partial'; 'nounrollpart'='-mllvm=-amdgpu-unroll-threshold-private=0'
 'wpe1'='W1';'wpe2'='W2';'wpe4'='W4';'wpe6'='W6';'wpe8'='W8'
}
foreach($k in $sets.Keys){ if($Only -and $k -notin ($Only -split ',')){continue}
 foreach($m in ($Modules -split ',')){
  $v=$sets[$k];$name="$k-$m";$t0=Get-Date
  try{ if($v -like 'W*'){& "$root\sb.ps1" -Name $name -Module $m -Wpe ([int]$v.Substring(1))|Out-Null}else{& "$root\sb.ps1" -Name $name -Module $m -Opts $v|Out-Null}
   "OK $name $([int]((Get-Date)-$t0).TotalSeconds)s $((Get-FileHash "$root\build-$name\gfx1201\$m.hsaco").Hash.Substring(0,8))"}
  catch{"FAIL $name $($_.Exception.Message)"}
 }}
'SWEEP_DONE'
