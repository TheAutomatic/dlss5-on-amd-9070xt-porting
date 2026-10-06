import re,sys
def funcs(path):
  cur=None;out={}
  for l in open(path):
    m=re.match(r'^[0-9a-f]+ <(.+)>:',l)
    if m: cur=m.group(1);out[cur]=[];continue
    if cur: out[cur].append(l)
  return out
for path,names in [('vit.s',['vit_stream_contract_frag_hout','vit_stream_project_n64_bh','vit_stream_qkv_frag_hin_w5']),('mh.s',['mh_pool_project_group_c512','mh_attention_project_frag_c512']),('deep.s',['split_projection_frag','vit_expand_blocked_fp8_frag_bytein','vit_attention_fused_400_bytein_bout'])]:
  F=funcs(path)
  for n in names:
    L=F.get(n,[]);inflight=0;serial=0;waits0=0;loads=0
    for l in L:
      if 'global_load' in l or 'buffer_load' in l: inflight+=1;loads+=1
      elif 's_wait_loadcnt 0x0' in l and 'dscnt' not in l:
        waits0+=1
        if inflight<=2: serial+=1
        inflight=0
      elif 's_wait_loadcnt' in l:
        k=int(l.split('0x')[1].split()[0],16);inflight=min(inflight,k)
    print(f'{n}: static loads {loads}, wait0 {waits0}, wait0 after <=2 loads {serial}')
