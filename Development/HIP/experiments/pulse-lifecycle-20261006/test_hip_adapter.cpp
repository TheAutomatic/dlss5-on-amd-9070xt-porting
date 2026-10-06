#include "../../submit_pulse_hip.h"
#include <cassert>
#include <cstdint>
#include <iostream>
#include <string>
#include <vector>
namespace {
struct State {std::string fail;int tls=9,owner=2,creates=0,destroys=0,records=0;bool pending=false;std::vector<std::string> calls;} s;
void* stream=reinterpret_cast<void*>(std::uintptr_t(16));
int hit(const char*n){s.calls.emplace_back(n);return s.fail==n?7:0;}
int select(int device){int status=hit("select");if(!status)s.tls=device;return status;}
int create(void**h){assert(s.tls==s.owner);int status=hit("create");if(!status)*h=reinterpret_cast<void*>(std::uintptr_t(++s.creates));return status;}
int record(void*h,void*q){assert(h&&q==stream&&s.tls==s.owner);s.pending=true;++s.records;return hit("record");}
int drain(void*q){assert(q==stream&&s.tls==s.owner);int status=hit("drain");if(!status)s.pending=false;return status;}
int destroy(void*h){assert(h&&s.tls==s.owner&&!s.pending);int status=hit("destroy");if(!status)++s.destroys;return status;}
hip_reference::HipSubmitPulseOps ops(){hip_reference::HipSubmitPulseOps o;o.owner=s.owner;o.stream=&stream;o.set_device=select;o.event_create=create;o.event_record=record;o.stream_sync=drain;o.event_destroy=destroy;return o;}
}
int main(){
 for(std::string fail:{"","create","record","select","drain","destroy"}){
  s=State{};auto o=ops();hip_reference::SubmitPulseLease<hip_reference::HipSubmitPulseOps> p(o);
  // Select failure here exercises create-time TLS boundary. Cleanup select is separately tested.
  s.fail=fail;bool active=p.Configure(true,true,1,0);
  int old_nn=0;p.Record();++old_nn;p.Record();++old_nn;assert(old_nn==2);
  if(fail=="create"||fail=="select")assert(!active&&s.creates==0);
  if(fail=="record")assert(!p.Active()&&s.records==1);
  s.tls=9;bool closed=p.Close();if(!closed)assert(p.HasHandles());
  s.fail.clear();assert(p.Close());assert(s.creates==s.destroys);
 }
 {s=State{};auto o=ops();hip_reference::SubmitPulseLease<hip_reference::HipSubmitPulseOps> p(o);assert(p.Configure(true,true));p.Record();s.tls=9;s.fail="select";assert(!p.Close()&&p.HasHandles()&&s.pending&&s.destroys==0);s.fail.clear();assert(p.Close()&&s.tls==s.owner);}
 for(int missing=0;missing<6;++missing){s=State{};auto o=ops();switch(missing){case 0:o.event_create=nullptr;break;case 1:o.event_record=nullptr;break;case 2:o.stream_sync=nullptr;break;case 3:o.event_destroy=nullptr;break;case 4:o.stream=nullptr;break;case 5:o.set_device=nullptr;break;}hip_reference::SubmitPulseLease<hip_reference::HipSubmitPulseOps> p(o);assert(!p.Configure(true,true)&&!p.HasHandles()&&s.creates==0);}
 {s=State{};auto o=ops();hip_reference::SubmitPulseLease<hip_reference::HipSubmitPulseOps> p(o);assert(!p.Configure(true,true,1,2)&&s.creates==0);}
 std::cout<<"PASS actual HipSubmitPulseOps: 6 failure cases, cleanup TLS failure, 6 missing ABI entries, flags2 rejection\n";
}
