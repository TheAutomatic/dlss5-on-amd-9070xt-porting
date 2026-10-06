# C32 normhoist: original complete HDR frame APP first screens

Only kernelH; plain stock overlays identical42 files exceptc32-wave1-fast, no pulse/default/config/install/ZIP changes. Actualstockmodel/modulemanifest checked everywindow. Original production benchmark_vit_reuse.cpp unmodified, canonicalMinGW C++17/O2/static/noisolate; no GetTimings/Poll/SetTag or shadowheaders. NET_TIMING0, GAME/BLACK/SPANprobe0, INPUT_POLL0 as baseline; originalpost_signal hipStreamQuery retained, not counted as timingleak.

Frozen realcapturedinput live-menu-before.f16,1296×720RGBA16F7464960B/HDRmax34.53125, restored eachframe; sourceoriginalcodec→NN900proc960 or1080proc1152→decode/copy. Wallfromafterrestorerflush throughProcessSubmittedFrame andemptyconsumerflush; excludes gamerender/FSR/Present, notnaturalcontinuousgamehistory. ActualadapterRX9070XT logged. Frame0firstread outsidewall timer afterfirstprocess, remainingwarmsteado discard80; edges_only1 nointermediatereadback. Keepcoldframe0~1.15s logs intact, whole160 coldRESULT~14/16ms not compared tosteadysample~7/9ms.

90037009exit0 LOCK_RELEASED, four80steady means A6.981925/H6.934625/H6.9062875/A6.9287375ms; pooledwall−0.034875ms,p99−0.103800ms, avg+p99gatepasses, not bothHaheadbothcontrol. Rawfirst/last allsamefinite, invalid0.

1152(next1080 tier)95706exit0LOCK_RELEASED: A9.6927875/H9.62785/H9.6255/A9.69595ms; mean−0.06769375ms,p99+0.073990ms. Avg+p99gatefails, no1152formalorbadbatchretry. BothscreensindependentofpureNetwork CUDAevents andsinglepulseexperiments; notaddtheirpercentagegains. No actualdefaultadoption. Next900formaldecision ownedroot.

EachGPUwindow owneratomiclock/gamecheck/nootherRTC/D>=100GB/15sgamewatchdog, ownprocess60stimeout. SHA/input/actualmodules/flags/CSV/whole-roundstats andrawhash archived; largeframef16 outsidegit retainedlocaltmp/D. No real game interruption.
