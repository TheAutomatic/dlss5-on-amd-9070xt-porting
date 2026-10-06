#include "../../submit_pulse.h"
#include <cassert>
#include <iostream>
#include <string>
#include <vector>
#include <stdexcept>
struct Ops {
 using Handle=int;std::string fail;std::vector<std::string> calls;int device=9,owner=2,created=0,recorded=0,destroyed=0;bool live=false;
 int call(std::string n)noexcept{calls.push_back(n);return n==fail?7:0;}
 int select_owner()noexcept{int s=call(live?"cleanup_owner":"owner");if(!s)device=owner;return s;}
 int supported(unsigned)noexcept{return call("export");}
 int create(int*h,unsigned)noexcept{assert(device==owner);int s=call("create"+std::to_string(created));if(!s)*h=++created;return s;}
 int record(int)noexcept{assert(device==owner);live=true;return call("record"+std::to_string(recorded++));}
 int drain()noexcept{assert(device==owner);int s=call("drain");if(!s)live=false;return s;}
 int destroy(int h)noexcept{assert(device==owner&&!live);int s=call("destroy"+std::to_string(h));if(!s)++destroyed;return s;}
 void log(const char*n,int)noexcept{calls.push_back(std::string("log:")+n);}
};
int main(){
 for(unsigned count:{1u,2u})for(std::string fail:{"","export","create0","create1","record0","record1","drain","cleanup_owner","destroy1"}){
  Ops o;o.fail=fail;
  {hip_reference::SubmitPulseLease<Ops> p(o);p.Configure(true,true,count);int old_nn=0;
   p.Record();++old_nn;p.Record();++old_nn;assert(old_nn==2);
   bool closed=p.Close();if(!closed)assert(p.HasHandles());else assert(!p.HasHandles());
   // Retry retained leases after injected error is removed, with unrelated TLS.
   o.fail.clear();o.device=9;assert(p.Close());assert(!p.HasHandles());
  }assert(o.created==o.destroyed);
 }
 for(bool requested:{false,true})for(bool eligible:{false,true}){
  Ops o;{hip_reference::SubmitPulseLease<Ops> p(o);assert(p.Configure(requested,eligible)==(requested&&eligible));p.Record();}
  assert(o.created==o.destroyed);if(!requested||!eligible)assert(o.calls.empty());
 }
 {Ops o;try{hip_reference::SubmitPulseLease<Ops> p(o);assert(p.Configure(true,true,2));p.Record();o.device=9;throw std::runtime_error("later ctor failure");}catch(const std::runtime_error&){}assert(o.destroyed==2&&!o.live&&o.device==o.owner);}
 {Ops o;hip_reference::SubmitPulseLease<Ops> p(o);assert(!p.Configure(true,true,3));assert(!p.HasHandles());}
 std::cout<<"PASS: actual shared helper 18 failure/mode cases, 4 eligibility combinations, later-constructor RAII and invalid count\n";
}
