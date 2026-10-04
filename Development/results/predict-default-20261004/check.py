from pathlib import Path
import re, subprocess, tempfile
root=Path(__file__).resolve().parents[3]
network=(root/'Development/HIP/hip_reference_network.h').read_text()
hot=(root/'src/native_hot_flags.h').read_text()
func=re.search(r'inline bool MultiPredictFromEnvironment\(\).*?\}',network).group()
expr=re.search(r'v.multi_pass_predict=(.*?);}',hot).group(1)
source='#include <cstdlib>\n#include <cstring>\n#include <cstdio>\n#include <cassert>\n'+func+'\nint hot(const char*m){return '+expr+';}\nint main(){unsetenv("DLSS5_MULTI_PASS_PREDICT");assert(MultiPredictFromEnvironment());'
for value,expected in [('',1),('0',0),('1',1),('2',0),('auto',0)]:
 source+=f'setenv("DLSS5_MULTI_PASS_PREDICT","{value}",1);assert(MultiPredictFromEnvironment()=={expected});assert(hot("{value}")=={expected});'
source+='}\n'
with tempfile.TemporaryDirectory() as tmp:
 p=Path(tmp);(p/'check.cpp').write_text(source)
 subprocess.run(['g++','-std=c++17',str(p/'check.cpp'),'-o',str(p/'check')],check=True)
 subprocess.run([str(p/'check')],check=True)
assert 'if(v.multi_pass_predict<0)v.multi_pass_predict=1;' in hot
assert 'if(multi_pass==3&&multi_predict){' in network
assert 'if(n<1||n>3||n==multi_pass)return;' in network
assert "bool multi_predict=true,multi_skin=false;" in network
for template in ['hip-game-flags.txt','hip-magpie-flags.txt','hip-re9-flags.txt']:
 text=(root/'scripts'/template).read_text()
 assert text.count('DLSS5_MULTI_PASS_PREDICT=1')==1
 for line in text.splitlines():
  if 'Predict pass 3 locally' in line: assert len(line.encode())<=191
stage=(root/'Development/tools/stage-config-layers.ps1').read_text()
assert 'Copy-Item $Template "$Lab\\default-config.txt"' in stage
print('PASS source-extracted CPU startup/hot parser: absent/empty/0/1/invalid; three templates; only MP3 branch; 4/5 unsupported unchanged; staged defaults copied from templates')
