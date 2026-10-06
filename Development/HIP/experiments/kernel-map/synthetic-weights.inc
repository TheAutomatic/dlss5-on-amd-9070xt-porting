// Microbenchmark fixture only. Call on decoded, original-layout floats BEFORE packing.
// Include inside hip_reference, above ReadWeights; requires existing string/vector/stdexcept/cstdint.
inline void SyntheticWeights(const std::string&path,std::vector<float>&v){
 const auto slash=path.find_last_of("/\\");std::string name=path.substr(slash==std::string::npos?0:slash+1);
 if(name.size()>=4&&name.substr(name.size()-4)==".f16")name.replace(name.size()-4,4,".f32");
 size_t matrix_end=0,scale_begin=0,expected=0; // prefix includes matrices and positional bias; tail scales become 1.
 if(name=="head-matrix.f32"){expected=matrix_end=524288;scale_begin=expected;}
 else if(name=="decoder39-weights.f32"){expected=524800;matrix_end=scale_begin=524288;}
 else if(name=="post70-scales.f32"){expected=64;matrix_end=scale_begin=0;}
 else if(name=="post70-head.f32"){expected=matrix_end=96;scale_begin=expected;}
 else{
  unsigned b=70;std::string type;
  if(name.rfind("block",0)==0){const auto dash=name.find('-');if(dash==std::string::npos)throw std::runtime_error("synthetic weight name: "+name);b=unsigned(std::stoul(name.substr(5,dash-5)));type=name.substr(dash+1);}
  else if(name.rfind("post70-",0)==0)type=name.substr(7);
  else throw std::runtime_error("unclassified synthetic weight: "+name);
  const size_t c=b<=4?32:b<=8?64:b<=14?128:b<=22?256:b<=30?512:b<=38?1024:b<=47?512:b<=55?256:b<=61?128:b<=65?64:32;
  if(type=="ds.f32"){expected=matrix_end=2*c*c;scale_begin=expected;}
  else if(type=="weights.f32"){matrix_end=scale_begin=2*c*c;expected=matrix_end+c;}
  else if(type=="ffwd.f32"){expected=matrix_end=524288;scale_begin=expected;}
  else if(type=="ffwd-projection.f32"){matrix_end=scale_begin=262144;expected=262656;}
  else if(type=="ffn.f32"){matrix_end=scale_begin=c==32?8704:9*c*c;expected=matrix_end+c;}
  else if(type=="attention.f32"){
   // C32: QKV/project[0,4096), bias[4096,8192), Qscale[8192], residual[8193,8225).
   // MH: matrices[0,4cc), bias[4cc,4cc+heads*4096), Qscale[heads], residual[c].
   matrix_end=scale_begin=c==32?8192:4*c*c+(c/32)*4096;
   expected=scale_begin+(c/32)+c;
  }
  else if(type=="expand.f32"){expected=matrix_end=4194304;scale_begin=expected;}
  else if(type=="contract.f32"){matrix_end=scale_begin=4194304;expected=4195328;}
  else if(type=="qkv.f32"){matrix_end=scale_begin=3145728;expected=3145760;}
  else if(type=="projection.f32"){matrix_end=scale_begin=1048576;expected=1049600;}
  else throw std::runtime_error("unclassified synthetic suffix: "+name);
 }
 if(v.size()!=expected||matrix_end!=scale_begin)throw std::runtime_error("synthetic weight shape: "+name);
 // Deterministic synthetic signs, retaining ONLY original matrix/bias zero locations.
 // Do not retain real trained signs or overwrite sparse structural zeros.
 uint32_t seed=2166136261u;for(unsigned char c:name){seed^=c;seed*=16777619u;}
 for(size_t i=0;i<matrix_end;i++)if(v[i]!=0.f){uint32_t x=uint32_t(i)^seed;x^=x>>16;x*=0x7feb352du;x^=x>>15;x*=0x846ca68bu;x^=x>>16;v[i]=(x&1u)?0.015625f:-0.015625f;}
 // These are scalar gains, not matrices. Includes normalization, residual and decoder skip scales.
 for(size_t i=scale_begin;i<expected;i++)v[i]=1.f;
 // Existing Append*C32/MhResidualDiagonals runs LATER: it decomposes scale=1 into (1,0,0).
 // Never synthesize the appended three pieces independently as (1,1,1).
}
