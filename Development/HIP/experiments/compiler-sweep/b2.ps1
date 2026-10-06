$R='D:\DLSSNR-Lab\hip-backend\compiler-sweep-20261001'
$np='-mllvm=-enable-post-misched=0'
& "$R\sb.ps1" -Name npilp-c32-wave1 -Module c32-wave1 -Opts "$np -mllvm=-amdgpu-sched-strategy=max-ilp"
& "$R\sb.ps1" -Name npitilp-c32-wave1 -Module c32-wave1 -Opts "$np -mllvm=-amdgpu-sched-strategy=iterative-ilp"
& "$R\sb.ps1" -Name npitilp-c64-wave2 -Module c64-wave2 -Opts "$np -mllvm=-amdgpu-sched-strategy=iterative-ilp"
& "$R\sb.ps1" -Name npilp-c512-m32-deep -Module c512-m32-deep -Opts "$np -mllvm=-amdgpu-sched-strategy=max-ilp"
& "$R\sb.ps1" -Name nopostra-deep_fast-packed -Module deep_fast-packed -Opts $np
