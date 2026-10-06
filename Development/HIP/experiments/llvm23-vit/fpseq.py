import sys,subprocess,re
B='/home/lmxxf/work/llvm-build-23/bin/llvm-objdump'
def seq(f,k):
    out=subprocess.run([B,'-d','--mcpu=gfx1201',f],capture_output=True,text=True).stdout
    on=False;r=[]
    for l in out.splitlines():
        if re.match(r'^[0-9a-f]+ <%s>:'%k,l): on=True;continue
        if on and re.match(r'^[0-9a-f]+ <',l): break
        if on:
            s=l.split('//')[0].strip()
            if not s: continue
            parts=re.split(r'\s+::\s+',s)
            for p in parts:
                op=p.split()[0].replace('v_dual_','v_')
                if re.match(r'v_(pk_)?(fma|fmac|add_f|sub_f|subrev_f|mul_f|mad_f|cvt|max_num|min_num|med3|exp|rcp|rsq|log|sqrt|ldexp|div|wmma|dot|ceil|floor|rndne|trunc|fract)',op):
                    ops=re.sub(r'\bv\[?\d+(:\d+)?\]?','v',p[len(p.split()[0]):]); ops=re.sub(r'\bs\[?\d+(:\d+)?\]?','s',ops)
                    r.append(op+' '+re.sub(r'\s+',' ',ops).strip())
    return r
a,b,k=sys.argv[1],sys.argv[2],sys.argv[3]
open('/tmp/claude-1000/v23s/sa.txt','w').write('\n'.join(seq(a,k))+'\n');open('/tmp/claude-1000/v23s/sb.txt','w').write('\n'.join(seq(b,k))+'\n')
