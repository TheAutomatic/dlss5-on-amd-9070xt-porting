# Sweep 2 (2026-10-02): on top of the recipe with -RowOpts (c32 no-post-RA+max-ilp, c512-m32-deep max-ilp), every dispatched module x option set.
param([string]$Modules='c32-wave1,c64-wave2,swin-persistent,c512-m32-mh,c512-m32-deep,vit-stream,multihead-fast-padded-wave-packed,deep_fast-packed,vit-wide-deep',[string]$Only='')
$ErrorActionPreference='Continue';$root='D:\DLSSNR-Lab\hip-backend\compiler-sweep-20261001'
$np='-mllvm=-enable-post-misched=0'
$sets=[ordered]@{ 'r'=''; 'np'=$np; 'npilp'="$np -mllvm=-amdgpu-sched-strategy=max-ilp"; 'npitilp'="$np -mllvm=-amdgpu-sched-strategy=iterative-ilp"
 'delay0'='-mllvm=-amdgpu-enable-delay-alu=0'; 'vopd0'='-mllvm=-amdgpu-enable-vopd=0'; 'mspostra'='-mllvm=-misched-postra'
 'igexact'='-mllvm=-amdgpu-igrouplp-exact-solver'; 'noprera'='-mllvm=-amdgpu-enable-pre-ra-optimizations=0'; 'nopartial'='-mllvm=-amdgpu-enable-rewrite-partial-reg-uses=0' }
foreach($k in $sets.Keys){ if($Only -and $k -notin ($Only -split ',')){continue}
 foreach($m in ($Modules -split ',')){$name="s2$k-$m";$t0=Get-Date
  try{& "$root\sb.ps1" -Name $name -Module $m -Opts $sets[$k] -Both|Out-Null;"OK $name $([int]((Get-Date)-$t0).TotalSeconds)s $((Get-FileHash "$root\build-$name\gfx1201\$m.hsaco").Hash.Substring(0,8))"}catch{"FAIL $name $($_.Exception.Message)"}}}
'SWEEP_DONE'
