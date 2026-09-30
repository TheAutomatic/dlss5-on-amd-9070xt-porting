#!/usr/bin/env bash
# results/c512-xblock-queue-20261001: ceiling probe for the C512 cross-block queue (plan P).
# A = HEAD host unchanged; X = HEAD host + HIP_C512_CEIL: env C512_CEIL=k runs encoder C512 blocks 23-30 as eight
# INDEPENDENT bodies (all read block 23's input) round-robin on k extra streams. Output is wrong on purpose:
# timing-only upper bound on what overlapping the eight blocks can buy under the real power wall. Not a candidate.
# Run from repo root; $1 = output dir.
set -euo pipefail; out=${1:?}; tmp=$(mktemp -d)
cp -r src "$tmp/src"; mkdir -p "$tmp/Development"; cp -r Development/HIP "$tmp/Development/HIP"
python3 - "$tmp/Development/HIP/hip_reference_network.h" <<'EOF'
import sys;p=sys.argv[1];s=open(p).read()
old='for(U j=0;j<8;j++){source=Body(source,W/32,H/32,512,shifts[j],23+j,j==7);}'
assert s.count(old)==1
new='''
#if HIP_C512_CEIL
 {static const U ceil_k=[]{const char*e=std::getenv("C512_CEIL");return e?U(std::atoi(e)):0u;}();
 if(ceil_k&&!opt.graph){using WaitFn=int(*)(Handle,Handle,unsigned);static WaitFn wait_event=reinterpret_cast<WaitFn>(GetProcAddress(api.dll,"hipStreamWaitEvent"));if(!wait_event)throw std::runtime_error("hipStreamWaitEvent");
  static std::vector<Handle>aux,ev;if(aux.empty()){aux.resize(ceil_k);for(auto&x:aux)api.Check(api.hipStreamCreate(&x),"ceil stream");ev.resize(ceil_k+1);for(auto&x:ev)api.Check(api.hipEventCreate(&x),"ceil event");std::printf("C512_CEIL k=%u\\n",ceil_k);}
  Handle main_stream=stream;api.Check(api.hipEventRecord(ev[ceil_k],main_stream),"ceil start");Tensor in0=source;std::vector<Tensor>keep;
  for(U j=0;j<ceil_k;j++)api.Check(wait_event(aux[j],ev[ceil_k],0),"ceil wait start");
  for(U j=0;j<8;j++){stream=aux[j%ceil_k];keep.push_back(Body(in0,W/32,H/32,512,shifts[j],23+j,j==7));stream=main_stream;}
  for(U j=0;j<ceil_k;j++){api.Check(api.hipEventRecord(ev[j],aux[j]),"ceil end");api.Check(wait_event(main_stream,ev[j],0),"ceil join");}
  source=keep.back();keep.clear();
 }else for(U j=0;j<8;j++){source=Body(source,W/32,H/32,512,shifts[j],23+j,j==7);}}
#else
'''+old+'''
#endif
'''
s=s.replace(old,new);open(p,'w').write(s)
EOF
for v in "A:" "X:-DHIP_C512_CEIL=1"; do n=${v%%:*}; d=${v#*:}
 x86_64-w64-mingw32-g++ -w -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -DHIP_SWIN_PERSISTENT=1 $d -I "$tmp/src" -I "$tmp/Development/HIP" "$tmp/Development/HIP/benchmark_vit_reuse.cpp" -o "$out/benchmark-$n.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid; done
rm -rf "$tmp"; sha256sum "$out"/benchmark-*.exe
