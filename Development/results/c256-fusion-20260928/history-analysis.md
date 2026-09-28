# C256 历史与最小接入（2026-09-28，只读）

## 先纠正两条历史的性质

`Development/results/transpose-persist-20260927/README.md` 的“C256 持久化已关”不是实现失败：标题写“未改源码”，正文写“没做实现”。原子领取(层,窗口)、核内等四个生产窗口这条路线只是被成本/预期收益筛掉。≤0.1ms 是根据 PDL 已覆盖部分流水重叠推测，不是 persistent kernel 的实测。报告的 C256 34 派发、1.954→1.860ms 是 PDL 0→1 的族账，不能作为融合只值0.1ms的证据；融合还可能省 feature/QKV 显存往返。

真正失败的是 `Development/results/c64-wave2-20260926/` 的整块 wave2 融合。`summary.json` mode3 = C256 only（对应 `Development/HIP/experiments/c64-wave2/prepare.py` 的模式表）：

| 900 短筛变体 | 相对当时 prod8 基线 ms |
|---|---:|
| row | +0.5184625 |
| frag | +0.4550625 |
| frag + launder | +0.2460000 |
| + sched | +0.3111188 |
| + roll | +0.2528875 |
| + hidden_tiles=2 | +0.2106813 |
| + hidden_tiles=4 | +0.3486063 |
| frag + defer-Q | +0.4876500 |

这些 mode3 是一组配对短筛，不是当前 float-FMA 基准的两档完整 ABBA。初版 private spill 确实存在，按 QKV tile 重引不透明 lane 后清零；零 spill 后仍慢，这排除了“只要修spill就成功”的说法。上面差值不能分解成单一因果：没有找到 C256 专门 occupancy/LDS-bank-conflict 的硬件计数器归因。不能把 LDS 冲突或低占用率写成已经证明的根因。

随后 mode6 保留原 FFN/QKV，只换 C256 一头一wave attention：900/1080 各三组200帧 ABBA -0.09923/-0.12809ms，所有首尾bitdiff=0、每帧16块正确替换。说明旧整体改写的前段/生命周期是值得关注的负担，但还不能从总时延隔离出某一条指令。

## 旧整块组织仍在当前源码

`hip/wave_owned_mh.inc::swin_wave2_body<C,ByteIn,ByteOut>`；c256_wave2 / _bi / _bo / _bi_bo 四个导出还编在 c64-wave2 模块中。

- 每组 C 个线程，C256=256线程=8 waves；一个8×8窗口一组，一wave负责一个32通道head。
- `plane0[64*C]` + `plane1[64*C]`，C256共32KiB LDS。初始input片段进plane0。
- 每wave收缩自己128 hidden通道；四个qt按循环处理，ht按W2_HIDDEN_TILES分组，expanded直接量化给contract，不落LDS。
- contract→plane1；跨头FFN混合读取plane1，叠原残差→feature覆盖plane0。
- 全头QKV读plane0，Q/K A片段、V反向直接B片段；按tile laundering限制寄存器活跃期。
- 每轮跨头数据交换用w2_sync（WG_FENCE3 + s_barrier + WG_FENCE2）。已有转置组织，不能以“Daniel用转置”当新增贡献。

当前完整C256导出的资源只能描述当前模块，不反推2026-09-26的资源数；历史README仅明确初版spill后来0，attention-only当时float/byte 151/142VGPR、32KiB LDS。

## 当前 host 分流

`Development/HIP/hip_reference_network.h::Body` 约353行：`wave_owned_active && (c==64 || c==128)`才走整体wave2。
整体路径已经具有正确输入/输出接口：原input、`PackedFusedMhWeightFrag`、`WaveOwnedAttentionWeight`、w/h/ww/hh/sx/sy/post，导出名按ByteIn/ByteOut拼接；返回前Stage。分配输出按byte_out压缩；进入时清pdl_prev/pdl_ffn_flags/pdl_anyorder。

C256落到生产分体路径：FFN/QKV `mh_ffn_fused_c256_frag_project_mapped_g128_qkv[_bytein]_fb[_pdl]`产生feature与norm；`AttentionFast`约326行 `wave_owned_active && c==256`转 `c256_attn_wave[_bo]`，通过现行PDL旗子衔接。

## 最小离线实验接入

1. 从当前HEAD拷贝/独立worktree出runner头文件，添加默认0编译宏（例如 `HIP_C256_WHOLE_EXPERIMENT`）。仅扩展Body的整块选择条件为原条件或 `(macro && c==256)`。
2. 保留该分支所有契约检查、输出shape、post标志、权重打包、PDL状态清理、Stage，不重新发明新runtime选项。既有Run对c256-wave导出使用256 threads，一个window一group，模块加载已有。
3. 先把现有C256整块核作为“当前算术基准上的旧结构”对照，再用新模块组织替换同名导出。这样区分历史struct重测与新Daniel组织，且能只替换模块比较。
4. 当前装机host不会因只换模块自动调用C256整块：host条件硬排除了256。若候选胜出，生产接入仍需一个很小的host路由改动/重编，不能谎称部署只换模块就完成融合；实验可不新增用户运行开关。
5. 不把旧 prepare.py 原样运行到新树，它依赖旧文本锚点和prod8默认，适合作历史契约参考，不是当前可用执行脚本。

## 限制

未读/用9070，未修改生产。WorkingPlan“已关路线”并不构成不能按新证据重开；此轮用户明确授权重新比较。旧计时基准早于float FMA/后续供数优化，不能拿旧 +0.21068ms直接否决新组织。

## 追加：分体与旧融合的确定结构差别

生产 `mh_ffn_qkv_body<C256>`（multihead_fast_padded.hip）：每组16 token，512线程=16 waves；wave编号0..15。FFN expand每wave负责64 hidden输出（4个16宽tile），16 waves合计1024 hidden。expand在K=256上循环16次，每次取一个输入A片段供四个输出tile。contract每wave负责16输出通道，两相邻wave同属一个32通道head，按 `(wave/2)*128` 选同一128 hidden组。随后mix/QKV在同一16-token组完成。

旧整块 `swin_wave2_body<256>`：每组64 token，256线程=8 waves；wave=head，每wave32通道、128 hidden。四个16-token qt串行；每qt hidden以W2_HIDDEN_TILES=2分四轮，每轮两个expanded片段，对256输入通道循环16次。contract两个16输出片段留在寄存器；随后整组交换contract、feature。QKV同样四个qt在每head wave内完成。

因此对相同64-token窗口，生产前段是**4个独立组×16 waves=64 wave任务**，旧整块是**1组×8 waves=8 wave任务**。旧融合把前段沿token的4路组并行和沿head输出半块的2路wave并行，改成每wave约8倍矩阵工作；attention阶段两者均1组×8 waves。不是矩阵数学少了8倍，而是工作分配粒度变粗，跨窗口总组数减少四倍、前段wave任务数减少八倍。这是源码事实；是否因此不能藏延迟/占用不足，仍需实际计时或计数器。

以每64-token窗口的expand计，FP8 WMMA动态wave指令总数两者相同：生产4组×16waves×16K×4tile=4096；旧融合8waves×4qt×4hidden轮×16K×2tile=4096。权重B片段随每次WMMA取，理论总数也一样，旧融合**没有因合核自动减少expand权重加载**。输入A片段读取则生产4×16×16=1024次wave级fragment读取；旧融合8×4×4×16=2048次，原因是HT2只复用到两个expanded，生产一次A供四个expanded。ByteIn生产A直接从global取，float输入则协作入LDS；旧融合初始统一入plane0，随后这2048次是LDS读取，不能把不同存储层级的数量直接等同耗时。HT4把旧融合A读取降回1024，但旧实测HT4更慢（+0.3486 vs HT2 +0.2107），说明“少读一定快”不成立。

旧融合获益点是expanded不进LDS、contract/feature/QKV不出全局内存；付出是更粗的前段任务划分、完整窗口QKV寄存器活跃期、跨头交换阶段。生产hidden必须落LDS并同步；完整融合保留Q/K/V片段和query索引，在同一kernel生命周期涵盖FFN到attention。不要把这些结构负担擅自排序为已经证实的瓶颈。

## 追加：准确块数与派发口径

按当前RunGraph（hip_reference_network.h）真块号是encoder **15～22**、decoder **48～55**，共16个C256块。`c512-round1/.../run.log`的TOPO标签记录的是上一Stage名，故看上去14～21、47～54，不能照抄为真实块号；矩阵维度/组数仍有效。

准确归属可用 `family-ledger-wave-owned-20260926/1080-pdl1/topology.csv`（Stage游标回填）核对：C256族34派发=16块×2 **+进入该族的pool C128→C256一次 +进入decoder C256的Up一次**。不是17个C256块；也不是把C256→C512的pool算在本族（它在后续C512区段）。

只把16个C256块两派发合成一派发：当前214→**198**整网派发；C256族34→**18**，其中16融合核+两次上下采样。不能声称本轮直接把34变16，除非另把pool/Up融合进去。

按旧TOPO工作尺寸计，900所有C256前段合计6656组×16waves、attention1664组×8waves；1080为9424组×16waves、attention2356组×8waves。整块后分别1664/2356组×8waves承担全部工作。注意这是调度任务计数，不是GPU驻留wave或总算术量减少比例。
