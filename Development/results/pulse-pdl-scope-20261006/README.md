# CPU audit: C512-start pulse after PDL

Conclusion: cumulative pdl_calls>0 is not a pending-dependency predicate. It wrongly excludes the tested 900 baseline merely because earlier kernels used AnyOrder. There is sufficient source/API evidence to test a single timed marker at this one boundary with baseline PDL1 unchanged. This is authorization for an isolated correctness gate, not production enablement or a claim of Windows driver proof.

## Actual sequence

hip_reference_network.h:775 loops C64/C128/C256 encoder groups, ending C256 block22 and Down(block22-ds). :776 begins block23 C512; pulse is immediately before this loop. C256 900 can use split PDL while 1080 uses wave-owned/persistent paths (:565). Attn PDL exits reset pdl_anyorder=false (:517,:521), and Body's FFN launch resets it immediately after the AnyOrder API (:597). Thus the normal successful call path reaches Down with this launch selector false. Down :605 calls Run on mh_pool_project_group_c256, which :447 selects ordinary hipModuleLaunchKernel. The final Down consumes the preceding C256 output. This is the existing baseline dependency boundary; a pulse is inserted after it, not inside the cooperative PDL producer/consumer chain.

pdl_calls increments on each AnyOrder dispatch (:447) and is never decremented on completion; it is a lifetime statistic. pdl_prev.flags remains a host metadata pointer and also does not prove live work. Neither should replace an actual boundary/scope contract.

## Primary contract and implementation evidence

- HIP event management: https://rocmdocs.amd.com/projects/HIP/en/develop/reference/hip_runtime_api/modules/event_management.html documents record-stream completion/preceding work semantics. Record is asynchronous; no host wait is added here. A marker does not need a matching end event when there is no elapsed-time calculation.
- AnyOrder launch API: https://rocmdocs.amd.com/projects/HIP/en/develop/reference/hip_runtime_api/modules/execution_control.html explicitly allows the flagged kernel to launch in any order. General stream-order promises alone must not be applied to those flagged launches without this qualification.
- Public CLR rocm-7.0.0 hipamd/src/hip_module.cpp:356 maps hipExtAnyOrderLaunch to NDRangeKernelCommand::AnyOrderLaunch. https://raw.githubusercontent.com/ROCm/clr/rocm-7.0.0/hipamd/src/hip_module.cpp
- Public CLR rocclr/device/rocm/rocvirtual.cpp:3605-3612 clears HSA_PACKET_HEADER_BARRIER only for AnyOrder launch; the normal dispatch retains the ordered header. :3753-3783 submitMarker adds a barrier with cache flushes for ordinary event flags. https://raw.githubusercontent.com/ROCm/clr/rocm-7.0.0/rocclr/device/rocm/rocvirtual.cpp
- hip_event.cpp:206-220 constructs EventMarker and defaults to cache-state-invalid unless DisableSystemFence is used. https://raw.githubusercontent.com/ROCm/clr/rocm-7.0.0/hipamd/src/hip_event.cpp

This implementation evidence explains why a normal Down boundary then marker can close prior AnyOrder work. It does not identify the proprietary installed Windows DLL's exact queue implementation. Keep standard flags0; no DisableSystemFence, no extra wait/query, no PDL-off baseline. Negative elapsed timestamps are a timing validity problem; without output failure they do not prove data corruption.

## Minimum experimental scope and gate

Retain graph0/history-off/MP1/full71/current module profile and existing single-host-thread owned device/stream eligibility. At the exact C512 start require pdl_anyorder=false and the known normal C256 Down path; do not reject merely pdl_calls>0. Do not broaden to an arbitrary position, skipped Down, other streams or in-chain pulses. Record counters must be positive and match expected successful frames; resources created without Record are not the tested candidate.

Before performance: in one isolated same-stock baseline/candidate executable, keep PDL1 and compare deterministic nonzero HDR full output bytes for cold first, warm repeat, changed nonzero input/seed, and return to original input/seed. First/last raw readbacks outside timed spans; baseline and candidate both must be finite and byte-identical. Log source identity, geometry, PDL lifetime counter, boundary selector/last ordinary launch, event Record count and errors. One geometry900 gate is enough to establish this Windows configuration before one controlled ABBA; no location/flags grid or repeated failing rounds. A small synthetic producer→AnyOrder consumer→ordered Down→marker→consumer sentinel probe may isolate API ordering if full-frame bytes fail, but is not required ahead of the actual full-frame gate and cannot replace it.

Unresolved question is concrete: does the installed Windows runtime execute this exact ordered boundary + flags0 marker with PDL1 without output changes? The CPU audit cannot answer it; a successful same-domain actual RecordN full-frame gate can. No evidence currently requires disabling baseline PDL to attempt that gate.
