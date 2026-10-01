import sys,subprocess,re,collections
B='/home/lmxxf/work/llvm-build-23/bin/llvm-objdump'
def seq(f,k):
    out=subprocess.run([B,'-d','--mcpu=gfx1201',f],capture_output=True,text=True).stdout
    on=False;r=collections.Counter()
    for l in out.splitlines():
        if re.match(r'^[0-9a-f]+ <%s>:'%k,l): on=True;continue
        if on and re.match(r'^[0-9a-f]+ <',l): break
        if on:
            s=l.split('//')[0].strip()
            if not s or s.startswith('s_delay_alu') or s.startswith('s_wait_alu') or s.startswith('s_nop'): continue
            for p in re.split(r'\s+::\s+',s):
                op=p.split()[0].replace('v_dual_','v_');op=re.sub(r'_e(32|64)$','',op)
                rest=p[len(p.split()[0]):]
                ops=re.sub(r'\b[vs]\[?\d+(:\d+)?\]?(\.[lh])?','R',rest);ops=re.sub(r'vcc_lo|null','R',ops)
                r[op+' '+re.sub(r'\s+',' ',ops).strip()]+=1
    return r
a,b=seq(sys.argv[1],sys.argv[3]),seq(sys.argv[2],sys.argv[3])
for k in sorted(set(a)|set(b)):
    if a[k]!=b[k]: print('%4d %4d  %s'%(a[k],b[k],k))
