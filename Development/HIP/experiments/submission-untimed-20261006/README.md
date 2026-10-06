# Same-position untimed event pair: prepared candidate, not a flush guarantee

Current isolated C512-start timed-pair screen has a small total-time gain, while
the empty interval itself costs roughly69us. A single StreamQuery regressed.
These are results, not proof of the driver's batching/flush implementation.

prepare.py extends the existing pacing clone with kind6 at exactly the same
C512-encoder23..30 start: two events created once via optional dynamically loaded
hipEventCreateWithFlags(...,0x2=hipEventDisableTiming), then two Record calls.
There is no query, sync, inner ElapsedTime, DisableSystemFence, dependency change,
or location scan. The timed-pair positive control in this clone also skips inner
ElapsedTime; only the original whole-network timed endpoints remain for both.
Events are destroyed after the existing owned-stream synchronization in Network
cleanup. Unsupported symbol/creation explicitly rejects this mode; no install.

Official API states DisableTiming suppresses profiling/timing capability; it
is not a promise of cheaper Windows commands or immediate host-queue submission.
Public clr rocm-7.0.0 event.cpp recordCommand191–205 always creates EventMarker
with markerTs=true; develop event.hpp68–77 explicitly enables marker profiling.
So the proposed flag does NOT establish removal of timestamp work. The exact
Windows DLL implementation is not identified by those public source snapshots.
Only event order and payload-neutral API behavior are assumed; speed must be
measured with unchanged raw output, full GPU span and CPU wall as separate fields.

Primary sources:
- https://rocmdocs.amd.com/projects/HIP/en/develop/reference/hip_runtime_api/modules/event_management.html
- https://raw.githubusercontent.com/ROCm/clr/rocm-7.0.0/hipamd/src/hip_event.cpp
- https://raw.githubusercontent.com/ROCm/clr/develop/hipamd/src/hip_event.hpp

CPU static PE parsing (no LoadLibrary or HIP invocation) of actual9070
System32/amdhip64_7.dll version10.0.3679.0 finds CreateWithFlags/Record/Destroy
exports; DLL SHA f6ac69c322b0ba729fdc2dbdcba8a62a9d52cc2c18e5b690e9ff14258e49c5e7.
That proves entry availability only, not successful flag2 creation or performance.
CPU-only MinGW candidate build has completed. No GPU experiment run in this stage;
root schedules after the current complete-framework timed-pulse first gate.
