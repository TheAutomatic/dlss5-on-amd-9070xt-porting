from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('root',type=Path);a=p.parse_args()
s=(a.root/'consumer/new.hip').read_text()
s+=r'''
// Byte transport only. Input already quantized; no arithmetic substitution.
WAVE void column_tail_byte_probe(const unsigned char*in,unsigned char*out,uint tokens){
 uint perpart=(tokens/16)*32,part=bid()/perpart,local=bid()%perpart,first=local/32*16,row=local%32*32;
 for(uint j=0;j<2;j++){i2 packed{};for(uint e=0;e<8;e++){uint b=in[(part*tokens+first+gr()*8+e)*1024+row+j*16+rc()];packed[e/4]=int(uint(packed[e/4])|(b<<(8*(e%4))));}
 __builtin_memcpy(out+size_t(part)*tokens*1024+size_t(first)*1024+(row+j*16)*16+rc()*16+gr()*8,&packed,8);}
}
WAVE void column_operand_byte_probe(const unsigned char*oldin,const unsigned char*in8,uint*out,uint tokens){
 uint perpart=(tokens/16)*32,part=bid()/perpart,local=bid()%perpart,key=local/32*16,head=local%32;
 uint lane=__builtin_amdgcn_workitem_id_x(),rr=(lane/8)*4+(lane&3),cc=(lane&4)?8:0;
 for(uint j=0;j<2;j++){
 i2 qold{},qnew{},vold{},vnew{};
 __builtin_memcpy(&qold,oldin+size_t(part)*tokens*1024+(key+rc())*1024+head*32+j*16+gr()*8,8);
 using gi2=i2 __attribute__((address_space(1)));
 qnew=__builtin_amdgcn_global_load_tr_b64_v2i32((gi2*)(in8+size_t(part)*tokens*1024+key*1024+(head*32+j*16)*16+rr*16+cc));
 for(uint e=0;e<8;e++){uint b=oldin[(part*tokens+key+gr()*8+e)*1024+head*32+j*16+rc()];vold[e/4]=int(uint(vold[e/4])|(b<<(8*(e%4))));}
 __builtin_memcpy(&vnew,in8+size_t(part)*tokens*1024+key*1024+(head*32+j*16)*16+rc()*16+gr()*8,8);
 uint pos=(bid()*32+lane)*16+j*8;
 for(uint w=0;w<2;w++){out[pos+w]=uint(qold[w]);out[pos+2+w]=uint(qnew[w]);out[pos+4+w]=uint(vold[w]);out[pos+6+w]=uint(vnew[w]);}
 }
}
'''
(a.root/'gold.hip').write_text(s)
