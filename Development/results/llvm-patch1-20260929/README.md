# LLVM21第一刀：VOPD前瞻配对逐位，但未达到0.5%门槛

**实验交付，生产不切换。** 在公开LLVM21 fork的 `GCNCreateVOPD` 增加默认关闭的局部前瞻，43个活跃核多配成513对VOPD、同时新增153条等待，净少360条静态指令。168个候选帧全部逐位、AE决策全同；对驱动版900快0.15～0.36%，1080慢0.03～0.15%，没有达到任一档至少0.5%的目标。

fork提交 **`269832faf25b`**，分支 `dlss5-gfx12`，LLVM仍基于 `6d585d87`。代码与两份MIR测试也保存在 [fork.patch](fork.patch)。没有修改HIP生产源码、配方、用户flags或游戏文件。

## 为什么选这刀

现有 `GCNCreateVOPD` 最终只合并相邻指令。虽然post-RA调度器有greedy配对mutation，实际产物里仍有独立可配对的MOV/算术被少量寄存器操作隔开。先从现有ISA筛同源MOV的保守证据，再以LLVM自己的opcode/物理寄存器约束检查实际配对，不凭文本启发式决定变换是否合法。

按最新900/1080 trace的实际groups×threads/32核对调用权重，热点包括ViT expand、C512 split FFN/QKV、C32 chain/prefix/post。`TOPO`两列分别为items、groups，权重取groups；没有把逻辑items当派发组数。初筛及片段见 [mov-pair-evidence.json](mov-pair-evidence.json)，实际改动按调用权重排序见 [call-weighted-opportunities.csv](call-weighted-opportunities.csv)。该排序仅是静态函数体×launch waves的代理，未乘循环次数/分支概率，不冒充每帧动态指令数。

选择后置配对是因为它有具体漏配证据、能够保留寄存器分配和算术，而不是再改已被源码绕过的clamp/转换/倒数。未凭静态wait数量宣称存在等量硬件停顿，也没有盲删wait。

## 补丁位置与边界

- `llvm/lib/Target/AMDGPU/GCNCreateVOPD.cpp`：新开关 **`-amdgpu-dlss5-vopd-lookahead=N`**，默认0；本轮N=4。编译时经 `-mllvm` 传入，只对我们的模块启用。
- 仅gfx1200/1201、wave32、非strictfp函数。在同一基本块内寻找独立的后续指令，保留现有 `checkVOPDRegConstraints`（opcode、bank、literal等限制）。
- 不跨内存、WMMA/MFMA、inline asm、bundle、同步/硬件寄存器边界；RAW/WAR/WAW检查包括隐式EXEC/MODE/VCC及物理寄存器别名；移动时清除旧kill标记。
- 寄存器已经分配完；后续原有memory-legalizer、waitcnt、MODE、hazard、delay pass重新生成必要等待。没有改浮点操作、归约顺序、量化或寄存器分配。

两个MIR/FileCheck文件、5条RUN全部通过（默认关、gfx1100不启用、独立正例、RAW/WAR/WAW、EXEC别名、MODE/内存/同步边界、kill与距离）。见 [lit.log](lit.log)。三个真实模块的Clang backend `-verify-machineinstrs` 通过，涵盖17＋104＋76个导出；验证对象三段与实际候选对象一致，见 [machine-verifier.json](machine-verifier.json)。完整C32 MIR直接回读曾遇到原有隐式VCC/VCC_LO描述不匹配，未以该回读作验证证据，改用真实BC直接经过完整backend verifier。

## 构建与逐位

默认关off、启用P均从同一生产配方完整编60份；拼接源码SHA逐一与之前基准相同。**off对未打补丁公开21：.text/.rodata/.note全部60/60相同**，见 [default-off-identity.log](default-off-identity.log)。P与off按每架构996导出逐核比较，两架构共1992个：188函数字节同、1804有变化；**全部kernel元数据相同**，包括VGPR/SGPR/LDS/private、spill、参数和波宽。因此静态驻留上限没有改变；gfx1200只编译，真卡为gfx1201。

EXACT/AE各七用例×12帧，共168候选＋168驱动基线帧，全读回检查：无NaN/Inf，两侧全部命中09-28 float FMA goldens；AE84行所有字段同、44复用/40刷新。见 [validation-P.json](validation-P.json)、[adaptive-P.json](adaptive-P.json)，原始hash/CSV/flags/log在 `replay-evidence.zip`。性能只在通过这个门后开始。

编译器是在fork提交前构建的，`--version`仍显示94aca371；不是拿该文档提交当补丁代码。实际C++源码SHA、编译器二进制SHA与新fork提交的对应见 [build-identity.json](build-identity.json)，60份产物及全部编译参数在 `off-manifest.json`、`patch-manifest.json`。

## 整网结果：两个基准分别ABBA，不跨批相减

同一生产host `799a47ad…`、相同资产/flags，EXACT、PDL1、DIRECT_IO3/BENCH_PLAIN1、graph off；每槽1000帧弃200，仅首尾读回。公开21与驱动21分别做两轮900/1080 ABBA，共32长槽、32000计时帧；原始800点均值逐槽重算。口径为完整NativeGameFrame回放wall时间，不是游戏FPS或纯HIP跨度。

|基准 / 轮次|900 基准→补丁 ms|变化|1080 基准→补丁 ms|变化|
|---|---|---|---|---|
|公开21 / 1|8.316066→8.312584|−0.042%|11.215927→11.197337|−0.166%|
|公开21 / 2|8.404309→8.380732|−0.281%|11.245972→11.223834|−0.197%|
|驱动21 / 1|8.392208→8.379759|−0.148%|11.215111→11.218029|+0.026%|
|驱动21 / 2|8.413816→8.383906|−0.355%|11.217114→11.234026|+0.151%|

公开版1080省约0.019～0.022ms，有小幅改善；对驱动版两档都未过0.5%，不采用为生产。不能挑900第二轮再四舍五入称过线。

精确数字：[timing-summary.csv](timing-summary.csv)、[32槽统计](timing-slots.csv)。计时帧仅首尾检查，不声称32000帧逐帧逐位。

## 这条路线的空间与限制

43个活跃kernel/module对的唯一静态函数体汇总如下；不是动态执行周期：

|族|新增VOPD对|新增WAIT类指令|净指令变化|
|---|---:|---:|---:|
|C32|111|35|−76|
|C64|50|7|−43|
|C128|50|8|−42|
|C256|89|24|−65|
|C512|78|36|−42|
|ViT|104|33|−71|
|边界/head|31|10|−21|
|合计|513|153|−360|

每族完整VALU/VOPD/WMMA/VMEM/SALU/WAIT及VGPR/spill在 [family-static.csv](family-static.csv)，逐核在 [active-kernels.csv](active-kernels.csv)。新调度下实际多了163条 `s_delay_alu`、少了10条 `s_wait_loadcnt`（[分项](wait-opcode-delta.json)），净增153条WAIT。配对后依赖间隔变短是合理解释，但没有硬件周期计数，不能把513对直接当513个周期收益。VMEM/WMMA工作与寄存器资源没变，原来的访存、矩阵供数、依赖链和公开版寄存器分配差距也没有被这刀解决。

N=8仅编C32/C64两个模块的gfx1201做静态探针：C32多2～4对但多数只净少0～3条；C64/C128部分反而长2～4条，C256 attention不变。见 [lookahead8-static-probe.json](lookahead8-static-probe.json)。没有把它当GPU候选、没有声称其数值或速度通过；扩大扫描已出现收益递减，未继续扫参数。

**本轮能下的结论是：现有post-RA配对的漏网空间存在，但局部前瞻这刀兑现不到0.5%；不能据此给整个编译器优化判定上限。** 更大的变化必须进入预分配调度/寄存器生命周期等其他问题，不能把后置配对再扫远一点当成同等潜力。本轮按够用交付，不扩成第二个无证据的大改。

复现：[tools/llvm-patch1](../../tools/llvm-patch1/README.md)。产物在 `~/work/llvm-patch1-20260929/` 和9070同名隔离实验根，未入库。[最终核对](final-state.json)确认现场64项未变、off/P的60份gfx1201实验模块hash未变。无游戏部署、无发包；fork保留默认关闭的实验开关。
