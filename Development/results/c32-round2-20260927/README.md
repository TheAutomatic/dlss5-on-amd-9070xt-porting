# C32 第二轮：调用加权、MODE 与 prefix 尾部（2026-09-27）

基线是上一轮已通过剑星验收的组合：`CW_DIRECT_OUT=1`、`CW_RTZ_PAIR=1`，gfx1201 `05359b6a…`、gfx1200 `2d345933…`。实验根 `D:\DLSSNR-Lab\hip-backend\c32-round2`。本轮保持 PDL=1，固定求和树、倒数修正、Q/K half 平方与累加均未改。

## 先修账，再选刀

上轮派工引用的 projection 876 条是旧账；当前 chain 的这段已是 **448 条**，激活/hidden 打包仍 1632，QKV 归一化/量化 720，score/exp 664、softmax 588。已删除的往返不重复计收益。baseline 加 debug 行号后的 `.text/.rodata/.note` 与原模块相同，来源见 `baseline-source-phases.json`（通用核源码归属）；最终调用加权账另按实际路由剔除 down=null 的死分支。

10 次 C32 派发的实测轨迹与 `hip_reference_network.h` 分派、`native_runtime_shifts.h` 完全一致。按“每窗口普通向量指令×真实窗口数”排序：

| 核 | 块号 / 次数 | 900 窗口合计 | 1080 窗口合计 | C32 向量指令份额（1080） |
|---|---|---:|---:|---:|
| prefix | 0 / 1 | 24000 | 34560 | 29.42% |
| post | 70 / 1 | 24321 | 34945 | 26.08% |
| chain | 2,3,67,68 / 4 | 24442 | 35090 | 20.86% |
| mapped | 1,66 / 2 | 12000 | 17280 | 11.03% |
| finish_dcrop | 4 / 1 | 6100 | 8760 | 6.59% |
| finish | 69 / 1 | 6100 | 8760 | 6.03% |

prefix/post 各一次，却运行全分辨率，合计约 **55.5%**。这决定本轮优先级；份额是指令工作量，不是测得的时间占比。完整内部窗口/历史开启路径是上界，边界分支少做的指令未逐窗口模拟。**69 的 down=null，本账明确跳过其不执行的下采样分支**，没有把通用核所有出口都算进去。详见 `baseline-weighted.json`、`ledger.py`；14 个回放进程的前10次实际派发均核对一致。

### SALU/WAIT 为何多

prefix 尾部约 955 SALU、1096 WAIT；其中 WAIT 主要是 `s_wait_alu` 645、`s_delay_alu` 333，`s_wait_dscnt` 113。finish_dcrop 尾部约1682 SALU、1587 WAIT，主要是坐标/地址、裁切条件和循环依赖。源代码64次主输出遍历在基线是每轮两像素，实际32轮；新候选有的展开成每轮4像素，统计脚本跟踪 ISA 的增量和终值，不能继续乘32。

这些裁切条件**已经是 wave-uniform**：同一 wave 的32个 lane写同一像素的32个通道。问题是对每个像素重复计算相同形式的标量边界，而不是 lane 分歧。prefix 的窗口完整、sx=sy=0，bounds 检查恒真；finish/dcrop 的边缘窗口确有裁切，不能一起删除。WAIT 条数不是等待周期，大幅删标量指令不保证等比例加速。

## MODE 必须先统计，且不能只看 RGB 回归

`CW_PACK_CENSUS=1` 给6种核×7处打包点做真实 GPU 统计（不是修改数值再观察是否传到最终 RGB）。记录 wave pack 调用数、含非有限值的 wave 数、超过448/1的 wave 数、最大绝对有限值。

七用例共 **888378240 次 wave pack**（每次32 lane×8个输入，包含重复回放，不是独立样本）；294行统计全部 `nonfinite_waves=0`、`over448_waves=0`，最大 **388.088379**。`over1_waves` 大量非零，确认统计活着。统计版七用例输出与基线逐帧同 SHA。

| 打包点 | 最大绝对值 |
|---|---:|
| input/prefix | 343 |
| hidden activation | 296.786957 |
| feature | 345 |
| QKV | 388.088379 |
| probability | 0.983491242 |
| AV | 356.1875 |
| chain/mapped output | 351.25 |

证据 `census.json` / `census-detail.txt` / `census.log`。范围结论限定于这套语料；MODE 饱和与 clamp 对非有限值并非同一语义。

### 拒绝 B：intrinsic 开关被搬空

最初 B 用 `__builtin_amdgcn_s_setreg` 包四个 FP8 转换。七用例虽然逐位、计时也变快，但 ISA 里有 **38 个空 MODE 段**：开→关紧挨着，QKV 的转换被移到后面。语料未越448，所以“没饱和但暂时也不溢出”照样能过 RGB 回归。这种实现不采用，源码里已经删除该路径。现场片段见 `rejected-empty-mode-segments.json`；B 的计时仅留作诊断，不作为正式收益。

### 采用 M：源内固定段

`CW_PACK_MODE_MASK` 每一位对应一个打包点，默认0。启用的点在 HIP 源码中用一个短 inline-asm 块执行：MODE.FP16_OVFL=1 → 四次两值 FP8 转换 → MODE.FP16_OVFL=0。这是像现有 Hrtz 一样的源码原语，由正常配方编译；没有修改生成的 `.s` 或部署手改汇编模块。

两架构 ISA 审计确认：每个段恰有4次转换，没有 f16 收窄/packed-half 运算混入，全部恢复 MODE。探针直接调用同一个 helper：65536个half编码中有限值零差异；2048个非有限编码不同（已知边界）；MODE恢复错误0，段后的 RNE f16 溢出错误0（仍为Inf，不变成65504）。见 `mode-probe.log`、`mode-audit-*.json`、`final-mode-audit-*.json`。

## 其它候选与没走的捷径

- **C / CW_PREFIX_DIRECT_OUT**（默认0）：prefix 字节尾部还有 `fp8(F(half_value))`，改成 `fp8(half_value+0)`，保持精确负零归一化及非零负值下溢行为；复用上轮的全half编码恒等式验证，另过本轮完整回归。
- **D / CW_PREFIX_FULL_TILE**（默认0）：只在 prefix 的完整8×8窗口去掉恒真的逐像素裁切判断；其它 finish 的边缘裁切保留。网络支持的处理尺寸均为8的倍数，prefix 的窗口数是 W×H/64，输出地址范围不变。
- **FMA 不采用**：E4M3 是整数×2^-9，零起累加的有限点积保持在2^-18网格。对[-4,4]的2097153个网格点做 CPU 初筛：q合并3个、p合并66个、两者合并68个 FP8 反例。q 的反例包含非零码 `94→95`，不只是零符号；足以否定通用恒等式，没有拿“七张图看不出来”替代它。源码/反例在 `fma-grid.cpp` / `fma-grid-cpu.txt`。没有改动实际多项式。
- score 的“先加偏置再乘23/512”不能直接挪成预计算偏置项；本轮不重新结合非零乘加。score/exp、固定归约、倒数修正保持原样，M只动后续量化。
- 上轮普通 clamp→med3 的结果接近噪声，本轮未重复包装为新收益。三条已关闭的路线均未重开。

## 指令与测试

当前基线→候选的每窗口普通向量指令（按实际finish无down路径）：

| 核 | 基线 | M 固定MODE | C prefix直接量化 | D prefix完整窗口 | E=M+C+D |
|---|---:|---:|---:|---:|---:|
| chain | 4648 | 3781 | 4648 | 4648 | 3781 |
| mapped | 4989 | 4232 | 4989 | 4989 | 4232 |
| finish | 5381 | 4619 | 5381 | 5381 | 4619 |
| finish_dcrop | 5879 | 5115 | 5879 | 5879 | 5115 |
| post | 5835 | 4909 | 5835 | 5835 | 4909 |
| prefix | 6656 | 5744 | 6384 | 6656 | 5424 |

D 的 prefix SALU **1163→598**，WAIT **2347→1622**；E 加回 MODE 段开关后 SALU787、WAIT1489。M 的 VMEM 每窗口多8条（不透明段限制了一些调度/复用），净收益以整网测试为准。

M/C/D/E 均双架构编译、gfx1201 七用例84帧逐位、900/1080各两批ABBA（1000帧/槽，丢前200，计时只首尾读回）。gfx1200只编译，无实卡证据。完成数字和部署见下方最终记录。


## 最终记录（19:20）

正式候选及组合的两批 ABBA，候选减基线（ms，负数更快）：

| 候选 | 900 第一批 / 第二批 | 1080 第一批 / 第二批 |
|---|---:|---:|
| M 固定段 MODE | −0.14452 / −0.13230 | −0.20723 / −0.19805 |
| C prefix 直接量化 | −0.03008 / −0.03279 | −0.02717 / −0.02636 |
| D prefix 完整窗口 | −0.01961 / −0.00760 | −0.01909 / −0.02298 |
| **E=M+C+D** | **−0.16734 / −0.18495** | **−0.25216 / −0.26534** |

组合：900 `9.47520→9.30786`、`9.58061→9.39566`；1080 `13.16883→12.91667`、`13.18528→12.91994`。即在上一轮基线上再省 **1.77～2.01%**。不能把各候选收益相加。这里是固定测试台的完整回放口径，不是游戏 FPS，也不是只测一个核。

M/C/D/E 各84个候选帧逐位同，共336帧。加上统计 CN 和被拒绝的 B，原始文件记录1008个 baseline/candidate 帧 hash；164条测试槽记录、164次实际 wave_owned=1/1 启动确认均核对。完整数据 `frame-hashes.csv`、`measurements.csv`、`timing-summary.json`、`startup-identities.txt`。

生产配方新增 `CW_PACK_MODE_MASK 127`、`CW_PREFIX_DIRECT_OUT 1`、`CW_PREFIX_FULL_TILE 1`。所有新宏在源码中默认0；诊断 `CW_PACK_CENSUS` 不启用。默认全关的最终源码重编与基线代码段相同；配方双架构重编与实测E代码段相同，见 `identity-checks.json`。旧 intrinsic 原型只保留证据和远端 build-B，最终源码不再提供该错误路径；build/suite 默认也不再跑它。

剑星已安装经过全部测试的 E：

- gfx1201 `ae95bdf6d52700e7ce978220ebd3466c9437aeccd69caf939bbd903850b05937`
- gfx1200 `e85c68c03d5fdbb9db11ce45093a80583f7f7f8d256bc01d8693c20795652974`
- 备份 `D:\DLSSNR-Lab\c32-round2-20260927\backups\stellar-20260927-192033`
- 还原：`powershell -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\c32-round2-20260927\install.ps1 -RestoreBackup D:\DLSSNR-Lab\c32-round2-20260927\backups\stellar-20260927-192033`

只换 c32-wave1 双架构并更新对应 checksum；add-on/dxgi/INI/flags 前后 SHA256 不变。游戏画面与 FPS 待 Zero，未发包。

## 复现与文件

实验脚本在 `Development/HIP/experiments/c32-round2/`；部署与回读证据在 `Development/deployments/c32-round2-20260927/`。stage 只允许首次保存基线；build 的每个集合显式覆盖本轮三个生产开关，避免配方变化污染 A/B。`build-host.py` 生成仅供统计的隔离 host（打印真实派发及读取 device global），生产 host 不加入统计。`census.ps1` 跑七用例，`collect-census.ps1` 保存42行/用例的计数；`mode-audit.py` 检查实际 MODE 段；`mode-probe.inc` 附到生成的 M 源上，测试实际 helper。`source-phases.py` 读取不可变的 build-A 源行号，不用于后来改过行号的源码。

最终源码/模块身份见 manifest、模块哈希和 identity-checks。手写短指令段保存在 HIP 源内，可从配方复编；没有对生成汇编打补丁。旧 B 虽通过七用例和两批计时，仍因空 MODE 段被拒，相关日志不应混入正式收益。
