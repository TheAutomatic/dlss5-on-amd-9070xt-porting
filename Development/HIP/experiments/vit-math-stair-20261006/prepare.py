"""Isolated attention score B; no changes to canonical recipe or production source."""
import argparse,hashlib,importlib.util,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4];sp=importlib.util.spec_from_file_location('recipe',r/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m)
row=next(x for x in m.recipe(r/'hip') if x[0]=='deep_fast-packed-fast');source=row[2]
helper=Path(__file__).with_name('score_half.inc').read_text()
needle='template<uint MAXT,bool ByteInput=false,bool ByteOut=false>\nDEV void vit_attention_transposed_score_body'
assert source.count(needle)==1
source=source.replace(needle,helper+'\n'+needle)
old='''float af=clampf(a[e]*from_half(0x2dbb)+1.708984375f,1.439453125f,1.9775390625f);
   uint hb=(bits(af)>>13)-0x1c000u;unsigned short u=(unsigned short)(((hb<<4)+0x4000u)&65535u);'''
start=source.index('DEV void vit_attention_transposed_score_body')
position=source.index(old,start)
changed=source[:position]+source[position:].replace(old,'unsigned short u=vit_trial_score_half(a[e]);',1)
(a.output/'B.hip').write_text(changed)
(a.output/'A.hip').write_text(row[2])
# Probe the same helper that B inlines, not a separate numerical approximation.
probe='''typedef unsigned uint;
#define DEV __attribute__((device,always_inline)) inline
#define KERNEL extern "C" __attribute__((global))
'''+helper+'''\nKERNEL void score_half_probe(const float*in,unsigned short*out,uint n){uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();if(i<n)out[i]=vit_trial_score_half(in[i]);}\n'''
(a.output/'score-probe.hip').write_text(probe)
(a.output/'source.json').write_text(json.dumps({'row':row[0],'compiler':row[1],'opts':row[5],'shape':'existing16query, K16 order, FP32 QK/AV, original denominator unchanged','B':'only f32 score ->half RNE then half FMA/clamp/map','A_sha256':hashlib.sha256(row[2].encode()).hexdigest(),'B_sha256':hashlib.sha256(changed.encode()).hexdigest()},indent=2)+'\n')

# C only replaces the denominator in B's same16-query body.640 has10 full chunks.
den_helper=Path(__file__).with_name('den_half.inc').read_text()
c=changed.replace(needle,den_helper+'\n'+needle)
start=c.index('DEV void vit_attention_transposed_score_body');end=c.index('\n#endif',c.index(' float inv=vit_inv(sum[0]);',start))
prefix,body,suffix=c[:start],c[start:end],c[end:]
assert body.count('f8 sum{},acc[2]{};')==1
body=body.replace('f8 sum{},acc[2]{};','f8 sum{},acc[2]{};trial_h2 den_part[4]{};_Float16 den_half=(_Float16)0.f;')
old_sum='#if HIP_VIT_ATTN_TRANSPOSED_AV\n  sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(ones,x,sum);\n#else\n  sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(x,ones,sum);\n#endif'
assert body.count(old_sum)==1
body=body.replace(old_sum,'trial_den_step(x,den_part,den_half,key,tokens);')
body=body.replace('float inv=vit_inv(sum[0]);','float inv=vit_inv(float(den_half));')
c=prefix+body+suffix
(a.output/'C.hip').write_text(c)

probe='typedef unsigned uint;\n#define DEV __attribute__((device,always_inline)) inline\n#define KERNEL extern "C" __attribute__((global))\ntypedef _Float16 h8 __attribute__((ext_vector_type(8)));\n'+den_helper+'\nKERNEL void den_half_probe(const _Float16*prob,_Float16*out,uint tokens){\n uint lane=__builtin_amdgcn_workitem_id_x(),q=__builtin_amdgcn_workgroup_id_x()*16+(lane&15),half=lane>>4;\n trial_h2 partial[4]{};_Float16 den=(_Float16)0.f;\n for(uint key=0;key<tokens;key+=16){h8 p{};for(uint e=0;e<8;e++)p[e]=prob[q*tokens+key+half*8+e];trial_den_step(p,partial,den,key,tokens);}\n if(lane<16)out[q]=den;\n}\n'
(a.output/'den-probe.hip').write_text(probe)

meta=json.loads((a.output/'source.json').read_text());meta['C_sha256']=hashlib.sha256(c.encode()).hexdigest();meta['C_contract']='64-key half tree in existing16query layout;640fullchunks match locked math;400tail16zero-missing-keys experiment, not448token opponent';(a.output/'source.json').write_text(json.dumps(meta,indent=2)+'\n')
