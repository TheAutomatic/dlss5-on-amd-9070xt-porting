from pathlib import Path
import importlib.util,argparse,json,hashlib
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4];sp=importlib.util.spec_from_file_location('recipe',r/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m)
row=next(x for x in m.recipe(r/'hip') if x[0]=='vit-stream-fast');name,compiler,source,defs,files,opts=row
s='#define VIT_CONTRACT_T32_W2 1\n'+source[:-1]+Path(__file__).with_name('candidate.inc').read_text()+'\n';(a.output/'candidate.hip').write_text(s)
(a.output/'source.json').write_text(json.dumps({'row':name,'compiler':compiler,'defines':['VIT_CONTRACT_T32_W2 1']+defs,'opts':opts,'sha256':hashlib.sha256(s.encode()).hexdigest(),'mathematics':'same skip + four K1024 partials; staging only, token waves independent'},indent=2)+'\n')
