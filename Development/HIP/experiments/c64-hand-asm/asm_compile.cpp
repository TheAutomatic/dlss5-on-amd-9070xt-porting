// asm_compile.exe output.hsaco input.s [gfx1200|gfx1201]
// Assembles AMDGCN assembly (e.g. the .hsaco.s that rtc_compile emits) with the driver's amd_comgr_3.dll and links it
// into a loadable code object. No SDK, no GPU needed. Actions: ASSEMBLE_SOURCE_TO_RELOCATABLE (8), LINK_RELOCATABLE_TO_EXECUTABLE (7).
#include <windows.h>
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <vector>
#include <string>
#include <fstream>
#include <stdexcept>
struct Handle{uint64_t value{};};
template<class T>T sym(HMODULE h,const char*n){auto p=GetProcAddress(h,n);if(!p)throw std::runtime_error(std::string("missing export ")+n);return reinterpret_cast<T>(p);}
static void check(int s,const char*n){if(s)throw std::runtime_error(std::string(n)+" status="+std::to_string(s));}
int main(int argc,char**argv){try{
 if(argc<3)return 2;std::string target=argc>3?argv[3]:"gfx1201";
 std::ifstream f(argv[2],std::ios::binary);if(!f)throw std::runtime_error("input missing");std::string src((std::istreambuf_iterator<char>(f)),{});
 wchar_t dir[MAX_PATH];GetSystemDirectoryW(dir,MAX_PATH);HMODULE h=LoadLibraryW((std::wstring(dir)+L"\\amd_comgr_3.dll").c_str());if(!h)throw std::runtime_error("comgr load");
#define API(name,signature) auto name=sym<signature>(h,"amd_comgr_" #name)
 API(create_data,int(*)(int,Handle*));API(set_data,int(*)(Handle,size_t,const char*));API(set_data_name,int(*)(Handle,const char*));API(create_data_set,int(*)(Handle*));API(data_set_add,int(*)(Handle,Handle));API(create_action_info,int(*)(Handle*));API(action_info_set_language,int(*)(Handle,int));API(action_info_set_isa_name,int(*)(Handle,const char*));API(action_info_set_option_list,int(*)(Handle,const char**,size_t));API(action_info_set_logging,int(*)(Handle,bool));API(do_action,int(*)(int,Handle,Handle,Handle));API(action_data_count,int(*)(Handle,int,size_t*));API(action_data_get_data,int(*)(Handle,int,size_t,Handle*));API(get_data,int(*)(Handle,size_t*,char*));
 Handle in,reloc,exec,data,action;check(create_data_set(&in),"in");check(create_data_set(&reloc),"reloc");check(create_data_set(&exec),"exec");
 check(create_data(1,&data),"data");check(set_data(data,src.size(),src.data()),"set");check(set_data_name(data,"kernel.s"),"name");check(data_set_add(in,data),"add");
 check(create_action_info(&action),"action");check(action_info_set_language(action,0),"lang");check(action_info_set_isa_name(action,("amdgcn-amd-amdhsa--"+target).c_str()),"isa");check(action_info_set_option_list(action,nullptr,0),"opts");check(action_info_set_logging(action,true),"log");
 int st=do_action(8,action,in,reloc);Handle res=reloc;
 if(!st){st=do_action(7,action,reloc,exec);res=exec;}
 for(int kind:{4,5}){size_t n=0;if(action_data_count(res,kind,&n))continue;for(size_t i=0;i<n;i++){Handle x;action_data_get_data(res,kind,i,&x);size_t sz=0;get_data(x,&sz,nullptr);std::vector<char>v(sz+1);get_data(x,&sz,v.data());if(sz>1)printf("COMGR kind%d: %.4000s\n",kind,v.data());}}
 check(st,"assemble/link");size_t cnt=0;check(action_data_count(exec,8,&cnt),"count");if(cnt!=1)throw std::runtime_error("expected one executable");
 Handle x;check(action_data_get_data(exec,8,0,&x),"get");size_t n=0;check(get_data(x,&n,nullptr),"size");std::vector<char>v(n);check(get_data(x,&n,v.data()),"bytes");
 std::ofstream o(argv[1],std::ios::binary);o.write(v.data(),v.size());printf("ELF hsaco saved bytes=%zu\n",n);return 0;
}catch(const std::exception&e){fprintf(stderr,"FAIL %s\n",e.what());return 1;}}
