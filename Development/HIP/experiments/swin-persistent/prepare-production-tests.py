#!/usr/bin/env python3
from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
root=Path(__file__).resolve().parents[4]
s=(root/'Development/HIP/experiments/kernel-map/regression.ps1').read_text()
s=s.replace("param([string]$Set='P'","param([int]$SwinRun=1,[string]$Set='Q'")
s=s.replace("if(@(Get-ChildItem $mods -Filter '*.hsaco').Count -ne 30)","if(@(Get-ChildItem $mods -Filter '*.hsaco').Count -ne $(if($candidate -and !$SameSet){31}else{30}))")
s=s.replace(' [IO.File]::WriteAllLines("$dir\\flags.txt",$flags)',' $flags += "DLSS5_HIP_SWIN_RUN=$(if($candidate){$SwinRun}else{0})"\n [IO.File]::WriteAllLines("$dir\\flags.txt",$flags)')
s=s.replace('^microbench|^runtime-smoke','^microbench|^runtime-smoke|^jobbench|^recorder')
(a.out/'regression-production.ps1').write_text(s)
