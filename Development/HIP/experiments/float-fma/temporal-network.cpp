// Offline raw network comparison, no game/D3D codec. Options copied by prepare from production.
#include "hip_reference_network.h"
#include <cstdio>
using namespace hip_reference;
int main(int argc,char**argv){try{
 if(argc!=6)return 2;
 Options o;o.width=1920;o.height=1152;o.post_shift=3;o.fast_vit=true;o.wmma=o.wave=o.tiled=o.pooled=true;o.assets=argv[1];o.modules=argv[2];const bool fast=true;
  if(fast)o.fast_c32=o.fused_c32=o.fused_ffn=o.fast_mh=o.fused_mh=o.mh_wave=o.fast_deep=o.fast_prefix=o.packed_weights=o.packed_c32=o.fp8_normalized=o.fp8_ffn=o.fp8_av=o.fp8_deep=o.fp8_middle=o.half_c32=o.crop_c32=o.fused_qkv_norm=o.fused_mh_ffn=o.tiled_mh_ffn=o.mapped_c32=o.vit_blocked=o.vit_contract_blocked=true;
  o.tiled_ffn_min_c=256;
  if(fast){o.vit_weight_mask=1;o.vit_pack_input=true;o.elide_identity_shift=true;o.raw_chain=true;o.pre_main8=true;o.post_merge_fold=true;o.fused_ffn_project=true;o.split_ffn_fused=true;o.split_mix_blocked=true;o.split_project_blocked=true;o.vit_qkv_blocked=true;o.vit_qkv_fused=true;o.mh_project_crop=true;o.mh_input_mapped=true;o.prefix_fused=true;o.direct_prefix_input=true;o.grouped_mh_contract=true;o.ffn_qkv=true;o.ffn_qkv_max_c=256;o.vit_attn_fused=true;o.vit_qkv_fp8=true;o.vit_expand_frag=true;/* 2026-09-16: fused ViT attention, byte ViT QKV, fragment-native expand weights (-0.23ms, bit-exact) */o.split_mix_h16w=true;/* 2026-09-16 21:50: C512 mix weights prepacked half (-0.12ms, bit-exact) */o.pool_project_h16w=true;/* 2026-09-16 22:20: downsample projection weights prepacked half/E4M3 (-0.21ms, bit-exact) */o.decoder_h16w=true;/* 2026-09-16 22:40: decoder up-projection weights prepacked half (-0.07ms, bit-exact) */o.c512_qkv_frag=true;/* 2026-09-16 20:45: C512 QKV from projection E4M3 tiles + fragment weights, no LDS (-0.37ms, bit-exact) */o.c512_proj_frag=true;o.c512_proj_tiles=true;o.mh_proj_diag=true;o.post_head_fused=true;o.c32_finish_fused=true;o.down_crop_fused=true;o.pool32_h16w=true;o.pool_project_group=true;o.vit_proj_frag=true;o.vit_qkv_frag=true;o.vit_contract_frag=true;/* 2026-09-16 21:55: C512 attention projection + split projection in the same shape (-0.31ms together, bit-exact) */o.prefix_inline=true;/* 2026-09-17 02:25: null on 09-17 00:21 while the block-0 kernel was issue-bound; -0.27ms once its F()/load serialization was fixed, bit-exact */}

 o.wave_owned=true;o.c512_m32=true;o.vit_proj_n64=true;o.vit_stream=3;o.pdl=true;o.mh_ffn_frag256=true;o.decoder_byte=true;o.mh_proj_diag_fb=true;o.mh_feature_byte=true;o.mh_byte_stream=true;o.vit_byte_stream=false;o.graph=false;
 // All 71 blocks: match original oracle topology, unlike release skip42/43/46.
 if(!WaveOwnedCompatible(o))throw std::runtime_error("wave-owned inactive");
 auto bytes=ReadBytes(argv[3]);if(bytes.size()!=1920ull*1080*16)throw std::runtime_error("input shape");
 std::vector<float> input(1920ull*1152*4);for(int y=0;y<1152;y++){int sy=y<1080?y:2158-y;memcpy(input.data()+y*1920ull*4,bytes.data()+sy*1920ull*16,1920*16);}
 Network net(o);net.SetNoise({});auto&api=net.Runtime();void*in{},*out{};api.Check(api.hipMalloc(&in,input.size()*4),"input");api.Check(api.hipMalloc(&out,1920ull*1152*12),"output");api.Check(api.hipMemcpy(in,input.data(),input.size()*4,1),"upload");auto hist=ReadBytes(argv[4]);if(hist.size()!=input.size()*4)throw std::runtime_error("sampled history shape");void*history{};api.Check(api.hipMalloc(&history,hist.size()),"history");api.Check(api.hipMemcpy(history,hist.data(),hist.size(),1),"history upload");
 for(int frame=0;frame<5;frame++){
 net.Enqueue(in,frame%2?history:nullptr,out,0);net.Synchronize();std::vector<char> result(1920ull*1152*12);api.Check(api.hipMemcpy(result.data(),out,result.size(),2),"readback");std::ofstream f(std::string(argv[5])+"-frame"+std::to_string(frame)+".f32",std::ios::binary);f.write(result.data(),result.size());if(!f)throw std::runtime_error("write");printf("frame=%d history=%d written=%zu\n",frame,frame%2,result.size());}
 api.hipFree(history);api.hipFree(in);api.hipFree(out);
 }catch(const std::exception&e){fprintf(stderr,"%s\n",e.what());return 1;}}
