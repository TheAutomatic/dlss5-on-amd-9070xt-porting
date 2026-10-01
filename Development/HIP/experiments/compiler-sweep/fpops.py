import sys,subprocess,re,collections
B='/home/lmxxf/work/llvm-build-dlss5-gfx12/bin/llvm-objdump'
def funcs(f):
    out=subprocess.run([B,'-d','--mcpu=gfx1201',f],capture_output=True,text=True).stdout
    cur=None;d=collections.defaultdict(collections.Counter)
    for l in out.splitlines():
        m=re.match(r'^[0-9a-f]+ <(\w+)>:',l)
        if m: cur=m.group(1);continue
        if cur and l.strip() and not l.strip().endswith(':'):
            op=l.split('//')[0].split()
            if not op: continue
            for o in (op[0], op[2] if op[0].startswith('v_dual') and len(op)>2 else None):
                if not o: continue
                o=o.replace('v_dual_','v_')
                for k,pat in (('fma',r'v_(pk_)?fmac?_(mix|f32|f16|dx9)'),('mul',r'v_(pk_)?mul_f(32|16)'),('add',r'v_(pk_)?(add|sub|subrev)_f(32|16)'),('mad',r'v_mad'),('wmma','wmma')):
                    if re.match(pat,o): d[cur][k]+=1
    return d
a,b=funcs(sys.argv[1]),funcs(sys.argv[2])
ks=[k for k in sys.argv[3:]] or sorted(a)
for k in ks:
    if k.endswith('.kd'): continue
    x,y=a.get(k,{}),b.get(k,{})
    if dict(x)!=dict(y): print('%-60s fma %d->%d mul %d->%d add %d->%d mad %d->%d wmma %d->%d'%(k,x.get('fma',0),y.get('fma',0),x.get('mul',0),y.get('mul',0),x.get('add',0),y.get('add',0),x.get('mad',0),y.get('mad',0),x.get('wmma',0),y.get('wmma',0)))
