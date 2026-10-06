evprof.exe = origin/main 640493c9 + Development/HIP/experiments/kernel-map-v3/event-profile-v4-host.patch, then (a) KEV prints
exec (begin->end) AND step (begin->next dispatch's begin) and (b) the SP stage is split into sp_init / sp_run / sp_recover events.
Built: x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -D_WIN32_WINNT=0x0A00 -DHIP_SWIN_PERSISTENT=1 benchmark_vit_reuse.cpp
