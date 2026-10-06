"""Copied experimental route; no production/default/source modifications."""
from pathlib import Path
import argparse,shutil
p=argparse.ArgumentParser();p.add_argument('root',type=Path);a=p.parse_args();r=Path(__file__).resolve().parents[4];d=a.root/'Development/HIP';d.mkdir(parents=True,exist_ok=True);shutil.copytree(r/'src',a.root/'src',dirs_exist_ok=True)
for x in (r/'Development/HIP').glob('*.h'):shutil.copy2(x,d/x.name)
shutil.copy2('/tmp/fresh-mochi1088-20261006/production_options.generated.h',d/'production_options.generated.h')
p=d/'hip_reference_network.h';s=p.read_text();needle='class Network {friend class D3D12Bridge;';s=s.replace(needle,needle+'''
 Handle dl_fn{};Tensor dl_input,dl_raw;void*dl_fw{},*dl_aw{};bool dl_pending=false;
 size_t dl_cap=0,dl_valid=0;unsigned long long dl_dispatches=0,dl_fused=0;std::vector<std::string> dl_names;
''',1)
needle='  if(skip_b8){if(!half_out)';assert s.count(needle)==1
route='''  const char*dl_ae=std::getenv("DLSS5_VIT_ADAPTIVE");
  if(dl_fn&&block==22&&name=="c256_wave2_bi_w16"&&raw&&byte_in&&!byte_out&&!half_out&&!skip_b8&&w==120&&h==68&&ww==120&&hh==72&&sx==0&&sy==4&&W==1920&&H==1088&&fast_numeric&&multi_pass==1&&!multi_skin&&!opt.graph&&!opt.experimental_temporal&&!pulse_frame_history&&opt.skip_blocks.empty()&&!adaptive_active&&(!dl_ae||!std::strcmp(dl_ae,"0"))){
   if(dl_pending)throw std::runtime_error("fusion pending overwrite");dl_input=input;dl_raw=out;dl_fw=PackedFusedMhWeightFragW16(Block(block,"ffn"),c);dl_aw=WaveOwnedAttentionWeight(Block(block,"attention"),c);dl_pending=true;
   Stage("block"+std::to_string(block),out);return out;
  }
''';s=s.replace(needle,route+needle,1)
needle='Tensor Down(Tensor raw,U w,U h,U c,const std::string&file,bool head=false,bool half_in=false){';assert s.count(needle)==1
route='''
 if(dl_pending){
  if(raw!=dl_raw||w!=120||h!=68||c!=256||head||half_in)throw std::runtime_error("fusion Down ownership/ABI");
  auto out=HIP_C512_PAD16?NewPad16(size_t(60)*34,512):New(size_t(60)*34*512);dl_cap=out->capacity;dl_valid=out->bytes;void*di=P(dl_input),*rr=P(dl_raw),*dw=PackedDsWeightFrag(file,256),*oo=P(out);U iw=120,ih=68,ww=120,hh=72,sx=0,sy=4,post=3;
  void*aa[]={&di,&dl_fw,&dl_aw,&rr,&iw,&ih,&ww,&hh,&sx,&sy,&post,&dw,&oo};
  api.Check(api.hipModuleLaunchKernel(dl_fn,135,1,1,256,1,1,0,stream,aa,nullptr),"new-only body22+Down");++dl_dispatches;++dl_fused;if(std::getenv("DLSS5_FUSION_SEQUENCE"))dl_names.push_back("FUSED_BODY22_DOWN");
  dl_pending=false;dl_input.reset();dl_raw.reset();pulse_ordered_down_c256=true;return out;
 }
''';s=s.replace(needle,needle+route,1)
s=s.replace(':New(size_t(ow)*oh*c*2);Run("mh_fast",', ':New(size_t(ow)*oh*c*2);if(c==256&&!head&&w==120&&h==68){dl_cap=out->capacity;dl_valid=out->bytes;}Run("mh_fast",',1)
s=s.replace('~Network(){','~Network(){if(dl_input||dl_raw){api.hipStreamSynchronize(stream);dl_input.reset();dl_raw.reset();dl_pending=false;dl_fw=nullptr;dl_aw=nullptr;}',1)
s=s.replace('for(unsigned repeat=0;repeat<repeats_here;repeat++){unsigned gg=', 'for(unsigned repeat=0;repeat<repeats_here;repeat++){++dl_dispatches;if(std::getenv("DLSS5_FUSION_SEQUENCE"))dl_names.push_back(kernel);unsigned gg=',1)
needle=' Handle Stream()const{return stream;}'
s=s.replace(needle,''' void DiagnosticBodyDownModule(const std::string&p){if(p.empty()||p=="-")return;Handle m{};api.Check(api.LoadModule(&m,p.c_str()),"isolated fusion module");api.Check(api.hipModuleGetFunction(&dl_fn,m,"c256_wave2_bi_w16_down_local"),"sole new export");modules["dl_new_only"]=m;}
 unsigned long long DiagnosticDispatchCount()const{return dl_dispatches;}
 size_t DiagnosticDownCapacity()const{return dl_cap;}size_t DiagnosticDownValid()const{return dl_valid;}
 unsigned long long DiagnosticFusedCount()const{return dl_fused;}
 const std::vector<std::string>& DiagnosticNames()const{return dl_names;}
'''+needle,1);p.write_text(s)
p=d/'swin_persistent_network.h';s=p.read_text();s=s.replace('api.Check(api.hipModuleLaunchKernel(', '++dl_dispatches;api.Check(api.hipModuleLaunchKernel(');p.write_text(s)
s=(r/'Development/HIP/experiments/sync-network-gap1080-20261006/benchmark.cpp').read_text();s=s.replace('if(argc!=9)', 'if(argc!=10)');s=s.replace('||!warm||','||');s=s.replace('Network net(opt);net.SetNoise({});','Network net(opt);net.DiagnosticBodyDownModule(argv[9]);net.SetNoise({});');s=s.replace('auto run=[&](){net.Enqueue(in,nullptr,out,0);net.Synchronize();};','''unsigned long long dispatch_per=0;
 auto run=[&](){auto old=net.DiagnosticDispatchCount();net.Enqueue(in,nullptr,out,0);net.Synchronize();auto delta=net.DiagnosticDispatchCount()-old;if(!dispatch_per)dispatch_per=delta;else if(dispatch_per!=delta)throw std::runtime_error("dispatch/frame changed");};''');s=s.replace('api.hipEventDestroy(begin);','printf("FUSION_ROUTE dispatch_per_frame=%llu fused_calls=%llu frames_total=%u module=%s\\n",dispatch_per,net.DiagnosticFusedCount(),1+warm+measured,argv[9]);api.hipEventDestroy(begin);');s=s.replace('for(U i=0;i<measured;i++){auto a=', 'for(U i=0;i<measured;i++){auto dc0=net.DiagnosticDispatchCount();auto a=');s=s.replace('auto b=std::chrono::steady_clock::now();float ms=', 'auto b=std::chrono::steady_clock::now();if(net.DiagnosticDispatchCount()-dc0!=dispatch_per)throw std::runtime_error("measured dispatch/frame changed");float ms=');s=s.replace('api.hipEventDestroy(begin);','printf("DOWN_CAPACITY bytes=%zu valid_bytes=%zu\\n",net.DiagnosticDownCapacity(),net.DiagnosticDownValid());api.hipEventDestroy(begin);');s=s.replace('printf("FUSION_ROUTE dispatch_per_frame=', 'if(std::getenv("DLSS5_FUSION_SEQUENCE")){for(size_t ii=0;ii<net.DiagnosticNames().size();ii++)printf("API_FN %zu %s\\n",ii,net.DiagnosticNames()[ii].c_str());}printf("FUSION_ROUTE dispatch_per_frame=');(a.root/'benchmark.cpp').write_text(s)
