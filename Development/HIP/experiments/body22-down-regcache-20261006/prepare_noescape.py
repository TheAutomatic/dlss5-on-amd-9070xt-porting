"""Single lowering fix: inline pool capture, no by-reference capture/finish closure. Same math/ABI."""
from pathlib import Path
import argparse,shutil,json,hashlib
p=argparse.ArgumentParser();p.add_argument('out',type=Path);a=p.parse_args();base=Path('/tmp/body22-down-regcache-20261006/hip');shutil.copytree(base,a.out/'hip',dirs_exist_ok=True)
p=a.out/'hip/wave_owned_mh.inc';s=p.read_text();start=s.index('DEV void swin_wave2_body_down_local(');end=s.index('\n#endif\n#define W2_KERNEL',start);b=s[start:end]
i=b.index(' auto down_capture=[&](f8*result,uint qt){');j=b.index('\n };',i)+len('\n };');cap=b[i:j];inner=cap[cap.index('\n  if constexpr'):cap.rfind('\n };')]
b=b[:i]+b[j:];assert b.count(' down_capture(result,qt);')==2
b=b.replace(' down_capture(result,qt);',' {\n const uint l=__builtin_amdgcn_workitem_id_x()%32;'+inner+'\n }')
needle=' auto finish=[&](auto full){';assert b.count(needle)==1
b=b.replace(needle,' const uint tx=(win%(workw/8))*8,ty=(win/(workw/8))*8;\n const bool full=(tx>=sx&&ty>=sy&&tx+8<=sx+width&&ty+8<=sy+height);\n {',1)
needle=' uint tx=(win%(workw/8))*8,ty=(win/(workw/8))*8;\n if(tx>=sx&&ty>=sy&&tx+8<=sx+width&&ty+8<=sy+height)finish(w2_true{});else finish(w2_false{});'
assert b.count(needle)==1;b=b.replace(needle,'',1)
# Lambda terminator now becomes an ordinary scope terminator, preserving qt loop ordering.
pos=b.index('\n#else\n _Pragma("clang loop unroll(disable)") for(uint qt=0;qt<4;qt++){',b.index('const bool full'))
prefix=b[:pos];k=prefix.rfind('\n };');assert k>=0;b=prefix[:k]+'\n }'+prefix[k+4:]+b[pos:]
s=s[:start]+b+s[end:];p.write_text(s)
(a.out/'source.json').write_text(json.dumps({'base':'/tmp/body22-down-regcache-20261006/hip','new_inc_sha':hashlib.sha256(s.encode()).hexdigest(),'scope':'only remove mutable reference closure capture/finish;same8cachevars/mapping/fullwave/two barriers/math/raw/ABI;no compileropts change','gold_pending':True},indent=2)+'\n')
