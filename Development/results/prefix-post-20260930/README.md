# C32 prefix / post 两个大核重新分账（2026-09-30）：离带宽下限约 2.7～2.9 倍，是算力核；两处 f32→E4M3 字节逐位收下，已装

**结论**：`c32_wave1_prefix`（900 约 659µs）和 `c32_wave1_post`（约 596µs）按当前模块重测，访存量 148/141MB，按 640GB/s 算访存下限约 230/220µs，实测是下限的 2.9/2.7 倍——**不是访存核，是 WMMA+VALU 算力核**（每窗口成本约为 chain 的 1.2～1.3 倍，chain 本身读写只有 ~200GB/s）。所以压数据格式只能拿到小头。能逐位改窄的只有两个 f32 张量（都是 `F(v)`，本来就是 E4M3 精确值）：block0 下采样输出（block1 读）、block69 主输出（post 读），各 49MB（900）→12MB。做成一刀 `CW_PREPOST_BYTE`，逐位，三轮 ABBA 两档全正：**900 −0.009/−0.024/−0.019ms，1080 −0.017/−0.021/−0.025ms**，p99 三轮合并 900 更好、1080 持平。按新规收下并装机。

## 1. 分账（当前模块 = 剑星现装 bb7ebfd1 + 31 模块）

jobbench（8 warmup、128 次图捕获、7 轮中位，合成权重，prefix job temporal=0 不读 history）：

| 核 | 档 | 窗口 | 现役 µs | 字节化后 µs | 读写 MB（现役→字节） | 访存下限 µs（640GB/s） | 倍数 |
|---|---|---:|---:|---:|---|---:|---:|
| prefix | 900 | 24000 | 659.0 | 646.0 | 147.5→110.6（含 history 24.6） | 230 | 2.9 |
| prefix | 1080 | 34560 | 939.8 | 934.1 | 212.3→159.3 | 332 | 2.8 |
| post | 900 | 24321 | 596.3 | 595.4 | 141.4→104.5 | 221 | 2.7 |
| post | 1080 | 34945 | 859.4 | 862.4 | 203.5→150.4 | 318 | 2.7 |
| mapped（block1，读 prefix down） | 900 / 1080 | 6000 / 8640 | 121.1 / 183.9 | 120.7 / 173.0 | 读 49→12 / 71→18 | | |
| finish（block69，写 post low） | 900 / 1080 | 6100 / 8760 | 138.6 / 199.5 | 132.9 / 189.3 | 写 49→12 / 71→18 | | |

- 字节账：prefix 读 rgba f32×4（16B/px）＋history f32×4（16B/px），写 main E4M3（32B/px，早已是字节）＋down f32（1/4 像素 ×32ch×4B）；post 读 low f32（1/4 像素）＋skip 字节（32B/px）＋color f32×4，写 rgb f32×3。
- 算力账（gfx1201 静态，`isa-kernel-stats.py`）：prefix 1955 条指令、WMMA 48、VALU 1326、LDS 75、全局读 49/写 20、s_wait 192；post 1590 条、WMMA 44、VALU 1115、全局读 84/写 3、s_wait 107；chain 1029 条、WMMA 50、VALU 732。三者 VGPR 129～134、LDS 4KB、占用 8 wave/SIMD，占用不是瓶颈。prefix 比 chain 多出的主要是 Box-Muller/PCG 噪声与逐像素输入、以及尾部 64 条逐字节 main 写＋16 条 down 写（tail 走 LDS 读回，ds 75 条）；post 多的是 RGB head（每像素 32×3 次乘加）和两路输入组合。
- 每窗口：chain 20.7ns，prefix 27.3ns，post 24.5ns。若访存完全被计算掩盖，两核合计最多还能省 ~260µs（900），实际字节化只兑现 ~14µs（prefix）＋ block1/69 的 6µs——剩下是指令本身。Windows 上无计数器，WMMA/VALU/等待的**时间**占比拿不到，只有上面的静态比例；逐指令时间要 ISA 对照（Daniel 同几何 prefix 647.7，基本同速）。

## 2. 两核读写张量格式盘点

| 张量 | 现格式 | 值域 | 能否逐位改窄 | 处理 |
|---|---|---|---|---|
| prefix 输入 rgba（游戏帧打包 raster） | f32×4 | prefix 只用 `Hrtz(x)`；但 post 同一缓冲按 f32 全精度读（`color*.125-.0625`） | prefix 侧存 RTZ half 逐位，但 post 要 f32 → 需 D3D 输入 shader 另写一份 half，改 44 个 shader 变体 | 记账，不在本轮（非有损，工作量大、收益 ≤ 12MB 读） |
| prefix 输入 history | f32×4 | 只经 `Hrtz` 使用 | 生产端写 RTZ half 可逐位（half 往返幂等） | 记账：需改历史帧生成端（D3D），同上 |
| prefix main（C32 skip，post 读） | E4M3 字节 | — | 已是字节 | — |
| **prefix down（block1 读）** | f32 | `F(...)`，E4M3 精确 | **是** | **本轮改：`c32_wave1_prefix_b8d` + `c32_wave1_mapped_b8`** |
| **post low（block69 主输出）** | f32 | `F(v)`，E4M3 精确 | **是** | **本轮改：`c32_wave1_finish_b8` + `c32_wave1_post_b8`** |
| post skip | E4M3 字节 | — | 已是 | — |
| post color | f32×4 | 游戏帧，未舍入参与运算 | 否（除非源本身是 half 精确，RGBA8 源不是） | 不动 |
| post 输出 rgb | f32×3，[0,1] | 未舍入 | 改 half 对 RGBA16F 输出目标可能逐位（RNE 一次），对 RGBA8/R10G10B10A2 目标会双重舍入 | **有损待拍板**（依输出格式） |

不能逐位的：post 输出改 half（见上）、prefix/post 输入走 FP8（Daniel 做法）——均**有损待拍板**，未做。

## 3. 候选与验收

`CW_PREPOST_BYTE`（`hip/wave_owned_c32.inc`，配方 c32-wave1 已加 1）：只**新增**四个导出；模板加 `InByte` 参数，mapped/post 的 `CW_VEC_INPUT` 路径按 8 字节读回 `cvt_f32_fp8`，非裁剪 down 与 main 按 `fp8(F(v))` 写字节。原 10 个 c32_wave1 导出反汇编逐条同（地址外）；配方默认编出（宏 0）与现装 `.text/.rodata/.note` 两架构逐字节同（文件差在模板符号名）。

逐位依据同 `c32-align-20260930`：`F` 在 HIP_FP8_SAT_MODE 3 下输出恒为有限 E4M3 值（NaN→−448），`fp8(F(v))` 是其精确编码，读回即 `F(v)`；mapped 用 `CW_INPUT_HALF` bit1 直接用读回值，post 读回后 `lo*scale` 与原 f32 同值。

宿主 `Development/HIP/hip_reference_network.h`：`HIP_C32_PRE_DOWN_BYTE`、`HIP_C32_POST_LOW_BYTE` 默认 1，纯宿主判断带回退——需 wave-owned、raw_chain、post_head_fused 等现役路径且四个导出齐全（`HasFn`）才走字节；旧模块＝旧行为。Run 的 32 线程发射白名单补了四个新名（第一次漏了，发射失败 719，已修）。无新用户开关，RE9 runtime 同头文件同行为。

| 验证 | 结果 |
|---|---|
| X = 新宿主＋新模块：7 用例 × EXACT/AE × 12 帧、AE CSV、900/1080 票号回绕 | 全 SAME（`full-X.log`） |
| F2 = 旧宿主＋新模块 | 全 SAME |
| F1 = 新宿主＋旧模块 | 第一次 720-motion EXACT 12 帧中 1 帧不同（末帧同；此组合下宿主走的代码与现装完全相同，判为偶发）；重跑 `full-F1b.log` 全 SAME |

ABBA（1000 帧弃 200，A-P-P-A；base = c256-w16 benchmark-P＝现装宿主源＋现装 31 模块）：

| 候选 | 轮 | 900 avg（p99） | 1080 avg（p99） |
|---|---|---|---|
| X（两刀） | 1 | 7.7827→7.7738，−0.009（8.030→7.992） | 10.6552→10.6386，−0.017（10.932→10.944） |
| X | 2 | 7.7948→7.7708，−0.024（8.035→7.991） | 10.6644→10.6435，−0.021（10.945→10.950） |
| X | 3 | 7.8001→7.7808，−0.019（8.013→8.019） | 10.6665→10.6418，−0.025（10.950→10.935） |
| 只 post 刀（Ppost） | 1 | −0.008 | −0.017 |
| 只 prefix 刀（Ppre） | 1 | −0.009 | +0.003 |

三轮 p99 合并：900 8.026→8.001（更好），1080 10.942→10.943（持平）。两刀合收；prefix 刀单测 1080 贴零，随合并收（同 small-wins I/P 的收法）。

## 装机

- 配方直编 c32-wave1：gfx1201 **301d3e16** / gfx1200 **88e9b8a9**，与实测候选 X `.text/.rodata/.note` 两架构逐字节同。
- 剑星：add-on **6d059845**（`6D059845017F0E60D8EFBD5819C94C09A1E6F46312150A3F35ED940CDAE20A9F`，= 7ca25c98＋W16＋本补丁）＋两架构 c32-wave1，重建 SHA256SUMS（62），flags 原样（DIRECT_IO=3、MAKE_RESIDENT_EVERY=60、SWIN_RUN=1）。备份 `D:\DLSSNR-Lab\hip-backend\prefix-post-20260930\backups\stellar-20260930-121025-prefixpost`。
- RE9 runtime **5e601d57**（`5E601D57B1ECD7154EB5688B8B1D45AF2A8CF63D7475B0C9754F0B6650FFF038`）：旧 runtime 88b59744＋旧模块 / 新＋新 / 新＋旧，900/1080 hash 同（b2980ada643da964 / 758674a8bbd0206d），runtime-smoke 过。
- 鬼武者：Content 与 `_storage_` runtime 换 5e601d57，HIP 模块与剑星对齐，备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-121025-prefixpost`。
- 没发包、没启动游戏。回滚 `install.ps1 -RestoreStellar <备份>` / `-RestoreOni <备份>`。打包须从含本补丁的源码重编 add-on/runtime。

复现：`Development/HIP/experiments/prefix-post/`（宿主 = 7ca25c98 worktree ＋ 12a632a8 的 W16 宿主改动 ＋ 本补丁，c32-align 的 build-hosts 命令编 A/P/Ppre/Ppost/Proll；setup → run.ps1 → finish-up.ps1；make-jobs.py＋`kernel-map/pack-jobs.py`＋jobs.ps1 为逐核 jobbench）。lab `D:\DLSSNR-Lab\hip-backend\prefix-post-20260930`。
