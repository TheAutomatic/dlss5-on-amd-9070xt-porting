from pathlib import Path
import shutil
root=Path(__file__).resolve().parents[4];out=Path('/tmp/vit-c512-aco-20260927/hip')
shutil.copytree(root/'hip',out,dirs_exist_ok=True)
p=out/'deep_fast.hip';s=p.read_text();s='#ifndef HIP_VIT_AV_BYTE\n#define HIP_VIT_AV_BYTE 0\n#endif\n'+s
for n in (256,400,640):
 s=s.replace(f'vit_attention_fused_body<{n},true>(in,out,tokens);',f'vit_attention_fused_body<{n},true,HIP_VIT_AV_BYTE>(in,out,tokens);')
p.write_text(s)
p=out/'vit_wide_deep.inc';s=p.read_text();old='DF_PACK8_LOOP(x[t],in[(first+t*16+rc())*IN+k+gr()*8+e]);'
new='{\n#if HIP_VIT_AV_BYTE\n    __builtin_memcpy(&x[t],reinterpret_cast<const unsigned char*>(in)+(first+t*16+rc())*IN+k+gr()*8,8);\n#else\n    DF_PACK8_LOOP(x[t],in[(first+t*16+rc())*IN+k+gr()*8+e]);\n#endif\n   }'
assert old in s;s=s.replace(old,new);p.write_text(s)
