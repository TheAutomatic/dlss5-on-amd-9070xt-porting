from pathlib import Path
p=Path('/tmp/mochizuki-022/hip/c512_m32_deep.inc');s=p.read_text();s='#ifndef C512_WEIGHT_MAJOR\n#define C512_WEIGHT_MAJOR 0\n#endif\n'+s
old='uint first=bid()/8*32,row=bid()%8*64;';assert s.count(old)==1
s=s.replace(old,'''uint nt=(tokens+31)/32;uint first,row;
#if C512_WEIGHT_MAJOR
 if(!nt)return;first=(bid()%nt)*32;row=(bid()/nt)*64;
#else
 first=bid()/8*32;row=bid()%8*64;
#endif
''');p.write_text(s)
p=Path('/tmp/mochizuki-022/hip/c512_m32_mh.inc');s=p.read_text();s='#ifndef C512_WEIGHT_MAJOR\n#define C512_WEIGHT_MAJOR 0\n#endif\n'+s
old='first=block/24*32,col=block%24*64;';assert s.count(old)==2
s=s.replace(old,'''first=0,col=0;
#if C512_WEIGHT_MAJOR
 uint nt=(tokens+31)/32;if(!nt)return;first=(block%nt)*32;col=(block/nt)*64;
#else
 first=block/24*32;col=block%24*64;
#endif
''');p.write_text(s)
