# ViT / C512 ACO 账与最小字节接口原型（2026-09-27）

第三轮任务的第 3 部分。基线为剑星已验收的 C32 round2（ba0cd46 工作树，c32 gfx1201 ae95bdf6）。实验根 `D:\DLSSNR-Lab\hip-backend\vit-c512-aco`，脚本 `Development/HIP/experiments/vit-c512-aco`。

## 数据形态先于指令数

本机 `~/work/aco-isa` 的 Mesa/RADV 假 gfx1201 重新导出十条管线；源码 SHA 见 source-hashes.json，ISA SHA 与静态账见 aco-static.json。`gemm1x1.comp` 默认 `NR_A_E4M3`：A 是已量化的字节，不先读取 f32 再量化。`vit_attn.comp` 的 QKV 与输出同样是字节 arena，输出经过 tile 排布。我们的 QKV 已是字节，expand 的输入和 hidden 也已是字节；**仍浪费的接口是 attention 的 AV 输出到 n64 projection：生产者把 F() 解成 f32 写出，消费者读后又 pack。**

这些差异不全来自编译器。ACO 的 QKV、激活与 exp 配置有不同的舍入/归一化路线；它也使用本项目已经否决的 packed-half 算术等手段。这里比较供数和调度，不搬数学配置。

## ViT 投影：同一 WMMA 工作量的实账

固定 1024×1024，单 wave 输出 16 token×64 列。分四个 K256 段；每段累加和最终相加顺序不变。源码与 ISA 对照后计入循环，不能拿静态 64→16 次 WMMA 当成减少计算。

| 每 wave | 当前 f32 AV | 原型 V：FP8 AV |
|---|---:|---:|
| WMMA | 256 | 256 |
| VALU + VOPD | 3128 | 764 |
| VMEM 指令 | 452 | 388 |
| 全局读取字节 / lane | 4240 | 2704 |
| 全局读取 / wave | 132.5 KiB | 84.5 KiB |
| 分配 VGPR（next_free） | 160 | 120 |
| scratch | 0 | 0 |

纯 A 操作数从 64 KiB/wave 降至 16 KiB/wave；权重的 64 KiB 不变，残差与 scale 保留。总请求读取少 36.2%，不是声称 DRAM 实际少同样比例（缓存会复用）。八层合计少请求 150 MiB（n=400）/240 MiB（n=640）；生产者 AV 写出另少 9.375/15 MiB。原型保留现有较大的分配，仅缩小实际读写范围，因此尚不兑现显存容量收益。

projection-A/V.json 给出加权 opcode 账和手工检查的循环范围。静态 VMEM 是 164→88，但静态数不能直接预测耗时。

## 与 ACO 对齐尺度

aco-weighted.json 按 K1024（ViT）或 C512 计入单一 K 循环。下表都是每 wave，tile 不同，不能直接相减当作优化空间；条件尾部按上界计费。

| ACO 管线 | 输出 tile / 工作 | VALU+VOPD | VMEM | WMMA |
|---|---|---:|---:|---:|
| gemmvact | 64×64，K1024 | 1489 | 512 | 1024 |
| gemmvproj | 64×64，K1024 | 1925 | 784 | 1024 |
| gemmvqkv | 64×64，K1024 | 863 | 512 | 1024 |
| gemmvqkvnorm | 同上，带归一化尾部上界 | 1991 | 544 | 1024 |
| gemmvqkvs | 32×32，K1024 | 207 | 224 | 256 |
| gemmproj | 32×32，K512 | 347 | 164 | 128 |
| ffwd3 | 16 token×一个64通道组，mix+FFN | 1151 | 164 | 256 |
| ffwd3w | 上述两个 token tile | 2219 | 200 | 512 |

例如 gemmvproj 工作量是我们 n64 的四倍，粗按四分之一是约 481 条普通向量、196 VMEM、256 WMMA；原型 V 为 764/388/256。仍有 output tile 大小、权重复用、残差与输出布局等差异，字节接口不会自动变成 ACO 同等速度。

vitattn 静态账为 VALU+VOPD 1177、VMEM40、WMMA64；它一 wave 两组 query，64 个 key 一段，含边界/模式分支。我们的 fused attention 一 wave 16 query、16 key 一段（静态526/36/5），还保留固定半精度分母路线。两者循环粒度、数学不同，不把这两个静态总数相除。

## C512：供数已部分优化，剩余不是同一种问题

c512-weighted.json：完整 token tile，Q/K 归一化分支上界；计数单位为单 wave，split FFN 每 workgroup 四个 wave。

| 当前核 | VALU+VOPD | VMEM | WMMA | 主要形态 |
|---|---:|---:|---:|---|
| split_mix_blocked_h16w_m32 | 1871 | 320 | 256 | A=f32→half，B=half；同一B喂32token |
| split_ffn_fused_fp8_t8 | 699 | 56 | 32 | mix=f32→half，hidden在LDS字节，输出f32+字节 |
| split_projection_frag | 593 | 260 | 128 | A/B已是字节，残差仍f32，双份输出 |
| mh_qkv_normalize_frag_c512_m32 | 1117 | 198 | 256 | A/B已是字节，归一化LDS，字节写出 |

这里 QKV/projection 的主矩阵输入已是 FP8，不能再获得 f32→FP8 的四倍缩减。mix 的 A 每 wave 请求 64 KiB，若上游直接给精确 half，可减至32 KiB；对应权重64 KiB仍要读，故这部分 A+B 请求最多从128降至96 KiB（−25%），不是整个核减半。mix→FFN 也能少 f32 读取和 half 转换，但需同时审核生产者及残差消费者。

ACO ffwd3 把 mix、expand、contract 连在寄存器片段里，不写出中间 mix，并换了数学/数据形态。我们的先前实测（results/c512-ffn-20260926）M32 复用权重有效、单改写出很小、投影 M32 无收益，支持先攻供数。静态计数本身不能证明哪一个硬件单元饱和。本轮不再尝试已否决的 DF_PACK8；优先方向是**精确 half 接口或保持原计算顺序的融合**，逐段 census 后再考虑量化尾部简化。

## 自适应兼容性与原型边界

`AdaptiveVitGroup` 的缓存只跨越 block31–38 的输入/输出，`reuse_finish` 读取 f32 anchor 并执行差值修正。各内部 ViT 核已经接收相同 reuse_gate，命中复用时直接返回；刷新时完整执行。故内部张量压成字节与复用并不天然冲突。

本轮原型 V 只改 attention→n64 projection 接口：

- 生产者使用现成 `ByteOut` 模板，写 `byte_F(Hrtz(...))`；消费者一次读八个 FP8 字节，取代八个 f32 的读取与 pack。
- block 输入、contract残差、整组输出、缓存、复用判断全保留现有形态；原来的 norm_inverse/求和顺序不变。
- 无须压缩缓存，也无须在 EXACT 和 AE 间搬缓存；已有 gate 同时挡住这两个核。
- `HIP_VIT_AV_BYTE` 默认0；只在实验目录 prepare.py 生成的两个模块一起开1。**目前是成对模块的实验 ABI，仅验证生产 n64 路线，不可单独替换任一模块或用于非 n64 投影。**生产化应另起明确 byte 输入的 kernel 名称，由 host 检查生产者/消费者匹配，再同步 RE9 入口。

完整 `vit_byte_stream` 的 host 互斥可以从结构上解除，内部核已有 gate，且 block31 会重置 vit_in8。但它会选回旧版投影、不同权重布局等路径，不能仅删互斥就声称相对当前生产逐位且更快。先保留 n64/fragment 核，把字节接口逐段接上，是本轮原型所验证的方向。缓存压缩留后续，不是本轮的必要前提。

## 实测

双架构编译通过；gfx1201 EXACT七组84帧、AE七组84帧，全部RGB逐位。连基线共336帧hash，44个进程均确认n64 requested/active=1。AE另外逐行比较84组决策：43次reuse、41次refresh，reason与三个差值统计均一致。静态序列含长期命中，运动序列含周期刷新和图像阈值触发刷新；不是仅测全算路径。

| EXACT ABBA，每槽1000帧弃前200 | 批1 A→V | 批2 A→V |
|---|---:|---:|
| 900 | 9.3413→9.2989（−0.0424ms） | 9.4424→9.3966（−0.0458ms） |
| 1080 | 12.9547→12.9005（−0.0542ms） | 12.9857→12.9414（−0.0443ms） |

约−0.34～−0.48%，比指令比例小得多：只改了ViT中的一条接口，shader请求字节也不等于DRAM实流量。这里没有测AE帧率收益，AE用例用于兼容性/逐位验证。基线仍为round2，**未把V与finish F相加或合测**。

原型不装游戏，作为任务允许的“账 + 可行性 + 最小原型”交付；C32成熟改动已单独部署。下一步是明确byte kernel名/host匹配，保持n64和复用兼容，再逐段扩到contract→QKV的精确f16接口。已有完整byte_stream互斥没有在生产中直接删除。

原始measurements.csv、frame-hashes.csv、adaptive-decisions.csv、correct/timing/adaptive日志及summary.json保留本目录。远端模块、完整RGB在实验根。V双模块各架构哈希见module-hashes.txt；prepare.py生成实验源码，生产hip/deep_fast.hip与vit_wide_deep.inc本轮不改。
