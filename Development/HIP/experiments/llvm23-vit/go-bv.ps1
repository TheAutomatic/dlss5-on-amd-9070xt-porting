# llvm23-vit (10-02): run go-cv.ps1 (19 groups, one module swapped into flat-A) for each variant dir under compiler-sweep-20261001\<V>.
# -Vs entries are V or V@mod1+mod2 (default modules: vit-stream, mh_fast).
param([string]$Vs='',[string]$Mods='vit-stream,multihead-fast-padded-wave-packed')
foreach($e in $Vs -split ','){ $v,$m=$e -split '@'; if(-not $m){$m=$Mods}else{$m=$m -replace '\+',','}; & "$PSScriptRoot\go-cv.ps1" -V $v -Mods $m }
'BV_DONE'
