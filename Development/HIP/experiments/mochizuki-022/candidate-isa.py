from pathlib import Path
import json,collections,importlib.util,re,sys,hashlib
root=Path(__file__).resolve().parents[4];d=Path(sys.argv[1]);spec=importlib.util.spec_from_file_location('S',root/'Development/results/aco-isa-20260927/tools/isa_stats.py');S=importlib.util.module_from_spec(spec);spec.loader.exec_module(S)
configs=[('I','c32-wave1','c32_wave1_mapped','I.s','c32_wave1_mapped'),('I','c32-wave1','c32_wave1_post','I.s','c32_wave1_post'),('P','c32-wave1','c32_wave1_prefix','P.s','c32_wave1_prefix'),('S','deep_fast-packed','split_projection_frag','T-deep.s','split_projection_frag_tc'),('S','c512-m32-mh','mh_qkv_normalize_frag_c512_m32','T-mh.s','mh_qkv_normalize_frag_c512_m32_tc'),('V','vit-stream','vit_stream_contract_frag_hout','T-vit.s','vit_stream_contract_frag_hout_tc'),('V','vit-stream','vit_stream_qkv_frag_hin','T-vit.s','vit_stream_qkv_frag_hin_tc'),('F','vit-stream','vit_stream_contract_frag_hout','F-vit.s','vit_stream_contract_frag_hout_tc'),('F','vit-stream','vit_stream_qkv_frag_hin','F-vit.s','vit_stream_qkv_frag_hin_tc'),('O','c512-m32-deep','split_mix_blocked_h16w_m32','O-mix.s','split_mix_blocked_h16w_m32'),('O','vit-stream','vit_stream_contract_frag_hout','O-vit.s','vit_stream_contract_frag_hout'),('G','c512-m32-deep','split_mix_blocked_h16w_m32','G-mix.s','split_mix_blocked_h16w_m32'),('G','c512-m32-mh','mh_qkv_normalize_frag_c512_m32','G-qkv.s','mh_qkv_normalize_frag_c512_m32')]
configs.append(('H','c512-m32-deep','split_mix_blocked_h16w_m32','H.s','split_mix_blocked_h16w_m32_wg4'))
for k in ['c32_wave1_mapped','c32_wave1_post','c32_wave1_prefix']:configs.append(('C','c32-wave1',k,'C.s',k))
def bill(path,k):
 text=path.read_text();b=dict(S.llvm_kernels(text))[k];classes=collections.Counter();ops=collections.Counter()
 for op,_ in S.ops_of(b):classes[S.classify(op)]+=1;ops[re.sub(r'_e(?:32|64)$','',op)]+=1
 meta={};tail=text[text.index('.amdgpu_metadata'):]
 for block in tail.split('  - .args:'):
  m=re.search(r'\.name:\s+(\S+)',block)
  if m and m[1]==k:
   for key in ['vgpr_count','sgpr_count','group_segment_fixed_size','private_segment_fixed_size']:
    n=re.search(r'\.'+key+r':\s*(\d+)',block);meta[key]=int(n[1]) if n else None
 return {'static_classes':dict(classes),'ops':dict(ops),'resources':meta,'isa_sha256':hashlib.sha256(text.encode()).hexdigest()}
out=[]
for tag,module,k,file,ck in configs:out.append({'set':tag,'module':module,'baseline_kernel':k,'candidate_kernel':ck,'baseline':bill(d/'census'/(module+'.hsaco.s'),k),'candidate':bill(d/'isa'/file,ck)})
print(json.dumps({'scope':'Static ISA comparison; counted polling loop once and includes occupancy dummy branch. Not executed instruction counts or cycles.','rows':out},indent=2))
