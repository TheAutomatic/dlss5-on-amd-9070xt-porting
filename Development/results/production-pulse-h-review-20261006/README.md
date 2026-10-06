# Production pulse + H900 CPU review

Reviewed working draft after H25c2df78; integrator owns modified core/bridge/adapter/env files. No modifications to those files, no GPU, no repeat of previously passed lease/ABI injection tests.

| Area | Result / remaining limit |
|---|---|
| Auto scope | Bridge queries its D3D adapter driver with CheckInterfaceSupport(IDXGIDevice). Auto requires exact bits0x00200000791f0800 and gfx1201; Network additionally requires runtime7/strict profile. Failed driver query cannot validate. Driver bits identify this adapter's reported version, not DLL SHA or all same-version hardware. |
| Explicit1/off0 | 1 bypasses driver validation only, keeps arch/profile/frame rejection, log says unvalidated-driver.0 allocates no pulse handles. No default quality/config file edit. |
| Site | Flag set only after normal C256 Down succeeds; Enqueue clears it each frame. Pulse checks current pdl_anyorder=false, not cumulative lifetime PDL. Geometry only1600x960 or1920x1152, MP1, graph0, no experimental/actual-history input, no adaptive/skip/predict/skin. |
| Resource counters | Create/Record/Destroy successes and failures tracked by actual adapter. Record failure locally disables and retains handles to drain; no per-frame query/sync. Current lifetime/resource log remains available at normal destructor. |
| Device/lifetime | Constructor owns stream/device/API; bridge selects device at warmup/Enqueue/wait. Private bridge-only Configure happens last. Bridge preclose failure preserves whole network/resources. Direct Network never obtains pulse handles; destructor-return would not protect members if that invariant were broken. No proof of multi-device stress or runtime context-loss recovery. |
| Timing dependency | Configure is in Bridge::Create, pulse in RunGraph site. TimingBegin is independently optional; no Get/Poll timing getter controls activation. Existing post-signal query is unchanged, not newly attributed to pulse. |
| H route | Full26 optional module export check; failure unloads candidate and old module remains. Fn resolves all c32_wave1 calls using independent normkey cache when active; MP/graph/experimental changes select whole old route. HasFn probes original legacy module, safe because selected H preserves all26. Non900/FAST0/RTZ original route. |
| Final runtime gate | Draft review does not replace actual host/resmoke, flags0 Record=N, route-active receipt or module payload SHA binding. Joint pulse+H performance is not the sum of separate gains. |

No new blocking code defect found in this review. Strict profile is a requested-options fingerprint, not a cryptographic lock on module content or every actual kernel fallback. SP fault/fallback or arbitrary modules under the same filenames may still match these requested flags; describe scope accordingly and use authoritative actual-route/resmoke logs. Do not claim all same-name payloads or every callback configuration measured merely from the predicate.

H900 formal tail resolution acceptance remains scoped;1152 H stays negative and is not selected. Legacy history on/off correctness evidence is separate from MP1 historyoff performance. No installation, config, package or push.
