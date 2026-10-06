# 复现

实测基线 445a832 / 第五刀。报告 `../../../results/aco-lineup-20260928/README.md`。

1. 当前生产配方已打开 `CW_ACT_FMED3=1`、`W2_BOUNDED_RCP=1`。新宏源码默认 0。`build-clean.ps1` 以显式 0 重编 Z，对旧现场；按配方重编 P，对实测组合 C。脚本中的远端路径为本轮实验目录。
2. `regression.ps1 -Set R/C -Batch correct -CorrectnessOnly`，随后 `-Batch adaptive -Adaptive 1 -CorrectnessOnly`；`-Batch r1/r2 -TimingOnly` 各跑两档 ABBA。modules-A 必须是第五刀不可变快照。实验需要独占 GPU，不能同时编译或跑另一套计时。
3. `collect.ps1`、`collect-adaptive.ps1` 导出；`analyze-results.py <results目录>` 核对 12 帧全幅 hash、全部 AE 字段和 ABBA。没有独立 ACT 整网计时，不能由跨批绝对帧时推导它的净收益。
4. `phase.py`/`extra_phase.py` 读 `/tmp/aco-lineup` 的不可变 debug ISA 与 generated HIP；循环权重和源码行是本轮快照专用。`baseline-identity.json` 钉源 hash，改源码须先重新核对行号。C32 尾部权重未完成通用化，**只有所选两个主体段进入排行**。
5. `aco_phase.py` 顺 ACO 临时值 ID 追激活、softmax 到 FP8 输出。后分配器的 `%0` 是无身份临时值，必须排除，不能当成共享 SSA 值传播。`rank.py` 乘本方真实 wave 数；C32 完整体 BB19 与四个边缘体互斥；C256 FFN 每 wave 的激活量按 1/8 换算。

大文件仍在 DGX `/tmp/aco-lineup`、9070 `D:\DLSSNR-Lab\hip-backend\aco-lineup`。生产 `.generated.hip` 从 `mochizuki-022/census` 复制；debug 编译用 `RTC_EXTRA_OPTS=-gline-tables-only`，需要先证明三个 ELF section 与无 debug 基线相同。ACO 构建器/反射器是 `results/aco-isa-20260927/tools`；使用 228d3a6 的 `linux/shaders/rdna4/pipelines.json`，glslang 16.5、Mesa 26.2.3。精确定义与 ISA hash 在 `aco-provenance.json`。

M/N 为 ISA 阶段淘汰的 half 直入写法，生成源留远端 `build-M-*/build-N-*`；不会进配方。`CW_ACT_FMED3.patch`、`W2_BOUNDED_RCP.patch` 是相对本轮旧基线的两处源码差分，当前仓库已经包含它们，不要重复 apply。
