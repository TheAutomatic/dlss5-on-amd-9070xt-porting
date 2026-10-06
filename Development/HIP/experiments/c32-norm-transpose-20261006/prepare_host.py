"""Create isolated diagnostic accessor; production header stays untouched."""
from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('out',type=Path);a=p.parse_args();a.out.mkdir(exist_ok=True,parents=True);repo=Path(__file__).resolve().parents[4]
s=(repo/'Development/HIP/hip_reference_network.h').read_text().replace('"../../src/native_experimental_history.h"','"'+str(repo/'src/native_experimental_history.h')+'"').replace('Api& Runtime(){return api;}','Handle C32DiagnosticModule(){return modules.at("c32_wave1");}\n Api& Runtime(){return api;}');(a.out/'hip_reference_network.h').write_text(s)
s=(repo/'src/native_hip_env_options.h').read_text().replace('"../Development/HIP/hip_reference_network.h"','"hip_reference_network.h"');(a.out/'native_hip_env_options.h').write_text(s)
(a.out/'production_options.generated.h').write_text((repo/'Development/results/sync-network-gap1080-20261006/production_options.generated.h').read_text())
