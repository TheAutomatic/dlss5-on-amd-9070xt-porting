# Daniel reference 对照与隔离候选

报告：`Development/results/daniel-kernels-20260928/README.md`。

离线：任务给定d050原二进制/反汇编，加当前float FMA生产COMGR ISA。`offline/dispatch`追host注册/分派，`offline/isa`分类与loop模型；`reproduce-offline.sh`先复制这些快照脚本回其原/tmp工作根重跑。`ours-census.py`、`layer-pairs.py`、`family-budgets.py`给当前40核、位置对应和明确条件的模型。大二进制/完整ISA留/tmp或远端，不入仓。

实验根：`D:\DLSSNR-Lab\hip-backend\daniel-kernels`。

- `snapshot.ps1`只读保存现场60模块与4个宿主/配置SHA；`flat-A`是float FMA基线。
- 用 `prepare-candidates.py <临时目录>` 将两份零上下文patch应用到隔离复制的`hip/`，而非生产仓（手动git apply需`--unidiff-zero`）。`W2_PACK_NOZERO`默认0，P=1；`CW_WEIGHT_CACHE`默认0，Q/R/C=1/2/3。两架构build，默认关闭代码段对现场相同。
- P：七EXACT＋七AE，每组12帧，强制A/P逐位；两档两批1000帧ABBA。Q/R/C：1080-motion12帧短正确性，随后两档两批200帧短筛。
- `regression.ps1`最终已对齐新zero-copy runner/assets、DIRECT_IO=3和BENCH_PLAIN=1。P原r1/r2由于无法排除外部benchmark-zc并发而隔离，`align-direct-io.ps1`保存旧目录；`retest-direct-io.ps1`重测P并补C组合。
- guard必须匹配`^benchmark`前缀，不能只匹配`benchmark.exe`。本次未杀其他人的进程。
- `collect.ps1`排除`overlap-rejected`；`analyze-results.py`比较所有已检查候选帧到float FMA golden、AE决策字段及ABBA。
- 所有候选未达0.5%，实验patch不合生产。对当前宿主只读核对：abef6155＋DIRECT_IO=3，后续部署要从这套重新备份，不能覆盖成旧宿主或flags。

计时序列存档区分旧host短筛与新host重测；不跨批比较绝对帧时，不把循环路径总和、逻辑字节或带宽等价时间当硬件计数器或实测族差。
