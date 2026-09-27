# 给闇：C32 第二刀（2026-09-27 18:25，朱雀）

上一轮（`results/c32-aco-20260927`，4b4346f）剑星实测通过：1080P 原生 AA，EXACT 普通场景 54 → **55～56**，AE 59，无黑块。基线现在是你的组合（配方里 `CW_DIRECT_OUT 1`、`CW_RTZ_PAIR 1`；剑星 c32-wave1 gfx1201 05359b6a / gfx1200 2d345933）。先 `git pull`。

## 目标：按你的 chain 分账往下砍（逐位）

| 段 | 现在 | 想法（你判断，不是命令） |
|---|---:|---|
| 激活与 hidden 打包 | 1632 | 最大头。clamp/NaN 规范化能否像 C64 那样用 fmed3 去掉 `max x,x`；多项式分步乘加能否在逐位前提下合 fma（只在"一次舍入的精确积 + 精确零"这类可证明同值的地方）；FP8 clamp+转换能否套 C64 的分段 FP16_OVFL（C64 已用 W2_PACK8 6，census 证明打包输入全有限、\|x\|≤448——C32 需要同样的 census 才能用） |
| 投影及结果量化 | 876 | "F() 后又 PACK8"听起来有重复转换，同你上轮去 FP8 往返的思路 |
| score/exp | 664 | 位置偏置/仿射/clamp/位映射，看有无可预计算到权重打包里的常量部分（不改数值） |
| Q/K 归一化/量化 | 648 | half 平方、固定归约顺序要保；看 rsq 与缩放、FP8 量化段 |
| softmax | 592 | 固定求和顺序与精确倒数修正要保；看概率量化段 |

另外两个疑点：

1. **finish / finish_dcrop / prefix 的 SALU 与 WAIT 异常高**（finish_dcrop SALU 1908、WAIT 2870；chain 只有 228 / 1396）。先查是什么：标量地址计算、循环控制、裁切下采样的分支、还是 s_waitcnt 串行化；若有不改数值的改法（地址预算、循环不展开/展开、把裁切分支变 wave-uniform）就做。
2. **按调用次数加权**：C32 共 10 块（chain/mapped/finish/finish_dcrop/prefix/post 各跑几次，以 `hip_reference_network.h` 的 wave-owned 分派为准），把"每窗口指令"乘上块数和窗口数，算清哪个核在整网里最值钱，再定先砍哪个。

## 约束（同上一单）

- 逐位是硬门槛（对当前剑星的 c32-wave1）；不照抄 mochizuki 的 `NR_ACC_F16=0` / `NR_NORM_F32` / `NR_ACT_ALT` 这类改数学路线的做法。
- 已关：`v_cvt_pk_f32_fp8` 成对解包（gfx1201 返回同字节两份）、`v_pk_*_f16`、核入口一次性 FP16_OVFL。
- 每个候选：新宏默认 0，双架构编译，ISA 计数，7 用例逐位，900/1080 两批 ABBA；手改汇编只当显微镜，不进生产。
- 9070 动 GPU 前查游戏进程（`SB-Win64-Shipping`、`LOP-Win64-Shipping`、`OnimushaWotS`、`re9`）。git 只推 297、不加 Co-Authored-By、push 前 pull --rebase。结果 `Development/results/c32-round2-20260927/README.md`，DevHistory 追加，WorkingPlan 只改 B 段对应条目。
- 成熟候选合进配方、装剑星（带备份），不发包。够用就交；单个候选卡 2 小时以上换下一个。

## 交付

中文摘要：加权后各核的价值排序、每个候选的指令变化/逐位/ms、合进配方后的整网 ms、剑星装了什么/备份、提交 hash。
