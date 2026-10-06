"""640-only K-row representation permutation; 400 remains exact old C source."""
import argparse
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('basis',type=Path);p.add_argument('out',type=Path);a=p.parse_args();s=a.basis.read_text()
helper='''
DEV void trial_den_permuted(h8 p,trial_h2*part,_Float16&den,uint key){
 trial_h2 a{p[0],p[1]},b{p[4],p[5]},c{p[2],p[3]},d{p[6],p[7]};
 a=a+b;c=c+d;
 part[0]=(key%64u==0)?a:part[0]+a;
 part[1]=(key%64u==0)?c:part[1]+c;
 if((key+16u)%64u==0){
  trial_h2 other0=trial_other_key_half(part[0]),other1=trial_other_key_half(part[1]);
  trial_h2 low0=gr()?other0:part[0],low1=gr()?other1:part[1];
  trial_h2 high0=gr()?part[0]:other0,high1=gr()?part[1]:other1;
  trial_h2 sum=low0+low1;sum=sum+high0;sum=sum+high1;
  den=(_Float16)(den+(_Float16)(sum[0]+sum[1]));
 }
}
'''
start=s.index('template<uint MAXT,bool ByteInput=false,bool ByteOut=false>\nDEV void vit_attention_transposed_score_body');end=s.index('\n#endif\n// FAST TIER',start)
b=s[start:end]
b=b.replace('const unsigned char*in8=', 'const uint krow=(rc()&3u)|((rc()&4u)<<1u)|((rc()&8u)>>1u);\n const uint loadrow=MAXT==640?krow:rc();\n const unsigned char*in8=',1)
b=b.replace('(tokens+key+rc())','(tokens+key+loadrow)')
b=b.replace('trial_den_step(x,den_part,den_half,key,tokens);','''if constexpr(MAXT==640){
 trial_den_permuted(x,den_part,den_half,key);
 uint exchange=gr()?uint(xb[0]):uint(xb[1]);
 exchange=__builtin_amdgcn_ds_bpermute(((__builtin_amdgcn_workitem_id_x()&31u)^16u)*4u,exchange);
 if(gr())xb[0]=int(exchange);else xb[1]=int(exchange);
}else trial_den_step(x,den_part,den_half,key,tokens);''')
s=s[:start]+helper+b+s[end:];a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(s)
