# 900 档逐核地图（2026-09-30，分析交付，未改代码/未装机）

**结论先行**：现役配方（剑星现装 b77bbc3c 同源：C256 持久化 + ViT attention 新核 + ViT QKV W5）900 档（1600×960）共 179 派发（175 条计时项，两段 C256 持久化各含 init/run/recover 3 派发合一项）。独立核中位数之和我方 **7258.6µs**，Daniel 0.5.0 reference 900（154 派发）**8171.6µs**；扣掉他在 42/43/46 上的 12 派发（288.9µs，我们跳块）后 7882.7µs。**这两个和都不是整帧**：同批整网回放 900 wall 8.03ms、1080 10.90ms（1000 帧弃 200）。

900 档真正落后 Daniel 的只有两处：**C32 浅层 +233µs**（同几何 1600×960，他也不是 1088 那种缩行）和 **C512 +182µs**（我们 50×30 比他 52×32 工作量还少约 10%）。C128/C256/ViT 都比他快（ViT 他 448 token、我们 400，不同形状）。

## 方法（与 kernel-map-20260929 同一 harness）

- **我方**：把 kernel-map 的 recorder patch 移植到 HEAD（`Development/HIP/experiments/kernel-map-900/recorder-v3-host.patch`），用现役 flat-P（vit-qkv lab 的 31 模块，vit-stream 与 build-prod 逐字节同）+ 现役 flags（SWIN_RUN1/PDL1/DIRECT_IO3/BENCH_PLAIN1/graph off）录 900、1080 各一帧：900 173 条、1080 156 条 Run 派发。合成权重规则不变（矩阵/bias ±1/64、增益 1、保结构零）。`gen-ours.py` 生成 typed jobs：沿用旧 ours-types.json，新增 9 个现役核的类型（400 attention/QKV W5/head 分组 c512 照同族；`mh_shift_pack` f32 进出；C256 PDL 四个核：消费端等待指针强制 null——源码 `if(!pflags)return` / `if(fflags)` 有空指针守卫——生产端 flag 给 1MiB 零缓冲）。
- **Daniel**：`make-shallow.py`/`make-daniel-deep.py` 改筛 `900-default` 行（W×H 1600×960、C512 52×32、head 28×16、ViT 448），46＋108=154 条。
- jobbench-v2：每 job 8 次 warmup、128 次串行 launch 图捕获、7 轮取中位；前后 CHECK guard=0/invalid=0/nonzero>0。**900 我方 173、Daniel 154、1080 我方 156 全部有效，0 条作废**（1080 第一批跑时同机混跑了交接探针，整批作废重跑，只用 `logs-ours1080b`）。
- **持久化 C256（sp_run256）jobbench 测不了**（设备队列，一次派发跑六层），用网络内事件估计：在 HEAD 宿主加逐派发 hipEvent（`event-profile-host.patch`，仅诊断，输出 hash 与不加时相同），事件法对每派发系统性多 43µs（173 项与 jobbench 对照的中位差，p10–p90 25–54µs），sp 两段 372/364µs 各减 43 → **约 329/321µs，标 est**，误差按 ±15µs 看。`event-profile-900/1080.csv` 是事件法原始逐派发表，只作参考，不作排名依据（小核被 43µs 底噪淹没）。

## 900 前 10 热点（我方，独立核中位数之和 7258.6µs 为分母）

|#|核|调用|总µs|单次µs|占比|对 Daniel 900|
|---|---|---:|---:|---:|---:|---|
|1|c32_wave1_prefix|1|654.9|654.9|9.0%|他 647.7（+7，同几何）|
|2|sp_run256（C256 持久化，est）|2|649.9|324.9|9.0%|他 C256 16 派发合 1579；我方 C256 全族 1001（−578）|
|3|c32_wave1_post|1|603.6|603.6|8.3%|他 534.8（+69，post 位移 (-4,-4) 多 1.3% 窗口，属几何差）|
|4|c512_qkv_attention_compact|13|601.7|46.3|8.3%|他 attn3 13 次 640.3（我方 −39，他 52×32）|
|5|c32_wave1_chain|4|497.5|124.4|6.9%|他同位 118～121/块（每块 +4～6）|
|6|c128_wave2_bi_bo|8|467.6|58.5|6.4%|C128 族我方 −132|
|7|c64_wave2_bi_bo|4|330.9|82.7|4.6%|他 87～90（我方略快）|
|8|mh_attention_project_frag_c512|13|214.4|16.5|3.0%|他 vit_conv 系 26 次 265（我方 −51）|
|9|vit_stream_qkv_frag_hin_w5|8|212.6|26.6|2.9%|他 reg1d_qkv 404.2（448 token，形状不同）|
|10|c64_wave2_bi|2|210.9|105.4|2.9%|他 91～111|

族汇总见 [family-900.csv](family-900.csv)：C32 2390.5 vs 2157.3（+233）、C64 779.6 vs 740.7（+39）、C128 774.0 vs 906.1（−132）、C256 1001.2 vs 1579.1（−578）、C512 1469.2 vs 1576.1（含他跳块 288.9；同结构 **+182**）、ViT 805.6 vs 1189.4（−384，形状不同）、head 18.8 vs 13.5、decoder 19.7 vs 9.5。

## 与 1080 对比（同方法、同现役配方，1080 独立核和 10117.6µs）

完整表 [compare-900-1080.csv](compare-900-1080.csv)。像素比 900/1080 = 0.694，绝大多数核落在 0.66～0.76。偏离的：

- **900 独有**：`mh_shift_pack` 13 次 128.7µs（1.8%）——900 的 C512 网格 50×30 不是整窗，每个 C512 块前要把 f32 特征压成紧凑布局；1080 60×36 恰好整窗走 identity，没有这一步。C256 非持久部分 900 走 `mh_ffn_fused_c256_…_pdl`＋`c256_attn_wave(_bo)`（7 派发 300µs），1080 是整块融合 `c256_wave2_bi`（09-28 "900 C256 新分组"已交负账，别重复）。
- **900 相对偏重**：`c512_qkv_attention_compact` 比例 0.85（占比 8.3% vs 1080 7.0%）——50×30 的窗口半满、448/560 两种 grid 交替，工作量不随像素缩；`vit_stream_contract_frag_hout` 0.79、`split_mix` 0.76。
- **900 相对偏轻**：`vit_attention_fused_400` 0.30（400 vs 640 token，注意力随 token² 缩）；`split_projection_frag` 0.61、`c128_wave2_bi_bo` 0.62。

## 900 逐位候选（按"收益×把握"排）

1. **去掉 900 的 `mh_shift_pack`（约 0.10～0.13ms，把握高）**：纯搬运、13 次每次 ~10µs。做法是让上一块的出口（`mh_attention_project_frag_c512`/`split_projection_frag`）直接按紧凑布局写，或让下一块的入口按映射读（1080 已经是 identity 路径）。只改地址不碰算术，天然逐位。900 是玩家最常用档，这是唯一"900 独有、Daniel 没有"的整块开销。
2. **C32 上采样首块 `c32_wave1_up`（+64µs）与 block4 `finish_dcrop`＋`pool_project_production_h16w`（184 vs Daniel 137，+47µs）**：同几何可比，他把 up/down 融在 swin32 核里（flags 8/4）。我们 C32 普通块已经只比他多 4～6µs，边界块多 20～60µs——值得逐条 ISA 对齐（照 09-28 "对照物比招式管用"）。把握中。
3. **C512 FFN 链（split_mix＋split_ffn＋split_projection 三核 524µs vs Daniel vit_ffwd 13 次 382µs，+143µs）**：差距真实，但 C512 FFN M32、单wave寄存器 R/RF 都是负账，FP8 展开有旧 10-float 反例；只能换组织方式，把握低。
4. **`c512_qkv_attention_compact` 900 占比偏高**：已经比 Daniel 快，余下是半满窗口的浪费（448/560 交替）；收益小于 1。
5. **C32 post +69µs**：主要是 post 位移几何（NVIDIA 原版位移，不追）。

## 文件

`ours-900-dispatch.csv`/`daniel-900-dispatch.csv`（逐派发 µs、状态）、`ours-900-kernels.csv`（每核 µs/调用/占比）、`family-900.csv`、`compare-900-1080.csv`、`ours900-jobs.json`/`ours1080-jobs.json`/`daniel-*-900.json`（job 定义）、`record-*-jobs.txt.gz`（recorder JOB 行）、`sp-estimate.json`、`event-profile-*.csv`、`jobbench-logs.zip`（三批全部原始日志）。复现脚本 `Development/HIP/experiments/kernel-map-900/`（工作根 9070 `D:\DLSSNR-Lab\hip-backend\kernel-map-900-20260930`，本地工作目录脚本里写作 /tmp/kernel-map-900）。
