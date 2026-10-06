# Minimal C32 norm transpose prototype: static stop

CPU only, generated canonical current c32-wave1-fast source (compile-modules.py.recipe), not cachednoise source. Q/K QKV operands swapped perK0/K16 with zero initialacc; V unchanged. Half square(v*v) and two f16inputFP32accum WMMA remain, swapping squares/ones to transpose norm. Tokenlane norm uses sum[0] and one rsqrt rather than eight elementrsqrt. Current Q/K FP8 fragment restored through one512B pergroupLDS plane; no production edits.

Pure layout check512positions/all256bytecodes: restoredoldfragment0bitdiff. This is byte representation proof only. RawQKV/squares/WMMA sum/rsqrt/normFP8 arithmetic requires realhardwaregold including ±0/Inf and overflow; no GPU was launched, so no equivalence claim. Existing generic transpose probes do not replace this exactstagegold. Shared samewave communication also needs gold before any acceptance.

Authoritative correction: the first A/T `-S` compile omitted the actual object route's `-amdgpu-internalize-symbols` and used a simplified auxiliary target/ffp-contractoff. Its169→193 next_free_vgpr counts are **not actual active ELF resources**; the allocation192→216/occupancy-worse claim is withdrawn. Saved old isa-summary.json and A/T-chain-LLVM23.s are prior CPU snapshots only, superseded by actual-object-isa-summary.json.

Rebuilt exact canonical Windows auxiliaryABI C++14, -real-true16, front→BC then rowopts/no-post-misched/max-ilp backend -c/internalize→link. A actualELF SHA f46b8af25841a9878ce34544f4b3465f71da36fec9f08f48ad33b48f08c1ee52 equals current staged stock c32-wave1-fast byte-for-byte, proving actualFAST1 baseline, not normal row. CW_FAST_NUM3 and RTZ/type macros intact.

ActualELF A/T: chain instructions1030→1119, DS4→40, ordinaryVALU703→695, VGPR131→129; prefix1517→1536, DS23→59, VALU964→961, VGPR128→128; post1524→1544, DS10→46, VALU995→982, VGPR132→128. All rsq16→2, LDS4096→4608, private/spill0, allVGPR round144 allocation. No claimedVGPRoccupancy improvement or regression. Minimal prototype remains staticstop on restoredfragment DS/totalinstruction/LDScost; noGPU and no arithmetic-equivalence claim.

Source T reconstruction prepare.py; A generated from current recipe. Gold SIMDswap order still pending; failed staticcost is not mathematical failure and does not prove allpossibletranspose representations slow. Most concrete useful finding is that saving duplicatedrsqrt alone is insufficient if rebuildingoldfragment costs36extraDSsites.
