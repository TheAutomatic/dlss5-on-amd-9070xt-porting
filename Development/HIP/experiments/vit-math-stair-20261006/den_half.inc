// Same 64-key half tree as locked mochi VT chunk, mapped to the existing16-query wave.
// Lane%16 is query; lane/16 supplies the other8 key probabilities. No LDS or query regrouping.
typedef _Float16 trial_h2 __attribute__((ext_vector_type(2)));
DEV trial_h2 trial_other_key_half(trial_h2 pair){
 uint word=__builtin_bit_cast(uint,pair);
 word=__builtin_amdgcn_ds_bpermute(((__builtin_amdgcn_workitem_id_x()&31u)^16u)*4u,word);
 return __builtin_bit_cast(trial_h2,word);
}
DEV void trial_den_step(h8 probability,trial_h2*partial,_Float16&den,uint key,uint tokens){
#pragma unroll
 for(uint j=0;j<4;j++){
  trial_h2 local{probability[j*2],probability[j*2+1]};
  trial_h2 pair=local+trial_other_key_half(local);
  partial[j]=(key%64u==0)?pair:partial[j]+pair;
 }
 if((key+16u)%64u==0||key+16u==tokens){
  trial_h2 sum=partial[0];sum=sum+partial[1];sum=sum+partial[2];sum=sum+partial[3];
  _Float16 chunk=(_Float16)(sum[0]+sum[1]);den=(_Float16)(den+chunk);
 }
}
