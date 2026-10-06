#!/usr/bin/env python3
from pathlib import Path
import subprocess,sys
root=Path(__file__).resolve().parents[4];here=Path(__file__).resolve().parent;out=Path(sys.argv[1]).resolve();rev='8c9a61db'
for name in subprocess.check_output(['git','ls-tree','-r','--name-only',rev,'hip'],cwd=root,text=True).splitlines():
 p=out/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(subprocess.check_output(['git','show',rev+':'+name],cwd=root))
subprocess.run(['patch','-s','-p1','-d',str(out)],input=(here/'ffn-kernel.patch').read_bytes(),check=True)
subprocess.run([sys.executable,str(here/'make-small-batch.py'),'--source',str(out/'hip/wave_owned_mh.inc'),'--output',str(out/'hip/wave_owned_mh.inc')],check=True)
for name,extra in [('wave_owned_mh.inc','c256_wave16.inc'),('c512_m32_mh.inc','c512_qkv_attention_fused.inc')]:
 p=out/'hip'/name;p.write_text(p.read_text()+'\n'+(here/extra).read_text())
