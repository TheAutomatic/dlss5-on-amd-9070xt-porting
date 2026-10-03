// hk_test: exercises NativeHotFlags::CycleMultiPass + reload on a DLSS5-AMD folder next to the exe.
#include "native_hot_flags.h"
#include <iostream>
int main(int argc,char**argv){
 auto&h=NativeHotFlags::Instance();h.Get(); // stamp
 unsigned cur=argc>1?unsigned(atoi(argv[1])):1;
 unsigned n=NativeHotFlags::CycleMultiPass(cur);
 Sleep(1100);auto v=h.Get();
 std::cout<<"next="<<n<<" reload_gen="<<v.generation<<" multi_pass="<<v.multi_pass<<" hotkey_vk="<<NativeHotFlags::HotkeyCode()<<"\n";
}
