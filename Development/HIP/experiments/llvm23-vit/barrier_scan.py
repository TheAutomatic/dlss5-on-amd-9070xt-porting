import sys,subprocess,re
B='/home/lmxxf/work/llvm-build-23/bin/llvm-objdump'
out=subprocess.run([B,'-d','--mcpu='+sys.argv[2],sys.argv[1]],capture_output=True,text=True).stdout
cur=None;pend=None;hits={}
for l in out.splitlines():
    m=re.match(r'^([0-9a-f]+) <(\w+)>:',l)
    if m: cur=m.group(2);pend=None;continue
    s=l.split('//')[0].strip()
    if not s: continue
    if re.match(r'ds_(store|write|bpermute|add|swizzle|append|cmpst|min|max|and|or|xor|inc|dec)\w*',s.split()[0]) or (s.startswith('ds_') and 'load' not in s.split()[0] and 'read' not in s.split()[0]): pend=s.split()[0]
    if re.match(r's_wait_(dscnt|storecnt_dscnt|loadcnt_dscnt) 0x0\b',s) or s.startswith('s_waitcnt'): pend=None
    if s.startswith('s_barrier_signal') and pend:
        hits[cur]=hits.get(cur,0)+1
for k,v in sorted(hits.items()): print('%-60s %d'%(k,v))
