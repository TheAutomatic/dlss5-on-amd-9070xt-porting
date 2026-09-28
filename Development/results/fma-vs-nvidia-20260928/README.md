# FMA 与 NVIDIA 原版、工作尺寸核实

> **后续校正（float-fma 合入轮）**：本报告的整网 raw 比较误用了 post_shift=0 的 `oracle-final.f32`，而候选 runner 是 post_shift=3。整网旧表保留为错误对照记录，**撤回据此计算的0.145%/0.517%精度改善结论**；局部CUBIN/ISA、历史exact字节核对、计时和尺寸审计不受影响。正确同shift单帧/五帧比较见 [`../float-fma-20260928/README.md`](../float-fma-20260928/README.md)。

任务 `conversation/20260928/yami-fma-vs-nvidia.md`；起点 `2137a35`，现场基线为 ACO-lineup。**仅审计与隔离实验；未改生产配方、未安装、未发布。**

## 先回答疑问

1. **原 NVIDIA 确实有 FMA，但主要是 half FMA。** 当前 fast 链的 float 分离乘加不是它的原算术；直接收缩为 float FMA也不是恢复原版。
2. **原来的 exact 复现是真的，fast 链后来有意离开了它。** 09-08 获批减少half舍入；09-10 为融合前后逐位，HLSL两边主动加precise；09-14以后HIP对的是fast HLSL CSO。不是HIP编译器偶然把原版FMA弄没了。详情 [history-audit.md](history-audit.md)。
3. **Daniel reference 的激活更接近原版，但不是已证明逐位的原版。** 它的范数归约、倒数和matrix half累加模拟仍有差异；704条fma_mix的全核统计不能当激活证据，激活实际是packed-half FMA。
4. **1080的1152行有原版实际调用参数证明。** 我们没有在此多算相对原版的行数；Daniel默认1088不应命名为“修复我们的原版尺寸错误”。

## 三方对照（四档均查原指令）

| 段 | NVIDIA原DLL SASS | 我们当前fast/HIP | Daniel 0.5.0 reference |
|---|---|---|---|
| C32/C64/C128/C256激活 | 两次HFMA2，中间各舍half；末次HMUL2 | 两次float mul+add，末次float乘法，FP8 | 两次v_pk_fma_f16，末次v_pk_mul_f16 |
| softmax指数仿射 | HFMA2，half位映射 | float乘加＋half位映射 | packed-half FMA＋half位映射 |
| softmax分母／倒数 | 固定half求和树；MUFU.RCP→half，再half乘 | WMMA float求和；float倒数修正和概率乘法 | half树；完整float除法修正→half，再half乘 |
| Q/K归一化 | HMUL2起步＋HFMA2平方累加，half归约；RSQ→half | C32 half平方＋float WMMA求和；MH串行float平方和 | 逐项half平方＋half加法树；RSQ→half |
| 残差／投影 | half残差乘法作为QMMA.F16初始累加器，按块舍half | float矩阵累加，部分Hrtz／对角FP8矩阵残差 | 分块float WMMA后用fma_mix加half累加器并舍half；未证所有支路完全同序 |

完整寄存器链、每核地址与小段机器码在 [isa-audit.md](isa-audit.md)、`isa/`。这些是从SHA锁定的二进制读取，不把文案中的“PTX arithmetic”当证明。

## 原版误差的两层检查

**历史整网exact复核**：旧AMD完整1080 raw输出与保留的原CUBIN oracle共6,635,520个float32全字节相同，SHA也同（[historical-exact-recheck.json](historical-exact-recheck.json)）。这是重新核对旧产物，不是本轮重跑整个原版游戏。

**局部控制**：63,488个有限half输入上，float分步与float FMA的最终FP8全部同；这不代表任意float输入等价，真正当前网络候选已改变输出。既有block1样本262,144个expand值也未落在该二者FP8差异点。保持其余步骤为NVIDIA参考，只换激活：

| 激活 | 对原CUBIN block1相同输出 | MAE | 最大绝对差 |
|---|---:|---:|---:|
| 当前float分步 | 62,554 / 65,536（95.4498%） | 0.00150824 | 1 |
| float FMA | 62,554 / 65,536（95.4498%） | 0.00150824 | 1 |
| half阶段舍入 | 65,536 / 65,536（100%） | 0 | 0 |

本轮另在Spark重跑准确DLL提取的普通/inpview C32 CUBIN：两份8MiB原始输出均与历史全字节同；inpview解码后65,536个float全部对上上述oracle（`fresh-cubin.json`），真值来源闭环。此项输入是已有验证样本，非游戏实帧；单块改善不保证整网误差单调改善。脚本 `activation-probe.py`，数据 [activation-oracle.json](activation-oracle.json)。

## 两个AMD候选的范围

- **F**：仅C32/C64/C128激活的两处float乘加收缩为float FMA。
- **H**：同样30块激活恢复输入half、两次half FMA、末次half乘法。上游矩阵仍是当前float累加，不恢复每K32的half累加，也不动softmax、范数、C256/ViT等。
- H是用标量转换与mixed FMA实现的最小语义实验，**不是已优化好的packed-half核**。它的实测耗时不能作为half实现的性能下限。
- 生产原样复编Z，两模块文件hash与现场完全相同；F/H各七用例×12帧全部有限且全部输出改变。AE未跑，未把它们当可部署逐位优化。
- 计时：两档各两轮ABBA，每槽1000帧弃前200，只读首尾；使用既有离线NativeGameFrame runner与发布跳块配置。全网误差比较另跑**全部71块**，无跳块，原始RGB fixture，seed0/reset，不经游戏codec；两者口径分开。
- 第一轮脚本误用旧架构子目录，已停掉、整轮标invalid隔离。最终实际使用30文件flat目录，每槽打印模块路径和两模块hash；未采用旧轮数字。

## 离线耗时与整网原版差距

| 候选 | 档位 | 第1轮基线→候选 ms | 第2轮基线→候选 ms | 两轮变化 |
|---|---:|---:|---:|---:|
|F|900|9.2470→9.1505|9.3049→9.2034|-1.04% / -1.09%|
|F|1080|12.5716→12.4397|12.6197→12.4848|-1.05% / -1.07%|
|H|900|9.2947→10.1358|9.2962→10.1351|+9.05% / +9.02%|
|H|1080|12.6041→13.8523|12.6251→13.8585|+9.90% / +9.77%|

同一原版随机RGB样本的可见1080区域，raw网络输出；PSNR固定峰值1，不是显示域游戏截图评分：

| 路线 | 对NVIDIA RMSE | MAE | PSNR（峰值1） | 对当前A的PSNR |
|---|---:|---:|---:|---:|
|A|0.01222051|0.00945441|38.2582 dB|—|
|F|0.01220281|0.00944141|38.2708 dB|44.024 dB|
|H|0.01215738|0.00939827|38.3032 dB|42.511 dB|

F的RMSE仅下降0.145%，H下降0.517%。单张样本上两者略向原版靠近，但这个幅度不足以宣称画质改善；当前矩阵/归约等其他近似仍在。F对当前输出约44dB，不能称逐位或默认无损。H虽然局部语义修复明确，朴素实现慢9～10%、整网改善很小；本轮不继续优化它。

判断：F可以作为“改变输出换约1%速度”的备选交Zero，不能包装为已恢复NVIDIA；H不以当前实现进生产。完整数字在 `summary.json`、`raw-oracle-comparison.json`，逐帧hash在 `frame-hashes.csv`。

## 工作尺寸与能省什么

| 有效输入 | NVIDIA实捕 | 我们 | Daniel默认 |
|---|---|---|---|
|1920×1080|1920×1152|1920×1152|1920×1088|
|1600×900|没有可靠原版捕获|1600×960|1600×960|

原始1080参数blob：`0x90`有效1920/1080；`0xf0`处理H/W=1152/1920；ViT20×32。捕获器没有改写这个参数。原DLL尺寸函数`0x18003c580`按layer shape下降次数计算两轴对齐步长；Daniel固定ceil64，两者不是相同规则。原生900的逐层计数仍未取到，不能认证960与原版相同。详见 [geometry-audit.md](geometry-audit.md)。

- 对齐**已捕获原版1080**：差0行，收益 **0ms**。
- 如果以后单独试1152→1088：少64行、122,880处理像素（−5.56%）；按12.6ms面积模型约省 **0.70ms**。这只是估算，本轮没有实现/ABBA测1088，ViT网格和边界窗口不能简单线性缩放。
- 输出可能改变**整图及后续历史帧**，不是只改底边：边界通过encoder进入ViT全局注意力，再传decoder；旧900缩高已有全图差异证据。
- 900与Daniel默认同尺寸，尺寸项没有可省差额；相对原生900尚不能给差额。

## 交付状态

`final-identity.json`确认现场60模块与开工快照全部同，Z两模块与现场hash同；只做gfx1201编译/实测，未测gfx1200、未装机、不改配方、不发包。原900尺寸仍未知、1088节省值仅估算、整网原版误差只有一个受控静帧，以上均保留为证据边界。
