# 自家 LLVM 构建链：60 模块编成，生产回归逐位通过

**已完成任务单四项。** 公开 AMD LLVM21 自编工具链可生成当前生产 HIP 模块，gfx1201 EXACT/AE 七用例各84帧全部命中09-28 float FMA golden，AE84行所有字段一致（44复用、40刷新）。没有编译器优化补丁，没有替换游戏模块，没有性能升级结论。

## 版本选择：ROCm 7.x 不等于 LLVM21

9070 实读 `C:\Windows\System32\amd_comgr_3.dll`：文件版本3.0.0.0，API版本3.0，SHA256 `5dbb6e593536bc5ca900c294b2e1f8c6c8873014c593d0f7cc245260ae99c4d2`。verbose probe 与所有现役模块 `.comment` 都指向内部提交 `590b9320a5be90e40268759c6203c01fde121e68` / Clang、LLD21；本地完整公开 amd-staging 历史无此对象。

实际检查公开标签版本源码：

|标签|LLVM主版本|提交|
|---|---|---|
|rocm-7.0.2|20|0dda3adf56766e0aac0d03173ced3759e1ffecbc|
|rocm-7.1.1|20|27682a16360e33e37c4f3cc6adf9a620733f8fe1|
|rocm-7.2.4|22|f58b06dce1f9c15707c5f808fd002e18c2accf7e|

选择 **`6d585d872fbd3c594da7a3c09ac9b22eef4167f6`（2025-07-15）**：公开 AMD first-parent 线上引入 LLVM22 的 merge `dec49e58…` 之前最后的 LLVM21，保留 AMD 分支补丁。它是同主版本的可复现候选；内部树不可见，不能证明其代码距离最近。原先“找个ROCｍ7发布分支就行”的假设已修正。

证据：[version-selection.json](version-selection.json)、[COMGR真实参数](comgr-probe.log)，上游[固定基点版本文件](https://github.com/ROCm/llvm-project/blob/6d585d872fbd3c594da7a3c09ac9b22eef4167f6/cmake/Modules/LLVMVersion.cmake)。已给 fork 加 upstream 并取上述标签。fork分支 `dlss5-gfx12`，文档提交 `94aca371a8e1`；未向上游提补丁。

## 构建与参数复刻

- 机器：DGX Spark spark-3a10，aarch64，GCC13.3、CMake3.28.3、Ninja1.11.1；LLVM Release，仅 AMDGPU，项目 clang/lld，16编译并行、2链接并行。
- 实际构建 **570秒（9分30秒，不含configure）**。输出 `~/work/llvm-build-dlss5-gfx12`，工具链与中间物约1.5GiB；增量构建复用同目录。
- `build.sh` 入仓；`compile-modules.py` 直接解析 `hip/build-modules.ps1` 的30行配方，所有宏与拼接段来自生产文件，没有手抄第二份配置。
- 按COMGR真实trace分阶段：HIP→优化BC→对象→LLD共享ELF；另生成汇编。Windows x86_64辅助ABI、C++14、short wchar、MS兼容版本明确指定；无HIP SDK/设备库/fast-math。CUID按长度+内容SHA256，与驱动probe结果完全一致。
- 两架构60模块全编过。源码、BC、对象、HSACO和完整反汇编在 `~/work/llvm-artifacts-20260929/`；产物不入仓。首次C32代表模块和整套重编的输出hash相同。

复现入口：[工具说明](../../tools/llvm-fork/README.md)。[build-identity.json](build-identity.json) 包含工具、配方、归档和回放host哈希；[module-manifest.json](module-manifest.json) 含60模块源/产物hash、完整命令和每模块耗时；完整构建日志 `llvm-build.log.gz`。

## 逐核差异

基线是13点后只读快照的剑星现役60模块，宿主 **ba010de7**，不是0.36旧发布包。传回DGX后逐个SHA核对；两架构都各有996个kernel导出（包含模块之间重复编译的通用/后备内核），总1992个逐一比较。

|项目|每架构结果|
|---|---|
|函数字节相同|0 / 996|
|静态反汇编指令总和|1,264,742 → 1,291,362（+2.10%）|
|VGPR元数据变化|392个导出|
|SGPR元数据变化|262个导出|
|LDS / private段大小变化|0 / 0|
|kernarg大小 / 完整参数ABI元数据变化|0 / 0|

`.text` 60份均不同；`.rodata`和`.note`各8份相同。差异包含真实指令与寄存器分配变化，不能仅归因CUID。静态总和包含重复/不执行核和未展开运行时循环，不用它预测速度。

另按今早1080 trace筛出**37个活跃导出、168次派发**：未加权静态指令90,477→91,157（+0.75%），14个核VGPR变化。示例：C128 bi/bi_bo159→148；C256 bi/bi_bo154→179；ViT投影120→136；ViT QKV96→94。LDS/private仍不变。公开版有得有失，未测ABBA，不替换生产编译器。

完整[逐核CSV](kernel-diff.csv)、[1080活跃核CSV](active-1080-kernels.csv)、[模块段汇总](summary.json)。完整指令/元数据明细及两侧反汇编保存在仓外comparison目录，可由脚本再生。

## 数值回归

9070空闲检查通过，实验根 `D:\DLSSNR-Lab\hip-backend\llvm-fork-20260929`。所有候选传输hash核对；两侧共用最新 `kernel-map\benchmark-production.exe`（SHA `799a47ad…`）、相同资产/flags，仅模块目录A/L不同。DIRECT_IO3/BENCH_PLAIN1、PDL1、graph off，非游戏安装。

- EXACT：720运动、900/1080静态与运动、900/1080历史，7×12=84候选帧。
- AE：相同七组84候选帧；84行frame/reuse/age/reason/relative/local/image全部同，44复用/40刷新。
- 候选168＋基线168共336帧逐帧全读回，无NaN/Inf；候选与现役基线相同，**两侧都独立命中09-28 golden**。
- 最初收集器用整数frame编号，而旧golden检查器使用文件名，因此先报覆盖命名不符；规范化为 `rgb-frame-N.f16` 后旧检查器通过，未改hash、未重算图像。脚本已修正后续输出字段。
- gfx1200只编译/静态对照；回归覆盖生产活跃路径，不声称996个后备导出全运行过。

[回归摘要](regression-summary.json)、[336帧hash](hashes.csv)、[AE逐字段对比](adaptive-comparison.json)。`replay-evidence.zip`保留28个槽的原始CSV/日志/flags和原始收集hash；计时是逐帧读回的正确性过程，不能拿来报告提速。

回归前后现场60模块和宿主/dxgi/INI/flags的64项hash未变。没有安装、没有新游戏备份、没有发包。

## 第一批补丁候选

详见[候选与语义边界](patch-candidates.md)：med3及NaN规范化、范围内精确倒数、可证明精确的half往返、有限条件下mul+add0、VOPD配对、等待/MODE依赖。已定位真实源码入口；MODE分段不列首补丁，避免再次出现转换越过开关的空段。

本轮的交付是可重建、能逐位的独立编译链；后续再拿一条真实指令差异做编译器补丁。
