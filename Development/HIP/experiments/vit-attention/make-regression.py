#!/usr/bin/env python3
import argparse,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4]
s=subprocess.check_output(['git','show','629b0555:Development/HIP/experiments/kernel-map/regression.ps1'],cwd=r,text=True)
s=s.replace('Count -ne 30)','Count -ne 31)').replace('^microbench|^runtime-smoke','^microbench|^runtime-smoke|^jobbench|^Magpie')
s=s.replace(' [IO.File]::WriteAllLines("$dir\\flags.txt",$flags)',' $flags += @(\'DLSS5_HIP_SWIN_RUN=1\',\'DLSS5_MAKE_RESIDENT_EVERY=60\')\n [IO.File]::WriteAllLines("$dir\\flags.txt",$flags)')
(a.out/'regression.ps1').write_text(s)
