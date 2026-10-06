from pathlib import Path
import importlib.util,argparse,json,hashlib
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4]
spec=importlib.util.spec_from_file_location('recipe',r/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
row=next(x for x in m.recipe(r/'hip') if x[0]=='swin-persistent-fast');name,compiler,source,defs,sources,opts=row
(a.output/'sp-fast.generated.hip').write_text(source)
(a.output/'source.json').write_text(json.dumps({'row':name,'compiler':compiler,'defines':defs,'sources':sources,'opts':opts,'sha256':hashlib.sha256(source.encode()).hexdigest()},indent=2)+'\n')
