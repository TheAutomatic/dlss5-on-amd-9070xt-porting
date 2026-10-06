#!/usr/bin/env python3
from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
root=Path(__file__).resolve().parents[4]
s=(root/'Development/HIP/experiments/kernel-map/regression.ps1').read_text()
old="if(@(Get-ChildItem $mods -Filter '*.hsaco').Count -ne 30)";assert s.count(old)==1
s=s.replace(old,"if(@(Get-ChildItem $mods -Filter '*.hsaco').Count -ne $(if($candidate -and !$SameSet){31}else{30}))")
s=s.replace('^microbench|^runtime-smoke','^microbench|^runtime-smoke|^jobbench|^recorder')
(a.out/'regression.ps1').write_text(s)
