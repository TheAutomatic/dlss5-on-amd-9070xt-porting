 // Isolated experiment: no new production option. Explicit context is mandatory.
 Tensor prefix_noise_cache;bool prefix_noise_enabled=false,prefix_noise_context=false,prefix_noise_ready=false;
 U prefix_noise_exposure=0,prefix_noise_reset=0,prefix_noise_key_style=0,prefix_noise_key_exposure=0,prefix_noise_key_reset=0;
 unsigned long long prefix_noise_builds=0,prefix_noise_hits=0,prefix_noise_fallbacks=0;
 Tensor PrefixNoiseCache(U seed){
  U style=0;std::memcpy(&style,&api.style_feature,4);
  if(!prefix_noise_enabled||!prefix_noise_context||seed!=0||opt.graph||opt.experimental_temporal||!HasFn("c32_wave1","cw_prefix_noise_build")||!HasFn("c32_wave1","c32_wave1_prefix_b8d_noise")){prefix_noise_ready=false;prefix_noise_fallbacks++;return {};}
  if(!prefix_noise_cache)prefix_noise_cache=New(size_t(W)*H*2); // own persistent pool lease; never early reuse
  if(!prefix_noise_ready||style!=prefix_noise_key_style||prefix_noise_exposure!=prefix_noise_key_exposure||prefix_noise_reset!=prefix_noise_key_reset){
   Run("c32_wave1","cw_prefix_noise_build",size_t(W)*H/16,P(prefix_noise_cache),W,H,seed);
   prefix_noise_key_style=style;prefix_noise_key_exposure=prefix_noise_exposure;prefix_noise_key_reset=prefix_noise_reset;prefix_noise_ready=true;prefix_noise_builds++;
  }else prefix_noise_hits++;
  return prefix_noise_cache;
 }
