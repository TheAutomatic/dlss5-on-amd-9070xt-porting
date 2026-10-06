import sys,re
def parse(path):
    L=open(path).read().split('\n')
    starts=[i for i,l in enumerate(L) if '; -- Begin function' in l]
    names=[re.search(r'Begin function (\S+)',L[i]).group(1) for i in starts]
    # trailer: after last kernel's csdata block
    last=names[-1];j=max(i for i,l in enumerate(L) if re.match(r'\t\.set (\.L)?%s\.'%re.escape(last),l))
    while j+1<len(L) and (L[j+1].startswith(';') or L[j+1].startswith('\t.section\t.AMDGPU.csdata')): j+=1
    head=L[:starts[0]];ch={};order=[]
    for k,(s,n) in enumerate(zip(starts,names)):
        e=starts[k+1] if k+1<len(starts) else j+1
        ch[n]=L[s:e];order.append(n)
    return head,ch,order,L[j+1:]
def entries(trailer):
    i=trailer.index('amdhsa.kernels:');j=i+1;out=[];cur=None
    while j<len(trailer) and (trailer[j].startswith('  ') ):
        if trailer[j].startswith('  - '): cur=[];out.append(cur)
        cur.append(trailer[j]);j+=1
    return i,j,out
def ename(e):
    for l in e:
        m=re.match(r'\s+\.name:\s+(\S+)',l)
        if m and not l.startswith('      '): return m.group(1)
    for l in e:
        m=re.match(r'    \.name:\s+(\S+)',l)
        if m: return m.group(1)
base,other,ks,out=sys.argv[1],sys.argv[2],[k for k in sys.argv[3].split(',') if k],sys.argv[4]
h,c,o,t=parse(base);_,c2,_,t2=parse(other)
for k in ks:
    assert k in c and k in c2,k
    ren=[re.sub(r'\.L(BB|func_end|tmp|func_begin|exception|set_)(\w*)',lambda m:'.LX'+m.group(1)+m.group(2),l) for l in c2[k]]
    c[k]=ren
i,j,E=entries(t);_,_,E2=entries(t2)
m2={ename(e):e for e in E2}
E=[m2[ename(e)] if ename(e) in ks else e for e in E]
t=t[:i+1]+[l for e in E for l in e]+t[j:]
open(out,'w').write('\n'.join(h+[l for n in o for l in c[n]]+t))
print('spliced',ks)
