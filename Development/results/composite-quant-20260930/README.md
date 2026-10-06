# 复合量化 Q(x)=FP8(Hrtz(x)) 的更短实现（2026-09-30）：成立，按新规收下并装机

**结论**：在输入是"FP8×FP8 WMMA 从 +0 累加"的字节出口，`FP8(Hrtz(x))` 可以把 half 的 RTZ 换成一条整数掩码 `bits(x)&0xffffe000`：少 `v_cvt_pkrtz_f16_f32`＋`v_cvt_f32_f16`，多一条 `v_and_b32`，**half 这一次舍入保留**，只省掉"f32→f16→f32"的往返。新宏 `W2_Q8_MASK`（源码默认 0，c64-wave2 / swin-persistent 配方写 1）。逐位 19 组 SAME；三轮 ABBA 两档 avg 都为正（900 −0.005～−0.016ms，1080 −0.003～−0.022ms）。已装剑星＋鬼武者，没发包。

## 1. 盘点：复合量化在哪、多热（900 档，数值个数/帧）

| 处 | 现写法 | 每值转换指令 | 每帧数值（估） | 权重 | 输入域 |
|---|---|---:|---:|---:|---|
| W2 注意力出口（C64/C128/C256 `_bo`/持久化，ByteOut、`post==0?Hrtz(v):v`） | 标量 Hrtz：pkrtz(x,x)+cvt_f32_f16 | 2 | ~90M | **~180M，最热** | 纯 WMMA 从 0 累加 ✔ |
| W2 FFN contract（C64/C128/C256 全部块） | `w2_rtz8`：pkrtz 成对＋cvt_f32_f16 | 1.5 | ~110M | ~165M | 纯 WMMA 从 0 累加 ✔ |
| C32 chain 注意力出口（site 6，4 派发） | `cw_rtz_half8` 成对 | 1.5 | ~50M | ~74M | **acc+res·w（f32 权重）**，可产生 \|x\|<2⁻²⁴ 负数 ✘ |
| C32 FFN contract | half 同时写 residual，half 本身要用 | — | — | 无收益 | |
| C32 prefix `Q8(Hrtz(pre))` | 标量 Hrtz | 2 | ~49M | ~98M | pre 非纯 WMMA，未证 ✘ |

数值个数按 kernel-map-900 的 grid（窗口×64 token×C）估：C64 8 派发 ~50M、C128 12 派发 ~39M、C256 持久化 12 层 ~20M；只作排序。本轮做前两处（同一文件 `hip/wave_owned_mh.inc`，两模块）。

## 2. 证明

- 生产序列（PACK8==6）：`h=pkrtz(x)`→`f=cvt_f32_f16(h)`→`f+0`→MODE.FP16_OVFL 下 `v_cvt_pk_fp8_f32`（饱和 ±448，RNE）。候选：`bitcast(bits(x)&0xffffe000)+0`→同一条 FP8。
- 为何等价：half 正规段的 RTZ 就是截掉低 13 位；|x|>65504 时 RTZ 得 65504、掩码仍 >448，两者都饱和成 448；half 次正规段（<2⁻¹⁴）两边都远小于 FP8 最小值的一半 2⁻¹⁰，都变 0——**只有符号可能不同**：x∈(−2⁻²⁴,0) 原式 Hrtz 得 −0，+0 后是 +0→0x00；掩码后仍是负的微小数→0x80。
- **CPU 穷举**（`Development/HIP/experiments/composite-quant/cpu_proof.c`，全部 2³² 位模式，非有限跳过）：有限 4,278,190,080 个，不等 864,018,432 个，**全部是负的 |x|<2⁻²⁴**，其它 0。
- **GPU 穷举**（`probe.hip`＋`probe.cpp`，9070 上用真实指令跑全部 2³²，逐块回读）：GPU 原式与 CPU 模型 **0 处不符**；O≠N 共 864,026,623 = 上述负微小数 864,018,432 ＋ 8,191 个 +NaN（载荷只在低 13 位，掩码后变 +Inf，得 0x7f 而原式 0xff，都是 NaN 字节）。
- 输入域：这两处的值是 FP8×FP8 乘积的 WMMA 累加（初值 +0）。E4M3 每个值是 2⁻⁹ 的整数倍，乘积是 2⁻¹⁸ 的整数倍；f32 格点在 |v|<2⁵ 时比 2⁻¹⁸ 细（精确可表示），更大时格点本身是 2⁻¹⁸ 的倍数，所以结果是 0 或 |x|≥2⁻¹⁸，且有限（≤448²×K 远小于 f32 上限）。两类反例都进不来。
- **两次舍入不能删**：同样域内 `fp8(x+0)`（直接一次舍入）与原式不同的有 1,032,066 个输入（全域有限 865,058,689 个，大多是负微小数的符号）。所以只省"往返"，不省"舍入"。

## 3. 指令账（gfx1201 静态）

每 16 值：FFN contract 原 8 pkrtz＋16 cvt → 16 and（转换段 24→16）；注意力出口原 16 pkrtz＋16 cvt → 16 and（32→16）。整模块静态：c64-wave2 166871→165651（pkrtz −368、cvt_f32_f16 −592、and +592），swin-persistent 134538→133855。整数指令少于原转换，第 3 步停止条件不触发。

## 4. 逐位与计时

- 默认（宏 0）编出的两模块与剑星现装 `.note/.rodata/.text` 两架构逐字节同；配方直编 final 与实测候选 M 两架构逐字节同。
- 7 用例 × EXACT/AE × 12 帧＋AE CSV＋900/1080 history×EXACT/AE 票号回绕：**19 组 SAME**（`bitwise.txt`）。
- ABBA（1000 帧弃 200，base＝现装 31 模块 + a80db313 源宿主，候选只换 gfx1201 两模块）：

| 轮 | 900 avg（p99） | 1080 avg（p99） |
|---|---|---|
| 1 | 7.7806→7.7733，−0.007（8.009→8.029） | 10.6983→10.6765，−0.022（11.028→10.974） |
| 2 | 7.8318→7.8154，−0.016（8.076→8.059） | 10.7075→10.6884，−0.019（10.995→10.961） |
| 3 | 7.7755→7.7704，−0.005（8.025→8.011） | 10.6857→10.6830，−0.003（10.960→11.009） |

- 判断：6 个 avg 全负（0.02～0.21%）。p99 单轮来回跳（1 轮 900 +0.02、3 轮 1080 +0.05，其它轮变好），三轮平均 900 8.037→8.033、1080 10.994→10.981 都不差，按"不拖累"收。**这是第一次按合并 p99 收**，Zero 觉得该按单轮严格判就回滚（见下）。

## 5. 装机

- 剑星：只换 gfx1200/gfx1201 的 c64-wave2、swin-persistent 并重建 SHA256SUMS（62），add-on a80db313 不变，DIRECT_IO=3 / MAKE_RESIDENT_EVERY=60 / SWIN_RUN=1 核过。备份 `D:\DLSSNR-Lab\hip-backend\composite-quant-20260930\backups\stellar-20260930-104107-q8`。
- 鬼武者：同样 4 个文件，HIP 目录与剑星逐文件一致；runtime（Content 与 `_storage_`）仍 fd4b2c0c 不动（`_storage_` 里没有模块，只备份了 runtime）。备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-104107-q8`。
- 新模块：c64-wave2 gfx1201 AAEA7306 / gfx1200 064709A4；swin-persistent gfx1201 5EC8204B / gfx1200 A2D9EC2B。RE9 runtime 只加载模块，接口不变。没启动游戏，没发包。

## 6. 可推广清单（未做）

| 处 | 预估 | 前提 |
|---|---|---|
| C512 `c512_m32_deep` / split 系 `F(Hrtz(acc))` f32 出口 | Hrtz 2→1，C512 13 派发 × 约 3M 值；约 0.003～0.005ms | acc 若纯 WMMA 从 0 则同一证明直接适用；F 输出是 float，要再核一次 F 的 −0 处理 |
| ViT contract/expand 若有 `Hrtz` 后接 fp8 | 同量级更小 | 先查是否纯 WMMA 域 |
| C32 chain 出口 site 6（~74M 权重） | 0.5/值，约 0.005ms | 域含 res·w（f32 权重），负微小数可达；需要补"\|x\|<2⁻²⁴ 置 0"，至少多一条指令，收益归零——不做 |
| C32 prefix `Q8(Hrtz(pre))` | 1/值 | 域未证 |

复现：`Development/HIP/experiments/composite-quant/`（cpu_proof.c；probe.hip＋probe.cpp；setup → build-all → run-M → r3 → final → install）；lab `D:\DLSSNR-Lab\hip-backend\composite-quant-20260930`。回滚：备份目录拷回原位。
