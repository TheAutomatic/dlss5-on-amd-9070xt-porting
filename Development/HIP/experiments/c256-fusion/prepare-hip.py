#!/usr/bin/env python3
"""Stage the pre-experiment recipe and all candidate macros reproducibly."""
from pathlib import Path
import subprocess,sys
root=Path(__file__).resolve().parents[4];out=Path(sys.argv[1]).resolve();revision='4f0a62f7'
for name in subprocess.check_output(['git','ls-tree','-r','--name-only',revision,'hip'],cwd=root,text=True).splitlines():
 p=out/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(subprocess.check_output(['git','show',revision+':'+name],cwd=root))
subprocess.run([sys.executable,str(Path(__file__).with_name('make-candidate.py')),'--source',str(out/'hip/wave_owned_mh.inc'),'--output',str(out/'hip/wave_owned_mh.inc')],check=True)
