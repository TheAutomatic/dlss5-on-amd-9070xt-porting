# Independent hardware counter window comparability (CPU only)

Existing HIP5115b43d and M cd7cbdb6 traces: independent audit.py reads actual RDF and derived tables; shared parser untouched, no GPU. comparison.json preserves actual provider metadata/config/timestamp summaries and ratios.

Passed gates: both SystemInfo JSON1949B identical, RX9070XT/index0/PCIbus4/LUID same, AMD driver26.10.07.02 same;31 DerivedSpmCtr index/name/kind/unit/reference/description identical;36 rawcounter IDs/instances same; sampleFrequency4096, SPM128MB, SQTT75MB/seMask1/instruction&exec tokensfalse identical. Raw ratio checks both<1.5e−14. Ratio aggregate is100*sum(numerator)/sum(referenced denominator), not unweighted mean of sample ratios. Memorybusy/stall/write/LDS all use counter20 CPbusy cycles; cache ratios use their own referenced request counters.

SystemInfo reports gpuCounterFreq100MHz/CPUQPC10MHz, shaderclock min500MHz/max2.52GHz and memoryclock max1.259GHz. These are metadata/limits, not measured current shader frequencies. Driver peak/restore logs are same requested policy, not independent physical clock read. ClockCalibrationv2 rawfields and SpmSession timestamps preserved; until named same-clock-domain schema is established, H10.28352ms/M9.56192ms conversions remain conditional, never native frame timings.

Actual windows: H13042/count161,5763samples;M9842/count123,5296samples. Both SpmSession PCI262144/flags0/interval4096/countercount1227, timestamp arrays strictly increasing and exactcount/shape. Hdiff160..388/M160..496 rawticks.4096 is GPUcycle sample interval, not expected rawtimestamp tickdelta; varying deltas alone neither prove loss nor prove continuity. Flags0 semantic overflow decode unresolved. Structure/ratio consistency does not establish SPM loss-free; SQTT marker/framedecode is a separate open problem.

Observed memorybusy H87.275/M90.236%, stalled H19.784/M12.944%;busy includes stall, so do not sum them or treat memorybusy as totalGPU/wallbusy. Fetch/write provider volumes include cache/memory effects, not shader load counts or guaranteed externalDRAM bytes; localvideomemory explicitly includes InfinityCache. No bandwidth/frame/instruction-family attribution from window sums. Icache99.381/65.075,L0hit77.317/75.191,L2hit96.863/95.293 are valid named-window observations, not proof of respective performance bottlenecks.

Material bounds only: windowphase not proved equivalent fullframe, actualclock not measured, loss not established, globalhardware counter scope not resolved into process/kernel families. Eachcapture matches its own no-capture/fresh output; crossimplementation raw equality is not required and not claimed. M lacks firstbeforewarm capture validation. Sameprovider/device/config supports comparing observed-window ratios; these unknowns do not make the data unusable, but constrain causal/per-frame claims. No endless audit or recapture is prescribed.

## Budget3 independent check (bd2b98aa)

Actual files /tmp/fullnn-spm-20261006/budget3/{trace.rgp,counters.json} and /tmp/mochi-spm-20261006/budget3/{trace.rgp,counters.json}. audit_budget3.py independently re-reads RDFSystemInfo/SpmSession and provider definitions, leaving shared parser untouched. HIP53594/M96434 both terminal/release with their own captured/no-capture reference output same, original source/assets identity and driver restore logs. These are483/369 render-op budgets, not decoded three-frame identities.

All actual device/driver/SystemInfo,31 definitions/references/units,36counter IDs/instances,4096 sample interval, SQTT+SPM configuration agree both crossimplementation and with Budget1. Actual samples17326/16496, strict timestamp monotonicity/exact chunksize, ratio errors<1.5e−14. sample counts are not forcibly3×Budget1; no continuity/overflow inference from that alone. Full RDFSystemInfo and timing/calibration/rawflags copied in budget3-comparison.json.

| Observed ratio | HIP B1 → B3 | M B1 → B3 |
|---|---|---|
| Memory unit busy |87.2752→89.8158% (+2.5406pp)|90.2365→90.2050% (−.0315pp)|
| Memory unit stalled |19.7841→20.3489% (+.5648pp)|12.9436→12.9225% (−.0212pp)|
| Write unit stalled |.8792→.9441% (+.0649pp)|.7328→.7171% (−.0157pp)|

All cache ratios change≤.103pp; LDSbank HIP0→0, M.5052→.5016. HIPminusM memory-stalled gap6.8404pp→7.4264pp. Thus higher HIP stalled-cycle fraction is robust to this one budget expansion; memorybusy values themselves are less invariant on HIP. It supports an observed-window supply/dependency hypothesis, not proof of per-frame causal bottleneck, bandwidth, native timing or universal repeated-run stability. Busy includes stall; fractions share CPbusy denominator, not framewalltime. Current unexplained native gap cannot be partitioned by multiplying these percentages.

Remaining actualclock/SPMloss/SQTTloss/framephase bounds remain explicit and do not require endless token-decoder work to retain this limited observation. No new capture/GPU/driver/config/installation. Wait for new actual instruction-dependency evidence before implementation candidates; no rerun of negative routes.
