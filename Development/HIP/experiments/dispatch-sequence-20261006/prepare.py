"""Generate isolated first-frame host function collector; no GPU or core edits."""
from pathlib import Path
import runpy,sys,re,shutil
here=Path(__file__).resolve().parent;out=Path(sys.argv[1])
base=here.parent/'fullnn-spm-20261006/prepare.py'
sys.argv=[str(base),str(out)];runpy.run_path(str(base),run_name='__main__')
p=out/'hip_reference_network.h';s=p.read_text()
s=s.replace('unsigned long long DiagnosticDispatchCount()const{return diagnostic_dispatch_count;}','unsigned long long DiagnosticDispatchCount()const{return diagnostic_dispatch_count;} void DiagnosticPrintFirstSequence()const{for(size_t i=0;i<diagnostic_first_sequence.size();++i)std::printf("SPM_FN index=%zu key=%s\\n",i+1,diagnostic_first_sequence[i].c_str());}')
s=s.replace('unsigned long long diagnostic_dispatch_count=0;','unsigned long long diagnostic_dispatch_count=0; std::vector<std::string>diagnostic_first_sequence;std::string diagnostic_layer="prefix/input"; void DiagnosticDispatch(const std::string&key){++diagnostic_dispatch_count;if(diagnostic_dispatch_count<=161)diagnostic_first_sequence.push_back(diagnostic_layer+"|"+key);}')
s=s.replace('++diagnostic_dispatch_count;unsigned gg=','DiagnosticDispatch(std::string(module)+"/"+kernel+"|api="+(pdl_anyorder?"ext_anyorder":"ordinary"));unsigned gg=')
for name,expr in [('C32Chain','fw'),('C32UpBody','std::string("block66/up-body")'),('CompactC512Body','"block"+std::to_string(block)'),('Body','"block"+std::to_string(block)'),('Vit','"block"+std::to_string(block)'),('UpBody','"block"+std::to_string(block)+"/up-body"'),('Down','file+"/down"'),('Up','file+"/up"')]:
 s,n=re.subn(r'((?:Tensor|C32Result)\s+'+name+r'\([^\n]*?\)\{)',lambda m:m[0]+'diagnostic_layer='+expr+';',s);assert n==1,(name,n)
p.write_text(s)
p=out/'swin_persistent_network.h';s=p.read_text();s=s.replace('Tensor SpStage(Tensor input,U w,U h,U c,U first,U layers){','Tensor SpStage(Tensor input,U w,U h,U c,U first,U layers){diagnostic_layer="blocks"+std::to_string(first)+".."+std::to_string(first+layers-1)+"/persistent";')
for key in ['sp_init_pair','sp_init']:
 s=s.replace('++diagnostic_dispatch_count;api.Check(api.hipModuleLaunchKernel(Fn("sp","'+key+'")','DiagnosticDispatch("sp/api=ordinary/'+key+'");api.Check(api.hipModuleLaunchKernel(Fn("sp","'+key+'")')
for var in ['kernel','recovery']:
 s=s.replace('++diagnostic_dispatch_count;api.Check(api.hipModuleLaunchKernel(Fn("sp",'+var+')','DiagnosticDispatch(std::string("sp/api=ordinary/")+'+var+');api.Check(api.hipModuleLaunchKernel(Fn("sp",'+var+')')
assert '++diagnostic_dispatch_count' not in s;p.write_text(s)
p=out/'benchmark.cpp';p.write_text(p.read_text().replace('const auto cold_end=net.DiagnosticDispatchCount();','const auto cold_end=net.DiagnosticDispatchCount();net.DiagnosticPrintFirstSequence();'))
shutil.copy2(here/'production_options.generated.h',out/'production_options.generated.h')
