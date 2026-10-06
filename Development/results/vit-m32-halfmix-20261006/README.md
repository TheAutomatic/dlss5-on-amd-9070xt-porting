# QB32 × half-score / 64-key half-den interaction

Research only; intentional mathematical change, no production integration. Old M32 artifact f3e32bed used FP32 affine score and F32 WMMA denominator, so this exact interaction was absent. Historical M32 and B/C16 negative results remain valid.

Canonical COMGR handle21602 old entire ELF matches stock11a25ae3; new8d5e91fe changes only640-bytein-bout, other77 functions and78-export ABI unchanged. New82VGPR/14SGPR,0LDS/private/spill; current16-query68VGPR, historical32-query95. No occupancy or speed inference. Score uses actual packed half FMA, denominator half tree; QK/AV remain F32, original K/V sharing retained. No TR or producer change.

Primitive gold99444 CPU /82714 GPU passed three non-symmetric finite FP8 inputs (including signed zero): independent same-math16-query reference vs32-query candidate, each655360 output bytes, byte differences0 and NaN codes0. This validates query pairing, sharedKV and output addressing under the reference math. Primitive compiledLLVM23; canonical wholeNN repeat/finite and relative-old numerical error are still required. No originalNV accuracy claim; no performance measurement.
