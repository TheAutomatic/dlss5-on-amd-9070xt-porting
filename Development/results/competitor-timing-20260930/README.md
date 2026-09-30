# 竞品网络速度同机实测（2026-09-30～10-01，9070 XT Windows，只测不改）

**结论先行**：同几何下，**mochizuki 0.0.2.5 Windows 离线网络比我们快约 1.3ms（900）/ 1.8ms（1088 行）**，约快 17～19%；Daniel 0.5.1（无离线 bench，逐核和＋空隙估算）：reference 比我们慢 0.2～1.3ms；fast 档 900 与我们持平、1088 比我们快 1.0～1.6ms。mochizuki 自报的 7.79ms 已复现（7.78～7.86）。

| 家 | 档 / 几何 | 自报 | 同机实测 | 测法 |
|---|---|---:|---:|---|
| mochizuki 0.0.2.5 Win | 1080p → 1920×1088 | 7.79 | **7.81 / 7.86 / 7.86** | 他的离线 bench（下 §1），GPU 时间戳 |
| 〃 | 900p → 1600×960 | — | **5.99 / 6.03 / 6.02** | 〃 |
| 〃 | 4K → 3840×2176 | 28.9 | 29.46 | 〃（一轮） |
| 我们现装 | 900（1600×960） | 7.256（09-30） | **7.267 / 7.343** | HIP 段 span 中位（§3） |
| 〃 | 1080（1920×1152） | 10.065 | **10.051 / 10.101** | 〃 |
| 〃 | 1080 + `ROWS=1088`（1920×1088） | — | **9.647 / 9.673** | 〃 |
| Daniel 0.5.1 reference | 900（1600×960，他 C512 52×32、ViT 448） | — | 逐核和 8.21（扣 42/43/46 后 7.91）；整网估 **≈8.1～8.6** | jobbench 逐核（§2），不含 swin_run |
| Daniel 0.5.1 fast | 900 | — | 逐核和 7.03（扣后 6.77）；整网估 **≈6.8～7.4** | 〃 |
| Daniel 0.5.1 reference | 1080 → 1920×1088 | 0.5.0 游戏日志 11.0 | 逐核和 10.16（扣后 9.83）；整网估 **≈9.9～10.5** | 〃 |
| Daniel 0.5.1 fast | 1080 → 1920×1088 | 0.5.0 游戏日志 9.4～9.8 | 逐核和 8.42（扣后 8.11）；整网估 **≈8.1～8.7** | 〃 |

（ms；"a / b / c" 是各轮。Daniel "整网估"：上沿 = 逐核和 + 我们实测的空隙（900 0.35、1088 0.32ms），下沿 = 上沿 ÷ 他自述 0.5.1 提速（reference 1.06、fast 1.08）；**是估计，不是实测**。）

## 同几何对比

| 几何 | 我们 span | mochizuki | 差 | Daniel ref 估 | Daniel fast 估 |
|---|---:|---:|---:|---:|---:|
| 1600×960 | 7.27～7.34 | 6.02 | mochizuki 快 1.25～1.32（17%） | ≈8.1～8.6（我们快 0.8～1.3） | ≈6.8～7.4（持平，±0.5） |
| 1920×1088 | 9.65～9.67 | 7.81～7.86 | mochizuki 快 1.8（19%） | ≈9.9～10.5（我们快 0.2～0.8） | ≈8.1～8.7（他快 1.0～1.6） |
| 我们 1152 vs 他们 1088 | 10.05～10.10 | 7.81～7.86 | — | — | — |

逐核口径另一个参照：我们 900 逐核和 6.827（hip-roofline，09-30；之后装了三个模块，未重测）vs Daniel 0.5.1 fast 900 扣跳块 6.77、reference 7.91。

## 不可比之处（按影响大小）

1. **口径**：mochizuki 是 `nr_graph` 一个命令缓冲里连跑 500 帧（warmup 50），TOP_OF_PIPE→BOTTOM_OF_PIPE 总时间 ÷ 帧数；帧间有 barrier，但没有逐帧提交/等待，权重与激活在帧间是热的。我们 span 是每帧一个 hipEvent 对（输入等待之后→输出 D2D 拷贝结束，含 0.04ms 拷贝），回放 1000 帧弃 200 的中位。他的口径对他有利，量级估计不超过 0.1～0.3ms，解释不了 1.3～1.8ms。
2. **算术**：三家都不逐位对 NVIDIA。mochizuki fp32 累加、`inversesqrt`/`1.0/x` 由编译器决定、Windows 版与他自己 Linux 版差 48.6dB；Daniel fast 是有损档；我们 EXACT。
3. **工作量**：我们跳 42/43/46（C512 三块，他俩都算），所以同几何下我们其实少算约 0.26～0.33ms（Daniel 这三块逐核）。mochizuki 不跳还快。ViT：mochizuki/Daniel 1088 按各自 token 数，我们 1088 仍 640 token（32×20 网格，见 geom-1088）。
4. **Daniel 不是整网实测**：他没有离线 bench（mod.dll 只有 dxgi 代理入口，字符串里无 bench/replay），不进游戏只能跑逐核。jobbench 用的是 kernel-map/kernel-map-900 的 0.5.0 调度结构（154 派发，合成权重）换 0.5.1 的 gfx1201 代码对象：**0.5.1 新增的 swin_run 持久化核与 v1dl ViT 核测不了**（设备端就绪队列 / 调度结构未知），所以 0.5.1 的主体提速不在逐核和里。旁证：同 harness 0.5.0 reference 900 = 8203.6µs（09-30 kernel-map-900 为 8171.6，+0.4%），0.5.1 同名核 8213.0，几乎不变——与 daniel-051 静态分析"收益主体在 swin_run"一致。fast 档符号替换：127/154 条换成 `…Lb1EE` 变体；`k_expand2`、`k_reg_vit_attn3`、`k_reg_head`、`k_repack` 无对应 fast 名（fast 的 ViT 注意力是 `attn2<true>`，grid 不明）沿用 reference 核。kernarg 大小 0.5.0/0.5.1 全部一致。所有 770 条 CHECK guards=0 invalid=0。
5. **mochizuki SPIR-V 编译**：本机是 aarch64，用 box64 跑他钉死的 glslang 16.5.0 x86_64 版编 `build_network.py rdna4`（48 网络管线），宿主 `nr_graph.cpp` 按 `windows/build/arch/rdna4.sh` 的宏用 mingw 编成 exe（vulkan-1 用 dlltool 导入库）。他没在 CLI 里生成 1080p 计划，本次用他 `nr_native_plan.cpp` 的 `make_native_plan(w,h)` 离线生成（与运行时同一函数），参数照 `nr_runtime.cpp` 调 `build` 时那一组（`--host-boundary --reuse --source-width/height --accumulation fp32`）。工作尺寸自报：1080→1920×1088、900→1600×960、4K→3840×2176；123 派发（6 段持久化合并后）。
6. 我们整网回放 wall（含跨 API 交接与 D3D 编解码）：900 7.64/7.69、1080 10.47/10.51、1088 10.05/10.07。

## §1 mochizuki 的测法

README "offline benchmark (network only)" = `windows/src/core/nr_graph.cpp` 的 `main`：`--repeats N --warmup W`，一次提交连跑，输出 `123 dispatches, one submit: X ms`。v0.0.2.5（d1185d2）网络 shader 与 0.0.2.4 相同来源；1080 第一次 100 帧 7.778ms 即复现他的 7.79。

## §2 Daniel jobbench

`jobbench-v2`（每 job 8 warmup、128 次图捕获、7 轮中位，与 kernel-map 同一 harness），job 定义：900 = `kernel-map-900-20260930/daniel-{shallow,deep}-900.json`，1088 = `kernel-map-20260929/daniel-shallow.json`（`1080-daniel-default`）+ `deep1080.json`。族汇总（µs，ref900 / fast900 / ref1088 / fast1088）：C32 2188/1934/2922/2630，C64 725/637/963/846，C128 904/692/1193/1034，C256 1577/1292/1731/1121，C512 1316/1098/1499/1331（另跳块 300/260/335/310），ViT 1172/1086/1484/1114，其余 <40。

## §3 我们

`benchmark-P.exe`（geom-1088 那份，HEAD ec6c0199 + 1088 开关）+ 剑星现装 31 个 gfx1201 模块（addon 6D059845，相对 hip-roofline 又换了 c32-wave1、c64-wave2、multihead-fast-padded-wave-packed），flags 同 hip-roofline（SWIN_RUN1/PDL1/DIRECT_IO3/BENCH_PLAIN1/graph off），`DLSS5_HIP_SPAN_PROBE=1` 写进 flags 文件，1000 帧弃 200，两轮。

## 现场

没有换装游戏（Daniel 不进游戏测不了，swap.ps1 未调用）；`swap.ps1 status` = ours，剑星 dxgi FBFB6676…、addon 6D059845… 未变。lab `D:\DLSSNR-Lab\competitor-timing-20260930`（dlssnr.bin、帧转储、pipeline cache 已删，余 80MB）。

## 文件

`daniel-jobbench.json`（逐 job µs、族和）、`dj-*.json.gz`（job 定义）、`m051.json`（0.5.1 gfx1201 kernel metadata 摘要）、`logs.txt.gz`（mochizuki 七次运行与我们 12 次回放日志）。脚本 `Development/HIP/experiments/competitor-timing/`：`mkplan.cpp`（链他的 nr_native_plan.cpp 出计划）、`mz1/mz2.ps1`、`oursetup/ours/oursall.ps1`、`dj-run.ps1`、`meta.py`、`parse.py`、`clean.ps1`。mochizuki 仓库与编译产物不入仓（他的构建需自己的 nvngx_dlssnr.dll 310.8 抽 dlssnr.bin）。
