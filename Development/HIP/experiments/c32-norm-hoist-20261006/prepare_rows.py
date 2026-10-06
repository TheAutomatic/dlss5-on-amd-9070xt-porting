"""Isolated canonical normal/rtz/fast rows, no recipe mutation."""
from pathlib import Path
import argparse,importlib.util,subprocess
p=argparse.ArgumentParser();p.add_argument('out',type=Path);p.add_argument('--stock-shape',action='store_true',help='Remove optional post-feature export absent in staged normal/RTZ only.');a=p.parse_args();a.out.mkdir(exist_ok=True,parents=True);repo=Path(__file__).resolve().parents[4];spec=importlib.util.spec_from_file_location('canon',repo/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
for name,compiler,s,*args in m.recipe(repo/'hip'):
 if name not in ['c32-wave1','c32-wave1-rtz','c32-wave1-fast']:continue
 stem={'c32-wave1':'N','c32-wave1-rtz':'R','c32-wave1-fast':'F'}[name]
 if a.stock_shape and stem!='F':s='\n'.join(l for l in s.splitlines() if not l.startswith('CW_ENTRY void c32_wave1_post_b8_features('))+'\n'
 base=a.out/(stem+'-base.hip');base.write_text(s)
 for mode in [0,1]:subprocess.run(['python3',str(Path(__file__).with_name('prepare.py')),str(base),str(a.out/(stem+str(mode)+'.hip')),*(['--enable'] if mode else [])],check=True)
