"""Canonical LLVM23 post tap source; compile with the original row compiler/opts."""
from pathlib import Path
import argparse,importlib.util,json,hashlib
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--row',default='c32-wave1-fast',choices=['c32-wave1','c32-wave1-rtz','c32-wave1-fast']);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4];sp=importlib.util.spec_from_file_location('recipe',r/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m)
name,compiler,source,defs,sources,opts=next(x for x in m.recipe(r/'hip')if x[0]==a.row)
assert compiler=='llvm23'  # C32 keeps its existing bare-barrier recipe; do not add the C64 fence override.
(a.output/'tap.generated.hip').write_text(source)
(a.output/'tap-source.json').write_text(json.dumps({'row':name,'compiler':compiler,'defines':defs,'sources':sources,'opts':opts,'source_sha256':hashlib.sha256(source.encode()).hexdigest(),'new_export':'c32_wave1_post_b8_features','buffer':'HWC32 f16 processing geometry; diagnostic only','validated_GPU':False},indent=2)+'\n')
