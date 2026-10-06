"""Isolated 0.41-a modules from current canonical recipe; original rows untouched."""
import argparse, hashlib, importlib.util, json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4]
spec=importlib.util.spec_from_file_location('recipe',r/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
rows={x[0]:x for x in m.recipe(r/'hip')};manifest={}
for name in ('c32-wave1','c32-wave1-fast'):
 row=rows[name];new=name.replace('c32-wave1','c32-wave1-temporal');path=a.output/(new+'.hip');path.write_text(row[2]);manifest[new]={'from':name,'compiler':row[1],'opts':row[5],'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
source=(r/'Development/HIP/experiments/temporal-sequence-20261005/warp.hip').read_text()+'\n'+(r/'Development/HIP/experiments/post-history-gate/gate_helpers.hip').read_text()
(a.output/'temporal-history.hip').write_text(source);manifest['temporal-history']={'compiler':'comgr','opts':'-ffp-contract=off','sha256':hashlib.sha256(source.encode()).hexdigest()}
(a.output/'source.json').write_text(json.dumps(manifest,indent=2)+'\n')
