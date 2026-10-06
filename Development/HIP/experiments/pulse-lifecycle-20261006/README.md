# Shared optional event lease CPU injection

Actual production-reusable template: `Development/HIP/submit_pulse.h`. test.cpp includes that header directly; this supersedes the earlier independent Python control model as helper evidence. No HIP/GPU runtime calls.

Build/run:

```
g++ -std=c++17 -Wall -Wextra -Werror -fsanitize=address,undefined Development/HIP/experiments/pulse-lifecycle-20261006/test.cpp -o /tmp/pulse-lifecycle-test
/tmp/pulse-lifecycle-test
```

Passed: 18 one/two-event failure-mode cases, 4 requested/eligible combinations, later-constructor exception RAII, invalid count. Failure cases include export/Create0/Create1/Record0/Record1/owner/drain/Destroy. Unsupported one-event-only faults are naturally not called in that mode. Successful cleanup balances mock creates/destroys. Failure cleanup retains handles and succeeds on explicit retry after injection clears, including changed simulated TLS device. Destroy is asserted never to occur before owned-stream drain.

Adapter requirements: Ops must outlive lease and contain owning device/stream/API, all methods noexcept with integer status. The owning device is selected at create/cleanup; hot Record requires the caller's established owner selection. Configure must be called only after stream exists; requested=false or eligible=false allocates nothing. Configure is once per lease, not lazy retry each frame. Count1 is one independent event record; count2 is two independent records, neither needs an end/timing measurement. No event synchronization/query/elapsed-time inside the helper.

Because Network currently explicitly destroys stream/API in its destructor body, member RAII alone is insufficient for normal Network destruction: call lease.Close() before stream teardown. Later constructor failure also requires cleanup before its existing catch destroys stream. Prefer a scope guard whose cleanup precedes that teardown; member lease then sees no handles after successful Close. If cleanup cannot select/drain, retain the corresponding whole owning context/resources under the existing bridge failed-work policy; destroying the stream and then invoking member cleanup is invalid. Final cleanup failure logs and intentionally leaks surviving handles; no resource stress or multi-device runtime success is claimed.

Create errors locally disable without aborting NN. Record errors disable and preserve lease; even the failed first record conservatively marks drain required because partial enqueue cannot be excluded by the portable adapter. Recovery from actual device/runtime failure is not guaranteed: only the existing NN path remains attempted. Graph/PDL/untested profile eligibility belongs to caller; all four requested/eligible combinations are exercised, not a proof those pipelines are safe.

## Actual HIP ABI adapter injection

`test_hip_adapter.cpp` directly includes the integrator's `Development/HIP/submit_pulse_hip.h` and the shared lease; it supplies fake HIP ABI function pointers, not a mirror adapter. Build using the command above with test_hip_adapter.cpp and `/tmp/pulse-hip-adapter-test`.

ASAN/UBSAN PASS: six success/failure cases (Create, Record, select, drain, destroy); cleanup select failure with changed TLS and pending work; six missing ABI/stream entries; flags2 rejection. Assertions bind every Record/drain to the configured stream, Create/drain/Destroy to the owning device, disallow Destroy while pending, verify local-disable Record only happens once, preserve old NN attempts and balance allocations after retry. Actual adapter error log text emitted as expected. Normal flags0 supported; flags2 explicitly unsupported by this adapter.

Review: borrowed API/DLL lifetime and stream pointer storage must outlive the lease. Configure must occur after the pointed-to owned stream is non-null; supported() checks pointer presence, not the pointee. Hot Record deliberately relies on bridge selecting the current TLS device; tests do not add hidden SetDevice into hot Record. The fake ABI cannot establish Windows runtime memory/queue behavior, concurrency safety or multi-device stress.
