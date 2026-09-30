# 发布配置来源

正式新包的DLSS5-AMD/native-game-flags.txt来自本目录的版本控制模板：

| 版本 | 默认模板 |
|---|---|
| 普通OptiScaler游戏版 | hip-game-flags.txt |
| Magpie版 | hip-magpie-flags.txt |
| REFramework旧后置版（≤0.27） | hip-re9-flags.txt |
| RE9特殊前置版（0.28起） | re9-presr.ini覆盖OptiScaler.ini；网络选项在LmxxfProductionOptions.h编译 |

改默认值就改相应模板，再打包。普通游戏与RE9模板以2026-09-20已测试配置校对，移除机器专属gain路径；自适应默认0、FPS默认1。Magpie保留独立色彩/历史设置并补齐当前HIP优化参数。游戏内用户修改不反向改变模板。

正式入口Development/tools/optiscaler-stellarblade.ps1 -Action Release、package-magpie-candidate.ps1、RE9/package-0261.ps1直接复制模板，不从旧包/运行游戏继承flags再追加。其他文件仍可使用已校验基础包。package-026.ps1向两个子脚本传递ConfigDirectory。按仓库目录运行时默认定位scripts；若单独上传脚本到Windows，须同步模板并显式传入例如 -ConfigDirectory D:\DLSSNR-Lab\release-config。缺模板报错，不回退。不要只更新远端脚本、遗漏同提交的模板。

Release生成新包使用模板；Repack/FinalizeOnly仅重封已有stage，保留stage内配置。部署升级继续允许保留玩家现有设置，不因重新编译自动覆盖游戏。

Development/native-game-flags.txt是早期测试配置，scripts/game-flags.txt与magpie-flags.txt属旧DX12路线；不作为当前HIP正式发布默认值。

0.27三包统一入口：Development/tools/package-027.ps1，同样通过ConfigDirectory读取本目录模板。普通包从已校验的历史ZIP重新解压，不使用可能被运行过的解压目录；REFramework以已校验0.26.1完整包为底座。


0.28三包入口为Development/tools/package-028.ps1。从逐文件校验的0.27完整ZIP构建；Magpie/普通OptiScaler使用各自flags模板，RE9使用re9-presr.ini覆盖基准OptiScaler.ini，并删除无效的旧native-game-flags.txt/post-present addon。RE9网络默认跳层42,43,46、复用关闭，旧F8/SHOW_FPS/NOTICE不适用；细节/颜色强度在OptiScaler菜单调，范围0～1。包内中文/英文说明来自scripts/package-notes/。打包不读取游戏个人配置。

0.28.1仅重打RE9专用包，入口Development/tools/package-0281-re9.ps1；采用74b8a67边界/恢复修复候选，其他两包维持0.28。新包验证通过后撤下本地RE9 0.28整包及其README下载入口。

| `DLSS5_PRE_UPSCALE_ASYNC` | `auto` (regular template) / `0` (Magpie) | Pre-upscale submission. `auto`: asynchronous except for titles in the add-on's quirk table (Cyberpunk 2077: transient aliased colour buffer needs synchronous submission). `1`/`0` force it. |
| `DLSS5_STRENGTH` | `auto` (regular template) | `transfer,colour` strength, each 0..1 (>1 extrapolates, diagnostic). `auto`: 1,1 except titles in the add-on's quirk table (Cyberpunk 2077: 1,0 -- its FSR colour buffer is pre-tone-map linear, so the network's hue run through the game's LUT turns green ambient brown; luminance-only keeps the detail gain with the game's own hue). |
| `DLSS5_HIP_PDL` | `1` (0.30 templates) | Chain launches of the C64/C128/C256 blocks go out with `hipExtAnyOrderLaunch` and the kernels wait on / publish per-tile flags (programmatic-dependent-launch emulation); the next launch fills the previous one's tail. Bit-exact; 900p about -1.6%, 1080p about -0.6%. `0` restores plain in-order launches. |
| `DLSS5_HIP_VIT_STREAM` | `3` (0.35 templates) | ViT attention writes its AV output as bytes straight into the n64 projection and the contract step uses the half interface (`vit-stream` module); works with adaptive ViT reuse. Bit-exact; 1080p about -1.3%, 900p about even. `0` keeps the previous f32 path; a missing module falls back to it and logs `vit_stream:nomodule`. |
| `DLSS5_FRAME_STATS` | `0` | Seconds per window of a frame-time log appended to `DLSS5-AMD\logs\frame-stats.txt`: frames, fps, frame interval avg/p50/p99/max (0.25 ms buckets up to 100 ms), 1% low, and how many frames the network ran / was bypassed (F6) / initialising / error / unsupported / idle. Interval = time between upscaler dispatches, not GPU time. Regular add-on reads it from the flags file; RE9 runtime from the environment the flags file sets (RE9 counts run/error per EnqueueHip only). `0` = off, no cost. |
| `DLSS5_DIRECT_IO` | `1` (add-on; RE9 runtime does not read it) | Zero-copy I/O around the HIP network, pure data movement (network input/output bytes and the final image are bit-identical). Bit 1: the RGB input pass writes the network input straight into the HIP-shared buffer (skips a 35 MB copy and an unused tile-order copy). Bit 2: on the pre-upscale route, FSR reads the decoder output texture directly instead of a copy of it (RGBA16F colour only; other formats copy as before). History/temporal sessions and `DLSS5_OVERLAP` keep the old path. `3` = both, `0` = previous behaviour. |
| `DLSS5_HIP_WAVE_OWNED` | `0` (source builds after 0.30) | Opt-in single-wave window kernels for the updated Magpie/regular OptiScaler add-on. Requires its matching `c32-wave1.hsaco` and `c64-wave2.hsaco`; compatible production byte-stream settings activate it, incompatible layouts retain the old path. `0` restores prod8 dispatch without loading extra modules. Full runtime regression passed; game FPS validation and release packaging pending. The separate RE9 C API runtime is not enabled by this flag. |

| `DLSS5_HIP_SWIN_RUN` | `1` (0.37 templates, all three: regular / Magpie / RE9; source default 0) | Optional C256 internal-stage ready queue (blocks 16–21 and 49–54) on the 900/1080 tiers, with matching `swin-persistent.hsaco`. Requires the wave-owned byte path and pooled allocations; graph/diagnostic layouts keep the old path. A 100 ms queue timeout aborts pending work, a bounded GPU serial replay restores the stage before consumers, and the instance disables persistence after observing the mapped error flag. Other stages retain their existing PDL behavior. Shared add-on / RE9 option; the RE9 runtime reads it from the environment its flags file sets. Bit-exact; offline 900 about -1.9%, 1080 about -0.6%. `0` restores the previous launches. |
| `DLSS5_HIP_INPUT_POLL` | `0` (source default; not in templates) | Experimental D3D→HIP handoff on the GPU: the game queue writes a marker (`WriteBufferImmediate`) and the HIP stream waits with `hipStreamWaitValue32` instead of the shared fence. `1` = own marker list per frame, `2` = marker recorded into the input-copy list. Start-up self-check and a 200 ms watchdog fall back to the fence path. Shared add-on / RE9 option (bridge header). Bit-exact, but the full-frame replay is 0.01–0.04 ms slower on both tiers (results/handoff-gpu-20260930), so it stays off. |
| `DLSS5_NETWORK_1080_ROWS` | `1152` (all three templates; source default 1152) | Rows the 1080 tier (fixed `DLSS5_NETWORK_HEIGHT=1080` or chosen by `auto`) runs on. `1152` = NVIDIA's geometry (1080 + 72 reflected rows, ViT 30x18 tokens in a 32x20 grid), bit-exact with previous versions. `1088` = **compact, LOSSY, differs from NVIDIA's geometry** (1080 + 8 reflected rows, ViT 30x17 tokens in the same 32x20 grid, post shift unchanged; the geometry Daniel/mochizuki use): faster, the output changes over the whole frame (see `Development/results/geom-1088-20260930`). `DLSS5_NETWORK_HEIGHT=1088` selects the same geometry as a fixed tier. Shared add-on / RE9 runtime option. 900/720 tiers unaffected. |
