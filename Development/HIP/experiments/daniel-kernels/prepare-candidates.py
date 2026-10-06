#!/usr/bin/env python3
from pathlib import Path
import shutil,subprocess,sys
here=Path(__file__).resolve().parent;repo=here.parents[3];out=Path(sys.argv[1]).resolve()
if out==repo:raise SystemExit('Use an isolated staging directory')
shutil.copytree(repo/'hip',out/'hip',dirs_exist_ok=True)
for name in ('W2_PACK_NOZERO.patch','CW_WEIGHT_CACHE.patch'):
 subprocess.run(['patch','-s','-p1','--forward','-d',str(out)],input=(here/name).read_bytes(),check=True)
