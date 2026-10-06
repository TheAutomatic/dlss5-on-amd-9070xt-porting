"""Shadow constructor-only 900 route; original benchmark/O2, no pulse or timing getters."""
from pathlib import Path
import argparse,subprocess,json,hashlib
p=argparse.ArgumentParser();p.add_argument('out',type=Path);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True);repo=Path(__file__).resolve().parents[4]
subprocess.run(['python3',str(Path(__file__).with_name('prepare_route.py')),str(a.out)],check=True)
p=a.out/'hip_reference_network.h';p.write_text(p.read_text().replace('#include "../../src/native_experimental_history.h"','#include "'+str(repo/'src/native_experimental_history.h')+'"'))
for n in ['native_hip_network.h','native_hip_env_options.h','native_game_frame.h']:
 s=(repo/'src'/n).read_text().replace('#include "../Development/HIP/hip_d3d12_bridge.h"','#include "hip_d3d12_bridge.h"').replace('#include "../Development/HIP/hip_reference_network.h"','#include "hip_reference_network.h"');(a.out/n).write_text(s)
(a.out/'hip_d3d12_bridge.h').write_text((repo/'Development/HIP/hip_d3d12_bridge.h').read_text())
(a.out/'benchmark.cpp').write_text((repo/'Development/HIP/benchmark_vit_reuse.cpp').read_text())
files=['hip_reference_network.h','native_hip_network.h','native_hip_env_options.h','native_game_frame.h','hip_d3d12_bridge.h','benchmark.cpp'];(a.out/'compat-source.json').write_text(json.dumps({n:hashlib.sha256((a.out/n).read_bytes()).hexdigest() for n in files},indent=2)+'\n')
