#!/usr/bin/env python3
"""Generate isolated host and HIP candidates from the current canonical math."""
from pathlib import Path
import argparse,importlib.util,json,hashlib,shutil,subprocess
p=argparse.ArgumentParser(__doc__);p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
here=Path(__file__).resolve().parent;root=here.parents[3];revision='70533d96'
def original(name):return subprocess.check_output(['git','show',revision+':'+name],cwd=root)
spec=importlib.util.spec_from_file_location('recipe',root/'Development/tools/llvm-fork/compile-modules.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
recipe=next(r for r in module.recipe(root/'hip') if r[0]=='c64-wave2')
defs=recipe[2]
core=original('hip/wave_owned_mh.inc').decode().split('#define W2_KERNEL')[0]
old='uint post,const float*upw=nullptr,const float*skip=nullptr){';assert core.count(old)==1
core=core.replace(old,'uint post,uint supplied_win,const float*upw=nullptr,const float*skip=nullptr){')
core=core.replace('DEV void swin_wave2_body(','DEV void sp_swin_body(')
old='const uint win=__builtin_amdgcn_workgroup_id_x(),head=';assert core.count(old)==1
core=core.replace(old,'const uint win=supplied_win,head=')
text=''.join('#define '+d+'\n' for d in defs)+(root/'hip/multihead_fast_padded.hip').read_text()+'\n'+core+'\n'+(here/'sp_types.h').read_text()+'\n'+(here/'persistent.hip').read_text()
(a.out/'swin-persistent.hip').write_text(text)
names=subprocess.check_output(['git','ls-tree','-r','--name-only',revision,'src','Development/HIP'],cwd=root,text=True).splitlines()
stage=a.out/'runner'
for name in names:
    if name.startswith('src/') or (name.startswith('Development/HIP/') and name.count('/')==2 and (name.endswith('.h') or name.endswith('/benchmark_vit_reuse.cpp'))):
        dest=stage/name;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(original(name))
hip=stage/'Development/HIP';shutil.copy2(here/'sp_types.h',hip/'sp_types.h')
h=hip/'hip_reference_network.h';s=h.read_text()
s='#ifndef HIP_SWIN_PERSISTENT\n#define HIP_SWIN_PERSISTENT 0\n#endif\n'+s
anchor=' Tensor Body(Tensor input,';assert s.count(anchor)==1
s=s.replace(anchor,'#if HIP_SWIN_PERSISTENT\n'+(here/'host.inc').read_text()+'\n#endif\n'+anchor)
old='~Network(){api.hipStreamSynchronize(stream);';assert s.count(old)==1
s=s.replace(old,old+'\n#if HIP_SWIN_PERSISTENT\nSpReport();\n#endif\n')
old='for(U j=0;j<counts[g];j++)source=Body(source,w,h,channels[g],shifts[j],starts[g]+j,j+1==counts[g],opt.mh_byte_stream&&j>0,opt.mh_byte_stream&&j+1<counts[g]);'
assert s.count(old)==1
s=s.replace(old,'''for(U j=0;j<counts[g];j++){
#if HIP_SWIN_PERSISTENT
 if(j==1&&SpEnabled(channels[g],false)){source=SpStage(source,w,h,channels[g],starts[g]+1,counts[g]-2);j=counts[g]-2;continue;}
#endif
 source=Body(source,w,h,channels[g],shifts[j],starts[g]+j,j+1==counts[g],opt.mh_byte_stream&&j>0,opt.mh_byte_stream&&j+1<counts[g]);}''')
old='for(U b=begin;b<=ends[g];b++)source=Body(source,ow,oh,cs[g],Shift(b),b,false,opt.mh_byte_stream&&(b>ups[g]||byte_up),opt.mh_byte_stream&&b<ends[g]);'
assert s.count(old)==1
s=s.replace(old,'''for(U b=begin;b<=ends[g];b++){
#if HIP_SWIN_PERSISTENT
 if(b==ups[g]+1&&SpEnabled(cs[g],true)){source=SpStage(source,ow,oh,cs[g],b,ends[g]-b);b=ends[g]-1;continue;}
#endif
 source=Body(source,ow,oh,cs[g],Shift(b),b,false,opt.mh_byte_stream&&(b>ups[g]||byte_up),opt.mh_byte_stream&&b<ends[g]);}''')
h.write_text(s)
(a.out/'source-identity.json').write_text(json.dumps(dict(source_commit=revision,recipe_defines=defs,production_body_sha256=hashlib.sha256(original('hip/wave_owned_mh.inc')).hexdigest(),generated_hip_sha256=hashlib.sha256(text.encode()).hexdigest()),indent=2)+'\n')
print(a.out)
