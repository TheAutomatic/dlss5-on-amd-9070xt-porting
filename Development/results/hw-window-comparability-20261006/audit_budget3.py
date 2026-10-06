"""Independent read-only RDF/derived comparability; no edits to shared parser."""
from pathlib import Path
import json,struct,hashlib,collections
out=Path(__file__).parent;data={}
for name,folder in [('HIP','fullnn'),('M','mochi')]:
 root=Path('/tmp/'+folder+'-spm-20261006/budget3');j=json.loads((root/'counters.json').read_text());b=(root/'trace.rgp').read_bytes();off,size=struct.unpack_from('<QQ',b,16);parts={}
 for p in range(off,off+size,64):
  n,z,v,ho,hs,do,ds,raw=struct.unpack_from('<16sIIQQQQQ',b,p);n=n.rstrip(b'\0').decode()
  if n in('SystemInfo','AsicInfo','ClockCalibration','SpmSession'):
   assert z==0;parts[n]=(v,b[ho:ho+hs],b[do:do+ds])
 sys=json.loads(parts['SystemInfo'][2]);h=parts['SpmSession'][1];pci,flags,interval,count,nctr=struct.unpack('<5I',h);ts=struct.unpack('<'+str(count)+'Q',parts['SpmSession'][2]);d=[y-x for x,y in zip(ts,ts[1:])];assert count==j['sample_count']and interval==j['sample_interval']and all(x>0 for x in d)
 gpu=sys['gpus'][0];freq=gpu['asic']['gpuCounterFreq'];rows={x['name']:x for x in j['counters']if 'weighted_percent'in x};defs=[{k:r[k]for k in('index','name','kind','unit','references','description')}for r in j['counters']];conf=j['trace_config'];exp=next(x['config']for x in conf['sources']if x['name']=='gpuperfexp');ratio_max=max(j['ratio_checks'].values());assert ratio_max<1e-5
 data[name]={'traceSHA':hashlib.sha256(b).hexdigest(),'SystemInfo':sys,'system_jsonSHA':hashlib.sha256(parts['SystemInfo'][2]).hexdigest(),'AsicInfoSHA':hashlib.sha256(parts['AsicInfo'][2]).hexdigest(),'api_data':j['api_data'],'derived_definitions':defs,'gpuperfexp_config':exp,'controller':conf['controller'],'sample_count':count,'spm_header':{'pci':pci,'flags':flags,'interval':interval,'counter_count':nctr},'timestamps':{'first':ts[0],'last':ts[-1],'delta':ts[-1]-ts[0],'min_diff':min(d),'max_diff':max(d),'most_common_diffs':collections.Counter(d).most_common(8),'strictly_increasing':True,'time_ms_IF_GPU_COUNTER_DOMAIN_CONFIRMED':(ts[-1]-ts[0])/freq*1000},'ClockCalibration_v2_raw_3u64':list(struct.unpack('<3Q',parts['ClockCalibration'][2])),'ratios':{k:v['weighted_percent']for k,v in rows.items()},'raw_ratio_check_max_error':ratio_max}
H,M=data['HIP'],data['M'];report={'gates':{'SystemInfo_exactsame':H['system_jsonSHA']==M['system_jsonSHA'],'derived31_definitions_exactsame':H['derived_definitions']==M['derived_definitions'],'gpuperfexp_exactsame':H['gpuperfexp_config']==M['gpuperfexp_config'],'spm_interval_same':H['spm_header']['interval']==M['spm_header']['interval'],'pci_same':H['spm_header']['pci']==M['spm_header']['pci']},'traces':data,'interpretation':'same provider/device/config and same raw denominators permits observed-window ratio contrast; frame phase,actual shaderclock,SPM loss,ClockCalibration named schema not established; no perframe/DRAM bandwidth or bottleneck attribution'}
(out/'budget3-comparison.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report['gates'],indent=2))
