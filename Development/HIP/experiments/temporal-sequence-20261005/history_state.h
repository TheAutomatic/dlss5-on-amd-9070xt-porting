#pragma once
#include <cstdint>
#include <stdexcept>
// Experimental MP1 lease policy, not a reconstruction of the private NGX API.
namespace temporal_experiment {
struct Shape {
 unsigned width{}, valid_height{}, processing_height{};
 bool operator==(const Shape& b)const{return width==b.width&&valid_height==b.valid_height&&processing_height==b.processing_height;}
 void Validate()const{
  // The current software warp implements one bottom mirror, no width padding.
  if(width<2||width>16384||valid_height>16384||std::uint64_t(width)*processing_height>(1ull<<26)||valid_height<2||processing_height<valid_height||std::uint64_t(processing_height)>2ull*valid_height-1)
   throw std::runtime_error("shape outside experimental single-mirror contract");
 }
};
enum class MissingMotion { StoreSpatialFallback, InvalidateUntilMotion };
struct Lease {bool use_history{}; unsigned seed{},read_slot{},write_slot{};std::uint64_t generation{};};
class HistoryState {
 Shape shape{};bool allocated{},ready{},pending{};unsigned write{},counter{};
 std::uint64_t generation{};Lease lease{};bool motion{};
 MissingMotion missing;
public:
 explicit HistoryState(MissingMotion policy=MissingMotion::StoreSpatialFallback):missing(policy){}
 Lease Begin(Shape next,bool reset,bool motion_valid,bool temporal,bool counter_seed){
  if(pending)throw std::runtime_error("history frame already pending");
  next.Validate();
  if(!allocated||!(shape==next)||reset){shape=next;allocated=true;ready=false;counter=0;++generation;}
  motion=motion_valid;
  lease={temporal&&ready&&motion_valid&&!reset,counter_seed?counter:0,write^1u,write,generation};
  pending=true;return lease;
 }
 void Commit(bool queue_completed){
  if(!pending)throw std::runtime_error("history commit without frame");
  if(!queue_completed)throw std::runtime_error("history cannot publish before queue completion");
  ready=motion||missing==MissingMotion::StoreSpatialFallback;
  write^=1u;++counter;pending=false;
 }
 void Abort(){if(!pending)throw std::runtime_error("history abort without frame");pending=false;ready=false;counter=0;++generation;}
};
}
