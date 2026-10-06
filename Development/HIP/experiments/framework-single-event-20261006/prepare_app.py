"""O2 APP wall/raw control preparation; no diagnostic timing getter or GPU timer."""
import argparse,subprocess,sys,hashlib,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args()
r=Path(__file__).resolve().parents[4]
subprocess.run([sys.executable,str(Path(__file__).with_name('prepare_safe.py')),str(a.output)],check=True)
# The original persistent Frame caller has no GetTimings/Poll/SetTimingTag.
b=(r/'Development/HIP/benchmark_vit_reuse.cpp').read_text()
for banned in ['GetTimings(','GetStatus(','PollNetworkTiming(','PacingNetworkTiming(','PacingTimingTag(']:assert banned not in b
(a.output/'benchmark.cpp').write_text(b)
p=a.output/'submit_pulse_hip.h';s=p.read_text()
s=s.replace('int owner{};Handle* stream{};', 'int owner{};Handle* stream{};unsigned long long create_calls{},create_ok{},record_calls{},record_ok{},destroy_calls{},destroy_ok{},drain_calls{};')
# Preserve aggregate ABI-entry order by putting counters at the end instead.
s=s.replace('Handle* stream{};unsigned long long create_calls{},create_ok{},record_calls{},record_ok{},destroy_calls{},destroy_ok{},drain_calls{};', 'Handle* stream{};')
s=s.replace('int(*event_destroy)(Handle){};', 'int(*event_destroy)(Handle){};unsigned long long create_calls{},create_ok{},record_calls{},record_ok{},destroy_calls{},destroy_ok{},drain_calls{};')
s=s.replace('return flags||!event_create?801:event_create(handle);', 'if(flags||!event_create)return 801;++create_calls;int result=event_create(handle);create_ok+=result==0;return result;')
s=s.replace('return event_record&&stream?event_record(handle,*stream):801;', 'if(!event_record||!stream)return 801;++record_calls;int result=event_record(handle,*stream);record_ok+=result==0;return result;')
s=s.replace('return stream_sync&&stream?stream_sync(*stream):801;', 'if(!stream_sync||!stream)return 801;++drain_calls;return stream_sync(*stream);')
s=s.replace('return event_destroy?event_destroy(handle):801;', 'if(!event_destroy)return 801;++destroy_calls;int result=event_destroy(handle);destroy_ok+=result==0;return result;')
p.write_text(s)
p=a.output/'hip_reference_network.h';s=p.read_text();needle='api.hipSetDevice(int(opt.device));api.hipStreamSynchronize(stream);experimental_history.reset();';assert s.count(needle)==1
s=s.replace(needle,'''std::fprintf(stderr,"APP_PULSE_RECEIPT create=%llu create_ok=%llu record=%llu record_ok=%llu destroy=%llu destroy_ok=%llu drain=%llu pdl_calls=%u site_visits=%llu attempts=%llu accepted=%llu reject_mask=%u\\n",pulse_ops.create_calls,pulse_ops.create_ok,pulse_ops.record_calls,pulse_ops.record_ok,pulse_ops.destroy_calls,pulse_ops.destroy_ok,pulse_ops.drain_calls,pdl_calls,pulse_site_visits,pulse_record_attempts,pulse_record_accepted,pulse_last_reject_mask);'''+needle,1);p.write_text(s)
p=a.output/'hip_d3d12_bridge.h';s=p.read_text()
s=s.replace('bool timing_on{};', 'unsigned long long app_timer_creates{},app_timer_records{},app_timer_queries{},app_post_queries{},app_poll_records{};bool timing_on{};',1)
s=s.replace('const int q=timing_query(timing_end[k]);', 'const int q=(++app_timer_queries,timing_query(timing_end[k]));')
s=s.replace('api.hipEventCreate(&timing_begin[k])', '(++app_timer_creates,api.hipEventCreate(&timing_begin[k]))').replace('api.hipEventCreate(&timing_end[k])', '(++app_timer_creates,api.hipEventCreate(&timing_end[k]))')
s=s.replace('network->Runtime().hipEventRecord(timing_begin[timing_next],network->Stream())', '(++app_timer_records,network->Runtime().hipEventRecord(timing_begin[timing_next],network->Stream()))').replace('network->Runtime().hipEventRecord(timing_end[k],network->Stream())', '(++app_timer_records,network->Runtime().hipEventRecord(timing_end[k],network->Stream()))')
s=s.replace('api.hipEventRecord(poll_evt[slot],network->Stream())', '(++app_poll_records,api.hipEventRecord(poll_evt[slot],network->Stream()))')
s=s.replace('if(post_query)post_query(network->Stream());', 'if(post_query){++app_post_queries;post_query(network->Stream());}',1)
needle='if(!WaitForSubmittedWork()||(network&&!network->CloseSubmitPulse()))return;';assert s.count(needle)==1
s=s.replace(needle,needle+'''std::fprintf(stderr,"APP_DIAGNOSTIC_RECEIPT timer_on=%u timer_creates=%llu timer_records=%llu timer_queries=%llu span_probe=%u poll_records=%llu post_signal_queries=%llu\\n",unsigned(timing_on),app_timer_creates,app_timer_records,app_timer_queries,unsigned(span_probe),app_poll_records,app_post_queries);''',1)
p.write_text(s)
(a.output/'app-source.json').write_text(json.dumps({'scope':'original complete NativeGameFrame caller; O2/static planned; NET_TIMING0; no GetTimings/GetStatus/Poll/SetTag; exit-only counter printing; candidate same old safe1event/samepoint','required_flags':{'DLSS5_NET_TIMING':0,'DLSS5_GAME_PROBE':0,'DLSS5_HIP_SPAN_PROBE':0,'DLSS5_HIP_INPUT_POLL':0},'unchanged_default_post_signal_stream_query':True,'files':{name:hashlib.sha256((a.output/name).read_bytes()).hexdigest() for name in ['benchmark.cpp','submit_pulse_hip.h','hip_reference_network.h','hip_d3d12_bridge.h']}},indent=2)+'\n')
