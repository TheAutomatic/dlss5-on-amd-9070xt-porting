# C2 640-only key permutation, CPU evidence

C numerical contract preserved by representation design, not yet hardware gold: permute Krow4..7/8..11 before QK, K0/K16 reduction and Q row unchanged. Half probabilities physical lowgroup keys0..3/8..11, highgroup4..7/12..15; pair locally then accumulate fourtile partials in half. Two half2 boundary exchanges restore canonical a0..a7 tree. One dword exchange per16tile restores natural P before unchanged V load/AV key order. 640 ten fullchunks only. 400 actual instruction text identical to C.

COMGR21 actual gfx1201 C640405→C2 398 instructions, ordinary VALU247→251 (exclude4WMMA), DSstatic4→3; dynamic64key DS16→6 (4 P restore +2 boundary). VGPR62→56, SGPR15, LDS/private/spills0, kernarg32/wave32; both round72 allocation, no occupancy gain. Initial loose substring VALU282 included disassembly comments; withdrawn, authority isa-check.json exact parsed lines. Doublearch compiled, no GPU C2 execution yet. CPU session24644 exit0 LOCK_RELEASED, game/RTC/process/space guards preserved.

Independent natural key eight×640 finite half probabilities: every64prefix and restored P0diff. This tests tree ordering/representation, not WMMA implementation. Trace gold source generated separately from actual C/C2 body; one 32-thread wave, 16queries/head0, zeros/signed checker/spike/signed-zero finite E4M3 fixtures. Trace raw QK logicalkeys, natural FP8 P, each64halfdenprefix, FP32 AV and finalbytes. Both rawQK/AV must bitmatch as well as finalbytes; failure blocks performance. NaN0x7f/0xff excluded. A fourth fixture explicitly alternates legitimate finite signed zero0x00/0x80; the initial description treating0x80 as special/nonfinite was incorrect and withdrawn. Hardware signed-zero trace remains pending. Trace compiledLLVM23 CPU and hostMinGW; COMGR trace and actualgold pending root queue. Traced probes never timing.

No variants/production/deployment changes. CPU C2 object alone is not evidence of improved network speed. B2 gate remains weak and not accepted.

## Actual GPU gold and first screen

2026-10-06 trace COMGR CPU session44001 exit0, then guarded GPU38113 exit0 LOCK_RELEASED. All four fixtures including signedzero have QK/naturalP/denprefix/AV/finalbyte0diff. CPU independently verifies raw trace numeric sections finite. Three signed/zero synthetic matrices are selected probes, not all-matrix proof.

Complete71 common encoded1088/640 A/C2/C2/A, warm80 frames160:8.904404/8.905948/8.911108/8.922194ms; pooled−0.004771ms, p99−0.068848ms, candidates not both ahead of controls. Weak screen, no formal sweep or default acceptance. Fullnetwork relative previous C float-bitdiff0; currentA PSNR52.632604/maxabs0.0335403, not production visual acceptance. CPU separate raw-check.json. First raw beforewarm, no midsequence scan; all repeat0/finite. No deployment. Released queue to integrator1152/untimed.
