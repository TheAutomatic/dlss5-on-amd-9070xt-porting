#!/usr/bin/env python3
"""Stage current host with a compile-time-only C256 fusion route (default 0)."""
from pathlib import Path
import subprocess,sys
root=Path(__file__).resolve().parents[4];out=Path(sys.argv[1]).resolve();revision='4f0a62f7'
names=subprocess.check_output(['git','ls-tree','-r','--name-only',revision,'src','Development/HIP'],cwd=root,text=True).splitlines()
for name in names:
 if not (name.startswith('src/') or (name.startswith('Development/HIP/') and name.count('/')==2 and (name.endswith('.h') or name.endswith('/benchmark_vit_reuse.cpp')))):continue
 p=out/name;p.parent.mkdir(parents=True,exist_ok=True)
 p.write_bytes(subprocess.check_output(['git','show',revision+':'+name],cwd=root))
p=out/'Development/HIP/hip_reference_network.h';s=p.read_text();a='if(wave_owned_active&&(c==64||c==128))';assert s.count(a)==1
s='#ifndef C256_WHOLE_BLOCK\n#define C256_WHOLE_BLOCK 0\n#endif\n'+s.replace(a,'if(wave_owned_active&&(c==64||c==128||(C256_WHOLE_BLOCK&&c==256&&(C256_WHOLE_BLOCK==1||(opt.width==1920&&opt.height==1152)))))');a='  void*reuse_gate_arg=adaptive_active?';assert s.count(a)==1
s=s.replace(a,'#ifdef C256_TRACE\n  std::printf("TOPO,%s,%s,%u,%u\\n",module.c_str(),kernel.c_str(),unsigned(groups?groups:(count+255ull)/256),threads);\n#endif\n'+a)
p.write_text(s)
