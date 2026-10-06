# 第一批编译器补丁候选（只调查，未实现）

基于公开 AMD LLVM `6d585d872fbd3c594da7a3c09ac9b22eef4167f6` 的实际源码，以及本项目 ACO 对照账。收益指向未做手写优化的源码；现役内核已经手工绕开多数问题，因此不预报整网百分比。

|优先级 / 候选|实际改动入口|数值约束与边界|可能影响|
|---|---|---|---|
|1：有证明的 min/max→med3，消除多余 NaN 规范化|`llvm/lib/Target/AMDGPU/SIISelLowering.cpp` 的 min/max combine（约13900行）及 `performFMed3Combine`；先用 LLVM IR/MIR 小例定位重复规范化产生阶段|现有代码显式检查 `isKnownNeverSNaN`，注释解释 signaling NaN 在 IEEE 模式下与 med3 不同；不能无条件删。优先传播已有 known-non-NaN/非 sNaN 事实；若用专用属性，明确声明输入域而非全局开 fast-math。还须覆盖 ±0、±Inf、qNaN/sNaN 与操作数次序。|C32 激活夹值、C64/C128/C256 量化夹值；当前 fmed3 intrinsic 已消掉一部分，价值主要是让普通写法得到同代码。|
|2：已知有限范围 `1/x` 的精确短路线|`AMDGPUCodeGenPrepare.cpp` 的 `optimizeWithRcp`；或 `SIISelLowering.cpp` 的 FDIV lowering，保留现有通用回落|不能直接用近似 rcp。仅对被证明在 [1/256,624] 的 f32 正数使用本项目两次误差修正序列，原 gfx1201 穷举依据见生产 bounded-rcp 记录；函数属性/专用 intrinsic 负责表达域，不能把整数 `!range` 生搬到浮点。跨架构和 denorm/舍入模式仍需验证。|softmax 分母；当前 wave-owned 已显式实现，可用朴素 `1.f/x` 对拍同生成代码。|
|3：精确值域内的 f32↔f16 往返清除|`llvm/lib/Transforms/InstCombine/InstCombineCasts.cpp` 的 `visitFPTrunc` / `visitFPExt`，以及 AMDGPU 对 `cvt_pkrtz`/位操作的 target combine|`fpext(fptrunc(x))` 一般有真实舍入，禁止通用删除。只消源本来是 half/有限 E4M3 格点且中间操作未离开可精确表示域的路径；RTZ、RNE、NaN payload、负零分开处理。本项目“直接FP8”和“先half再FP8”的反例仍是拒绝门。|C32 mapped/post 输入、C512/ViT 接口；现有 byte/half 流已绕过不少站点。|
|4：`(x*y)+(+0)` 的专用收缩|`llvm/lib/CodeGen/SelectionDAG/DAGCombiner.cpp::visitFADDForFMACombine`；优先 AMDGPU 局部 combine/受限属性，不改全目标默认|不能仅因为加数为零就说严格 IEEE 等价：乘积负向下溢先舍入成 -0，再加 +0 与单次 FMA 的零符号可能不同；NaN/Inf、异常及 denorm 模式也要单列。只在证明乘积不下溢/溢出且零符号满足合同，或后继量化明确消除差别的局部序列启用。任意两层激活乘加收缩不属此候选，已有反例。|W2_Q8_SETF 等乘积打包站点；当前显式 fmaf 已解决，先验证能否把这个事实自动识别。|
|5：VOPD 配对与寄存器银行约束|`GCNVOPDUtils.cpp` 的调度 mutation、`GCNCreateVOPD.cpp`；流水线在 `AMDGPUTargetMachine.cpp` 中先 VOPD 再 waitcnt|保持每线程依赖、寄存器银行/操作数编码限制、EXEC 与隐式状态依赖。仅配对不允许改变浮点算术顺序；静态配对增加仍须完整网络计时，不能由槽数推收益。|所有 wave32 VALU 密集内核，优先 C32/C64 微例；当下访存受限核未必受益。|
|6：等待指令更晚/合并，保持 MODE 边界|`SIInsertWaitcnts.cpp`、`AMDGPUInsertDelayAlu.cpp` 与 machine scheduling；用 MIR 测试钉住实际 hazard|不删除真实 VMEM/LDS/VALU hazard，不把 `s_wait_alu`/`s_delay_alu` 误认访存等待。分段 FP16_OVFL 涉隐式 MODE，需保留转换与开关的先后及所有退出路径原 MODE 恢复。|C32 边缘/地址链，W2 MODE 空段；先找具体冗余实例，再决定是否写 pass。|

## MODE 不作为首补丁

将 FP8 饱和 clamp 改为 FP16_OVFL 分段开关，需要有限输入合同，并影响处于同段的 half 收窄；±Inf/NaN 行为不同。本项目曾发生 LLVM 把转换移到空 MODE 段外的情况。应先把 MODE 读写及转换建成有准确隐式状态依赖的目标指令序列，必要时用 `SIModeRegister` 相关 pass 统一管理，再讨论消除冗余切换。它不是在 IR 层简单插两次 setreg 就可靠的通用优化。

## 首补丁验收方式

每条先做一个来自真实内核的小型 IR/MIR 例子，说明旧/新 ISA、语义前提及反例域；不能只写模式匹配快照测试。再重编两架构，七用例 EXACT/AE、决策逐字段和完整网络 ABBA。输出不逐位就不作为现役替换。此次没有编译器优化补丁。
