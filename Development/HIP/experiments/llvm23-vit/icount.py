import sys,subprocess,re,collections
B='/home/lmxxf/work/llvm-build-23/bin/llvm-objdump'
ks=sys.argv[2].split(',')
for f in sys.argv[3:]:
    out=subprocess.run([B,'-d','--mcpu=gfx1201',f+'/gfx1201/'+sys.argv[1]+'.hsaco'],capture_output=True,text=True).stdout
    cur=None;c=collections.Counter();w=collections.Counter()
    for l in out.splitlines():
        m=re.match(r'^[0-9a-f]+ <(\w+)>:',l)
        if m: cur=m.group(1);continue
        if cur in ks and l.strip(): c[cur]+=1; w[cur]+=('wmma' in l)
    print('%-14s'%f[:14],' '.join('%5d/%-3d'%(c[k],w[k]) for k in ks))
