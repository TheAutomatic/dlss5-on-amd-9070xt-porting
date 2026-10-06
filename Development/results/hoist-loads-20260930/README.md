# 串行读等外提（hoist-loads，2026-09-30 晚）

**结论先行**：扫了现装 31 模块里的每个热核，找"读一条、等一条"的串行段。真正的串行段集中在**条件读**上：每个 `if(越界) 读` 编译成"一个分支、一条读、`s_wait_loadcnt 0`"。收两刀，都逐位（19 组 SAME），两档三轮全正：**C64/C128 wave2 输入暂存外提（`W2_HOIST_LOADS 15`）**＋**C32 up 外提（`CW_HOIST_UP 3`）**。合并确认三轮 900 −0.043～−0.044、1080 −0.066～−0.072ms；合并 avg/p99：900 7.6253→7.5822 / 7.872→7.820，1080 10.4383→10.3706 / 10.747→10.690。已装剑星、鬼武者。swin-persistent 同宏不全正，不收。

## 1. 扫描（`scan.py`：`s_wait_loadcnt 0` 前在飞 ≤2 条读的次数，按 900 地图 µs 排序；`ctx.py` 看每段读了什么）

| 核（900 µs×次） | 串行段 | 是什么 | 处理 |
|---|---|---|---|
| c128/c64_wave2_bi(_bo)（468+331+211+142） | 27 | 8 个条件 b64 输入读（暂存到 LDS，每个一分支），另有 FFN 权重 K 循环里每拍 2 读等一次 | 暂存外提 → 19 |
| c64/c128_wave2_up（119+83） | 50 / 37 | 低分辨率输入每个 k 步条件读、skip 逐元素条件读 | → 26 / 27 |
| c32_wave1_up_b8（188） | 33 | 同上＋每元素 `upw[2048+c]`、`fw[8704+c]` 各一条 b32 挨个等 | → 12 |
| sp_run*/sp_recover*（swin-persistent，650） | 93 / 29 | 同 wave2 的暂存＋持久化循环 | −8，计时不全正 |
| c32 prefix/post/chain/finish | 9～14 | 多是循环体内已成批的读（口径把部分等待也算进来了），不是真串行 | 不动 |
| decoder_project2x | 177 | skip 每个都排在前一条 out 写之后 | fill-cu 已试（不全正） |
| mh_pool_project_production_h16w | 16 条件 b32 | 生产已走 c32_b8 版，地图是旧名 | 不动 |
| C512 / ViT | ≤5 | —（HOIST_RES 已收） | — |

剩下没动的真串行：wave2 FFN 权重 K 循环（每拍 2 读等一次，同 `C512_MIX_PIPE` 的软件流水问题，负账里 null）。

## 2. 候选（全部：越界下标夹到合法地址先读，读完 select 0；运算顺序不变）

- `W2_HOIST_LOADS`（`wave_owned_mh.inc`，位掩码）：1 输入暂存 8×b64；2 FFN 残差输入字节（静态无变化，编译器已外提）；4 Up 低分辨率输入；8 Up skip。配方开 15。
- `CW_HOIST_UP`（`wave_owned_c32.inc`）：1 up k 步输入；2 up_b8 每 qt/ci 先读 skip 8 字节（夹下标）和 8 个 upw、8 个 fw 缩放，再逐元素算。配方开 3。

## 3. 整网（逐位 7 用例×EXACT/AE×12 帧＋AE CSV＋900/1080 票号回绕 = 19 组；ABBA 1000 帧弃 200）

| 集合 | 逐位 | 900 三轮 | 1080 三轮 | 合并 avg / p99 |
|---|---|---|---|---|
| HC（c64-wave2 `W2_HOIST_LOADS 15`） | 19 SAME | −0.026/−0.032/−0.026 | −0.031/−0.032/−0.039 | 900 7.6364→7.6083 / 8.071→8.005；1080 10.4724→10.4386 / 10.914→10.869 |
| SP（swin-persistent 同宏） | 19 SAME | −0.008/−0.020/**+0.006** | −0.010/−0.002/−0.006 | 不收（宏默认 0，配方不开） |
| CU（c32-wave1 `CW_HOIST_UP 3`） | 19 SAME | −0.019/−0.022/−0.022 | −0.015/−0.022/−0.035 | 900 7.6283→7.6077 / 7.868→7.833；1080 10.4505→10.4269 / 10.761→10.738 |
| **HCU 合并（配方重编）** | 19 SAME | −0.044/−0.043/−0.043 | −0.066/−0.066/−0.072 | 900 7.6253→7.5822 / 7.872→7.820；1080 10.4383→10.3706 / 10.747→10.690 |

配方重编 gfx1201 与实测候选 `.text` 逐条相同（文件哈希因宏顺序不同而不同）；现配方未改时重编与现装 `.text` 相同。

## 4. 装机

- 模块：c64-wave2 gfx1200 FBBF2819…、gfx1201 48B6FA8B…；c32-wave1 gfx1200 E878B848…、gfx1201 020B2B0D…（其余 29 个不变）。
- 剑星：只换这两个模块（两架构），add-on 6d059845、三个 flags 不动，62 模块 SHA256SUMS 重建；备份 `D:\DLSSNR-Lab\hip-backend\hoist-loads-20260930\backups\stellar-20260930-223942-hoist`。
- 鬼武者：模块镜像剑星，runtime 5e601d57 不变（含 `_storage_`），备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-223942-hoist`。
- RE9 runtime 没变，不重编。帧转储已删（21.1GB，D 盘剩 514GB）。

## 文件

脚本 `Development/HIP/experiments/hoist-loads/`（复制自 fill-cu：setup/build/mkset/run/full/summarize/p99m/final/install；go/b1～b3 是本轮编排；scan/ctx/cmp.py 是 ISA 扫描，输入是 llvm-objdump 的反汇编）。lab `D:\DLSSNR-Lab\hip-backend\hoist-loads-20260930`。
