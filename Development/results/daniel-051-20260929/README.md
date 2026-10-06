# Daniel DLSS-NR on AMD 0.5.1 静态对照（对 0.5.0）

安装包 `temp/dlssnr_on_amd_setup_0.5.1.zip`（内含 setup exe + OptiScaler.dll），用 `Development/tools/closed-inspect/extract.py` 抽出 mod.dll（sha256 `493b4a3b…`，0.5.0 为 `cddfb09e…`）与各架构 hsaco；未运行安装器、未装游戏、**未做单核计时**（只做静态）。他自述：RDNA4 fast +8%、reference +6%；RDNA3 fast +3%。

## 他改了什么

| # | 改动 | 证据 | 影响档 |
|---|---|---|---|
| 1 | **新增 Swin 持久化 "run" 内核** `k_reg_swin_run<64/128/256, ref/fast>`：一次派发连跑同一 stage 的多个 Swin 层，层间用设备端就绪队列同步 | 每核 4 条原子 + `s_sleep` 轮询；host 串 `launch_reg_swin_run<%d>: %d layers`、`swin runs: mask %d, grids …`、`swin run: %u ready-queue waits timed out (100 ms each; frame output not trustworthy)`；新 env **`DLSSNR_SWIN_RUN`、`DLSSNR_SWIN_RUN_ALL`**；新用 `hipHostMalloc/hipHostGetDevicePointer`（映射内存，推测给超时/状态标志） | 两档都有（C64～C256 派发大减），很可能是 +6%/+8% 的主体 |
| 2 | **reference 档去寄存器溢出** | `k_reg_swin_mh<C,4/5,false>` private 336/272 → 80/0，scratch 指令 −70、等待 −150；`k_reg_swin32<4/5/20,false>` private 32～40 → 0 | reference（与 0.5.0 的 RDNA4 +5% 同一类） |
| 3 | **fast 档继续削算术** | `*<…,true>` 变体普遍 cvt −2～−30、VALU −80～−667、LDS −17～−108 | 仅 fast（有损路线） |
| 4 | **ViT 新 1D 层内核** `k_v1dl_{qkv,conv,expand}<2,…>` 取代部分 `k_reg1d_*` | 每 wave WMMA 32→64、VGPR 176～231、LDS 最多 16KB——更大的 tile/每 wave 做两份活 | 两档 |
| 5 | reference 数学未变 | `false` 变体 cvt 计数基本不变（swin_mh 的 false 版 cvt 零变化） | — |

内核数 gfx1201 168 → 181（只增不删：+6 swin_run、+7 v1dl）；同名 168 个里 60 个有变化。RDNA3（gfx1100 对象 7.85 → 7.74MB）未细看。

## 对我们

- **#1 是唯一值得研究的新东西**：我们 C64～C256 目前是逐块派发 + PDL（块间 flags、any-order），他改成**单次派发跨层的持久化内核 + 设备端就绪队列**。我们 09-2x 的"C256 持久化"更慢已关——他这版给了一个跑得更快的实例（队列设计、网格大小、每层 tile 分配、超时兜底），属于"有新证据可重开"。风险点：持久化自旋 + 看门狗（他用 100ms 超时报警），Zero 已定"风险不换速度"，可评估。
- #2 我们生产核已 private 0 / spill 0，无可借鉴。
- #3 是有损路线（C 段），不逐位。
- #4 ViT 的"每 wave 双倍 tile"可和我们 ViT 49 对 40 派发的账一起看（`results/deep-layers-20260929`）。

## 复现

`extract.py <setup.exe> x` → `llvm-objdump -d --mcpu=gfx1201` → 按函数统计（脚本思路同 `d050/mix.py`，本轮 `cmp.py` 在 scratchpad `d051/`）；`llvm-readelf --notes` 取 vgpr/private/group。

## 换装

9070 `D:\DLSSNR-Lab\daniel-051\`：`mod.dll`（0.5.1）+ `swap.ps1 daniel|ours|status`（沿用 daniel-040 的 nvngx 与 ini；默认 fast 档，`Quality=reference` 切换）。现状 `state=ours`。
