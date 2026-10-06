from pathlib import Path
import shutil
r=Path(__file__).resolve().parents[4];out=Path('/tmp/vit-column-producer-shadow-20261006');out.mkdir(exist_ok=True)
for name in ['hip_reference_network.h','native_hip_env_options.h','production_options.generated.h']:shutil.copy(Path('/tmp/c512-den-actual-20261006')/name,out/name)
p=out/'hip_reference_network.h';s=p.read_text().replace('class Network {friend class D3D12Bridge;','class Network {friend class D3D12Bridge; std::function<void(const char*,void**,unsigned)> column_hook;',1)
s=s.replace('if(opt.profile)api.Check(api.hipEventRecord(timing.end,stream)', 'if(column_hook)column_hook(kernel.c_str(),argv,sizeof...(A));if(opt.profile)api.Check(api.hipEventRecord(timing.end,stream)',1)
s=s.replace(' Handle Stream()const{return stream;}', ' void DiagnosticColumnHook(std::function<void(const char*,void**,unsigned)>h){column_hook=std::move(h);}\n size_t DiagnosticWeightBytes(void*p)const{for(auto&x:weights)if(x.second->ptr==p)return x.second->bytes;throw std::runtime_error("weight pointer absent");}\n Handle Stream()const{return stream;}',1);p.write_text(s)
s=(r/'Development/HIP/experiments/c32-direct-feature-20261006/whole_diag.cpp').read_text()
hook=r'''
 bool captured=false;
 net.DiagnosticColumnHook([&](const char*name,void**args,unsigned argc){if(captured||std::strcmp(name,"vit_stream_qkv_frag_bin_w5f8"))return;if(argc!=4)throw std::runtime_error("producerABI");captured=true;U tokens=*static_cast<U*>(args[3]);if(tokens!=640)throw std::runtime_error("producer tokens");void*src=*static_cast<void**>(args[0]),*wp=*static_cast<void**>(args[1]),*original=*static_cast<void**>(args[2]);size_t wb=net.DiagnosticWeightBytes(wp),ib=tokens*1024,ob=3*ib;api.Check(api.hipStreamSynchronize(stream),"producer original snapshot boundary");
 void*si{},*sw{},*so{},*sn{};api.Check(api.hipMalloc(&si,ib),"shadow input");api.Check(api.hipMalloc(&sw,wb),"shadow weights");api.Check(api.hipMalloc(&so,ob),"shadow old");api.Check(api.hipMalloc(&sn,ob),"shadow new");api.Check(api.hipMemcpy(si,src,ib,3),"input D2D");api.Check(api.hipMemcpy(sw,wp,wb,3),"weights D2D");
 auto dump=[&](void*ptr,size_t bytes,const char*label){std::vector<char>v(bytes);api.Check(api.hipMemcpy(v.data(),ptr,bytes,2),"snapshot read");std::ofstream(std::string(argv[5])+"/"+label,std::ios::binary).write(v.data(),bytes);};dump(si,ib,"input.bin");dump(sw,wb,"weights.bin");dump(original,ob,"original.bin");
 for(unsigned side=0;side<2;side++){const char*path=std::getenv(side?"DLSS5_LAB_COLUMN_PRODUCER_NEW":"DLSS5_LAB_COLUMN_PRODUCER_OLD");if(!path)throw std::runtime_error("shadow module path");Handle mod{},fn{};api.Check(api.LoadModule(&mod,path),"shadow module");api.Check(api.hipModuleGetFunction(&fn,mod,name),"shadow function");void*dst=side?sn:so,*gate=nullptr;void*av[]={&si,&sw,&dst,&tokens,&gate};api.Check(api.hipModuleLaunchKernel(fn,768,1,1,160,1,1,0,stream,av,nullptr),"shadow launch");api.Check(api.hipStreamSynchronize(stream),"shadow completion");dump(dst,ob,side?"new-column.bin":"old-aos.bin");api.hipModuleUnload(mod);}
 printf("COLUMN_PRODUCER_SHADOW tokens=640 groups=768 threads=160 input_bytes=%zu weights_bytes=%zu output_bytes=%zu original_chain_unchanged=1 captures=1\n",ib,wb,ob);api.hipFree(sn);api.hipFree(so);api.hipFree(sw);api.hipFree(si);
 });
'''
needle=' auto run=[&]()';assert s.count(needle)==1;s=s.replace(needle,hook+needle);(out/'shadow.cpp').write_text(s)
