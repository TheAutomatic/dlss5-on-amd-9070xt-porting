# 网络前后零拷贝：DLSS5_DIRECT_IO（2026-09-28，分身）

来源：`frame-breakdown-20260928` 的可做项 2、3（输入直写共享缓冲、输出免回拷）。第 4 项（GPU 轮询交接）不做。

## 改了什么

| 位 | 路径 | 以前 | 现在 |
|---|---|---|---|
| 1（默认开） | 输入 | RGB 输入 pass 写私有 `color` 缓冲 **和** 一份 tile 排布副本（HIP 后端从来不读），桥接再 `CopyBufferRegion` 35MB 到 HIP 共享缓冲 | 共享输入缓冲建成可 UAV，输入 pass 直接写它（静息 COMMON），桥接跳过拷贝；tile 副本不写也不分配（`NATIVE_RGB_NO_TILES`） |
| 2（剑星装机开，模板默认关） | 输出 | decode 写私有 RGBA16F 纹理 → `CopyResource` 回 `low` → FSR 读 `low` | pre-upscale 路线直接把 decode 输出纹理交给 FSR（NON_PIXEL_SHADER_RESOURCE），省回拷 |

自动回退：历史/时序会话（Magpie）、`DLSS5_OVERLAP`、非 RGBA16F 颜色（UNORM16/浪人、UNORM8/Magpie、R11G11B10 走缓冲输出+拷贝）保持旧路径。RE9 runtime 不走 NativeGameFrame，不读这个键，行为不变（同一批类的新参数都有默认值，runtime 照常编译）。

文件：`Development/HIP/hip_d3d12_bridge.h`（`RequestDirectInput`/`DirectInput`，RecordInput 跳过拷贝）、`src/native_hip_network.h`、`src/native_game_rgb_input.h`（`tiles_needed`、`RedirectOutput`）、`shaders/native_game_rgb_input.hlsl`、`src/native_game_frame.h`（`NativeDirectIo`、`DirectOutput`、`deliver`）、`src/native_game_oneshot.h`（`Delivered`）、`src/native_pre_upscale.h`（FSR 输入换成 `fed`）、`Development/HIP/benchmark_vit_reuse.cpp`（`DLSS5_BENCH_PLAIN=1`：非时序会话，同剑星）。模板 `scripts/hip-game-flags.txt`、`hip-magpie-flags.txt` 加 `DLSS5_DIRECT_IO=1`，`scripts/CONFIGURATION.md` 一行。

## 验证（离线完整 NativeGameFrame 回放，剑星现场 30 模块与 flags）

**逐位**：9 组 × 12 帧（900/1080 静止与平移、720 平移、900/1080 历史、900/1080 AE），`DLSS5_DIRECT_IO=0` 对 `=1` 每帧 RGB 哈希全同（108 候选帧）；AE 两组决策日志逐字节同；非时序会话（`DLSS5_BENCH_PLAIN=1`，同剑星）与回放原本的时序会话在旧路径下也逐帧同（7 组）。直写路径实际启用 7 次（`native-game-oneshot.txt` 的 `direct_input` 步骤）；历史用例按设计走旧路径。

**计时**（同一 exe、同模块，1000 帧弃前 200，ABBA：槽 0/3 = 旧、1/2 = 直写；wall_ms 为整帧回放墙钟）：

| 批 | 档 | 旧 | 直写 | 差 |
|---|---|---:|---:|---:|
| t1 | 900 | 9.068 | 9.051 | −0.018（−0.19%） |
| t1 | 1080 | 12.423 | 12.406 | −0.017（−0.14%） |
| t2 | 900 | 9.181 | 9.153 | −0.028（−0.30%） |
| t2 | 1080 | 12.492 | 12.441 | −0.050（−0.40%） |

两批四档都是直写更快，但只有 **0.02～0.05ms**，远小于上轮按带宽粗估的 0.1～0.15ms：35MB 拷贝在 9070 上本来就被队列里前后的工作部分掩盖，省掉它换来的主要是少一次 GPU 空泡。输出直交（位 2）省的是一次 16.6MB 纹理拷贝，按同比例估 0.01～0.03ms，只能游戏内看。

结论：纯工程、逐位、稳定为正，但量级小；网络外那约 0.45ms 的主要部分不在拷贝本身，更可能在两次跨 API 交接（第 4 项，fence 由 OS 调度唤醒 vs Daniel 的 GPU 轮询）。

## 剑星装机

已装（`deploy-stellar.ps1 -Io 3`，输入+输出都直写）：add-on `abef6155…`、新 `native_game_rgb_input.hlsl`、flags 加 `DLSS5_DIRECT_IO=3`。备份 `D:\DLSSNR-Lab\zero-copy-io-20260928\backups\stellar-20260928-170538`（含 manifest；`deploy-stellar.ps1 -Restore` 还原到 float FMA 装机状态）。

## 游戏内（待 Zero 本机）

输出直交（位 2）在回放里测不到（回放没有 FSR），只能游戏里看：画面正常、无黑屏/花屏即通过；它交给 FSR 的就是原来被拷进 `low` 的同一张图，逐位同源。

Zero 本机步骤（9070 前，不用 Splashtop；约 3 分钟）：
1. 剑星 1080P 窗口、FSR 原生 AA、F8 切 EXACT。看画面是否正常（位 2 的唯一验收）。
2. 站立不动 30 秒，读黄字小数。
3. 按 **F6**（切原生 FSR 直通），继续站 30 秒；再按 F6 切回，退出游戏。
4. 日志 `DLSS5-AMD\logs\frame-stats.txt`：`bypass=` 非 0 的窗口 = 游戏自身开销 G；17.6 − G 是否 ≈ 12.3（上轮时间账）；顺便看站立 p99 是否回到 ≈18.5ms（区分 Splashtop 与 `MAKE_RESIDENT_EVERY=60`）。
5. 画面异常：flags 改 `DLSS5_DIRECT_IO=1`（只留输入直写）；仍异常则 `deploy-stellar.ps1 -Restore`。

## 复现

`regression.ps1`（`-CorrectnessOnly` / `-TimingOnly -Batch t1|t2`）、`deploy-stellar.ps1`（`-Restore` 还原）。实验根 `D:\DLSSNR-Lab\zero-copy-io-20260928`（assets 为 Magpie 0.23 资产副本 + 新 `native_game_rgb_input.hlsl`，benchmark-zc.exe 由 `benchmark_vit_reuse.cpp` 编）。
