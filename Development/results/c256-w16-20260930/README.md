# C256 FFN 权重 16 字节片段读取（2026-09-30）：逐位，按新规收下并装机

**结论**：09-23 `mhfast-wide-frag` 的做法搬到现役 C256 路径（`swin_wave2_body`：持久化 `sp_run256` 与非持久化 `c256_wave2*`）。宿主给 C256 FFN 权重另打一份宽片段布局（`FragmentPackedMatrixW16`，键 `@ffn-frag-w16`：512 字节 tile 内同一 lane 的两个 K16 片段相邻），核里 expand / contract / mix 三处一条 16 字节读喂两条 WMMA，每个累加器的 k 顺序不变。逐位 19 组 SAME＋两种回退组合＋两条路径实证；三轮 ABBA 900 全为正、1080 两正一平，p99 三轮合并两档都更好。已装剑星＋鬼武者，没发包。

## 做法与回退

- 核：新宏 `W2_FFN_W16`（`hip/wave_owned_mh.inc`，源码默认 0，c64-wave2 / swin-persistent 配方写 1）。它**只新增导出**：`c256_wave2{,_bi,_bo,_bi_bo}_w16`、`sp_run256_w16`、`sp_recover256_w16`（模板参数 `W16`），原导出照旧读旧布局。宏 0 编出的两模块与现装 `.note/.rodata/.text` 两架构逐字节同。
- 宿主（`Development/HIP/hip_reference_network.h`、`swin_persistent_network.h`、`packed_weights.h`，add-on 与 RE9 runtime 共用）：`HIP_C256_FFN_W16`（默认 1）。只有模块里有 `_w16` 导出（`HasFn`）才用宽布局＋`_w16` 核；持久化要 run/recover 两个都在。所以 **新宿主＋旧模块 = 旧行为，旧宿主＋新模块 = 旧行为**（两种都实测逐位，下）。无新用户开关。
- ISA（gfx1201 `sp_run256` → `_w16`，静态）：global_load 513→503（b128 12→46、b64 477→433），VGPR 154→184，无 scratch。

## 逐位（base = benchmark-base（a80db313 源）＋现装 31 模块）

- W（新宿主 benchmark-P＋W16 模块）：7 用例 × EXACT/AE × 12 帧逐帧 SHA 同、AE CSV 同、900/1080 history × EXACT/AE 票号回绕同，19 组 SAME（`full-W.log`）。
- F1 新宿主＋现装模块、F2 旧宿主＋W16 模块：同样 19 组全 SAME（回退正确）。
- 路径实证（诊断宿主 Proll2）：持久化开时 `SP_PLAN c=256 ... w16=1`（900/1080 两段各 1）；`SP_CHANNELS=0` 走非持久化时打印 `W2_C256 c256_wave2_bo_w16`，7 用例 × EXACT/AE 对 base 全 SAME（`diag.log`）。

## ABBA（1000 帧弃 200，A-B-B-A；候选 = benchmark-P＋W16 模块）

| 轮 | 900 avg（p99） | 1080 avg（p99） |
|---|---|---|
| 1 | 7.7726→7.7616，**−0.011**（7.991→7.988） | 10.6728→10.6430，**−0.030**（11.016→10.938） |
| 2 | 7.8271→7.8024，**−0.025**（8.070→8.050） | 10.6852→10.6700，**−0.015**（10.949→10.968） |
| 3 | 7.7867→7.7695，**−0.017**（8.033→8.012） | 10.6691→10.6722，+0.003（10.980→10.998） |

900 三轮 −0.011～−0.025ms（0.14～0.32%），p99 每轮都更好；1080 −0.030/−0.015/+0.003，三轮平均 −0.014ms，p99 三轮平均 10.982→10.968 不差。第 3 轮 1080 +0.003 在噪声内（与 09-30 composite-quant 第 3 轮 −0.003 同量级）。量级与 09-23 旧核的 −0.03～−0.04ms 相比略小。按新规（逐位、合并为正、p99 合并不差）收。

## 装机

- 剑星：add-on **bb7ebfd1**（`bb7ebfd15352a813a8b081a06f290ecf184ea4d03f5cfbeee776131245f4e770`，= 7ca25c98〔a80db313 源〕＋本补丁，不含其后未装的 1088/input-poll/产品侧改动）＋两架构 c64-wave2（gfx1201 E46EA20F / gfx1200 E4F84F44）、swin-persistent（8911ECD3 / 23022D04），重建 SHA256SUMS（62），flags 原样（DIRECT_IO=3、MAKE_RESIDENT_EVERY=60、SWIN_RUN=1 核过）。备份 `D:\DLSSNR-Lab\hip-backend\c256-w16-20260930\backups\stellar-20260930-112518-c256w16`。配方直编 final 与实测 W 两架构 `.text` 同。
- RE9 runtime **88b59744**（`88b597445e2a0ff32e03da11e5185e147721d0e89c26a19b640776970185b206`）：旧 runtime fd4b2c0c＋旧模块 / 新 runtime＋新模块 / 新 runtime＋旧模块，900/1080 hash 同（b2980ada643da964 / 758674a8bbd0206d），runtime-smoke 过。
- 鬼武者：Content 与 `_storage_` runtime 换 88b59744，HIP 模块与剑星对齐，备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-112518-c256w16`。
- 没发包、没启动游戏。回滚 `install.ps1 -RestoreStellar <备份>` / `-RestoreOni <备份>`。

复现：`Development/HIP/experiments/c256-w16/`（宿主在 7ca25c98 worktree 打本补丁后用 c32-align 的 build-hosts 命令编 A/P/Proll/Proll2；setup → build-all → run-W → r3（含 diag）→ final → runtime-check → install）。lab `D:\DLSSNR-Lab\hip-backend\c256-w16-20260930`。
