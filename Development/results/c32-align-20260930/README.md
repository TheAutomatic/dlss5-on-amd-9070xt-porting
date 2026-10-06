# C32 上采样块 + 块 4 边界对齐 Daniel：块 4 主输出/下采样改存 E4M3 字节，逐位通过，已装剑星＋鬼武者（2026-09-30）

**结论**：900 地图里 C32 两处落后（`c32_wave1_up` 188 vs Daniel 124µs；块 4 `finish_dcrop`＋`pool_project` 184 vs 137µs）的大头不是指令，是**访存格式**。块 4 的 main（C32 skip，只被块 66 的 up 读）和 dcrop 下采样输出一直按 f32 存，而它们的值是 `F(v)`——本来就是 E4M3 精确值。改成直接存 E4M3 字节：块 4 写 800×480×32 从 49MB→12MB，up 读同量减 3/4；下采样 12MB→3MB，`pool_project` 读同比减少。**整网 900 −0.049/−0.050ms（0.62/0.63%），1080 −0.088/−0.091ms（0.81/0.84%）**，两档两轮都过 0.5%。

## 对齐：多出来的归到哪（Daniel 0.5.1 `k_reg_swin32<8>`=up、`<4>`=块 4，与我方 c32-wave1 逐段对比）

| 段 | 我方 | Daniel | 归类 |
|---|---|---|---|
| up 的 skip 读取 | f32 32 通道/像素，逐元素 `cw_up_F`（fp8 往返+零判）| FP8 字节 b128 一次读，`cvt_pk_f32_fp8` | **组织方式（数据格式）**：值本就是 E4M3 精确值，f32 存储纯属浪费 → 本轮改 |
| 块 4 main 写出 | f32 `F(v)`，`global_store_b32` | 字节 | 同上 → 本轮改（`store_b32`→`store_b8`，同指令数，字节量 1/4） |
| 块 4 dcrop 下采样写出 + pool_project 读入 | f32 → h16w 核里逐元素 `pack()` 成 fp8 | 字节 | 同上 → 本轮改（新 `mh_pool_project_c32_b8`：b64 直读，VALU 531→298、WMMA 4→2 静态） |
| up 的低分辨率输入（C64 解码器输出）| f32，逐元素转 half，f16 WMMA 8 条 | FP8 输入、fp8 WMMA | **语义必须**：我们的值不是 E4M3（half 语义），改 fp8 属有损，不做 |
| up 的 4×4→8×8 分发 | 16 条 `ds_bpermute`/qt | LDS 存再读（`ds_store_b128`×2+`ds_load_b128`×8）| 组织方式，量小（LDS 带宽级），本轮未动 |
| 块 4 残差 | 12 条 WMMA，含 6 条乘零 | 他全展开、不含乘零 | 编译/源码写法 → 小件 D（见 `small-cuts-20260930`） |

静态计数（gfx1201）：`up`→`up_b8` 全局读 b32 52→36、VALU 1116→966；`finish_dcrop`→`_b8d` 只把 23 条 `store_b32` 换成 `store_b8`。

## 为什么天然逐位

`F(v)`：零→+0、|v|≥448 饱和到 ±448，其余 `cvt_pk_fp8` RNE 往返——输出恒为有限 E4M3 值、无 −0。于是 `fp8(F(v))` 是它的精确编码，`cvt_f32_fp8(byte)` 读回就是 `F(v)`；up 原本对 skip 再做一次 `cw_up_F`（幂等），读回值不变。下采样值同为 `F(...)`，h16w 核里 `pack()` 的 `q8(F(...))` 与存下的字节逐位相同，WMMA 的 A 片段完全一样。

## 逐位（基线 = benchmark-base.exe（剑星现装宿主 62803606 同源）＋剑星现装 31 模块）

候选 benchmark-P（新宿主）＋ flat-B（新 c32-wave1＋新 mh-fast）：7 用例 × EXACT/AE × 12 帧逐帧 SHA 同、AE 决策 CSV 同；900/1080 history × EXACT/AE 强制票号回绕（Proll）同。18 组 SAME。另 flat-S（只 main 字节、down 仍 f32）同样 18 组 SAME。日志 `full-S.log`、`full-B.log`、`full-BD.log`。

## 整网 ABBA（1000 帧弃 200，A-P-P-A；A = base 宿主＋现装模块）

| 组 | 轮 | 900 基线→候选 ms | 省 | 1080 基线→候选 ms | 省 |
|---|---|---|---|---|---|
| S（只 main 字节）| 1 | 7.9091→7.8789 | 0.38% | 10.8627→10.7925 | 0.65% |
| S | 2 | 7.9545→7.9039 | 0.64% | 10.8993→10.8219 | 0.71% |
| **B（main＋down 字节，已装）** | 1 | 7.910074→7.861226 | **0.62%** | 10.861405→10.773898 | **0.81%** |
| **B** | 2 | 7.933174→7.883135 | **0.63%** | 10.882844→10.791812 | **0.84%** |
| BD（B＋小件 D，未装）| 1 | 7.919609→7.835819 | 1.06% | 10.850263→10.731824 | 1.09% |
| BD | 2 | 7.946956→7.869758 | 0.97% | 10.857609→10.733849 | 1.14% |

预估 ~0.1ms（按 49+12MB 带宽算上界），实得 900 0.05ms、1080 0.09ms。up 剩下与 Daniel 的差距主要在低分辨率输入是 f32/half（语义）和 bpermute 分发，前者是有损方向，不追。

## 代码

- `hip/wave_owned_c32.inc`：`CW_SKIP_BYTE`（默认 0）只**新增**三个导出 `c32_wave1_finish_dcrop_b8`（main 字节）、`c32_wave1_finish_dcrop_b8d`（main＋down 字节）、`c32_wave1_up_b8`（skip 字节读）；原 17 个函数反汇编逐条同。`CW_TAIL_QUAD` 与之互斥（`#error`）。
- `hip/multihead_fast_padded.hip`：`HIP_POOL32_B8`（默认 0）新增 `mh_pool_project_c32_b8`；原 101 个函数逐条同。
- `hip/build-modules.ps1` 配方：c32-wave1 加 `CW_SKIP_BYTE 1`，multihead-fast-padded-wave-packed 加 `HIP_POOL32_B8 1`。配方直编与实测候选 `.text/.rodata` 两架构逐字节同。
- `Development/HIP/hip_reference_network.h`（add-on 与 RE9 runtime 共用）：`HIP_C32_SKIP_BYTE`/`HIP_C32_DOWN_BYTE` 默认 1——**纯宿主判断且带回退**：只有块 66 走 wave-owned up（`C32UpBodyPath()`，与原判断同一函数）且模块导出齐全（`HasFn`）才启用，旧模块/其他路径照旧 f32。新宿主＋旧模块 = 旧行为，旧宿主＋新模块 = 旧行为。无新用户开关。

## 装机

- 剑星：add-on **a80db313**（`a80db313e6b02139deaeccb137e2019c60f7213019d58374b9180c99464b59ff`）＋两架构 `c32-wave1`（gfx1201/1200 同 .text，文件 ecd5619c / 31b061b1）、`multihead-fast-padded-wave-packed`（23a5abb9 / 1acba935），重建 SHA256SUMS（62 模块），flags 原样（DIRECT_IO=3、MAKE_RESIDENT_EVERY=60、SWIN_RUN=1）。备份 `D:\DLSSNR-Lab\hip-backend\c32-align-20260930\backups\stellar-20260930-034433`。
- RE9 runtime **fd4b2c0c**（`fd4b2c0c72f9504dad088143eb9baff7377550ee421f42ce1f00599b007602ee`）：旧 runtime be828151＋旧模块 / 新 runtime＋新模块 / 新 runtime＋旧模块，900/1080 hash 同（b2980ada643da964 / 758674a8bbd0206d，与 09-29 同），runtime-smoke 过。
- 鬼武者：Content 与 `_storage_` runtime 换新，HIP 模块与剑星对齐，备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-034433-c32`。
- 没发包、没启动游戏。回滚 `install.ps1 -RestoreStellar <备份>` / `-RestoreOni <备份>`。

复现：`Development/HIP/experiments/c32-align/`（build-hosts.sh → setup.ps1 → build.ps1 → full.ps1 -Set B -Cand P → final.ps1 → runtime-check.ps1 → install.ps1；mkset.ps1/bmh.ps1 拼组合）。lab `D:\DLSSNR-Lab\hip-backend\c32-align-20260930`。
