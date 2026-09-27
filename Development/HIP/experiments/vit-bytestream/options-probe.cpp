#include "LmxxfProductionOptions.h"
#include <cassert>
#include <cstdio>
int main(){
 for(unsigned mask=0;mask<4;mask++){
  char text[2]={char('0'+mask),0};_putenv_s("DLSS5_HIP_VIT_STREAM",text);
  auto o=LmxxfProductionOptions(1600,960,"unused","unused");assert(o.vit_stream==mask);assert(hip_reference::VitStreamCompatible(o)==(mask!=0));
  auto f=o;f.vit_proj_n64=false;assert(!hip_reference::VitStreamCompatible(f));
  f=o;f.vit_byte_stream=true;assert(!hip_reference::VitStreamCompatible(f));
  f=o;f.vit_ffn_fused=true;assert(!hip_reference::VitStreamCompatible(f));
  f=o;f.vit_contract_frag=false;assert(!hip_reference::VitStreamCompatible(f));
 }
 for(auto text:{"-1","4","1junk","true"}){_putenv_s("DLSS5_HIP_VIT_STREAM",text);bool rejected=false;try{auto o=LmxxfProductionOptions(1600,960,"unused","unused");}catch(...){rejected=true;}assert(rejected);}
 puts("PASS masks 0..3, incompatible layouts fall back, malformed flags rejected");
}
