// Native 1440 free geometry has 40x24=960 tokens. Fix strides/loop bounds without changing operations.
#ifndef HIP_VIT_ATTN_960
#define HIP_VIT_ATTN_960 0
#endif
#if HIP_VIT_ATTN_960 && HIP_VIT_ATTN_TRANSPOSED_SCORE
WAVE void vit_attention_fused_960_bytein_bout(const float*in,float*out,uint tokens,const uint*reuse_gate){
 if(reuse_gate&&reuse_gate[0])return;
 vit_attention_transposed_score_body<960,true,true>(in,out,960);
}
#endif
