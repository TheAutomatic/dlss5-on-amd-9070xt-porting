#!/usr/bin/env python3
# Build typed jobbench jobs for OUR current recipe from a recorder-v3 log (2026-09-30).
# usage: gen-ours.py WORK HEIGHT   (WORK has record-HEIGHT.log, flat-P/, ours-metadata.json from read-meta)
# Reuses kernel-map-20260929 ours-types.json + entries for kernels new since b99e9ef6.
# PDL consumer wait pointers are forced null (kernels guard on null); producer flag outputs get a 1 MiB zero buffer.
import sys,json,copy,subprocess
from pathlib import Path
W=Path(sys.argv[1]);H=sys.argv[2];K=Path(__file__).resolve().parents[1]/'kernel-map'
s=(W/f'record-{H}.log').read_bytes().decode('utf-16')
jobs=[json.loads(x[4:]) for x in s.splitlines() if x.startswith('JOB ')]
t=json.load(open(K/'ours-types.json'))
t['vit_attention_fused_400_bytein_bout']=copy.deepcopy(t['vit_attention_fused_640_bytein_bout'])
t['vit_stream_qkv_frag_hin_w5']=copy.deepcopy(t['vit_stream_qkv_frag_hin'])
t['mh_pool_project_group_c512']=copy.deepcopy(t['mh_pool_project_group_c256'])
t['mh_shift_pack']={'input_types':{'0':'f32'},'output_types':{'1':'f32'},'weight_args':[],'special':'C512 compact pack; f32 in/out.'}
for k,i0 in [('mh_ffn_fused_c256_frag_project_mapped_g128_qkv_fb_pdl','f32'),('mh_ffn_fused_c256_frag_project_mapped_g128_qkv_bytein_fb_pdl','fp8')]:
    t[k]={'input_types':{'0':i0,'16':'zero'},'output_types':{'3':'fp8','4':'fp8'},'weight_args':[1,2],'special':'PDL wait arg11 null; producer flags arg16 zero.'}
for k,o in [('c256_attn_wave_bo','fp8'),('c256_attn_wave','f32')]:
    t[k]={'input_types':{'0':'fp8','2':'fp8','13':'zero'},'output_types':{'3':o},'weight_args':[1],'special':'PDL wait arg11 null; producer flags arg13 zero.'}
waits={k:11 for k in ['mh_ffn_fused_c256_frag_project_mapped_g128_qkv_fb_pdl','mh_ffn_fused_c256_frag_project_mapped_g128_qkv_bytein_fb_pdl','c256_attn_wave_bo','c256_attn_wave']}
for j in jobs:
    if j['symbol'] in waits:a=j['args'][waits[j['symbol']]];assert a['type']=='ptr';a['value']=0
json.dump(jobs,open(W/'ours-record.json','w'),indent=1);json.dump(t,open(W/'ours-types.json','w'),indent=1,ensure_ascii=False)
src=(K/'make-ours.py').read_text().replace("r=Path('/tmp/kernel-map')",f"r=Path('{W}')").replace("module_file='flat-A/'+file","module_file='flat-P/'+file").replace("'vit_stream':'vit-stream'}","'vit_stream':'vit-stream','vit_wide_deep':'vit-wide-deep'}")
exec(compile(src,'make-ours','exec'))
jobs=json.load(open(W/'ours-jobs.json'))
for x in jobs:
    x['id']=x['id'].replace('ours-',f'o{H}-')
    for b in x['buffers']:
        if b['init']=='file' and b['file'].startswith('synthetic/'):b['file']=b['file'].replace('synthetic/',f'synthetic-{H}/')
        if b['bytes']==0:b['bytes']=b['check_bytes']=1<<20
json.dump(jobs,open(W/f'ours{H}-jobs.json','w'),indent=1);print(len(jobs),'jobs',H)
