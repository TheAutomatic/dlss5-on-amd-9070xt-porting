import re,sys
mod,fn=sys.argv[1],sys.argv[2]
L=[];cur=None
for l in open(f'isa/{mod}.s'):
  m=re.match(r'^[0-9a-f]+ <(.+)>:',l)
  if m: cur=m.group(1);continue
  if cur==fn:L.append(l.split('//')[0].strip())
last=0
for i,l in enumerate(L):
  if 's_wait_loadcnt 0x0' in l:
    seg=[x for x in L[last:i] if re.search(r'global_load|buffer_load|s_cbranch|ds_|v_wmma|global_store|s_wait',x)]
    loads=[x for x in seg if 'load' in x and ('global' in x or 'buffer' in x)]
    print(f'--{i}: {len(loads)} loads; wmma {sum("wmma" in x for x in seg)} br {sum("cbranch" in x for x in seg)} st {sum("store" in x for x in seg)} | '+' ; '.join(loads)[:200])
    print('   next:',' ; '.join(L[i+1:i+4])[:160])
    last=i
