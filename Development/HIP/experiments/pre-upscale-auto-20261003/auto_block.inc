/* DLSS5_PRE_UPSCALE = 1 | 0 | auto (2 = FFX-only smoke replay, kept for debugging). Anything unrecognised falls back to 0,
   the post-upscale route -- the previous behaviour. auto (0.42): the first processed frame probes the Stellar Blade
   tail-of-list contract; work recorded after the upscaler dispatch in the same list (Forza Horizon 6, Wo Long 2) makes the
   pre-upscale route permanently fall back to the post-upscale route instead of dying as a fatal passthrough. */
inline constexpr int kModeAuto=3;
inline int RequestedMode(){
 const wchar_t*v=_wgetenv(L"DLSS5_PRE_UPSCALE");if(v)return !wcscmp(v,L"1")?1:!wcscmp(v,L"2")?2:!wcscmp(v,L"auto")?kModeAuto:0;
 static int configured=[](){int mode=0;for(const std::string&cfg_line:NativeConfigFileLines()){const char*line=cfg_line.c_str();{if(!strcmp(line,"DLSS5_PRE_UPSCALE=1"))mode=1;else if(!strcmp(line,"DLSS5_PRE_UPSCALE=2"))mode=2;else if(!strcmp(line,"DLSS5_PRE_UPSCALE=auto"))mode=kModeAuto;else if(!strcmp(line,"DLSS5_PRE_UPSCALE=0"))mode=0;}}return mode;}();return configured;
}
inline std::atomic<int>&AutoDecision(){static std::atomic<int>d{0};return d;} /* 0 = undecided, 1 = pre-upscale confirmed, 2 = fell back to post */
inline int Mode(){
 const int requested=RequestedMode();
 if(requested!=kModeAuto)return requested;
 return AutoDecision().load()==2?0:1;
}
/* Sticky first-frame probe, kept free of D3D12 so a host-path unit test can drive it: called once per processed job
   until the decision lands. following_work = draw/dispatch recorded after the captured upscaler dispatch in the same list. */
inline int AutoDecide(bool following_work){
 if(RequestedMode()!=kModeAuto||AutoDecision().load())return Mode();
 AutoDecision().store(following_work?2:1);
 return Mode();
}
inline bool Enabled(){return Mode()!=0;}
