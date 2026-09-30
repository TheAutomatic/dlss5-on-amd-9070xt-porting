import re,sys
def F(path):
  cur=None;out={}
  for l in open(path):
    m=re.match(r'^[0-9a-f]+ <(.+)>:',l)
    if m: cur=m.group(1);out[cur]=[];continue
    if cur: out[cur].append(l)
  return out
def st(L):
  infl=0;serial=0;w0=0;loads=0
  for l in L:
    if re.search(r'\b(global_load|buffer_load)',l): infl+=1;loads+=1
    elif 's_wait_loadcnt 0x0' in l:
      w0+=1
      if infl<=2: serial+=1
      infl=0
    elif 's_wait_loadcnt' in l:
      k=int(l.split('0x')[1].split()[0],16);infl=min(infl,k)
  return f'len {len(L)} loads {loads} w0 {w0} ser {serial}'
A=F(sys.argv[1]);B=F(sys.argv[2])
for n in A:
  if n in B and A[n]!=B[n]: print(n,'|',st(A[n]),'->',st(B[n]))
