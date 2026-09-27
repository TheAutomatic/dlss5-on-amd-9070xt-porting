# pack8: E4M3 fragments packed two values per v_cvt_pk_fp8_f32 (W2_PACK8 generalised). Full 29-module sets through the
# production recipe (hip/build-modules.ps1 -ExtraDefines). A = defaults (code sections must equal the installed 0.32 set),
# CW = C32 wave (c32-wave1), W2 = wave-owned MH, DF = deep_fast/vit-wide/c512-m32-deep, MF = multihead_fast_padded
# (reverted: its sites are in disabled branches, no production module changed), ALL = CW + W2 (DF bit-exact but no gain).
param([string[]]$Sets=@('A','CW','W2','DF','MF','ALL'),[string[]]$Targets=@('gfx1201'))
$ErrorActionPreference='Stop';$d=Split-Path -Parent $MyInvocation.MyCommand.Path
$rtc='D:\DLSSNR-Lab\dual-arch-src\rtc_compile.exe'
$map=@{A=@();CW=@('CW_PACK8 1');W2=@('W2_PACK8 1');DF=@('DF_PACK8 1');ALL=@('CW_PACK8 1','W2_PACK8 1');Z=@('CW_PACK8 1','W2_PACK8 2');N=@('CW_PACK8 1','W2_PACK8 2','HIP_FP8_SAT_MODE 3');M=@('CW_PACK8 1','W2_PACK8 3','HIP_FP8_SAT_MODE 3','HIP_FMED3_CLAMP 1');O=@('CW_PACK8 1','W2_PACK8 4','HIP_FP8_SAT_MODE 3','HIP_FMED3_CLAMP 1');CNF=@('W2_PACK8 5','W2_CENSUS_T 0');C448=@('W2_PACK8 5','W2_CENSUS_T 448');C4K=@('W2_PACK8 5','W2_CENSUS_T 4096');C64K=@('W2_PACK8 5','W2_CENSUS_T 65504');C1=@('W2_PACK8 5','W2_CENSUS_T 1');P=@('W2_PACK8 4')}
foreach($s in $Sets){
 $out="$d\modules-$s";$t=Measure-Command{& "$d\hip\build-modules.ps1" -Compiler $rtc -SourceDir "$d\hip" -OutputDir $out -Targets $Targets -ExtraDefines $(if($map[$s].Count){$map[$s]}else{@("PACK8_NONE 1")})|Out-Null}
 "set $s built in $([int]$t.TotalSeconds)s -> $out"
}
