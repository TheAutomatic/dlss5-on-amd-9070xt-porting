# 09-28 float FMA 合入与剑星部署

基于 `e3f6863` 任务单，Zero已批准改变输出。**09-28 起基准改为 float FMA；09-28 起基准变更：float FMA 激活。** 本轮已合生产、备份装剑星，未发包。

## 改动范围

7个fast源文件的23处激活：C32 wave/非wave、C64/C128/C256、C512与ViT；两处多项式乘加显式float FMA（原已有外层FMA只改内层）。末次乘法、FP8量化、矩阵累计、softmax、归一化、half reference没有改。15个受影响模块各编gfx1200/gfx1201，保持旧选项/缺模块回退的HIP路径同一激活口径；gfx1200仅编译，gfx1201实测。

旧DX12 HLSL precise保留历史基准，不再作新HIP fast逐位裁判，`hip/README.md`与旧validate脚本已标明。没有新flags、host改动或RE9 ABI变更。

## 性能

同批两轮ABBA，1000帧/槽弃前200，只读首尾；游戏进程每槽检查，计时与编译不重叠。

| 档位 | 第一轮基线→新基准 ms | 第二轮基线→新基准 ms | 两轮耗时变化 |
|---|---:|---:|---:|
|900|9.1949→9.0850|9.2653→9.1508|-1.20% / -1.24%|
|1080|12.5512→12.3999|12.5781→12.4301|-1.21% / -1.18%|

整网约快1.2%。`timings.csv`是槽汇总，`timing-series.json`保留16×1000个原始帧时，独立复算全部均值一致。

## 对NVIDIA误差

**校正上轮测量**：fma-vs-nvidia轮的整网oracle是post_shift=0，而runner是3；旧“RMSE改善0.145%”结论撤回，原报告已加醒目标记。本轮全部统一post_shift=3，并锁定原CUBIN的 `shift-full-oracle.f32` SHA。局部CUBIN审计、上轮计时不受此问题影响。

全部71块、不跳层、seed0；固定RGB/history五帧off/on/off/on/off，采样shader取自已逐位通过的历史版本，shader SHA与accepted manifest同。不是自反馈真值序列；游戏式反馈由运行时七用例另测。以下是可见1080行raw RGB RMSE：

| 范围 | 现行A | float FMA P | 变化 |
|---|---:|---:|---:|
|单帧，无history|0.0080383812|0.0080365856|-0.0223%|
|五帧off/on/reset聚合|0.0080368624|0.0080010754|-0.4453%|

两项均不劣；幅度小，不宣称游戏画质变好。五帧中的off和on重复帧各自完全一致。`oracle-comparison.json`保留逐帧值和输出hash，`fixture-manifest.json`记录输入及历史shader来源。

## EXACT / AE 与新goldens

七用例×EXACT/AE×12帧：168个P帧全部有限，均有意不同于旧A；连基线336帧。AE共84次：A为43复用/41刷新，P为44复用/40刷新；复用/刷新变化 **1帧**、连age/reason的控制字段变化3帧、包含分数的任一字段变化50帧。

差异发生1080-history第8帧：relative 0.225316525→0.219200358，跨过0.22阈值，刷新变复用；image读数相同。另独立重放两次该12帧用例：额外24帧全部同新baseline，AE整份决策日志也相同。`confirm-result.txt`记录确认。

**以后逐位对这个版本**：[`new-baseline-hashes.csv`](new-baseline-hashes.csv)，84 EXACT＋84 AE；`check-baseline.py`检查覆盖与哈希。当前生成结果已通过manifest完整性校验，敏感AE用例另有独立重放，不把读自己生成的manifest当全部168帧重复测试。`baseline-context.json`锁定runner和原输入capture的SHA，`source-hashes.json`、两架构modules CSV锁定实现。

## 安装

剑星已换15模块×双架构，共30个HSACO及对应SHA256SUMS项；回读全部相同，其余30模块、addon、dxgi、INI、flags hash均未变。C32 gfx1201 `AA999258…`、C64 `F9E8F0C5…`。

备份：`D:\DLSSNR-Lab\float-fma-20260928\backups\stellar-20260928-153921`。

部署脚本与收据在 `Development/deployments/float-fma-20260928/`，`install.ps1 -RestoreBackup <上述路径>`可还原。未发包；本机游戏画面/FPS仍由Zero验收，标准为1080P窗口＋FSR原生AA、F8 EXACT、读黄字小数；此前ACO两刀的远程57.1仍不可直接作本机基准。
