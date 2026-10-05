 void PrefixNoiseExperiment(bool enabled,float pre_exposure,U reset_epoch){
  prefix_noise_enabled=enabled;prefix_noise_context=std::isfinite(pre_exposure)&&pre_exposure>0.f;
  if(prefix_noise_context)std::memcpy(&prefix_noise_exposure,&pre_exposure,4);
  prefix_noise_reset=reset_epoch;if(!enabled||!prefix_noise_context)prefix_noise_ready=false;
 }
 void PrefixNoiseInvalidate(){prefix_noise_ready=false;}
 void PrefixNoiseReport(){std::printf("PREFIX_NOISE_CACHE enabled=%u ready=%u builds=%llu hits=%llu fallback=%llu bytes=%zu seed0_only=1 cached_rgb_history_style=0\n",unsigned(prefix_noise_enabled),unsigned(prefix_noise_ready),prefix_noise_builds,prefix_noise_hits,prefix_noise_fallbacks,size_t(W)*H*8);}
 void PrefixNoiseHalfGold(void*out,U seed){Run("c32_wave1","cw_prefix_noise_gold",size_t(W)*H/16,out,W,H,seed);}
 void PrefixNoiseBuildProbe(void*out,U seed){Run("c32_wave1","cw_prefix_noise_build",size_t(W)*H/16,out,W,H,seed);}
 void PrefixNoisePrefixProbe(void*rgba,void*hist,void*main,void*down,U seed,bool cached){
  auto cache=cached?PrefixNoiseCache(seed):Tensor{};const U windows=W*H/64;
  if(cache)Run("c32_wave1","c32_wave1_prefix_b8d_noise",windows,rgba,hist?hist:rgba,PackedC32Weight("block0-ffn.f32",false),PackedC32Weight("block0-attention.f32",true),main,down,windows,0u,1u,W,H,seed,U(bool(hist)),P(cache));
  else Run("c32_wave1","c32_wave1_prefix_b8d",windows,rgba,hist?hist:rgba,PackedC32Weight("block0-ffn.f32",false),PackedC32Weight("block0-attention.f32",true),main,down,windows,0u,1u,W,H,seed,U(bool(hist)));
 }
