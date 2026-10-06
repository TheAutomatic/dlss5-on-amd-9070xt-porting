from pathlib import Path
import shutil,json,hashlib
root=Path('/tmp/vit-m32-grid-20261006');root.mkdir(exist_ok=True)
snapshot=Path('/tmp/c512-den-actual-20261006')
for name in ['hip_reference_network.h','native_hip_env_options.h','production_options.generated.h']:shutil.copy(snapshot/name,root/name)
p=root/'hip_reference_network.h';s=p.read_text();needle='unsigned gg=unsigned(groups?groups:(count+255ull)/256);'
assert s.count(needle)==1
patch=needle+r'''if(module=="deep_fast"&&kernel=="vit_attention_fused_640_bytein_bout"&&count==640u*512u&&threads==32&&std::getenv("DLSS5_LAB_QB32_GRID")&&std::string(std::getenv("DLSS5_LAB_QB32_GRID"))=="1"){if(gg!=1280)throw std::runtime_error("QB32 original grid changed");gg=640;if(repeat==0)fprintf(stderr,"QB32_GRID node=%s module=%s original=1280 actual=640 threads=32 count=%u\n",name,module.c_str(),unsigned(count));}'''
s=s.replace(needle,patch);p.write_text(s)
for source,target in [('Development/HIP/experiments/c512-den-repeat-20261006/benchmark1088.cpp','benchmark.cpp'),('Development/HIP/experiments/c32-direct-feature-20261006/whole_diag.cpp','whole_diag.cpp')]:shutil.copy(source,root/target)
(root/'source-receipt.json').write_text(json.dumps({'scope':'onlydeep_fast:640byteinbout/count327680/threads32; explicitLABgrid1','hashes':{x.name:hashlib.sha256(x.read_bytes()).hexdigest() for x in root.glob('*') if x.is_file()}},indent=2))
