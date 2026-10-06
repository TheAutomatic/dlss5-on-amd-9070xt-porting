# 旧门槛淘汰的小正收益件重测（2026-09-30）：I+P+O 按新规收下并装机，Q 不收

**结论**：mochizuki-022 那轮因不到 0.5% 被淘汰的 I/P/O（及组合 C），加上 c32-round3 的 Q，在现役内核（a80db313 + 31 模块，含 `CW_DIAG_ONLY`）上重做。全部逐位（每个候选 7 用例 × EXACT/AE × 12 帧 + AE CSV + 900/1080 票号回绕，19 组 SAME）。按 09-30 新规（逐位、ABBA 为正、p99 和另一档都不变差）**收 C = I+P+O**，Q 不收。只换三个模块，宿主 a80db313、RE9 runtime fd4b2c0c 没变。

## 候选与现状核对

| 件 | 出处 | 现役是否已覆盖 | 本轮做法 |
|---|---|---|---|
| I 入口去 half 往返 | mochizuki-022 | 否。另有一处新增：09-30 C32 up 路径（`H()` 已是 half 值）也有同样的 `float((_Float16)v)` | 新宏 `CW_INPUT_HALF`（bit0 post Hrtz、bit1 mapped 输入、bit2 up 的 H 值），取 7 |
| P prefix 保留 half 位模式 | mochizuki-022 | 否（prefix split 代码没变） | 新宏 `CW_PREFIX_HALF_SOURCE 1`，改写与 09-28 相同 |
| O 占用上限 | mochizuki-022 | 否。C512 mix `split_mix_blocked_h16w_m32`（c512-m32-deep）仍在用；ViT contract 现在走 vit-stream 的 `vit_stream_contract_frag_hout`，共用 `vit_contract_blocked_body` | 新宏 `C512_MIX_OCC_LDS 4096`、`VIT_CONTRACT_OCC_LDS 4096`（占位 LDS，占位分支对真实 token 数永不执行） |
| Q post 内部窗口免逐像素判断 | c32-round3 | 宏 `CW_POST_FULL_TILE` 还在源码里，与现役 post 能编译 | 直接开 1 |

补搜 results/ 与 DevHistory，符合"逐位＋当时两档两轮都快"的只多一件：**mhfast-wide-frag（09-23，C256 FFN 权重 16B 片段读，约 −0.03～−0.04ms）**。它要改宿主打包器（add-on＋RE9 runtime 都要重编），核也在 09-23 之后多次改写，本轮 2 小时内没重做，留在 B 段。其余"不采用"项要么当时就有一档变慢或来回跳（mh-round1 T/D、c32-pair-encode mode4、network-fixed-shapes、daniel-kernels C），要么所在的旧核已退役（c32-register-attention 等），要么已经进了配方（fp8-sat-mode med3），都不列入。

默认值（宏全 0）编出的 c32-wave1 / c512-m32-deep / vit-stream 与剑星现装模块 `.note/.rodata/.text` 两架构逐字节同。

## 结果（base = benchmark-base＝c32-align benchmark-P＋现装 31 模块；候选只换模块；1000 帧弃 200，A-B-B-A）

| 候选 | 轮 | 900 avg ms（p99） | 1080 avg ms（p99） | 判断 |
|---|---|---|---|---|
| Q | 1 | 7.8398→7.8374，−0.002（8.065→8.071） | 10.7072→10.7087，**+0.0015**（11.007→10.978） | 不收：1080 一轮变慢，量级约 0.005ms，与 09-27 同 |
| Q | 2 | 7.8649→7.8614，−0.004 | 10.7379→10.7261，−0.012 | |
| O | 1 | 7.8476→7.8302，**−0.017**（8.087→8.083） | 10.7484→10.7294，**−0.019**（11.057→11.018） | 收 |
| O | 2 | 7.8550→7.8476，−0.007（8.129→8.109） | 10.7106→10.7007，−0.010（11.020→11.014） | |
| I | 1 | 7.8325→7.8332，+0.0007 | 10.7280→10.7214，−0.007 | 单独在噪声内，随 C 收 |
| I | 2 | 7.8727→7.8686，−0.004 | 10.7310→10.7273，−0.004 | |
| P | 1 | 7.8431→7.8236，−0.020 | 10.7238→10.7244，+0.0006 | 单独 1080 持平，随 C 收 |
| P | 2 | 7.8711→7.8583，−0.013 | 10.7284→10.7256，−0.003 | |
| **C = I+P+O** | 1 | 7.8405→7.8145，**−0.026**（8.089→8.064） | 10.7101→10.6943，**−0.016**（11.028→10.989） | **收** |
| **C** | 2 | 7.8564→7.8276，**−0.029**（8.104→8.066） | 10.7192→10.6912，**−0.028**（11.050→11.001） | |
| 配方直编 final（=C） | 3 | 7.8294→7.7998，**−0.030**（8.072→8.066） | 10.7431→10.7274，**−0.016**（11.039→11.033） | 合并后整体确认，不拖累 |

C 三轮：900 −0.026/−0.029/−0.030ms（0.33～0.38%），1080 −0.016/−0.028/−0.016ms（0.15～0.26%），p99 两档三轮都不变差或更好。I、P 单测只有 ~0.005ms、一轮贴零，但合在 C 里比 O 单独多省 0.01～0.02ms，按整体收。

## 逐位

每个候选（Q/O/C/I/P/final）：7 用例 × EXACT/AE × 12 帧逐帧 SHA 同，AE 决策 CSV 同，900/1080 history × EXACT/AE 强制回绕（Proll）同。6 × 19 SAME＋FULL_DONE 全在 `bitwise.txt`。I 的依据同 09-28：post/up 的值已是 half 格点（Hrtz/H 的结果），mapped 输入由 prefix FP8 或 decoder half 产出，`float((_Float16)v)==v`；P 只换表示（RTZ half 位模式经 bpermute 直接装 WMMA 操作数），不删任何舍入；O 只加占位 LDS。

## 配方与装机

- `hip/build-modules.ps1`：c32-wave1 加 `CW_INPUT_HALF 7`、`CW_PREFIX_HALF_SOURCE 1`；c512-m32-deep 加 `C512_MIX_OCC_LDS 4096`；vit-stream 加 `VIT_CONTRACT_OCC_LDS 4096`。配方直编与实测候选（IP/Omix/Ovit）两架构 `.note/.rodata/.text` 逐字节同。
- 新模块：c32-wave1 gfx1201 77d163c8 / gfx1200 dfc09dad；c512-m32-deep 8e84f7c0 / fa30654b；vit-stream fef8a768 / 72ee6081（`final-hashes.txt`）。
- 剑星：只换这 6 个文件并重建 SHA256SUMS（62），add-on a80db313 不变，flags 原样（DIRECT_IO=3、MAKE_RESIDENT_EVERY=60、SWIN_RUN=1 核过）。备份 `D:\DLSSNR-Lab\hip-backend\small-wins-20260930\backups\stellar-20260930-101608-smallwins`。
- 鬼武者：HIP 模块与剑星对齐（逐文件核过），runtime（Content 与 `_storage_`）仍 fd4b2c0c 不动。备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-101608-smallwins`。
- RE9 runtime：宿主代码没改，不重编；新模块按同一 HIP 接口加载（只改核内部，导出不变）。
- 没发包、没启动游戏。回滚：把备份目录里的文件拷回原位。

复现：`Development/HIP/experiments/small-wins/`（setup.ps1 → build-all.ps1 → run-singles.ps1 → summarize.ps1 → final.ps1 → install.ps1；g.ps1 查逐位行）。lab `D:\DLSSNR-Lab\hip-backend\small-wins-20260930`。
