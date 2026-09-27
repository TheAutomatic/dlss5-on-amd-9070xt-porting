# C32 ACO 对照与逐位候选（2026-09-27，闇）

基线为 **0.34** 的 c32-wave1：gfx1201 `5e9b3593…`、gfx1200 `6d6e57f2…`。从剑星实际安装目录取全模块集 A；原配方双架构重编与两个已装文件完整 SHA256 相同。所有新宏默认 0，Z 默认构建的代码/metadata 与基线相同；候选仅替换 c32-wave1，PDL=1、其它模块不动。

## 循环加权账

单位为**一 wave 处理一个 64-token 窗口**的 issued instruction；VOPD 一对计一条，WMMA 单列。WAIT 是等待/调度指令的条数，不是等待周期，不能把这一列直接折成 ms。选完整内部窗口（不越界、finish 的 main/down 都存在、prefix 有历史）的路径；边界裁切和空输出指针的实际工作更少。

`ledger.py` 按真实 ISA 回边加权：外层 query tile ×4、嵌套 hidden ×8（有效 ×32）、注意力 query tile ×4。尾部 main 的 C++ 64 次被编译器每轮展开两项，真实循环 **32 次**；裁切下采样 16 次；RGB post 每 lane 2 次。没有拿源码迭代数直接套汇编。

分段使用 `RTC_EXTRA_OPTS=-gline-tables-only` 的 `.loc` 和 inline caller 行号。**debug 与基线的 `.text/.rodata/.note` 逐字节相同**，所以不是插桩改变后的账。源码行号丢失的调度/地址指令留在 control_unattributed，不强行摊派。脚本只接受已核对的 debug 源指纹。明细见 `baseline-ledger.json`。

| 核 | VALU | VOPD | 两者合计 | WMMA | VMEM | LDS | SALU | SMEM | WAIT |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| chain | 3889 | 1190 | 5079 | 336 | 312 | 128 | 228 | 8 | 1396 |
| mapped | 4172 | 1262 | 5434 | 288 | 288 | 128 | 228 | 7 | 1309 |
| finish | 4754 | 1193 | 5947 | 336 | 376 | 320 | 1513 | 9 | 2625 |
| finish_dcrop | 4842 | 1195 | 6037 | 336 | 376 | 320 | 1908 | 9 | 2870 |
| post | 4519 | 1412 | 5931 | 288 | 380 | 200 | 261 | 7 | 1461 |
| prefix | 5484 | 1313 | 6797 | 304 | 360 | 324 | 1162 | 8 | 2417 |

chain 的普通向量指令分账（VALU+VOPD，合计 5079）：

| 段 | 条数 | 主要内容 |
|---|---:|---|
| 控制/未归属 | 139 | 地址和寄存器调度，含 `.loc 0` |
| 输入 | 8 | 有源码归属的输入地址；其它地址在上一行 |
| FFN 残差 | 4 | 另有 48 条 WMMA、48 条 VMEM |
| FFN 展开 | 64 | 另有 64 条 WMMA、64 条 VMEM |
| 激活与 hidden 打包 | 1632 | clamp/NaN 规范化、多项式的分步乘加、FP8 clamp+转换 |
| FFN 收缩 | 0 | 64 条 WMMA、64 条 VMEM，向量地址准备已归展开 |
| FFN 结果量化/残差存储 | 300 | RTZ→f32→f16→LDS、FP8 打包 |
| QKV 矩阵 | 48 | 另有 48 条 WMMA |
| Q/K 归一化/量化 | 648 | half 平方、固定归约、rsq、缩放、FP8 |
| score/exp | 664 | 位置偏置、仿射、clamp、位映射 |
| softmax | 592 | 原固定求和顺序、精确倒数修正、概率量化 |
| AV | 104 | 另有 32 条 WMMA |
| 投影及结果量化 | 876 | 残差乘加、RTZ、F() 后又 PACK8 |
| 尾部写出 | 0 | 8 条 VMEM |

## ACO 对照

本机现成 RADV/Mesa 26.2.3 + drm-shim 假 gfx1201 重新导出了四个 SPIR-V 的 ISA，和旧导出字节相同；假设备不执行、不提供 GPU 性能。工具入口 `export-aco.sh`，源/ISA 指纹 `audit-manifest.json`，明细 `aco-g_*-ledger.json`。

| ACO 管线 | VALU | VOPD | 合计 | WMMA | VMEM | LDS |
|---|---:|---:|---:|---:|---:|---:|
| fswin32 | 1600 | 461 | 2061 | 256 | 82 | 12 |
| fswinds32 | 2006 | 465 | 2471 | 256 | 90 | 12 |
| fswinimagepreds32 | 2418 | 452 | 2870 | 264 | 88 | 12 |
| fswinimagepost32 | 2476 | 429 | 2905 | 256 | 92 | 0 |

**chain 普通向量指令约 2.46 倍，不等于有 2.46 倍的逐位提速空间。** ACO 的配置有 `NR_ACC_F16=0`、`NR_NORM_F32=1`、`NR_ACT_ALT=3`，数学路径与我们不同。尤其矩阵数差异能对账：我们多的 80 条 = FFN 三段对角残差 48 + Q/K half 平方和 16 + softmax 固定求和 16。prefix 的差额是 40 条（归约32 + 原数值路径的零片段8），post 的差额是归约32条。

辅助分段（普通向量 issued 指令；ACO 是数据依赖归属，跨段残差种子留在其数据来源，不能据此当作时间账）：

| 组 | 我们源码归属 | ACO 数据归属 |
|---|---:|---:|
| FFN 残差/展开/激活/收缩/暂存 | 2000 | 978（深度1+2） |
| QKV 与归一化 | 696 | 268 |
| score/exp/softmax | 1256 | 609 |
| AV 与量化 | 104 | 32 |
| 投影及量化 | 876 | 32（另有残差种子的乘法归深度2） |
| 输入/控制/混合归属 | 147 | 142 |

prefix/post 管线的工作边界也未必等于我们的单核，尤其外部噪声/历史生产者不计在这些 ACO 管线里。因此跨内核表只作寻找指令差异的入口，不能把差值相加当整网预计收益。

按同类操作对照：

- **输入/供数**：我们滚动四个 query tile，重复读取 FFN 权重；ACO 展开窗口后复用权重片段。它因此读指令少，但 fswin32 用 192 VGPR。不能只把它的展开照抄：我们原先全展开有寄存器压力的负结果。
- **激活**：我们每窗口 1632 条普通向量指令归在展开激活/量化行。ACO 相应数据链约 910 条，主要是 clamp、`v_fma_mix_f32`、成对 fmaak/mul、FP8 转换。它省了规范化、饱和 clamp，也收缩了乘加；后一项改变原舍入路径，本轮不拿来凑收益。
- **QKV**：ACO 用 packed-half/f32 的归约和直接混合半精度 FMA；我们的固定 half 平方和通过 WMMA 实现。低指令数含算法差异；未启用已否定的 `v_pk_*_f16` 运算路线。
- **softmax**：ACO 同段包含 packed-half exp/求和，我们保持固定归约顺序及倒数修正。都做概率量化，但不能交换归约树来追指令数。
- **投影**：我们的 `F(float((_Float16)Hrtz(...)))` 已做 FP8 量化+解包，随后 `CW_PACK8` 又做一次量化。ACO 直接打包写出。这条差异可以在保留零符号语义的条件下消掉，形成候选 C。
- **half 暂存**：我们的 Hrtz 是 opaque asm，编译器看不到“输出已是精确 half”，又生成 f32→f16 和逐元素 LDS store。一次 RTZ 转两个值、直接保留 half bits，再按 16B 写共享内存，形成 D。
- **MODE、成对 FP8 解包**：ACO 中可见分段 MODE 和成对解包；本轮没有重试已关的成对解包、packed-half 运算或核入口一次性 MODE 路线。

ACO 分段辅助工具按物理半寄存器的数据依赖层数标注，WMMA 的层数分布恰好是展开64/收缩64/QKV48/score32/AV32/投影16；没有循环。它的阶段明细按**数据来源**记账，残差保留值在后段的运算可能仍归 FFN，不能和 LLVM 源码行号明细每格硬减；上面的逐段结论结合了实际指令序列。

## 独立候选

- **B / `CW_FMED3_CLAMP`**：cw_body 中的普通 clamp 改 med3；PACK8 原来的 med3 不动。默认 0。
- **C / `CW_DIRECT_OUT`**：只有 chain/mapped 的字节输出去掉重复 F() 往返，改为 `v+0.f` 后 PACK8。精确 -0 按原 F() 规则变 +0；负的非零小数下溢到 -0 的行为保留。默认 0。
- **D / `CW_RTZ_PAIR`**：FFN 结果和投影残差和两处，用现有 `v_cvt_pkrtz_f16_f32` 的两个输入，保持每个 half 的 RTZ 边界；half 向量直接存 LDS。这不是 `v_pk_*_f16` 算术，不改 MODE。默认 0。

三项均独立双架构编译，gfx1200 无实卡只做编译；gfx1201 跑七用例和两批千帧 ABBA。默认全关的 Z 代码与 A 一致。每批 ABBA 去前 200 帧、计时只首尾读回；七用例另逐帧对比。

每窗口普通向量指令（A→候选），LDS 整段条数见 JSON：

| 核 | A | B | C | D |
|---|---:|---:|---:|---:|
| chain | 5079 | 5019 | 4616 | 4944 |
| mapped | 5434 | 5373 | 5191 | 5325 |
| finish | 5947 | 5859 | 5947 | 5788 |
| finish_dcrop | 6037 | 5949 | 6037 | 5879 |
| post | 5931 | 5863 | 5931 | 5835 |
| prefix | 6797 | 6613 | 6797 | 6656 |

D 的 LDS：chain/mapped 128→16，finish 两种 320→152，post 200→32，prefix 324→156。所有候选 scratch=0；D 的描述符 VGPR 需求在 finish 从169到172、prefix到173，需以实测判断收益。

## 完成记录：回归、测速与采用

B/C/D/E 各 7 用例×12 帧：720 移动、900/1080 静态/移动/连续历史，全部逐帧 SHA256 相同，共 336 个候选帧；含 baseline 的 672 条帧 hash 在 `frame-hashes.csv`。120 个测试进程的启动日志均确认 wave_owned requested=1/active=1，并记录实际 modules 路径（`startup-identities.txt`）。

标量探针：65536 个 half 编码（含两种零、次正规、Inf/NaN）的 `fp8(F(v))` 对 `fp8(v+0)` 全同；1048576 对 f32 位模式经“旧 RTZ→f32→half”与新双输入 RTZ 的 half bits 全同。见 `scalar-probe.log`。这补充了最终 RGB 回归，不把有限样本冒称所有 f32 输入的穷举。

两批 ABBA 的候选减基线（ms；负数更快）：

| 候选 | 900 第一批 / 第二批 | 1080 第一批 / 第二批 | 采用 |
|---|---:|---:|---|
| B med3 | +0.00146 / −0.02976 | −0.01428 / −0.02806 | 收益接近噪声，默认关 |
| C 去重复 FP8 往返 | −0.07338 / −0.08616 | −0.11728 / −0.10919 | 是 |
| D RTZ 双输入 + LDS 向量读写 | −0.11018 / −0.09290 | −0.15342 / −0.13925 | 是 |
| **E = C+D** | **−0.12688 / −0.13737** | **−0.18696 / −0.19259** | **生产配方采用** |

组合的四组基线→候选：900 `9.61103→9.48415`、`9.70118→9.56382`；1080 `13.34438→13.15743`、`13.37191→13.17932`。即 **整网测试台约 −1.3～−1.4%**，收益不相加。全部计时槽末帧 hash 也相同；没有声称 64000 个计时帧都做了逐帧读回。原始 120 槽记录在 `measurements.csv`，计算结果 `timing-summary.json`。

最终 E 的 chain 普通向量指令 5079→4648（−8.5%）、mapped 5434→4989；post/prefix 的收益主要是 LDS 访问和 half 暂存，没有把它们的整段 VALU 同比例砍掉。C32 全分辨率首尾与低分辨率中间链权重不同，不能从 chain 的 −8.5% 推出整网 −2.9%。

`hip/build-modules.ps1` 的 c32-wave1 行加 `CW_DIRECT_OUT 1`、`CW_RTZ_PAIR 1`，B 保持默认 0。按新配方双架构复编，与已测 E 的 `.text/.rodata/.note` 全同（`identity-checks.json`）；文件 SHA 不同来自编译单元身份，交付使用跑过全部回归的 E 文件。

## 剑星部署（17:34）

只更换两架构 c32-wave1，并更新这两项 checksum；add-on/dxgi/INI/flags 的 SHA256 前后核对不变。没有发包，没有代替 Zero 判断游戏画面或 FPS。

- gfx1201：`05359b6a2f4e8cb6979959d503248df3abe5c93448e13fc318b80d4fb0efe4d2`
- gfx1200：`2d345933c9f1cbe23bbe76122c151c8082c96630d1b560192c456fd75bce5841`
- 备份：`D:\DLSSNR-Lab\c32-aco-20260927\backups\stellar-20260927-173404`
- 还原：`powershell -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\c32-aco-20260927\install.ps1 -RestoreBackup D:\DLSSNR-Lab\c32-aco-20260927\backups\stellar-20260927-173404`
- 部署源码/manifest：`Development/deployments/c32-aco-20260927/`；安装回读证据 `installed.json`。Zero 待测：1080P 窗口 + FSR 原生 AA + F8 EXACT，对照主菜单50～51、场景54。

## 复现入口

`Development/HIP/experiments/c32-aco/`：stage（仅第一次、保留不可覆盖的 0.34 A 快照）、build（每套显式覆盖三个宏，避免后续生产配方变化污染对照）、regression/suite（7用例+两批1000帧）、collect、scalar_probe、debug/ledger、export-aco。9070 实验根 `D:\DLSSNR-Lab\hip-backend\c32-aco`。

源码行号分段使用该目录已保存的 **初始 build-A/gfx1201/c32-wave1.generated.hip**（0.34 原源码），不是后来插入宏后的源文件；debug.ps1 读取这个不可变底稿。ACO 的完整 ISA/工具仍在 `~/work/aco-isa/`，重新导出四管线字节相同。两架构 default-off 与基线、debug 与基线、最终配方与 E 的代码身份检查均记录在 `identity-checks.json`。gfx1200 只有编译证据，无实卡运行证据。
