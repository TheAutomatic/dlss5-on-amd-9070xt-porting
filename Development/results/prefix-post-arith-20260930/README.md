# C32 prefix / post 按"算力受限"找刀（2026-09-30）：prefix 字节尾向量化，逐位，两档三轮全正，已装

**结论**：两核按指令族、按每窗口动态条数拆开后，prefix 最"浪费"的一段是尾部写 main/down 字节：每条 lane 管一个通道、64+16 次逐字节循环，光尾部就占每窗口 1018 条 VALU＋390 条 SALU＋128 次 ds_load_u16＋80 次 global_store_b8（Daniel 同位核写出只有 4×b128＋2×b64）。改成"每 lane 管 8 个连续通道"：一次 ds_load_b128、一次 cw_pack8、一次 8 字节写，每字节的值不变。新宏 `CW_PREFIX_TAIL_VEC`（源码默认 0，c32-wave1 配方写 1），只改 `c32_wave1_prefix_b8d`，宿主不动。逐位 19 组 SAME；三轮 ABBA **900 −0.040～−0.046ms（0.51～0.60%），1080 −0.065～−0.074ms（0.61～0.70%），p99 六个全变好**。已装剑星、鬼武者，没发包。post 这轮没出刀（见 §3）。

## 1. 指令构成（gfx1201，COMGR 现装 301d3e16，每窗口动态条数 = 静态×循环次数）

循环：qt 4 次（输入＋QKV）、ht 8×4=32 次（隐层 FFN）、注意力 qt 4 次；prefix 尾 main 16 次、down 直线；post RGB head 2 次。脚本 `Development/HIP/experiments/prefix-post-arith/{cls,dyn}.py`，明细 `isa-regions-installed.txt`。

| 核（每窗口） | 总 | WMMA | VALU | 其中 转换 | 乘加 | 比较/选择(med3) | 位/打包 | 整数地址 | mov | dual(VOPD) | SALU | 等待 | LDS | 访存 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| prefix_b8d | 7923 | 304 | 4987 | 1560 | 736 | 623 | 816 | 186 | 117 | 828 | 788 | 680 | 156 | 373 |
| post_b8 | 6794 | 288 | 4544 | 1292 | 832 | 464 | 593 | 234 | 68 | 964 | 449 | 523 | 32 | 383 |

WMMA 只占 4%，VALU 63～67%；RDNA4 上 FP8 WMMA 与 VALU 不重叠，VALU 条数就是时间。转换族（pkrtz/cvt_f32_f16/cvt_pk_fp8/cvt_f32_fp8）是最大一族，prefix 每窗口 1560 条。

**VALU 热段（900 档，每帧条数 = 每窗口 × 窗口数，prefix 24000、post 24321）**：

| # | 段 | 每窗口 VALU | 每帧（百万） | 构成 |
|---|---|---:|---:|---|
| 1 | prefix 注意力（与 chain 同） | 1380 | 33.1 | 位/打包 352（exp 位运算）、转换 320、乘加 256 |
| 2 | post 注意力（同上） | 1364 | 33.2 | 同上 |
| 3 | post 输入组合 `Hrtz(Hrtz(lo·s0)+high·s1)` | 916 | 22.3 | 转换 416、位 140、地址 72 |
| 4 | prefix 隐层 ht 循环（与 chain 同） | 992 | 23.8 | med3 256、乘加 256＋dual 256、转换 128 |
| 5 | post 隐层 ht 循环 | 992 | 24.1 | 同上 |
| 6 | prefix 输入（噪声＋rgba/history 的 Hrtz 链） | 816 | 19.6 | 转换 392、med3 104 |
| 7 | post QKV | 712 | 17.3 | 转换 352、rsq 64 |
| 8 | prefix QKV | 704 | 16.9 | 同上 |
| 9 | **prefix 尾 main 字节循环** | 608 | 14.6 | **位/地址 304**、转换 128、med3 64（另 SALU 336、ds_load_u16 64、store_b8 64） |
| 10 | post RGB head | 476 | 11.6 | 乘加 224＋dual 102、转换 76 |
| 11 | **prefix 尾 down 字节** | 410 | 9.8 | 转换 240（每值 15 条）、med3 62（另 ds_load_u16 64、store_b8 16） |

1～8 与 chain 共用模板，前几轮（c32-round*、small-cuts、composite-quant）已挖过；prefix 独有的 9＋11 是尾部组织方式，本轮出刀处。

## 2. 与 Daniel 对齐（他的同位核 `k_reg_swin32<20,false>` = block0/prefix 647.7µs、`<32,false>` = block70/post 534.8µs，900 kernel-map）

| 项 | 我方 prefix / post | Daniel prefix / post | 归类 |
|---|---|---|---|
| 尾部输出 | 64+16 次 global_store_b8、ds_load_u16 68 | 4×b128＋2×b64 / 2×b128 | **组织方式**（本轮改掉 prefix） |
| 半精度算术 | f32 算＋`v_cvt_pkrtz`/`cvt_f32_f16` 往返（prefix 116/224 条静态） | `v_pk_mul/add/fma/max/min_f16` 成对算 1100+ 条、`v_fma_mix` 600 条 | **语义**：他在 f16 里直接算（fast 档），我们逐位要求 f32 算后 RTZ，不能照搬 |
| 饱和 | `v_med3` 92 / 56 | `v_pk_max/min_f16` 成对 | 语义（同上，f16 域） |
| FP8 打包 | MODE 夹 4 条 cvt_pk（setreg 34） | cvt_pk_fp8 328/216，无 MODE | 编译产物/等价 |
| 结构 | 全展开，ht 循环 32 次 | 同样一窗一 wave，主循环每次 32 WMMA | 同 |

他的 VALU 静态条数比我们多（prefix 6965 条静态），但成对 f16 算术一条顶两值；差距的主体是"f16 域算术"这个语义选择，属 fast 档（C 段待拍板），不在逐位范围。能逐位拿的只有组织方式——尾部写出。

## 3. 候选与判定

| 候选 | 做法 | 结果 |
|---|---|---|
| **T `CW_PREFIX_TAIL_VEC`** | lane = (像素槽 c>>2, 通道组 c&3)；main 8 次、down 2 次，每次 ds_load_b128 取 8 个连续残差 half，`cw_pack8`（MODE 饱和）得 8 字节，一次 8 字节写；8 lane×4 组 = 一行 8 像素 256 字节连续 | **收** |
| post 输入 Hrtz 成对（`v_cvt_pkrtz` 两值一条） | 省 16 条 pkrtz，但 gfx12 的 `v_cvt_f32_f16` 无 op_sel、读高半要 `v_lshrrev`，净 0（本地 LLVM fork 反汇编） | 不做 |
| post 输入 `Hrtz(lo·s0)` 换掩码 | lo·s0 是 E4M3×f32 标度，可进 half 次正规段，掩码与 RTZ 不等价；域不纯 | 不做 |
| post RGB head 换 WMMA | 累加顺序变，非逐位；HEAD_VEC 09-27 已试 1080 反慢 | 不做 |

**T 的逐位依据**：main 原为 `fp8(v+0)`（med3 夹后 cvt），v 是残差 half 值（`cw_rtz_half8` 产出，RTZ 不会从有限值溢到 Inf，上游 f32 和有限）→ 有限值下 MODE 饱和 cvt 与 med3+cvt 同字节，与 C32 site 2 打包同一类值、同一论证；成对 cvt 与单值 cvt 同字节（CW_PACK8）。down 原为 `fp8(F(x))`，x 为有限 half 值：F 只在 ±0 处与 x 不同（都得 0x00），其余 F(x) 是 x 的 E4M3 精确值，再 fp8 是同一字节 → 等价于 `fp8(x+0)`；Hrtz 链逐条照抄。

**指令账（COMGR，每窗口）**：尾部 VALU 1018→514、SALU 390→71、LDS 128→16、store 80→10、等待 259→56；但编译器重排后 ht 循环 VALU 992→1088、QKV 704→744（VOPD 配对变少，源码未动）。整核每窗口总条数 7923→6745（−15%），VALU 4987→4572（−8%）；静态 1937→1728 条、代码 10540→9156 字节。明细 `isa-regions-T.txt`。

## 4. 验证与计时

- 配方默认（宏 0）编出 c32-wave1 与现装 301d3e16 `.text/.rodata/.note` 逐字节同；配方直编 final（`CW_PREFIX_TAIL_VEC 1`）与实测候选 T 两架构三段逐字节同。
- 宿主不变（导出名同），只换 gfx1201 c32-wave1：7 用例 × EXACT/AE × 12 帧、AE CSV、900/1080 history 票号回绕 × EXACT/AE：**19 组 SAME**（`full-T.log`）。
- ABBA（1000 帧弃 200，A-T-T-A；base = prefix-post 的 benchmark-P＝现装宿主源＋现装 31 模块）：

| 轮 | 900 avg（p99） | 1080 avg（p99） |
|---|---|---|
| 1 | 7.7272→7.6810，−0.046（7.968→7.909） | 10.6014→10.5364，−0.065（10.903→10.811） |
| 2 | 7.7741→7.7344，−0.040（8.008→7.966） | 10.6156→10.5438，−0.072（10.913→10.845） |
| 3 | 7.7636→7.7236，−0.040（8.023→7.976） | 10.6285→10.5546，−0.074（10.926→10.820） |

六个 avg、六个 p99 全变好，按新规收。单刀即全部，无需合并再确认。

## 5. 装机

- c32-wave1：gfx1201 **3F9CDD24**（`3F9CDD24C6798C2F12BB8BF42054E9E87CC8F0000757635D408B30D9402EBB58`）/ gfx1200 **00B1D536**（`00B1D536EB801C83EA0D248F85CDC45EFEC501EBE071F5DE3C2177B3EE727C24`）。
- 剑星：只换两架构 c32-wave1、重建 SHA256SUMS（62），add-on 6d059845 不变，flags（DIRECT_IO=3、MAKE_RESIDENT_EVERY=60、SWIN_RUN=1）核过未动。备份 `D:\DLSSNR-Lab\hip-backend\prefix-post-arith-20260930\backups\stellar-20260930-123126-pparith`。
- 鬼武者：HIP 模块与剑星逐文件对齐；runtime（Content 与 `_storage_`）5e601d57 未换，一并备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-123126-pparith`。
- RE9 runtime 5e601d57 不变（只加载模块，导出名不变），未重编。没启动游戏，没发包。回滚 `install.ps1 -RestoreStellar <备份>` / `-RestoreOni <备份>`。

## 6. 余下（未做）

- 同样的尾部向量化可推到 `c32_wave1_finish*`（block4/69 等，finish_b8 静态 ds 140、store 37），不在本轮范围；需分整窗/边缘与 DownCrop 两路。
- ht 循环因重排多出 ~96 条 VALU/窗口：编译器调度产物，若要追回需 sched_barrier 隔开尾部，收益小，未试。

复现：`Development/HIP/experiments/prefix-post-arith/`（setup → build → run.ps1 → final → install；ISA 拆账 cls.py/dyn.py 读 `.hsaco.s` 抽出的核体）。lab `D:\DLSSNR-Lab\hip-backend\prefix-post-arith-20260930`。
