# CPU statistical audit of H900 formal p99

No new performance rounds, no CSV edits, no new candidate/kernel/default or proposed numeric tolerance. OriginalthreeO2/NET0NativeGameFrame formal datasets,320frames discard80:240steady/slot,480/arm/round,1440/armpooled. Allcoldframes retained inoriginalCSV;48first/last frameSHA equality remains. Prior formal stopped strictly onpositiveR3 remains historical event; this audit corrects the claim that its sign establishes physicaltailregression.

Actual originalstaticexe steady_clock::now disassembly calls gettimeofday→getntptimeofday, then timeval seconds/microseconds multiplied1000 into nominalnanoseconds. gettimeofday narrows nanos to integerµs; although declaredchrono period1ns and CSV%.6fms=1ns displayprecision, measurements here are integerµs. ActualCSVallsteadyvalues integerµs verified. SamecompilerO2staticclockCPUprobe10000reads min/gcd1000ns,9600zero/0negative. QPFhardware10MHz/100ns/min1tick is separatelyread; it is **not** the wallclock path used bythisoriginalexe. UnderlyingFileTime path may use preciseSystemTime, stillµstruncatedbeforeelapsed. No futuremonotonic/systemadjustment guarantee inferred from shortprobe.

|Round|A0 p99 ms|A3 p99 ms|H1 p99 ms|H2 p99 ms|A3−A0 µs|Merged H−A µs|
|---|---:|---:|---:|---:|---:|---:|
|1|7.344510|7.308770|7.229930|7.187440|−35.74|−116.56|
|2|7.299510|7.347270|7.269780|7.227010|+47.76|−78.77|
|3|7.252270|7.295580|7.255740|7.256060|+43.31|+0.14|

R3 exactDecimalp99linear = rank474.21zero-based (=475/476orderstats), weight.21. A endpoints7255/7326µs→7269.91µs; H7269/7274→7270.05µs. Lowerendpoint H−A+14µs, upper−52µs; interpolation(.79×14+.21×−52)=+0.14µs exactly. It is **not floatingpoint arithmetic error**, but a fractionalestimate formed from integerµs samples with71µs/5µs adjacentgaps. Quantilerankconventions can give differing signs; do not select favorablemethod or silently replace existinglinear gate. Onlyaboutfiveupper-tailobservations per480arm determine each99percentile, with serialsamples/visiblecontrolprocess drift; no iidclaim or precisionCI inferred.

Allthreepooled linearp99: A7333.44µs (7331/7335,w.61), H7258.86µs (7243/7269,w.61), difference−74.58µs. This uses everyroundincludingR3, not cherry-pick; it is additionaldescriptive evidence, not retroactive replacement forperroundcriteria.

Interpretation: +0.14µs cannotbyitselfestablish trueslowertail at thisclockresolution. Integerµs timestamptruncation can change eachmeasuredinterval bylessthan1µs; empiricalquantile isboundedbythemaxperturbation, giving aconservative±2µs differenceuncertaintyfromquantizationalone, containingzero forR3. This is a derivedinstrumenterrorbound, **not** a newlychosenacceptance margin. Also sparsep99rank/endpoints cross, andAcontrolp99drift35–48µs exceeds.14µs. ThusR3is compatiblewithmeasurement-leveltie/unresolvedtail, notproof ofphysicalequivalence, andnot formalstatisticalequivalencewithoutaprespecifiedmargin/assumptions. Avg gains inallthree andpooledtailgain supportcontinuingmath/compatibilitygates ifrootchooses; productionacceptance remainsrootdecision.

1152short +73.99µs is a distinctdataset wellbeyondthis1µsquantization scale; its negativegate stayssealed andisnot waivedbythis900audit. No future/allgames/tailsafety proof;900doesnotcomplete900/1080goal.
