# 给闇：核实"两次舍入"是否忠于 NVIDIA + 工作尺寸（2026-09-28 14:05，朱雀）

ACO 对齐两刀收到（9a82385，离线 900 −0.82/−0.65%、1080 −0.75/−0.74%）；剑星经 Splashtop 远程 57.1，待本机复测。先 `git pull`（9e21f68 起）。

## 起因

你的对齐表把激活段 q=mul→sub、p=mul→add（各 256 个独立舍入边界）判为"语义必须"——必须是相对**我们现行输出**。但 Daniel 0.5.0（分身静态分析，`results/daniel-050-20260928/`）的 reference 档自称 NVIDIA PTX 算术，C64 核里 704 条 `v_fma_mix*_f16`，即一次舍入。若 NVIDIA 原本是 FMA，我们的两次舍入不但慢，而且偏离 NVIDIA。

## 要做

1. **查 NVIDIA 原文**：从 NVIDIA DLSS5 NR 的 DLL（我们逆向所用的那版）里找到对应的激活/归一化/softmax 段的 PTX 或 SASS，逐处判定是 `fma`/`HFMA2`/`FFMA` 还是 `mul`+`add` 分开（注意 `.rn`、`contract`、f16x2 与 f32 混合的 `fma.rn.f32` 带 f16 操作数等价于 `fma_mix` 的情况）。覆盖：C32/C64～C256 FFN 激活、softmax 求和与倒数、归一化、残差。给出"NVIDIA 做法 / 我们做法 / Daniel reference 做法"三列表。
2. **追溯我们为什么是两次舍入**：是逆向时照抄 NVIDIA、还是 HIP 编译默认不收缩（`-ffp-contract`）留下的？查我们逐值移植时对拍 NVIDIA 的记录（DevHistory / 早期 results）——当初"逐位对 NVIDIA"的基准到底是什么。
3. **若我们确有偏离**：做候选"改成与 NVIDIA 相同的 FMA"，量两件事：a) 与 NVIDIA 参考输出的差距是否变小（若有 NVIDIA 真值帧/中间张量可对拍，逐位对 NVIDIA 为最佳）；b) 离线 900/1080 ABBA 的 ms。这类改动**不与当前输出逐位**，只评估、不合配方、不装机，交 Zero 拍板。
4. **工作尺寸**：Daniel 0.5.0 默认按 NVIDIA 原生工作尺寸跑，128 对齐填充变成回退（`DLSSNR_EXTENT`/`PAD128`）。核对我们 1080 档处理 1152 行、900 档对应行数，与 NVIDIA 原生工作尺寸（从 DLL/调用参数确认）差多少、多算的比例、若对齐能省多少 ms、输出变化范围（只在边缘？）。同样只评估、交 Zero 拍板。

## 约束

- 本轮以核实为主，**不改生产配方、不装机、不发包**。
- 9070 动 GPU 前查游戏进程（Zero 可能在测剑星）。
- 结果 `Development/results/fma-vs-nvidia-20260928/`，DevHistory 追加；WorkingPlan 只改"正在进行"与 B/C 段（整页覆盖式）。够用就交。

## 交付

中文摘要：三列对照表（NVIDIA / 我们 / Daniel）、我们两次舍入的来历、若有偏离则 FMA 候选的"与 NVIDIA 差距 + ms"、工作尺寸差异与估算收益、提交 hash。
