"""Isolated Up48→Body48 route, sentinel Tensor pinned; no default production changes."""
from pathlib import Path
import argparse,shutil
p=argparse.ArgumentParser();p.add_argument('root',type=Path);a=p.parse_args();r=Path(__file__).resolve().parents[4];d=a.root/'Development/HIP';d.mkdir(parents=True,exist_ok=True);shutil.copytree(r/'src',a.root/'src',dirs_exist_ok=True)
for x in (r/'Development/HIP').glob('*.h'):shutil.copy2(x,d/x.name)
shutil.copy2('/tmp/fresh-mochi1088-20261006/production_options.generated.h',d/'production_options.generated.h')
p=d/'hip_reference_network.h';s=p.read_text();s=s.replace('class Network {friend class D3D12Bridge;','''class Network {friend class D3D12Bridge;
 Handle ub_fn{};Tensor ub_low,ub_skip;void*ub_weight{};bool ub_pending=false;
 unsigned long long ub_dispatches=0,ub_fused=0;std::vector<std::string>ub_names;
''',1)
needle='Tensor Up(Tensor input,Tensor skip,U iw,U ih,U ow,U oh,U ic,U oc,const std::string&file,bool byte_out=false){';assert s.count(needle)==1
s=s.replace(needle,needle+'''
 const char*ae=std::getenv("DLSS5_VIT_ADAPTIVE");
 if(ub_fn&&wave_owned_active&&HasFn("c64_wave2","c256_wave2_bi_bo_w16")&&W==1920&&H==1088&&fast_numeric&&multi_pass==1&&!multi_skin&&!opt.graph&&!opt.experimental_temporal&&!pulse_frame_history&&opt.skip_blocks.empty()&&!adaptive_active&&(!ae||!std::strcmp(ae,"0"))&&byte_out&&iw==60&&ih==34&&ow==120&&oh==68&&ic==512&&oc==256&&file==Block(48,"weights")){
  if(ub_pending)throw std::runtime_error("pending Up overwrite");ub_low=input;ub_skip=skip;ub_weight=PackedDecoderHalf(file,size_t(ic)*oc);ub_pending=true;
  return input; /* sentinel, never consumed by original byte body when pending */
 }
''',1)
needle='  if(skip_b8){if(!half_out)';assert s.count(needle)==1
s=s.replace(needle,'''  if(ub_pending){
   if(block!=48||input!=ub_low||name!="c256_wave2_bi_bo_w16"||raw||!byte_in||!byte_out||half_out||skip_b8||w!=120||h!=68||ww!=120||hh!=72||sx||sy)throw std::runtime_error("pending Up/Body48 scope mismatch");
   void*lo=P(ub_low),*sk=P(ub_skip),*fw=PackedFusedMhWeightFragW16(Block(block,"ffn"),256),*aw=WaveOwnedAttentionWeight(Block(block,"attention"),256),*oo=P(out);U iw=120,ih=68,pw=120,ph=72,x=0,y=0,post=0;
   void*aa[]={&lo,&fw,&aw,&oo,&iw,&ih,&pw,&ph,&x,&y,&post,&ub_weight,&sk};api.Check(api.hipModuleLaunchKernel(ub_fn,135,1,1,256,1,1,0,stream,aa,nullptr),"new-only Up48Body48");++ub_dispatches;++ub_fused;
   if(std::getenv("DLSS5_FUSION_SEQUENCE"))ub_names.push_back("FUSED_UP48_BODY48");ub_pending=false;ub_low.reset();ub_skip.reset();ub_weight=nullptr;Stage("block48",out);return out;
  }
'''+needle,1)
s=s.replace('for(unsigned repeat=0;repeat<repeats_here;repeat++){unsigned gg=', 'for(unsigned repeat=0;repeat<repeats_here;repeat++){++ub_dispatches;if(std::getenv("DLSS5_FUSION_SEQUENCE"))ub_names.push_back(kernel);unsigned gg=',1)
s=s.replace('~Network(){','~Network(){api.hipSetDevice(int(opt.device));if(ub_low||ub_skip){api.hipStreamSynchronize(stream);ub_low.reset();ub_skip.reset();ub_pending=false;ub_weight=nullptr;}',1)
s=s.replace(';api.hipSetDevice(int(opt.device));api.hipStreamSynchronize(stream);experimental_history',';api.hipStreamSynchronize(stream);experimental_history',1)
s=s.replace(' Handle Stream()const{return stream;}',''' void DiagnosticUpBodyModule(const std::string&p){if(p.empty()||p=="-")return;Handle m{};api.Check(api.LoadModule(&m,p.c_str()),"isolated UpBody module");api.Check(api.hipModuleGetFunction(&ub_fn,m,"c256_up48_body48_bi_bo_w16_local"),"sole main export");modules["ub_new_only"]=m;}
 unsigned long long DiagnosticDispatchCount()const{return ub_dispatches;}
 unsigned long long DiagnosticFusedCount()const{return ub_fused;}
 const std::vector<std::string>& DiagnosticNames()const{return ub_names;}
 Handle Stream()const{return stream;}''',1);p.write_text(s)
p=d/'swin_persistent_network.h';p.write_text(p.read_text().replace('api.Check(api.hipModuleLaunchKernel(', '++ub_dispatches;api.Check(api.hipModuleLaunchKernel('))
s=(r/'Development/HIP/experiments/sync-network-gap1080-20261006/benchmark.cpp').read_text();s=s.replace('if(argc!=9)','if(argc!=10)').replace('||!warm||','||').replace('Network net(opt);net.SetNoise({});','Network net(opt);net.DiagnosticUpBodyModule(argv[9]);net.SetNoise({});')
s=s.replace('auto run=[&](){net.Enqueue(in,nullptr,out,0);net.Synchronize();};','''unsigned long long per=0;
 auto run=[&](){auto old=net.DiagnosticDispatchCount();net.Enqueue(in,nullptr,out,0);net.Synchronize();auto n=net.DiagnosticDispatchCount()-old;if(!per)per=n;else if(per!=n)throw std::runtime_error("dispatch/frame changed");};''')
s=s.replace('for(U i=0;i<measured;i++){auto a=', 'for(U i=0;i<measured;i++){auto dc0=net.DiagnosticDispatchCount();auto a=');s=s.replace('auto b=std::chrono::steady_clock::now();float ms=', 'auto b=std::chrono::steady_clock::now();if(net.DiagnosticDispatchCount()-dc0!=per)throw std::runtime_error("measured dispatch changed");float ms=')
s=s.replace('api.hipEventDestroy(begin);','''if(std::getenv("DLSS5_FUSION_SEQUENCE")){for(size_t i=0;i<net.DiagnosticNames().size();i++)printf("API_FN %zu %s\\n",i,net.DiagnosticNames()[i].c_str());}printf("FUSION_ROUTE dispatch_per_frame=%llu fused_calls=%llu frames_total=%u module=%s\\n",per,net.DiagnosticFusedCount(),1+warm+measured,argv[9]);api.hipEventDestroy(begin);''')
(a.root/'benchmark.cpp').write_text(s)
