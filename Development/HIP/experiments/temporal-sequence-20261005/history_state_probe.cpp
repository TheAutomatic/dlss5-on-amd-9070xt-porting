#include "history_state.h"
#include <cstdio>
using namespace temporal_experiment;
static void require(bool good){if(!good)throw std::runtime_error("state regression");}
template<class F>void rejected(F f){bool caught=false;try{f();}catch(const std::runtime_error&){caught=true;}require(caught);}
int main(){try{
 Shape shape{1920,1080,1152};HistoryState state;
 auto first=state.Begin(shape,true,true,true,true);require(!first.use_history&&first.seed==0&&first.write_slot==0);
 rejected([&]{state.Begin(shape,false,true,true,true);});rejected([&]{state.Commit(false);});state.Commit(true);
 auto next=state.Begin(shape,false,true,true,true);require(next.use_history&&next.seed==1&&next.read_slot==0&&next.write_slot==1);state.Commit(true);
 auto missing=state.Begin(shape,false,false,true,true);require(!missing.use_history&&missing.seed==2);state.Commit(true);
 auto fallback=state.Begin(shape,false,true,true,true);require(fallback.use_history&&fallback.seed==3);state.Commit(true);
 auto reset=state.Begin(shape,true,true,true,true);require(!reset.use_history&&reset.seed==0&&reset.generation>next.generation);state.Commit(true);
 auto resize=state.Begin({2560,1440,1472},false,true,true,true);require(!resize.use_history&&resize.seed==0);state.Abort();
 auto after_failure=state.Begin({2560,1440,1472},false,true,true,true);require(!after_failure.use_history&&after_failure.seed==0);state.Commit(true);
 auto fixed=state.Begin({2560,1440,1472},false,true,true,false);require(fixed.use_history&&fixed.seed==0);state.Commit(true);
 auto spatial=state.Begin({2560,1440,1472},false,true,false,true);require(!spatial.use_history);state.Commit(true);
 rejected([&]{state.Commit(true);});rejected([&]{state.Begin({64,40,80},false,true,true,true);});
 HistoryState invalidate(MissingMotion::InvalidateUntilMotion);
 invalidate.Begin(shape,true,true,true,true);invalidate.Commit(true);invalidate.Begin(shape,false,false,true,true);invalidate.Commit(true);
 auto invalidated=invalidate.Begin(shape,false,true,true,true);require(!invalidated.use_history);invalidate.Commit(true);
 require(invalidate.Begin(shape,false,true,true,true).use_history);invalidate.Commit(true);
 std::puts("CPU_HISTORY_STATE_PASS: leases/reset/resize/failure/missing-MV policy pair; no private-format or GPU parity claim");return 0;
}catch(const std::exception&e){std::fprintf(stderr,"CPU_HISTORY_STATE_FAIL: %s\n",e.what());return 1;}}
