#define KERNEL extern "C" __attribute__((global))
using uint=unsigned int;
using i2=int __attribute__((ext_vector_type(2)));
using gi2=i2 __attribute__((address_space(1)));
KERNEL __attribute__((amdgpu_flat_work_group_size(32,32))) void tr_b64_probe(const unsigned char*in,uint*out,uint stride,uint base){
 uint l=__builtin_amdgcn_workitem_id_x(),r=l&15u,g=l>>4;
 // Mesa byte8 transpose-load read indexing: arbitrary row stride.
 uint rr=(l/8)*4+(l&3),cc=(l&4)?8:0;
 for(uint c=0;c<2;c++){
  i2 old{};for(uint e=0;e<8;e++){uint b=in[base+(g*8+e)*stride+c*16+r];old[e/4]=int(uint(old[e/4])|(b<<(8*(e%4))));}
  i2 tr=__builtin_amdgcn_global_load_tr_b64_v2i32((gi2*)(in+base+rr*stride+c*16+cc));
  out[l*8+c*2]=uint(old[0]);out[l*8+c*2+1]=uint(old[1]);out[l*8+4+c*2]=uint(tr[0]);out[l*8+4+c*2+1]=uint(tr[1]);
 }
}
