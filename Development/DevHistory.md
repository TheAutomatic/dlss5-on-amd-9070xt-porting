# DLSS5（DLSSNR）→ AMD RX 9070 XT 移植：开发史

> 本文件是本项目开发、部署、运维与后续工作的**唯一记录入口**。
> **2026-09-23 压缩**：原文 593KB（约 30 万 token）已整本移到 `Development/history/DevHistory-full-20260923.md`（git `a300c20` 之前的完整版）。本文只留结论、关键数字、现行约定和"别再做"的清单；要查某一刀的细节、SHA、日志路径，去原文 grep 日期或关键词，别整本读。
> 更早的逐刀原始记录在 `Development/history/` 其余文件（见文末索引）；每轮实验的数据在 `Development/results/<名字>-<日期>/`、`Development/HIP/experiments/<名字>/`。

**续写规则**：
- 新事件**直接追加在文件最末尾**（§12 流水，时间正序，`## 日期 时间：标题` + 正文），不要往 §4 的表里塞，也不要插到中间。
- 现状与待办只在 `WorkingPlan.md` 维护（§3、§11 只留指针）；新的"不要重做"补进 §7，新教训补进 §8。
- §12 长到读不动时：每天压成 §4 的一行，结论并入 §5～§8，原文照样挪进 history/。

---

## 1. 目标与硬约束

把 NVIDIA 泄露样本 `nvngx_dlssnr.dll`（DLSS 5 神经渲染，内部名 DLSSNR）里的 71 块网络恢复出来，在 RX 9070 XT 上按原版数值执行，并在真实游戏里以可玩帧率替换 FSR 输出。

- 验收三级：离线复现 → AMD 跑通 → 游戏可用。后来 Zero 收紧为"9070 XT 走完 71 块出最终 RGB"，再到 1080p ≥10fps，再到 30fps。
- **exact 链**（tag 0.01，186ms）逐值等于原版，冻结当裁判；**fast / HIP 链**：结构改动必须逐位不变，算术改动看 PSNR，画面由 Zero 在游戏里按 F6 拍板。
- 帧率只信游戏内读数或同批 ABBA；绝对帧时跨批次留 ±0.3ms。

| 机器 | 用途 |
|---|---|
| `desktop-2026`（`ssh amd9070`），Win11 Insider 26H2，RX 9070 XT（RDNA4，gfx1201，16GB，128 SIMD / 32 WGP） | 靶机 |
| `NucBox_EVO-T1`（`ssh rtx5090`），RTX 5090 OCuLink | 标准答案机（原版 DLSSNR） |
| DGX Spark `spark-3a10`（GB10，sm_121） | 能直接加载 sm_120 CUBIN 当 oracle |

驱动：DX12 路线需要**预览驱动 32.0.31007.2048**（SM 6.10 / LinAlg，私有 Agility 721、开发人员模式）。HIP 路线（0.20 起）只需驱动自带 `amdhip64_7.dll`，不要预览接口；正式驱动有用户反馈可用。

---

## 2. 逆向结论（硬事实，不会再变）

**样本**：`nvngx_dlssnr.dll` 310.8.0.0，SHA-256 `e16bcf15…1fc8e`。资源 `WEIGHTS_HT` 147,695,410 字节，153 条记录（`name_length→name→body_span→body`），live 层对象 152 个（block70 的 blend_scale 与 layer 同属一个 Layer）。矩阵主体是 packed E4M3，偏置/skip/scale 是 FP16/f32；运行时 arena 按 512 字节对齐，共 147,719,680 字节，运行时不改写权重。DLL 内含 15 个 sm_120 CUBIN。

**网络**（构图函数 `0x180039780`，config `hnet-vigilant-squid` / variant `crazy-cuckoo`）：
```
0        PreBlock 1H / C32          1–3 Swin C32   4 ds 32→64
5–7      Swin 2H / C64              8 ds 64→128
9–13     Swin 4H / C128             14 ds 128→256
15–21    Swin 8H / C256             22 ds 256→512
23–30    split-Swin 16H / C512（30 带 ProjPool + FinalHead 512→1024）
31–38    ViT 1D / C1024（Expand→Contract→QKV→Attention→Projection）
39       DecInputUpsample 1024→512  40–47 split-Swin C512
48/56/62/66 upsample + Swin（C256/C128/C64/C32），49–55 / 57–61 / 63–65 / 67–69 同族
70       PostBlock C32 + RGB 头（blend_scale=0.73974609375）
```
跳接：`39←38+30`、`48←47+22`、`56←55+14`、`62←61+8`、`66←65+4`、`70←69+0`。

**1080p 几何**：处理区 1920×1152（底部 72 行镜像，`2*extent-coord-2`），ViT 20×32 = 640 token（有效 18×30）；post shift 3。decoder 移位 40–55 = 0/3/1/2 循环，56–61 = 1/2/0/3…，62–69 = 0/3/1/2（`native_runtime_shifts.h` 唯一）。900 档是我们自定的几何：1600×900 有效、**1600×960 处理**（09-17 定，原 1024 行版保留为 `900w`），ViT 25×16，第 16 行是零 token。

**NGX 输入**：Color / Output（1080p RGBA16F）/ Depth / MVec；history（slot8）= 上一帧网络输出，motion 在 slot10；`input_scale=1/32`，`rgb_mode=1`。

**算术**：
- FFN 激活 `x=clamp(x,-4,4); y=x*(0.89453125+x*(0.447265625-0.055908203125*|x|))`（half 多项式，不是 GELU）。
- 残差 skip-first：`H(input*skip)` 作为初始累加器，之后每 K32 做一次 half 舍入；FP8 是 E4M3 SATFINITE、RNE，次正规尾数允许进位到 8。
- 注意力：每 head 32 维，Q/K 归一化用半精度平方和，归约顺序固定；softmax 的 exp 是 half 仿射加移位的位映射（C32、ViT 系数不同）；分母求和树是固定的 key 顺序，不是平衡树。
- C64 三矩阵 FFN：64→256（分组扩展）→64（分组收缩，**每 32 输出通道只连 128 hidden，其余全零**）→64（混合）；C512 split FFN 是 512 混合→8 组 64→256→64。
- 输入混合按 WMMA 规则：两操作数指数和的最大值对齐，按 `2^(E-27)` 朝零截断后精确求和。随机场是 Box–Muller，用 MUFU 近似。
- 时序采样：UV 定点 21 位，五点十字核，MUFU.RCP 归一化。
- post70：输出合同是 `Color + 神经残差`；RGB 头两个 K16 的 27 位对齐整数规则。
- 原版 FP16 输出 surface 是**朝零截断**；AMD 预览驱动的 `f32tof16` 也是朝零截断。

---

## 3. 当前状态

**不在这里维护。** 现状（当前版本、基线、各游戏现装、正在进行）只看 `Development/WorkingPlan.md`——两处锚点必然有一处过期（09-29 发现本节还停在 09-26）。版本改动看 `CHANGELOG.zh-CN.md`。

## 4. 时间线（里程碑）

| 日期 | 事件 | 关键数字 |
|---|---|---|
| 08-31 | 权重解析、71 块构图恢复、5090 跑通原版、AMD 上传 arena | 153 条记录 |
| 09-01 | block0 出图、SASS 解出算术；row-major 假设被反证（矩阵按 tensor-core tile 排列） | |
| 09-02～03 | 在 5090 游戏 backend 里抓 live 中间层，用"下一层当裁判"逐段前移 | block70 RGB corr 0.945 |
| 09-04 | 动态游戏链 484s→10.6s；DirectML；1080p 单 DLL 进游戏 | 11.98fps |
| 09-05 | 像素审计翻案（此前根本没提交），8×8 网格 → 停追 FPS，改做 native 正确性 | |
| 09-06 | 原生逐值链 RGB512→0–70→RGB 全 exact；实机几何 640 token | 786,432 值 diff 0 |
| 09-07 | valid1080 整网 exact、时序 exact、进游戏出正确画面；闇夜战 4.0s→1.47s | 2fps |
| 09-08 | 闇→0.47s；光→0.186s（**tag 0.01 exact 终点**）；fast 链到 62.7ms（0.03） | 5→15fps |
| 09-09 | 33ms，GPU 饱和；显存之争（6.8→3.75GB）；闪烁靠输出平滑；0.04～0.06 | 29fps |
| 09-10 | fast38 34.0ms；0.07 包；浪人崛起 XeSS 出图；发现机器降频态（重启后 24.4ms） | 35fps |
| 09-11 | Magpie 路线打通；黑块根因 = 硬件 E4M3 Cast 不饱和 → NaN；全仓 43 处加饱和（0.10）；接管时间 22s→3.4s（0.11） | |
| 09-12 | 屏幕提示层（0.12）、FPS 显示 + XeSS FG（0.13）、0.14；C512 FFWD 换 FP8 无收益，"项目收尾" | Magpie 28→55 显示帧 |
| 09-13 | 小窗口 FIT_INPUT（0.15）；720 / 900 分支 | |
| 09-14 | **HIP 分支**：comgr 无 SDK 编译、D3D12↔HIP 桥接、512/900 逐位对上 oracle | |
| 09-15 | HIP 生产快路径 51→25ms；异步重绑竞态修复；读回节奏污染 HLSL 基准被识别 | 游戏 17→30fps |
| 09-16 | MH 分组收缩零结构、各家族 attention+投影融合、ViT 融合；"dup / 跳块"帧内成本法；权重预打包四连 | HIP 18.07 |
| 09-17 凌晨 | 读 `.s` 当 profiler：F() 去分支 + 16 load 连发（−0.68）、prefix 内联翻盘等 → **HIP 反超 HLSL** | 16.9→15.5ms，游戏 47→52fps |
| 09-17 | **0.20**（HIP，免预览驱动）；生产内核搬进 `hip/`；auto 选档（0.21）；900→960 行（0.22） | 900P 52～54 / 1080P 37～38 |
| 09-18 | 多 GPU 主机修复（0.23）；黑神话的钩子三道坎（未验通，已复原） | |
| 09-19 | OptiScaler 前置链（0.24）；主城掉帧修复；C32 寄存器复用 / 有界倒数；**900 解码尾部漏派发修复**；gfx1200 + gfx1201 双构建（0.25）；C256 frag；LOP 黑屏 = 打包漏 R11 shader（0.26） | |
| 09-20 | RE9 后置专用版（0.26.1）；从 AttExp 选入精确流式 attention / R3 自适应复用（默认关）；0.27 | 900P 56～57 |
| 09-21 | **算力缺口研究立项**（主线，见 §6）；C128/C256 零填充快路径、固定尺寸 ViT/decoder（−1.2/−1.7%） | |
| 09-22 | TheAutomatic PR5 设计独立实现分阶段桥接 → RE9 真正超分前接入 + 曝光修复（0.28、0.28.1）；合并 PR #7/#8；栅栏 local 化 + C32 CU 模式 | 58～59fps |
| 09-22 夜～09-23 | prod3～prod6：折叠 FFN、字节链、向量化 staging、mh 寄存器化、in16 别名、尾段转置 | 相对 prod2 −4.3/−4.5% |
| 09-23 | prod6 装机；DLSS5_FIT_LARGE（issue #6，>1080 输入降到 1080 层）剑星 + RE9 验通；**0.29 三包** | ~60fps；网友最低画质 73 |

---

## 5. 性能演进要点

### DX12 fast 链（09-08～09-12，186→约 24ms）
收益全部来自数据搬运：寄存器分块复用、FP8 格点上的中间量改用 f16 存、权重常驻 DEFAULT 堆、删 LDS 转存和 barrier、合批。**这台卡的核成本几乎全在逐元素标量尾巴**（软件 H/F、散写），不在带宽也不在矩阵乘。逐刀表见原文 §3「fast 链每刀收益表」。

### HIP 链（09-14～09-23，离线 900 档 51→12.1ms，全部逐位一致）
有效的几类刀，按类别记：
- **核融合**：各家族 FFN+QKV、attention+投影（C64/C128/C256）、prefix 进 block0、post RGB 头 / finish / 下采样进 C32 尾部。
- **权重预打包**：half / E4M3 / fragment 布局，一次 memcpy 取 B 片段；C512 QKV、ViT QKV / proj / contract、pool、decoder。
- **ISA 病灶**：F()/q8 的分支饱和改 fmin/fmax + cndmask；串行 load→wait 改连发；scale 读从循环里提出来。
- **结构零**：MH 收缩只遍历本组 128 K；C128/C256 全零 padding tile 直接写零。
- **固定尺寸**：编译期常量解锁展开与读取调度（ViT expand 一处 −26～36%）。
- **同步 / 驻留**：栅栏限定 LDS 地址空间（去掉 `global_inv`）、C32 用 CU 模式、in16 别名到 Scratch。
- **WMMA 操作数对调**（A/B 寄存器格式相同，对调得到 D^T）：折叠 FFN 让 hidden 不进 LDS、mh 的 ex/prob 留寄存器、ffn_fused 尾段转置。
- **请求合并**：C32 staging 把 16 条行读并成 b128（字节链 + 向量化）。

---

## 6. 算力缺口研究（318 期主线，09-21 起）

**问题**：9070 XT 独立程序实测 FP8 405T / FP16 204T / FP32 49.9T（与标称一致，时钟约 3.1GHz）；网络主矩阵有效吞吐只有约 55T。**判据是解释缺口，不是零碎提速**；负结果能排除原因也算数。总汇总 `results/network-cost-summary-20260921/README.md`，公众号稿 318.md。

已建立的认识：
1. **整网份额**（900/1080，稀疏事件 + 区段 ABBA）：C32 约 35%，C64 / C128 / C256 / C512 / ViT 各约 11～13%。局部机制证据**不能相加成整网解释百分比**。
2. **ViT 同 FLOPs 不同耗时**：expand/contract 的差异主要来自编译调度组织（固定尺寸解锁展开）；禁止 contract 展开慢 175%。
3. **计算密度探针**：保持读取量不变、只加寄存器内 WMMA，吞吐 150→299T，说明 150T 不是硬件上限，是供数和指令组织在限制。
4. **供数**：B 的工作集吞吐不单调；B tile 间距 +256B 后 span64 48→22μs；页内翻 bit10 同样有效 → 对地址低位敏感。真实 ViT 核在 RGP 里 memory stalled 68%（只代表那个热核状态）。
5. **规则**：读写成本 ≈ 指令数 + 触及的缓存行数，两项都算；lane 间仍连续时并宽才有效。排队按请求数算，不按字节数。
6. **分组 / 编号映射**：wave 总数固定时，组大小 1→2 或重排 logical_wave 编号都会慢 45%；HIP 驻留上限相同，原因未定。
7. **C32 周期账**（核内时间戳）：staging 31%、FFN 26%、QKV 11%、注意力 12%、投影 8%、尾部 9%、barrier 9%；矩阵只占 post 核约 15%。驻留贴着 LDS 上限。
8. **驻留**只在它是瓶颈时才值钱：VGPR 封到 96 反而慢；c256_attention 每个 launch 的尾巴 25～37% 是结构税。

仍未解：ViT 剩余约 50% 参考算力的具体限制因素；C32 余下部分的归因。

---

## 7. 已否定 / 不要重做（除非瓶颈变了，按"旧 null 要重测"原则说明理由再测）

- **占用率捷径**：C32 no-unroll（+0.64→+1.0 更慢）、waves_per_eu 提示（编译器不理）、LDS_SLIM、ffn_fused VGPR 封 96。
- **LDS 凑片**：C32 LDS_VECTOR（测了四次都是 null）、C32 / MH 的 V 转置、概率 DWORD 布局、AV 共读。
- **字节 / half 流**：MH 完整字节流当时慢（09-19 修漏派发后重测才通过，已进 0.25）；ViT byte/half stream、N2/N4 / M2 / M4、ViT FFN 融合（并行度不够）。
- **小通道 FFN 换布局**：C64/C128 tiled 或 frag（+0.3～0.4 更慢）。
- **C512**：mix 并进 FFN、FP8 展开（有逐位反例，只能收缩用 FP8）、attention+投影融合。
- **各种 hipGraph**：当前 GPU 时间把 CPU 提交全盖住了，收益为零。
- **C32 转置尾部并宽**（09-24：逐位同，慢 0.03ms；C32 卡读队列，写并宽不是瓶颈，转置反而让残差/缩放读变差）。
- **其他**：DX12 overlap（与游戏并发是双输）；VMM 稀疏映射（驱动只认"保留区 == 一个完整物理块"，封死）；buffer_load 32 位地址（正确，常量必须是 `0x31004000`，但无收益）；噪声缓存；多遍 NR（5090 上也不值）；C32 注意力寄存器化（压力抵消收益）；注意力投影输出转置（滚动循环别转置）。

---

## 8. 工程教训（合并版）

**测量**
- 只信同批交错 ABBA，别跨批比较绝对值；GPU 会卡在降频态好几天，量之前先跑基线。
- 逐核 HIP event 在这套驱动上不可靠，会出现负值，全插反而把帧时拉长 80%；短段事件也不能当依据。要么用 wall 加重复放大，要么用 dup / 跳块法（注意 HLSL 跳块带拷贝，会压低 HLSL 那边的家族成本）。
- 读回节奏会改变 GPU 频率：HLSL 全读回 26ms，只读首尾 16.7ms。性能测试一律只读首尾，正确性另做全帧检查。
- 单核隔离会把工作集留在缓存里，不能直接相加当整帧。
- `DLSS5_GAME_PROBE` 每帧 Flush，会破坏异步提交时序（地面变透明），不要和 ASYNC_SUBMIT 同开。
- 测帧率别开 Splashtop；先确认游戏有没有锁帧（剑星曾锁 30）。
- **游戏内帧率标准测试**（09-26 Zero 定）：《剑星》**1080P 窗口 + FSR 原生 AA**（渲染 1920×1080），**主菜单**读数，最简场景为辅。离 60 上限远、无缩放策略差异。flags 须 `NETWORK_HEIGHT=auto` 或 `1080`（固定 900 会把 1920 宽缩小）。基准：wave-owned 与 Daniel 0.4.0 均为主菜单 47～48 / 最简场景 51～52。 **按 F8 切 EXACT 再读**（剑星 flags 默认 `DLSS5_VIT_ADAPTIVE=1`，静止主菜单会复用 ViT 白赚约 3 帧；与 Daniel 对比必须 EXACT）。 09-27 Zero 重申：以后日常效能测试一律 1080P 窗口 + FSR 原生 AA；《匹诺曹的谎言》1080P 最低画质也贴 58～59（疑似 60 上限，未查），不作对比用；**日常只用剑星**（50 帧上下最敏感）。匹诺曹现装 0.32 + PACK8 模块，备份 `D:\DLSSNR-Lab\liesofp-fresh-032\backup-20260927-081126`。
- 派生测试脚本后先 grep runner 名；对照组没变化先怀疑脚本（09-16 两个假 null 就是这么来的）。
- RGP 捕获会改时钟和输出；RGP 里的 HLSL ELF 按占位哈希缓存，要先用 `dxilhash.py` 签名。

**数值**
- HLSL `round()` 是 RNE；`f32tof16` / D3D 驱动输出 surface 是朝零截断。
- FMA 收缩和上下文相关，凡要逐位的尾链两边都显式 `precise`。
- 单点候选能修一个反例，全幅上反而可能更差，别拿单点匹配去推广舍入规则。
- 单层高相关不等于多层稳定，必须做完整累计门。
- 硬件 E4M3 Cast 不饱和，所有无界值转换前都要 clamp ±448。

**GPU / D3D12 / HIP**
- 2 的幂行步长会让内存通道撞车；单 command list 塞整网会 DEVICE_HUNG，必须分块提交加 fence。
- D3D12 单轴 group 上限 65535；视图格式变量别复用（会建出 UNKNOWN 视图，device removed）；宿主贴图只能拷贝，不能建 UAV。
- ReShade immediate list 在 `_has_commands=false` 时直接 return，原生录的命令可能根本没提交。
- 派发网格按 token 和通道分别分块（900 档漏掉 4 个通道 tile 就是没这么做）。
- COMGR 确定性：同一文本两次编译字节一致，源码一变只改 `__hip_cuid_*`。校验标准 = 三道 hash + 去掉 cuid 后的 `.s` 对比。

**方法**
- 核内延迟问题先读 `.s`（数分支、数 load→wait、看重复 load），别凭结构直觉盲改。
- 跟 HLSL 并排逐段对"做同一件事但做法不同"的段。
- 旧 null 要重测：一刀的收益取决于当时的瓶颈。
- 静态指令数少不等于快；少 barrier 不等于快；少字节不等于快。

**运维**
- 游戏或 Magpie 开着时绝不换 DLL / HSACO，也不跑测试台。
- Windows Update 和 AMD Install Manager 会偷换驱动（已设 `ExcludeWUDriversInQualityUpdate=1`，计划任务已禁用）。
- 打包不能继承旧资产目录，要从仓库模板和当前源同步；配置唯一来源是 `scripts/*flags*.txt`（见 `scripts/CONFIGURATION.md`）。
- 远端 PowerShell 一律用 `-File`，别在 `-Command` 里 type 自己的输出文件（曾涨到 4.8GB）。
- commit 不加 Co-Authored-By；每做完一刀给 Zero 一句进度；时间只信 hook 时间戳。

---

## 9. 运维 / 构建 / 部署入口

- **目录**：生产宿主 `src/`、生产内核 `hip/`（`build-modules.ps1` 24 行配方，默认双架构，`SHA256SUMS`）、DX12 shader `shaders/`、打包与配置 `scripts/`；实验在 `Development/HIP/experiments/`，结果在 `Development/results/`，RE9 前置宿主在 `Development/RE9/presr/`（只入库版本锁定 + 补丁 + 脚本）。
- **AMD 机**：实验根 `D:\DLSSNR-Lab`（`hip-backend\` 放模块目录和 benchmark）；《剑星》在 `C:\Program Files (x86)\Steam\steamapps\common\StellarBlade\SB\Binaries\Win64`；成品在 `D:\給網友打包`。5090 的《剑星》在 `D:\SteamLibrary\…\Win64`。
- **构建**：`scripts/build-addon.sh --hip`（DX12 用 `--tiled`）；`hip/build-modules.ps1`。
- **部署**：每轮一个 `Development/deployments/<名字>/` 或 `D:\DLSSNR-Lab\stellar-<名字>\install.ps1`，流程是源 hash 校验 → 备份 → 替换 → 读回，并确认宿主 / INI / flags 前后不变，失败回滚。
- **打包**：`Development/tools/package-0xx.ps1`，底包逐文件核对、44 个 shader 变体编译、ZIP 读回校验，flags 从仓库模板复制。
- **远程 UI**：交互计划任务 `dlss5game` / `dlss5magpie` / `dlss5toggle` / `dlss5shot` / `dlss5rgp` / `dlss5toolbar` / `dlss5profiler`；Magpie 热键 **Alt+Shift+A**。
- **HIP 选项**：默认组合在 `src/native_hip_network.h` 的 HIP_FAST；诊断开关（dup / skip / memory / span probe）全部默认关。

---

## 10. 游戏适配要点

- **《剑星》**：FFX `ffxDispatch` 钩子（ReShade addon）；现走 OptiScaler 0.9.4 前置链，必须 `Dx12Upscaler=fsr31`（写 `ffx` 会静默落到 FSR2.1）；`GameUserSettings.ini` 里 AA=OFF 时 FSR 根本不创建。
- **Magpie**：输入是 8 位 sRGB 成品图，需要 `CODEC_SRGB=1`；光流在暗部会出垃圾向量，是已知限制（止血用 `MOTION_MAX_PX=64`）；包内带 XeSS FG ZeroMV。
- **浪人崛起**：XeSS 路径，运动向量符号为 −1。
- **匹诺曹的谎言**：R11G11B10 输出，需要 R11 写回 shader（0.26 修）。
- **RE9**：同一列表后面还有游戏自己的 draw（51～53 次），普通前置被安全检查拒绝。走 TheAutomatic PR5 设计的分阶段桥接 + GPL 命令列表代理，在超分前接入；曝光纹理必须传入（否则褪色）；尺寸越界要先检查、失败要回滚（0.28.1）。Xbox 版《鬼武者》用 0.26.1 后置包可用。
- **黑神话**：FSR3 静态链进 exe，未验通，已复原。
- **FIT_INPUT / FIT_LARGE**：≤1080 的小窗口 letterbox；>1080 的输入降采样到 1080 层，按亮度比调制原图。

---

## 11. 待办

已并入 `Development/WorkingPlan.md`（B/C 段与"产品适配与等待事项"）。本文件不再维护待办。

## 附：history/ 文件索引（流水在本表之后）

| 文件 | 内容 |
|---|---|
| `DevHistory-full-20260923.md` | **本文压缩前的完整版**（08-31～09-23 每一刀的数字、SHA、日志路径） |
| `porting-worklog.md` | 08-31～09-08 逐块移植流水（6276 行；第 2976 行之后倒序） |
| `reverse-engineering-notes.md` | 逆向结论原始记录 |
| `CURRENT-STATE.md` | 09-07～09-10 fast 链逐刀状态（最新在上） |
| `amd-port-plan.md` / `fast-path-plan.md` / `next-steps-plan*.md` / `PLAN.md` | 各阶段计划 |
| `README.md`、`native-runtime-contract.md`、`local-patch-tool.md`、`optiscaler-intro.md` | 早期索引 / 已过时的方案 |

---

## 12. 流水（新事件追加在本节末尾，时间正序）

## 2026-09-23 16:00：DevHistory 压缩

原文 593KB（约 30 万 token，新 session 读不动）按主题重组为本文件（约 22KB）：逆向事实、当前状态、里程碑、性能演进、算力缺口认识、不要重做清单、合并教训、运维入口、游戏适配、待办。完整原文 `git mv` 到 `Development/history/DevHistory-full-20260923.md`（提交 e0824bf）。续写规则改为新事件只追加在文件最末尾。

## 2026-09-23 23:00～09-24 00:05：《卧龙 2》Alpha Demo 试装（网友反馈"用不了"）

游戏在 9070 机 `C:\Program Files (x86)\Steam\steamapps\common\Wo Long 2 Wings of Ember Alpha Demo`（Katana 引擎，Streamline 2.9 接 DLSS，自带 FSR）。装 0.29 常规 OptiScaler 包（脚本 `Development/deployments/wolong2-20260923/install.ps1`，覆盖游戏自带 libxess/libxell 时备份到 `_dlss5_backup`），逐层排查：

1. ReShade 菜单出、无 DLSS5：游戏选 DLSS 后 OptiScaler 建了 fsr31 特征，每帧 Evaluate/Dispatch 都在跑，但 addon 钩的 `amd_fidelityfx_dx12.dll::ffxDispatch` 一次没触发。改钩 `amd_fidelityfx_upscaler_dx12.dll`（26KB 的 dx12.dll 只是转发壳）仍无触发。
2. 根因（读 OptiScaler 源码 FfxApi_Proxy.h）：游戏自己先加载了 upscaler dll，OptiScaler 把它当"游戏加载的 FFX 模块"用 Detours 钩其五个导出做输入捕获，自己的派发走 Detours 跳板，不经导出入口。`[Inputs] EnableFfxInputs=false` 后钩子每帧触发，网络初始化成功（1580×888 → 900 档）。
3. 常规前置随即被自家检查拒绝：`UNSAFE: draw/dispatch after deferred upscaler in same list`——和 RE9 同类，FSR 之后同列表还有 draw。
4. 换 RE9 宿主（`-Variant re9`，不装 REFramework dinput8.dll）：`PrepareFrame: render input metadata/texture size mismatch`（游戏开着动态分辨率，纹理按最大分配）+ 宿主 300ms/2 帧稳定判定永远过不了。关掉游戏内动态分辨率后两者消失（1664×935 = 1664×935）。
5. 之后神经路径生效：画面变灰、帧率不变（60）。日志：曝光扫描 >64 个候选（RE9 定制的过滤在 Katana 上失效，曝光未识别，FP16 线性场景色按曝光 1 归一化）；`prior job not yet submitted; original SR` 反复出现（Submitted 钩子对队列/时机的假设是 RE9 的，卧龙提交路径不同，多数帧绕过）。

结论：卧龙 2 不是"装不上"，是三层都要适配：EnableFfxInputs、动态分辨率关、以及 RE9 宿主的曝光发现 + 提交观察两处 Katana 化。当前机上装的是 RE9 变体 + `LmxxfDiagnostic=off`。代码改动：`src/native_submission_order_probe.cpp` 优先钩 upscaler dll 并在 hook_status 行记模块名/导出地址、派发入口前 8 次记类型（剑星回归未做，未发包）。未记入 0.29。

## 2026-09-24 00:30：C32 转置尾部（out 并宽）null

WorkingPlan 的"C32 产出端并宽"试完：FFN 收缩 + prefix + 投影全部转置，ffn8/scratch.ex/out/pre16 的窄写并宽。逐位同，但 1080/900 六组配对全部慢 0.03ms（0.2～0.3%）。原因：残差初始化和缩放访问改成 lane=行后 LDS 读变差，投影缩放 2→16 读，chain/finish VGPR +15。开关 `HIP_C32_TRANSPOSED_TAIL` 留 0，进"不要重做"。详见 `results/c32-transposed-tail-20260924`。

## 2026-09-24 01:00：探索 1 关闭——RDNA4 没有直达 LDS 的读取

318 账本里 staging 31% 想用 `global_load_lds`（显存直落共享内存）省掉寄存器往返和 LDS 写指令。comgr 报 `__builtin_amdgcn_global_load_lds` 需要 target feature `vmem-to-lds-load-insts`，gfx1201 没有；汇编器也不认 `global_load_lds_b128`。RDNA4 上这条指令不存在（CDNA/gfx9 有），硬件没铺路。探索 1 关，改看频率账本（探索 3，`Development/HIP/experiments/clock-ledger`）。

## 2026-09-24 01:05：频率账本——功耗墙，FFN 最费电，ViT 最省电

探索 3 做完（`results/clock-ledger-20260924`）：核族 dup×8 占满一帧逐族量时钟功耗。板功耗每个配置都钉在 325～328 W，时钟随负载变：C64～C256 FFN 占满时 2.51～2.55 GHz（比基线低 8～9%），C32 低 1～1.5%，C512/C256 注意力持平，ViT 反而高 1～2%（2.78～2.85）。整网 2.75 是加权结果，峰值测试 3.1 是纯寄存器矩阵省电。318"ViT 单测 2.5 GHz"是孤立微基准的读数，要改口。新杠杆：让 FFN 核族省电能抬全帧时钟，上界 1～2%；用户侧功耗上限 +10% 值得实测。dup 开关在 flags 文件里不在环境变量（第一遍白跑，当基线重复性用了）。

## 2026-09-24 01:15：FFN 核族的电烧在全局窄写；并宽指令不省电，减少触及行数才省

FFN 占满一帧换 mh_fast 模块看时钟（`results/clock-ledger-20260924/ffn-tail`、`ffn-stores`）：串行求和、LDS 交换 + barrier 都不耗电；去掉 norm 全局写 +4% 时钟，norm 和 out 都去 +7%。prod6 把 norm 写 24 条 b8 并成 3 条 b64，时间 −2.6ms 但时钟不动——转置后每条写仍触及 16 行，功耗跟触及行数走。下一把刀（逐位）：out 从已有的 qfeature LDS 暂存整行写出，norm 按 part 暂存 4 KB 后整行写出，每行只写一次；预期 FFN 占满时钟 +7%、整帧 1～2%。

## 2026-09-24 01:30：mh_fast 全行写（HIP_FFN_LINE_STORES）——逐位，−0.6/−0.7%，prod7 候选回归通过

功耗账本指出的那把刀做完：out 从 qfeature LDS 暂存整行写出，norm 三个 part 暂存后整行写出（多一个 barrier，LDS 每组 +8.4 KB，驻留仍由 VGPR 定）。模块集 ABBA 三孪生逐位全 0，1080 −0.10/−0.10/−0.08ms，900 −0.08/−0.09/−0.09ms；FFN 占满一帧时钟 +1.2%（2526→2554 MHz）。写出字节没变所以没到"去掉写"的 +7%，省的是部分写的开销。prod7 候选（只换 mh_fast 两架构）回归：12 帧 RGB 哈希 2 序列 × 2 档全部与 prod2 基线一致，四组额外对照一致；1000 帧计时 900 12.01/12.03、1080 16.91/16.92（基线 prod2 12.62/12.72、17.80/17.88）。`results/mhfast-line-stores-20260924`、`deployments/stellar-prod7-20260924`。未装机，等用户关游戏。

## 2026-09-24 07:13：prod7 装进剑星

用户确认游戏关闭后 `stellar-prod7-20260924\install.ps1`：2 个 mh_fast 模块（gfx1200/gfx1201）哈希核对后替换，宿主/INI/flags 未动，备份 `D:\DLSSNR-Lab\stellar-prod7-20260924\backups\20260924-071340`（`-RestoreBackup` 回滚）。等用户实玩反馈。

## 2026-09-24 07:19：用户反馈 prod7

《剑星》900P 中画质拉伸 2K，常测场景稳定 60 帧（prod6 时"最快接近 60"）。prod7 通过实玩，进 0.30。

## 2026-09-24 07:30～18:30：《赛博朋克 2077》2.31 试装——三层坑，最后一层是别名瞬态资源

常规 OptiScaler 0.29 包装进 `bin\x64`（`deployments/cyberpunk-20260924/install.ps1`，覆盖游戏自带的 5 个 xess/ffx dll，备份 `_dlss5_backup`）。网友"用不了"逐层：
1. 和卧龙一样：游戏自带 FSR dll，OptiScaler 走 Detours 跳板 → `[Inputs] EnableFfxInputs=false` + 优先钩 upscaler dll 的 addon。
2. `terminal resource state not representable by FFX`：Reverse() 只认 8 种状态。补齐深度态和任意只读组合态，并把撞到的状态值写进日志（`src/native_pre_upscale.h`）。
3. **网络跑起来但画面只有色调变化。** dump 网络输入发现每帧都是同一幅"天空 + 灰地"的静止环境（第 600 帧和第 3000 帧统计四位全同，字节不同——云在动），而用户看的是街景。根因：`DLSS5_PRE_UPSCALE_ASYNC=1` 的延后提交让我们拷贝颜色纹理的命令排到游戏下一帧的早期通道之后，REDengine 的颜色缓冲是瞬态别名资源，那时那块显存装的是天空探针。剑星的颜色纹理持久，赛跑读到上一帧也看不出。**`DLSS5_PRE_UPSCALE_ASYNC=0` 后 dump 是真场景**（min 0.04 / 中位 0.17 / p99 0.64 / max 9.8，纸白 1 正好）。
中途把纸白猜成 8 是错的（那是天空探针的量级），已改回 1；顺手加了 `DLSS5_PAPER_WHITE`（Record 的门从 {0.5,1,2} 放宽到有限正数）和 `DLSS5_DUMP_FRAME`（每帧路径第 n 帧 dump 游戏颜色输入，配 DLSS5_DEBUG_DUMPS）。dump 统计脚本在 /tmp/f16stats.py 一类的临时件，结论在此。用户实机确认待做（ASYNC=0 + 纸白 1 的组合还没看过）。
教训：**同队列不等于同时序——延后提交遇到别名瞬态资源就读到别人的内容；游戏适配先关 ASYNC。**

## 2026-09-24 18:34：赛博朋克 2077 用户确认

ASYNC=0 + 纸白 1 后用户实机："材质明显差异了"。赛博朋克通过。机上 flags 已清掉 DEBUG_DUMPS/DUMP_FRAME/PAPER_WHITE，保留 EnableFfxInputs=false（OptiScaler.ini）与 DLSS5_PRE_UPSCALE_ASYNC=0；addon 是探针版（钩 upscaler dll + 状态表补齐 + 两个诊断开关），进 0.30 前要过剑星回归。

## 2026-09-24 19:10：细节量化——"只有光影"还是"有纹理"，离线一算就知道

赛博朋克那次教训：色调变了不等于网络起了作用。做了个客观指标（`/tmp` 临时脚本，方法记这儿）：输入与网络输出同尺寸，亮度进 log2(1+64L) 的显示域，减高斯低通得高频，比 RMS 与相关系数；再比梯度幅值。
- **赛博朋克（坏的那次，天空探针输入）**：σ=3 高频相关 0.9997、拉普拉斯能量比 1.04——纯色调，判"没起作用"。
- **剑星凍结菜单帧（prod7 网络输出 vs live-menu-before 输入，900 档）**：σ=1 高频 RMS +11%、梯度幅值 +13%、相关 0.887（细节是新合成的，不是拷贝）；σ=4 比 0.95/相关 0.92（中频基本保留）；低频色调变化 std 0.27（色调也变，但不只色调）。裁图 `deployments/stellar-addon030-20260924/detail-crop-in-vs-out.png`：皮肤出毛孔级纹理、布料出织纹、背景金属出颗粒，边缘有彩色微噪。
判据可复用：高频相关 >0.99 且能量比 ≈1 = 只改了色调；相关 <0.95 且 σ=1 能量比 >1.05 = 有新细节。用户实机（19:06）：双钩 addon 在剑星画面/60 帧照旧。
- **赛博朋克第 3000 帧（ASYNC=0 后的真场景，中央裁 1296×720 离线跑 prod7 900 档）**：σ=1 高频比 1.001、相关 0.973；σ=2/4 比 1.03/1.04；梯度幅值 +13%。比剑星温和：它的输入本身已经很锐（高频 RMS 0.152 对剑星 0.131），网络主要是把已有的划痕/磨损纹理强化、边缘高光提亮，不像剑星那样在光滑皮肤上合成新纹理。裁图 `deployments/cyberpunk-20260924/detail-crop-in-vs-out.png`。用户主观"材质明显差异"与此一致。

## 2026-09-24 19:16：剑星双钩 addon 帧率（用户）

900P 拉 2K 最简单场景 60～61 帧，经 Splashtop 远程测（远程 UI 约吃 1～2 帧，本机应 61～63）。双钩 addon（c7f68e60…）在剑星画面/帧率与 prod7 一致，剑星侧通过。赛博朋克帧率待用户报。

## 2026-09-24 19:29：赛博朋克帧率（用户）

低画质 900P 拉 2K 约 50～51 帧（Splashtop 远程）。用户主观：材质有差异但"不够真实"；屏幕上黄色分辨率/帧率字样在 2077 里没显示。

## 2026-09-24 19:40：prod7 内核装进 RE9

RE9 目录里的内核比 prod6 还旧（0.28.1 那版，c32/mh_fast 哈希都对不上）。runtime 从 HIP\gfx1201 加载（LUID 选子目录），SHA256SUMS 只查文件名。`deployments/re9-prod7-20260924/install.ps1`：两架构各覆盖生产模块（10 个换掉，参考/实验模块不动），备份 `D:\DLSSNR-Lab\re9-prod7-20260924\backup`（-Restore）。gfx1201 mh_fast 98faa6d4、gfx1200 36ad568f = prod7。等用户看效果。

## 2026-09-24 19:50：RE9 装 prod7 后用户"绝对只是亮度变化"——抓帧量化说不是

用 RE9 宿主的 capture-colour.request（runtime 从 _storage_ 加载，请求放 _storage_）抓同帧：input RGB9E5 1512×848、proxy/neural 1600×900 FP16、result FP16。
- 网络域 proxy→neural：细纹理能量比 1.03、相关 0.979、**梯度幅值 +19.5%**。
- 游戏域 input→result：能量比 1.08/1.11/1.13（σ=1/2/4）、相关 0.99/0.986/0.982、梯度 +19%；平均亮度 4.108→4.077（几乎不变）。
判据：色调-only 是相关 0.9997、比 1.0、梯度 1.0；RE9 明显不是。裁图 `deployments/re9-prod7-20260924/detail-crop-in-vs-out.png`：面板缝、划痕、黑色金属边缘都更硬。
另外 prod7 与 0.28.1 内核逐位同（回归对 prod2 基线 12 帧哈希全同），换内核不可能改画面，只可能改速度；用户印象里的"之前不一样"不是内核造成的。发出去的 0.29 REFramework 包（prod6 内核 + fitlarge runtime）同理不受影响。本机 D: 上 0.29 包文件夹和 zip 已不在（用户上传后删了），无法重新哈希。

## 2026-09-24 20:00～20:50：强度外推试看、Google Drive 链接、网友"统一宿主"补丁审查

- 用户要看"最高强度"：`DLSS5_STRENGTH` 上限放到 3（>1 沿 lerp 外推，纯诊断），剑星/2077 flags 临时写 2,1；用户看完 21:07 已删回默认。
- 0.29 三包补了 Google Drive 镜像（给没有中国手机号的用户），README 两处链接；以后发布 = 夸克 + Google Drive。
- git：用户定"只推 297，别动外层 ai-theorys-study"。
- 网友的 OptiScaler 通用宿主补丁（统一 RE9 与常规包）审完，归档 `Development/RE9/presr/contrib/generic-host-20260924/REVIEW.md`：查询记账（切点无未闭合查询即可切分）与提前包裹（返回地址判断游戏 exe 建列表）两处可用；backend 补丁是我们 prepare-host.py 旧快照的翻版且缺曝光 ABI v2 两行；runtime 编译脚本不打我们的 runtime 补丁（退回 0.26 时代）；宿主 dxgi.dll 需 MSVC 未提；无测试证据。等用户问到网友在哪个游戏跑通、帧率多少再定要不要合进 prepare-host 实测。

## 2026-09-24 21:10～21:50：2077 三方对比（默认 / OP / Magpie 0.29）——红偏来自颜色转移，改成按 exe 查表 1,0

用户同机位截四张（机位微差，逐像素对不上，看全局统计 + 等倍裁片；图在 `deployments/addon030-strength-20260924/`）：

| | 平均 R/G/B | 高通细节 RMS（σ=2，log 亮度） |
|---|---|---|
| 默认 FSR（F6 关） | .107/.112/.059 | 0.159 |
| OP 1,1（847p 前置） | .122/.094/.049 | 0.193（+22%） |
| OP 1,0（只转亮度） | .120/.121/.072 | 0.189（+19%） |
| Magpie 0.29（1080p 后置，OSD 30 帧 33 ms） | .105/.111/.055 | 0.212（+34%） |

- 第一轮误判：先拿到的 op/magpie 两张机位差太多，看成"OP 动得轻"；补了默认那张才看清：OP 1,1 不是轻，是**色相转了方向**——R +14%、G −16%，绿色霓虹环境光压成灰褐；Magpie 和默认色调几乎一样，只加细节。
- 原因：前置路线把色调映射**之前**的线性缓冲交给网络，解码 `Hue(neural×ratio, neural)` 在线性域取神经色相，再过 2077 的 tonemapper + LUT，色相就跑了；Magpie 吃的是 sRGB 成品，LUT 已定型。
- 只转亮度（1,0）：色相比例回到游戏自己的，细节增益基本没丢（+19% 对 +22%），脸/报纸/红衣服都比默认清楚。
- 落地：`native_game_codec.h` `LegacyParameters` 里 `DLSS5_STRENGTH` 缺省或 `auto` → 按 exe 查表（Cyberpunk2077.exe → 1,0，其他 1,1），写 `event=strength` 到 oneshot 日志；模板 `hip-game-flags.txt` 加 `DLSS5_STRENGTH=auto`，CONFIGURATION.md 一行。addon a569ed6f…（`deployments/addon030-strength-20260924`，build-addon-oneclick.sh --hip），21:50 两游戏都关着，已装进剑星和 2077（backup-stellar / backup-cyberpunk，`install.ps1 -Restore`），两处 flags 的显式 STRENGTH 行删掉由表决定。剑星行为不变（1,1）。
- 细节上限：Magpie 在 1080p 上跑网络所以细节比 OP 多一截，但 30 帧对 51 帧；这是前置路线用 847p 换帧率的结构代价，不是 bug。
- RE9 宿主路线（LmxxfNrRuntime.cpp 自己读 `DLSS5_STRENGTH`，上限 1）不受影响；RE9 是后置 sRGB 域，色相问题不适用。

## 2026-09-24 23:00～25 01:30：launch 尾巴——双流死路，同流任意序 + tile 旗子成刀（900 −1.6%）

主线第 4 条。先量驱动（`HIP/experiments/stream-overlap`）：两条 stream 在这块 Windows HIP 上**完全不并发**（只有一条硬件队列，`GPU_MAX_HW_QUEUES` 无效），跨流事件一对 110～180 μs；同流 `hipExtModuleLaunchKernel` + `hipExtAnyOrderLaunch`（去 AQL barrier 位）能让下一个 launch 在上一个收尾时派发（2 wave/SIMD 时每 launch 198 → 31 μs）。第一版 spin 核用 `readsteadycounter` 计时，那条 `s_sendmsg_rtn` 全 GPU 串行，量出来全是消息拥塞——换成 `SHADER_CYCLES` + `s_sleep` 才对。
任意序没有"部分依赖"，只能把依赖搬进核里：土法 programmatic dependent launch（`HIP/experiments/pdl-chain`，`results/pdl-chain-20260925`）——C64/C128/C256 六条链上 FFN/QKV 核与窗口注意力核各发 `_pdl` 孪生，入口按 token 坐标等上游 tile 的计数器（FFN 组等上一块注意力的 ≤6 个窗口，注意力组等本块 FFN 的 ≤8 个 tile），出口每 wave `fence(release)` 后 +1；host 链头普通提交、其余任意序，计数器按（核种、通道、格子宽高）各一份、永不清零、目标为累计 wave 数；最近几块张量攥住不还 pool。逐位：18 个槽 2880 帧零差异。
拆账（1080）：协议纯成本 +0.25～0.29 ms（发旗 0.10，等旗 0.15～0.19：组开头一次 L2 往返 + barrier，没法和核开头重叠），调度捡回 0.23（正好是 launch-occupancy 预测的尾巴）；组屏障发旗版净零，改每 wave 发计数器 + 去掉 per-group acquire 后净 −0.1（−0.6%）；**900：11.74 → 11.55，−0.18 ms，−1.6%**，三次重跑 −0.16～−0.19。只开 FFN 或只开注意力都是零，两头要一起。
坑：(1) 环形槽位混用不同尺寸格子 → 累计目标追不上 → 死锁一次；(2) helper 里加空指针提前返回那版在任意序下三跑三报 `hipErrorLaunchFailure`，普通提交正常，撤掉后两跑两过，原因未明；(3) 时钟随功耗漂，只看相邻 A/B。
生产化：两份 hip 源加 `HIP_PDL_KERNELS` 孪生（原核不动）、host `opt.pdl`（`DLSS5_HIP_PDL`，模板 =1，Magpie 模板同）、插件重编 5be18ac3…；`deployments/stellar-prod8-20260925`（build/regression/payload/install）。regression-prod8（01:02）：900/1080 各两序列 12 帧哈希对 prod2 逐位全同；1000 帧 ABBA 对 prod2 基线：900 −0.80 ms（−6.3%，prod7 同口径 −0.65/−5.1%，即 prod8 比 prod7 约 −1.2%），1080 −1.02 ms（−5.7%，prod7 −0.92/−5.2%，约 −0.5%）。日志 `deployments/stellar-prod8-20260925/regression-prod8.log`。06:40 装进剑星（5 文件 + flags 一行，备份 backups\20260925-064001）。

## 2026-09-25 06:47～07:20：剑星切 DLSS 档位后 DLSS5 消失——钉死的 FSR 上下文

用户装 prod8 后从"平衡"切"质量"/"DLAA"，效果没了，切回也没了（进程内永久失效）。日志：06:47:00 切 DLAA 时 OptiScaler 建了新 FSR 上下文（1000002）并释放旧的（1000001），我们的 pre-upscale 日志从那一刻起一行都没有——不是回归失败，是 `dispatch_core` 在 `DLSS5_FIT_INPUT` 分支里把 `fit_context` 钉在第一个上下文上，"直到它被销毁"，而销毁钩子只挂在 upscaler dll 的 `ffxDestroyContext` 上；剑星的宿主经 shim 调用，我们钉住的是 shim 级句柄，provider 级销毁钩子里的指针对不上，永远清不掉——后面每个 dispatch（新上下文，任何档位）都静默透传。`restarts>=8` 也是个隐患：每次切分辨率的 session reset 都吃预算，切八次就死。
修：(1) shim 的 `ffxDestroyContext` 也钩（同 dispatch 的双钩子），命中记 `fit_context_destroyed via=shim/provider`；(2) 自愈：钉住的上下文连续 120 次没派发而别的上下文在派发，视为已死，改钉新的（记 `fit_context_reassigned`），FSR4 跟随者交替派发时每次命中都清零计数，钉不丢；(3) restart 预算只在失败（phase 5）时消耗，几何/队列变化无限次。插件 0211a78a…（`deployments/stellar-prod8-20260925` payload 已更新），等用户关游戏装。与 PDL 无关（flags 曾临时改 0，装机脚本写回 1）。
07:03 装剑星（用户切档位来回确认恢复）。根因追到 09-24 `1a3aa01`（卧龙 2 那次把主钩子挪到 upscaler dll、dispatch 补了 shim 双钩子而 destroy 没补）；0.29 发包时钩子还在 shim 上，不受影响。用户实测剑星：900P→2K 简单场景 60～61，1080P→2K 47～48。07:08 同一 payload 装进 2077（install.ps1 加 -Game）。
用户实测 2077（Splashtop 远程，简单场景）：低画质 2K 质量档（1707×961，1080 网络）41 帧，平衡档 51～52（昨天 prod7 50～51）。黄字仍不显示（老问题，低优先级）。

## 2026-09-25 07:20～08:20：C512 链旗子（不采用）与 0.30 打包

用户定"这一轮做完就打包"。C512 链 7 个核各发 `_pdl` 孪生（`HIP/experiments/pdl-c512`，四个模块），逐位；900：只 C512 −0.16 ms、只 C64-256 −0.19、两者都开 −0.15/−0.16；1080：−0.11 / −0.12 / −0.09。不相加——板功耗钉 325 W，填了空隙就掉时钟，两族像共用一份"时钟预算"。**不采用**，实验和结论归档 `results/pdl-c512-20260925`；用户加功耗上限后可复测叠加。坑：实验 host 打在生产头文件上，生产 ctor 只在 opt.pdl 时分配旗子缓冲，timeline 的 flags.txt 没写 PDL=1 → 对空指针算偏移 launch 失败。
0.30 打包：`Development/tools/package-030.ps1`（0.29 复制：三包基线 0.29，模块 prod8 两架构与剑星机上一致，插件 0211a78a，flags 模板查 PDL=1 / ASYNC=auto / STRENGTH=auto，常规包 OptiScaler.ini 叠加 `scripts/optiscaler-regular.ini`，RE9 宿主/runtime 与 0.29 同哈希，codec hlsl 与 0.29 同哈希）；package-notes 六份改 0.30；README 两处"当前版本"与更新记录行（链接待上传）。

07:53 三包打完（`Development/tools/release-030-results.json`，D:\給網友打包）：Magpie 336,377,155 B sha256 2b467532…、OptiScaler 366,576,181 B 8b3f1ae3…、OptiScaler-REFramework 421,034,771 B ae445772…；每包 SHA256SUMS 逐项核对、44 个 shader 变体编过、RE9 runtime 冒烟通过。等用户上传夸克 + Google 后填 README 链接。
08:08 用户上传完成：夸克 https://pan.quark.cn/s/80a735ab9f88（三包一个分享）、Google Drive https://drive.google.com/drive/folders/1pKZpLosgJXxUOZTMg_m0sbCipX9Q3WYo；README 两处链接已填。0.30 发布。

19:55 《极限竞速：地平线 6》（Xbox 商店版，`C:\XboxGames\Forza Horizon 6\Content`，实际运行路径在 WindowsApps 下）装 0.30 常规包（`deployments/forza6-030-20260925/install.ps1`，覆盖了游戏自带 `amd_fidelityfx_upscaler_dx12.dll`/`libxess.dll`，有备份可 `-Restore`）。第一次启动黑屏卡死（OptiScaler/ReShade 日志在第三次 D3D12CreateDevice 后同秒断掉，进程活着，插件一行未写——它在 30 帧 Present 之前不动手），关插件后正常，再开插件却不再复现，原因未抓到；`dump.ps1`（dbghelp MiniDumpWriteDump）备着，再黑就抓。真正的问题：链路通了（DLSS→OptiScaler→FSR，`render=1508x848 upscale=2560x1440`），但前置路线第一帧 `UNSAFE: draw/dispatch after deferred upscaler in same list` → fatal 透传，F6 无反应——和卧龙 2 同一种列表布局。`DLSS5_PRE_UPSCALE=0` 后置路线可用：1440 缩 1080 档，稳态 22.5 ms/帧≈44fps，覆盖 5362/6300 帧，F6 切换有日志，STRENGTH auto→1,1，黄字不显示（同 2077）。0.30 包不动，README 分游戏段写手动改法；下一版把 PRE_UPSCALE 做成 auto（首帧探测列表尾部有无后续工作，有则落后置）。网友说的"运行不了"多半就是这种"装了跟没装一样"。


## 2026-09-25 20:09 起：mapped/post 数据流审计与 post70 输入复用候选（Yami，待 GPU 实测）

按更新后的 WorkingPlan 开始追生产者/消费者。发现旧计划的前提过时：mapped/post 的 staging 在 09-23 已改为每 lane 4 次 b128，不是仍在 16 次 b32；当前特征生产者也是 HIP 而不是 HLSL 编码。block1 ← block0 down；block66 ← decoder_project2x_h16w(oc=32)；post70 low ← block69 main，skip ← block0 main8。每 token 的通道本已连续，改 tile 顺序不保证减少缓存行请求，不能直接承诺读等待减半。

先做较小候选 `HIP/experiments/c32-post-input`：post70 每 wave 两行像素共享同一低分辨率行，k=2/3 的 low 读取复用 k=0/1 寄存器；skip 与所有数值运算不变，奇数 sy/height 回落原读法。保留原核、同体异名 control、reuse 三个导出；新 runner 从现行 host 提取选项，prod8 模块底包、PDL=1、adaptive/graph/dup 关，两档整网 ABBA，计时外槽首尾逐位比较，并检查 post 每帧确实调用一次。生产源码和游戏安装均未改。

本机地址/有效性检查 59,904 对通过，MinGW Windows host 编译通过；已传 `D:\DLSSNR-Lab\hip-backend\c32-post-input`，入口 `start.ps1`（检查空闲→GPU 编译→900/1080 对照）。此时 GPU 编译、原核/control ISA 对照、GPU 逐位和性能结果均待执行，不宣称提速。原始依据和操作见实验 README；布局改造仍保留，先看这个重复读候选值不值得。


## 2026-09-25 22:21 起：自主跑完 post70 三种输入候选，均不采用

Zero 明确授权：DLSS5 优化的耗时编译、实验、回归、分析由 agent 自行执行，不再让用户手动跑命令。已记 WorkingPlan；仍遵守机器空闲检查。

`HIP/experiments/c32-post-input` 在 gfx1201 跑三类候选，两档各三轮 ABBA，并有同体异名 control。通用纵向低分辨率复用：900/1080 平均 +0.0265/+0.0278ms；将偶数几何提升到 host 检查后：+0.0084/−0.0028ms；block69 main→post70 low 用 FP16 精确传值：+0.0071/+0.0056ms。control 单次噪声约 ±0.028ms；后两者无稳定收益，不采用。每槽首尾 RGB 逐位检查全同，计时内无读回，post 调用计数确认每帧一次；这是固定输入筛选，不是全时序回归。

ELF 比对确认实验模块内 10 个原核机器码与 prod8 全同，control 与原 post 全同。偶数特化实际少两条 b128；FP16 post 改为 4 条 b64 低分辨率读取，post VGPR 都为 158，block69 VGPR 153 未变。不是假 null，也不能因此宣布整个 staging 已到极限。结果和代码身份归档 `results/c32-post-input-20260925/README.md`。生产源码、游戏安装、发布包未改。

同时补读 ViT 旧 page/pitch/groups 记录：完整 4MiB 权重的 padding/xor 收益很小，随机 stride 重排和多 wave 合组更慢。下一轮若做调度，限定真实核一 wave 一组的小范围二维 tile 编号重排，验证 A/B 复用取舍，不重追特殊 span64。


## 2026-09-25 22:33 起：ViT 局部二维工作组编号，六候选无稳定收益

`HIP/experiments/vit-group-order`：真实展开/收缩各做 GM2/4/8，保持每组一 wave、原累加顺序和输出地址，只让相邻 token tile 接连访问同一列权重。区别于旧随机 stride 和多 wave 合组。26,973 个 tile 映射检查无漏无重，覆盖 900 档25行的尾组。

两档各三组 ABBA（每槽20预热+160计时帧）。展开三候选的900均值 +0.006～+0.008ms，1080约0～+0.013ms；收缩900约−0.002～+0.005ms，1080约+0.002～+0.019ms。同期同体异名对照单次约−0.011～+0.036ms，未获稳定收益，六个均不采用。各槽首尾RGB逐位同，调用计数确认命中；这是固定输入筛选，不是全时序回归。

两次模块内76个原核函数体对prod8逐字节全同，展开/收缩control也全同。展开VGPR77→78/77/77，收缩205→211/212/212，地址计算改变编译调度，不能把耗时差全归给缓存。数据、源码身份、ISA核对归档 `results/vit-group-order-20260925`。生产、游戏和发布包未改。

下一步改为重测prod8 C32阶段账：旧c32-phase-trace逐核同步+Memcpy更新全局trace指针，host替换锚点还没适配PDL；先改成参数传trace区域、预分配、少量阶段/稀疏采样，并确认计时ISA和插桩扰动，别直接沿旧阶段份额猜刀。WorkingPlan已更新。


## 2026-09-25 22:56 起：重建 C32 阶段账，得到一把约0.1～0.2%的逐位小刀

`c32-phase-current` 去掉旧工具逐核CPU同步/Memcpy，预分配trace缓冲并经参数传指针，显式本地20位SHADER_CYCLES，不用REALTIME消息。每次测一个阶段与整段、每32窗口抽一个、8帧轮换余数。两档粗分+FFN细分全部RGB逐位同，插桩约+0.05～0.14ms（不到整帧1%）；部分核VGPR增加，故只以稳定阶段排序指导实验，不冒充未插桩精确账。新观测：输入准备约24%，FFN整体38%；其中主体25%、残差4%、入口同步2.6%、FFN发布6.8%。主体包括权重读取/量化，不是纯WMMA份额。结果 `results/c32-phase-current-20260925`。

沿残差检查发现非对角K16半块恒零，`c32-diag-zero` 去掉每wave六条乘零WMMA。六组真实权重×全部有限FP8编码，49,152个float32结果逐位同；短槽3轮、800帧长槽2轮，两档十组候选对照均快。长槽900 −0.0256ms（约0.2%）、1080 −0.0148ms（约0.09%），收益很小，留下一次合包，不单独装游戏。

标准导出候选收窄为只改chain/chain_finish_dcrop/chain_finish三核：三个函数体与实测孪生相同，其余七核对prod8字节不变。双架构编译通过，gfx1201正式NativeGameFrame回放8条件×12帧，96个候选RGB帧与prod8逐帧同哈希（含720、900/1080移动、history和浮点路径）；gfx1200仅编译。最终C32 hash gfx1201 e41c5c0b… / gfx1200 fafe5fe1…，候选在 `D:\DLSSNR-Lab\hip-backend\c32-diag-zero\candidate-modules` / `candidate-gfx1200`。完整结果、每帧hash和复现代码见 `results/c32-diag-zero-20260925`。生产源码和游戏/发布包未换。

下一刀查C32 FFN权重的片段预排，尤其32×128收缩矩阵的跨行读取；只改排列与对应寻址，不同时动同步/输出转置。WorkingPlan已更新，§3当前状态也从prod6/0.29旧摘要同步到prod8/0.30。


## 2026-09-26 01:55 起：闭源v0.4.0汇编调查，单wave/寄存器路线；偏淡对应默认LocalTone=0

用户给桌面下载目录dlssnr_on_amd_setup.exe，SHA 2d37453e…与官方v0.4.0资产digest一致（发布说明：比0.3.3性能提升42%）。另下载官方0.3.3（af5b9bbe…）对照。静态提取DLL与HIP fat bundle，用libLLVM20反汇编gfx1201：旧44、新86个函数，未知指令0；未运行安装器或闭源核、未改游戏。

C32的32线程/2KB LDS/零barrier寄存器快核在0.3.3已有；0.4.0新增42个核，其中24个C64/128/256专用MH核，另有reg1d/reg_vit与512布局转换。C64新核64线程/4KB LDS/7个静态barrier，对照旧通用核256线程/15616B/17个；有真实spill，不能只看零barrier。C32入口/出口四次128位读写，坐标除4、tile步长512B，支持4×4片段组织推断。packed-half归约与我们的求和路线不同，未证明逐位等价。C256 chain是显式DLSSNR_CHAIN开启，默认不能归功给它。

02:10用户补充网友截图偏淡、灯光/色彩不浓。进一步找到安装包完整INI模板：LocalTone=0、LocalStructure=1、ToneChannels=0、ToneLift=0、Style=0、ToneCurve=reinhard。UI明确LocalTone管大范围光照/色彩，宿主也将默认0送入控制参数；这与反馈相符，但未拿网友INI/做同帧A/B，不能定死为根因，更不能说它关闭光照计算换帧率。PreUpscale默认1，所以1080输出也不自动等于1080网络输入。

报告/身份/资源/默认INI在 `results/closed-v040-20260926`，复现工具 `tools/closed-inspect`，原二进制与完整反汇编只留/tmp。WorkingPlan把独立C32单wave窗口原型提到优先位，保留我们原数值与视觉控制；权重片段预排转后续小刀。单窗口四wave不是算法必付成本，这条认知需修正。


## 2026-09-26 02:21：从新增核名单收窄到关键派发与数据归属

Zero指出Daniel可能是一个关键改法带来40%跃升，不能把42个导出理解成42项小优化。进一步对齐宿主：0.3.3在0x1800363a3先要求C==32才进寄存器快路；0.4.0在0x180039c67检查同类flag后，0x18007a480表把C32/64/128/256都分派到快核。默认flag条件旧版已有，变化是覆盖范围与实现，不是简单把默认0改1。

旧通用路径每窗口显式global workspace为C32/C64 8KiB、C128 16KiB、C256 32KiB，新快分支绕过分配。旧C64 GPU入口从参数0xa0读取这块指针，加窗口号×8192，0x95c7c即有准备后输入的global_store_b32；还没完整标注其全部生命周期，不只叫“概率表”。旧swin_var本来也是融合核，真正关键候选是一个head的完整窗口归同一wave，减少中间状态落global/LDS，而不只是“多融合一次”。

自家旧c64_window_fused.hip已核：256线程，head=alltid/128，first=awave*16，nrm/feat放LDS，仍一头四wave；其null没有否定一头一wave。主线改为C64受控原型，原色彩/分辨率/数值路线不动；42%因果份额仍待实验。证据追加closed-v040报告、dispatch-delta.json/txt，WorkingPlan同步。


## 2026-09-26：一头一wave的C64首版逐位跑通，继续追整网质变

按Daniel版本差异线索独立实现c64-wave2：两wave覆盖完整窗口的两个head，两块4KiB LDS原生片段平面按生命周期复用，Q/K/V驻留寄存器，V用相反WMMA方向直接生成B片段。32项f32归一化用4次wave部分和传递保持原顺序，softmax保留现有WMMA归约，不改颜色/分辨率/跳层。4个barrier、VGPR190/191、零private spill。

900/1080各三组200帧ABBA，最终RGB槽首尾逐位同；替换8个C64块后平均−0.149/−0.257ms，约1.3～1.5%。模块74ed8686…，工具与结果分别HIP/experiments/c64-wave2、results/c64-wave2-20260926。只是可行节点，目标未完成；下一步扩C128/C256分账，查片段供数与寄存器生命周期。未改生产和装机，完整多帧历史回归待稳定候选。

## 2026-09-26：一头一wave扩展与寄存器调度，混合候选整网约3%

C128/C256独立实现均通过固定输入RGB逐位。初始C256有private spill；每个QKV tile重新引入不透明lane索引，限制跨tile地址/片段缓存生命周期后清零spill。编译调度栅栏进一步降VGPR，滚动query循环用uniform寄存器索引缩小代码；FFN两路展开优于四路，但C256全融合仍慢。没有改FP8/FP16舍入、颜色控制或分辨率。

最终筛选组合frag+launder+sched+roll+ht2，只替换C64+C128共20块，C256维持prod8：900/1080各三组200帧ABBA，配对均值−0.29591/−0.50451ms，约2.5%/3.0%耗时下降。全部槽首尾bitdiff=0，目标调用36/帧、实际替换20/帧。C256单独短筛+0.21068ms，全部替换−0.16194ms；不能因为零spill就判定C256问题已解决。

源码、全部分支筛选CSV/日志及校验脚本已归档c64-wave2；候选module SHA256=601f93af77afb3ac376ef5fdbe6cad8e9e2865f005988d4dc381a13fcacfe8bd。下一步保留生产FFN/QKV，仅验证C256一头一wave attention/projection。完整历史回归、gfx1200、游戏FPS仍待做；未部署。Daniel关键结构线索已转化为小幅实测收益，42%的因果份额与本项目质变目标尚未完成。

## 2026-09-26：C256保留生产前段，单换一头一wave注意力获得小幅收益

新增mode 6，独立核读取生产normalized FP8 [pixel][Q,K,V][channel]，用共享平面把V转成B片段后复用为AV，attention/projection段由已验证完整原型生成。原FFN/QKV与输入feature保持不变，输出PDL每窗口16wave计数改为8，前段计数与槽复用方式不变。现有PDL可见性/复用待审问题仍保留，测试通过不代替协议证明。

900/1080各三组200帧ABBA，配对均值−0.09923/−0.12809ms，所有槽首尾bitdiff=0，16块/帧替换计数正确。C256全融合+0.21068ms回退可通过保留生产前段避开；仍非大幅提升。gfx1201 float/byte输出151/142VGPR、零spill、32KiB LDS，module cc8166b3…；mode 7组合随后完成两档各三组200帧ABBA：900 −0.39283ms、1080 −0.67259ms（约3.3%/4.0%耗时下降），所有槽首尾逐位同、36块/帧替换正确。结果目录c64-wave2-20260926，下一步组合分账及feature直接读取省LDS。

## 2026-09-26：C256 attention残差直接读取，LDS减半但新增收益未定

实验增加DirectFeature开关：feature只在最终对角残差计算时从原FP8输入读，省掉16KiB plane0；V转置/AV复用仍用plane1。gfx1201模块6a0c6426…，LDS32768→16384B，float/byte输出VGPR151/142→152/144，零spill。1080 mode 6三组200帧ABBA全部槽首尾逐位，配对−0.15867/−0.17082/−0.14146ms，均值−0.15698ms。旧attention-only的−0.12809ms不在同批，不能把差值直接算新增收益；开关默认关，mode 7最佳已验证组合不变。

源、manifest与日志归档c64-wave2。下一主线移到C32完整窗口单wave原型，先中间chain，再prefix/post生产者布局；不把其收益混入Daniel版本差异解释。

## 2026-09-26：C32完整窗口单wave链式原型逐位跑通

独立额外模块c32-wave1替换block2/3/67/68四个非finish chain。保留输入输出窗口FP8、shift/crop补零、三段残差对角、C32专用FP16平方和与四个K16顺序softmax归约。Q/K/V寄存器驻留，FFN展开转置直接收缩，AV直送projection；4KiB LDS只存FFN半精度残差，单wave无需组barrier。

首版两档各三组200帧ABBA、每槽首尾RGB逐位同，每帧4次替换计数正确：900 −0.05340ms、1080 −0.08415ms。VGPR240、零spill，module380a5da9…；收益仅约0.5%，不当成目标完成。跨tile地址隔离版本239VGPR、零spill，1080 −0.06430ms（同样三组逐位）；没有实测改善。FFN隐藏片段滚动循环对照也完成1080三组逐位：−0.10293ms，VGPR仍240，module efc870c3…；与首版差仅约0.019ms且跨批，不据此断言额外提升。后续优先扩大到mapped/finish，再查prefix/post布局。未改生产/部署，多头组合与完整历史回归尚待。

## 2026-09-26：C32扩到八块；滚动窗口降寄存器并扩大收益

mapped首块block1/66和finish block4/69加入单wave原型，分别保留mode0输入先转half再乘scale、裁切/F转化和2×2下采样原求和顺序。finish用原4KiB半精度残差平面复用输出，未增加全局临时缓冲。八块首版两档三组200帧ABBA逐位，900 −0.09231ms、1080 −0.13849ms；mapped256VGPR/private60B/14spill，chain240、finish244VGPR。

QKV子段坐标隔离+编译调度栅栏未降压力（chain246、mapped15spill），1080短筛−0.06934ms；单wave改WGP mode短筛−0.11416ms，均无改善证据。保留开关默认关。

关键变化是保留窗口四tile外层循环：Q/K/V从动态C++数组换为可统一索引ext_vector，避免全展开与数组溢出。RollHidden+RollWindow：chain/mapped165VGPR、finish174VGPR、全部零spill、4KiB LDS；模块e51696a7…。两档三组200帧ABBA，900配对−0.16490/−0.18124/−0.17031ms（均−0.17215），1080−0.24577/−0.26211/−0.26295ms（均−0.25694），所有槽首尾逐位、8块/帧计数正确。不能把跨批差额精确归因于一个编译设置，但资源变化和整网增益方向一致。

未部署，尚未与MH候选组合、未跑完整多帧历史。下一步prefix/post全分辨率两端，随后组合回归。C32旧版Daniel已有，不当成0.3→0.4新增原因；当前结果仍远未到质变目标。

## 2026-09-26：prefix/post完整单wave与MH组合，整网耗时下降6.0%/6.6%

C32加入post70和prefix0，完整10块：post保留低分辨率特征+FP8 skip合并的两次Hrtz、最后RGB32项顺序f32点积；prefix复用生产噪声/历史特征，用低16lane算特征、高16lane取后8项，保留两次FP16 WMMA（零K片段也保留），main8和下采样顺序不变。两端分别176/174VGPR、零spill、4KiB LDS。完整C32模块73a2dfdb…，两档三组200帧ABBA逐位：900 −0.29543ms、1080 −0.45633ms。

新增DynamicFrames，按fixture生成位移/增益/黑白输入、seed=123+17*f，首帧null history、后续前一帧输入作history。每帧先baseline后candidate，同步完成后比最终RGB；两档各16帧完整C32全逐位。它证明Network入口的数学/历史输入一致，不替代NativeGameFrame完整宿主生命周期。

wave-owned-combined生成host把C32和MH候选接到同一Network，mode0 prod8、1 MH36块、2 C3210块、3合用46块。MH模块cc8166b3…（C64/C128整块融合+C256 attention-only，非DirectFeature），C32模块73a2dfdb…。两档三组200帧ABBA：900配对−0.70055/−0.70633/−0.70033ms，均−0.702405ms，11.661035→10.958630ms，耗时−6.0235%；1080−1.10831/−1.10106/−1.09592ms，均−1.1017625ms，16.693508→15.591746ms，耗时−6.5999%。全部槽首尾逐位、46块/帧计数正确；组合也完成两档各16帧动态历史对照，全逐位。

所有source生成器、原始日志/CSV、module manifest与校验脚本归档。未部署、未宣称游戏FPS提高相同比例。下一步可选生产集成、gfx1200编译、NativeGameFrame完整回归，再测真实游戏；后续继续研究ViT/C512/布局。6.6%是阶段结果，尚未实现用户要求的质变，也未证明Daniel42%的精确贡献分配。

## 2026-09-26：完整NativeGameFrame回归与gfx1200编译通过，6.7%收益保留

prepare-runtime.py把已验证组合Network接进原NativeGameFrame/D3D12桥接与benchmark_vit_reuse.cpp，仅以进程flag DLSS5_HIP_WAVE_OWNED=0/1选择基线/候选，记录销毁时46块/帧的累计调用/替换数。尚未改生产头文件、游戏或发布包。gfx1200两额外模块用gfx1201同一源构建通过，完整module hash清单归档；没有gfx1200硬件运行证据。

900/1080静态与移动、720移动、900连续历史，共6对12帧。72个候选RGBA16F帧逐帧SHA256与基线相同，所有已检查帧无非有限值，累计替换数与实际帧数吻合。覆盖真实捕获HDR输入→D3D12 encode→HIP网络→history/decode→D3D12输出，补上前轮仅Network接口的缺口；不覆盖所有游戏宿主资源生命周期。

完整处理长测每槽1000帧，去前200帧，按基线/候选/候选/基线：900四槽11.94554/11.23668/11.28361/12.00644ms，均值11.97599→11.26015，−0.71585ms/−5.98%；1080四槽16.98308/15.85462/15.87311/17.01188ms，均值16.99748→15.86386，−1.13362ms/−6.67%。计时槽只检查抽样输出，不能称8000帧全部逐位；72帧正确性回归单独逐帧比较。

所有帧hash、flags、原始日志与CSV、校验脚本、host输入头文件hash归档wave-owned-combined。下一步生产可选路径集成、兼容条件/回落、双架构打包与游戏计时；继续研究Daniel新增ViT/C512寄存器路线，目标仍未完成。

## 2026-09-26：wave-owned进入可选生产路径，正式构建回归与回落通过

生产Options增加wave_owned，NativeGameFrame add-on解析DLSS5_HIP_WAVE_OWNED=0/1、默认关。启用且兼容时加载c32-wave1/c64-wave2两模块并选择46块新路径；不同布局、graph及被替换范围跳层保留prod8派发。首次计数回归抓到skip_blocks.empty()过严：正式配置本来跳ViT42/43/46，导致0块替换；修正为只限制相关范围，后续实际46块/帧并逐位通过。

四份内核实现原样迁至hip/wave_owned_*.inc，实验生成器共用；正式通用配方支持26模块，增量prepare_wave_owned.py输出相同内核。两架构编译通过。通用/增量初次文件hash不同，经完整汇编对比确认只有__hip_cuid编译单元符号差异，规范化此一项后所有指令与metadata一致。gfx1200只编译，gfx1201实机。

生产host的完整NativeGameFrame回归：720/900/1080静态/移动/历史6对12帧，72候选帧逐位相同；关闭MH byte stream和关闭byte feature两种配置，在没有新增模块的旧模块目录测试flag1回落，额外24帧逐位，计数0替换。性能使用无计数插桩的生产host：每槽1000帧去前200，900 11.98305→11.26020ms（−0.72284，−6.03%）；1080 16.99276→15.87261ms（−1.12014，−6.59%）。

add-on SHA256 3e3ca57a079b607405227a7b3b5b1c72b71ae0416438928e69bc3b65808e67a8；payload包括两架构四新模块和add-on，部署脚本提供prod8预检、游戏关闭检查、已存在/新增文件备份恢复、flags回滚。gfx1200实验基线只含5个旧更新模块，不能假装是完整24模块集；安装仅增补新pair，其他旧模块不改。已准备但未执行安装/发布。RE9/C API实例配置尚未接此环境开关，后续独立处理。下一步同场景真实游戏ABBA与继续研究Daniel剩余ViT/C512差异，目标未完成。

## 2026-09-26 04:55～05:49：wave-owned 剑星实机 A/B（闇采数，朱雀补记）

闇在最后一次提交后按 install.ps1 实装了一轮，并已自行回滚：04:55 prod8 拍 `baseline-a`，05:02 安装（备份 `D:\DLSSNR-Lab\hip-backend\wave-owned-production\deploy-stellar\backups\20260926-050241`），05:12/05:18 拍 `candidate-b1/b2`，之后回滚到 prod8（05:49 核对：addon 0211a78a、flags 无 WAVE_OWNED、无新模块）。每组 6 张 HUD 截图 + samples.json（约 500MB，未分析），目录 `wave-owned-production\game-evidence\`。
同场景《剑星》2K 质量档（1707×961 → 1080 网络，FSR 输出 2560×1440），HUD 读数：baseline 47/47/46，candidate b1 49/49/49、b2 49/49/49；05:49 用户在 prod8 下复读 47～48，补齐 ABBA 的第二个 A。**约 +2fps（+4%），帧时约 −0.7ms**；离线 1080 档网络 −1.12ms，游戏里兑现六成多（网络约占 21ms 帧的 17ms，外加功耗墙）。画面未见异常，逐位一致由离线回归保证。尚未正式装机，2077 未测。

## 2026-09-26 05:51～05:54：wave-owned 正式装进剑星

用户关游戏后 `install.ps1 -Game stellar`：5 文件哈希校验、flags 加 `DLSS5_HIP_WAVE_OWNED=1`、dxgi/OptiScaler.ini 不变，备份 `deploy-stellar\backups\20260926-055146`。用户同场景 2K 质量档实测 49～50fps（prod8 47～48）。`native-hip.txt` 当前进程 `wave_owned_requested=1 wave_owned_active=1`，未回落。2077 未装，发布包未改。

## 2026-09-26 06:02～06:10：Daniel v0.4.0 同场景实机——快在少算 35% 像素，按像素效率持平

手动代理装（`results/daniel-040-ingame-20260926/swap.ps1`，只换 dxgi.dll，已切回并核对 fbfb6676）。剑星 2K 质量档同场景：Daniel **56～57fps**，我们 wave-owned 49～50。其日志：网络直接跑渲染分辨率 1707×961（我们 FIT 到 1080 层，处理 1920×1152，像素多 35%），网络 GPU 11.7～12.2ms；我们 15.87ms 按像素折算 ≈11.8ms——**内核效率持平，差距全在网络尺寸**。其 0.3→0.4 的 42% 是补自家旧通用路径的课（与闇静态拆包结论一致）。另见 WMMA 统计：Daniel 全包仅 73 条 FP16 WMMA，我们 ViT QKV（130 条）与 decoder 投影为 FP16——原版权重即 float/half，逐位约束所致，全换 FP8 估计整网仅 2～4%，不是主因。
画质："浅"有依据——其默认 PreHistory=0（日志 `history off`，时序历史未喂网络）、LocalTone=0、961 行网络。
**新主线**：网络按渲染分辨率跑（只补齐到网络所需倍数，不再放大到 1080 几何），像素约 −20%，预期帧时 −3ms 级，保留时序历史与现有色彩控制。需新增任意尺寸几何（ViT token、decoder 移位、固定尺寸编译特化）。

## 2026-09-26 06:12～06:25：2K 质量档往下缩进 900 档——帧率撞 60 上限；auto 规则改为"超出 ≤10% 往下缩"

根因复盘：1707×961 在 auto 下超过 1600×900 → 选 1080 档，`NativeInputGeometry::Make` 按比例**双线性放大**到 1920×1080 再补到 1920×1152——网络多算的 35% 像素全是插值。剑星 flags 临时 `DLSS5_NETWORK_HEIGHT=auto→900`（备份 `D:\DLSSNR-Lab\daniel-040\sb-flags-before-900.txt`）：日志 `input=1707x961 network=1600x900 viewport=0,0,1599,900`、temporal armed、wave_owned_active=1。用户：同场景（去帧率限制/垂直同步）稳 60，日志 avg_ms_per_frame 16.6～16.7 = 仍有 60 上限（来源未查：驱动 Chill/FRTC、60Hz+强制垂直同步或 Splashtop），真实余量未测；主菜单 56～57（非上限）；立绘效果可见。对照：同档 1080 放大 49～50，Daniel 56～57。
代码：`native_network_geometry.h` `ForInput` 改为输入两轴都不超过某档 110% 时往下缩进该档（1707×961/1760×990→900，1761→1080，1366×768/1408×792→720，1920×1080 仍 1080）；本机单元小测通过。缩放与 FIT_LARGE 无关（只管 >1920×1080 的接收），走同一 `Make()` 双线性。RE9 宿主同样调用 auto。**未重编 add-on**，剑星当前靠 flags 固定 900；下一版打包时恢复 auto。画质损失 = 输入宽高各缩约 6%，待 Zero 在游戏内对比确认。

## 2026-09-26 06:30～06:38：标准对照（1080P 窗口 + FSR 原生 AA，主菜单）——与 Daniel 0.4.0 打平

Zero 定标准测试：1080P 窗口、FSR 原生 AA（渲染 1920×1080，两边网络同尺寸）、主菜单读数（最简场景为辅）。flags 临时 `NETWORK_HEIGHT=1080`。
- 我们 wave-owned：日志 `input=1920x1080 network=1920x1080`、wave_owned_active=1；**主菜单 47～48，最简场景 51～52**。
- Daniel 0.4.0（swap.ps1）：**主菜单 47～48，最简场景 51～52**，完全相同。其日志网络 14.0ms（200 帧均值，history off）、游戏队列自旋等待 14.1ms、present 周期 19.5ms。
我们离线 15.87ms 为 1920×1152（多 72 行补齐，+6.7%），按像素折 ≈14.9ms，另含时序历史一路；游戏内持平是因为我们 PRE_UPSCALE_ASYNC=1 与游戏渲染重叠，他是 inline 自旋。结论：**同尺寸打平**；此前 2K 质量档他领先 7 帧全因少算 35% 像素，已由 cd0fea6 往下缩进 900 档补齐。可做的小账：1080 档底部 72 行补齐（原版几何，逐位约束所致）。

## 2026-09-26 06:43～06:50：auto-tier add-on 装进剑星并三档验收

本机重编 add-on（cd0fea6 源码，`deployments/autotier-20260926`，f71f38a3），只换 addon、flags `NETWORK_HEIGHT=auto`，备份 `D:\DLSSNR-Lab\autotier-20260926\backups\20260926-064302`（`install.ps1 -RestoreBackup`）。注意：本机 mingw 13-posix 编译**不确定性**（同源连编两次哈希不同），且与闇装的 3e3ca57a（4,055,051 B，非本机编）大小不同；源码差异仅 `native_network_geometry.h`，以游戏内行为验收。
同进程切三档，日志与用户读数（主菜单 / 最简场景）：1080P AA 1920×1080→1080 档 47～48 / 51～52（与旧 add-on 同）；2K AA 2560×1440→1080（FIT_LARGE 缩）42～43 / 45～46；**2K 质量 1707×961→900 档 56～57 / 60**（与固定 900 一致）。auto 新规则通过，今后标准测试不必改 flags。

## 2026-09-26 07:04：wave-owned 生产状态逐族区段账——C32 仍 34%，C512 成了唯一没动的族

新工具 `HIP/experiments/family-ledger`（sparse-prefix 改动态拓扑：先录一帧 Stage 游标，按阶段名定 15 区段，16 轮 localABBA），结果 `results/family-ledger-wave-owned-20260926`。prod8+wave-owned 46 块、生产 flags、graph/adaptive 关，09-21 捕获帧；派发 234→214。900/1080 × PDL 1/0 四组，每组 18 次原始 FP32 逐位检查全 0；标记扰动 PDL1 ≤0.11%、PDL0 ≤0.24%，区段和对 GPU 跨度 +1.2～1.8%，以 PDL=1 为准。
1080（ms / 份额，括号为 09-21 旧账）：C32 5.243 / 34.1%（6.444 / 35.5%）、C64 1.828 / 11.9%（2.363）、C128 1.787 / 11.6%（2.214）、C256 1.860 / 12.1%（2.254）、**C512 2.231 / 14.5%（2.179 / 12.0%）**、ViT 2.232 / 14.5%（2.471）、transitions 0.182。900：C32 3.623 / 33.5%、C512 1.768 / 16.4%（第二大）。
判断：C64/C128/C256 降约 20%，C32 同比例降但排位不变；C512 是唯一未做一头一 wave 的注意力族（92 派发不变），Daniel 0.4.0 对应有 reg1d / 512 布局转换核。下一刀推荐 C512 一头一 wave（按 MH 比例估 1080 −0.4～0.5ms）；C32 剩余为输入准备与 FFN 主体，排第二。未改生产源码/游戏/发布包。

## 2026-09-26 07:05～07:28：C512 一头一 wave（attention/projection-only）——逐位但 null，不采用

逐族账里 C512 是唯一没动的族，照 C64/C128 做法试一头一 wave。`c512_attn_wave`（`HIP/experiments/c512-wave`）：一窗口一 workgroup、16 wave 各一头，替换 `mh_attention_fused_fp8_out` + `mh_attention_project_frag_c512`/`..._scalar_fp8`；吃生产的 FP8 normalized、f32 feature、`PackedMhWeightQkvFrag`，AV 留 32 KiB LDS，投影保持生产操作数方向/K 顺序/残差初值/尾部。124 VGPR、0 spill。900/1080 各 3 组 200 帧 ABBA（对照 = prod8 + wave-owned 46 + PDL=1）全部槽首尾逐位、16 帧动态历史逐位、13 次/帧替换（含 identity 块）：**900 −0.017 ms、1080 −0.019 ms，噪声内，null**。两 wave 共一头（1024 线程）撞 192 VGPR 上限溢出 110，+0.30 ms。
重复派发量被替换两核边际成本：attention +0.165/+0.252 ms、projection +0.221/+0.331 ms（900/1080）——奖金约 0.4～0.6 ms，但融合核花掉同样多。原因：C512 只有 104/135 个窗口，一窗口一 16-wave 组、每 WGP 约 3 个常驻，排出第二轮尾巴且每 wave 串行 4 个 query tile；生产两核有上千个小组。投影要全部 16 头的 AV（K=512），拆 query 撞 VGPR、拆头要跨组，融合在这一层没空间。C512 的时间主要在 FFN 链（mix→split FFN→split projection→QKV），若再动 C512 应看那段。详见 `results/c512-wave-20260926`。生产、游戏、发布包未改。

## 2026-09-26 07:30～08:40：C512 FFN 链——QKV 与 mix 改 32 token/wave，逐位，900 −1.0% / 1080 −1.3%，进可选生产路径（未装）

重复派发分账（13 块/帧）：QKV 归一化 0.60/0.50ms 最贵，mix(h16w) 0.28/0.42，ffn_fused_t8 0.23/0.29，projection_frag 0.16/0.24。四核都是「一 wave = 16 token × 64 列」，每 16 token 重读整列权重（QKV 1080 单次 ~424MB L2 权重流量）。候选（`HIP/experiments/c512-ffn`，两档三组 200 帧 ABBA，全逐位+动态历史）：QKV 字节尾巴经 LDS 并成 b128 仅 −0.04；**QKV 32 token/wave −0.07～−0.10**；48/64 token 溢出反慢；投影 32 token null；**mix 32 token −0.04/−0.12**；**QKV+mix 合用 900 −0.122（−1.12%）、1080 −0.216（−1.40%）**。结论：C512 FFN 链受供数（每字节权重只喂 16 token）限制。
生产化：`hip/c512_m32_{mh,deep}.inc` + 两个独立新模块（配方 28 个，原模块源不变），开关 `DLSS5_HIP_C512_M32`（默认 0，`C512M32Compatible` 仅在生产 h16w/frag 配置激活，日志 `c512_m32_requested/active`）。生产配方机器码与实验逐条相同；双架构编译。NativeGameFrame 回归（`deployments/c512-m32-20260926`）：900/1080 静态+移动、720 移动、900/1080 历史全部逐帧同 SHA，每帧 26 次替换，回落用例 0 替换；生产 host 千帧长测 900 11.114→11.005（−0.99%）、1080 15.683→15.481（−1.29%）。add-on 3d8295db（含 auto-tier）+ 4 模块 payload 与 `install.ps1` 就绪于 `D:\DLSSNR-Lab\c512-m32-20260926`，**未安装未发包**。
⚠️ 回归中**现行生产基线**一次 900 历史用例第 8～11 帧与其余 20+ 次不同（非本改动），疑 PDL 可见性/复用，待高次数 PDL=1/0 对照。结果 `results/c512-ffn-20260926`。

## 2026-09-26 09:00～10:10：生产基线 900 历史偶发不一致——PDL 1/0 共 350 次零复现，不调默认值

c512-ffn 回归里那次"基线第 8～11 帧不一致"：回归的 `extra-900-history-False` 本身就是离群那次（多数结果 frame8 `F9FABBE4…`），异常时帧时抖到 18～23ms（有外部 GPU 负载），第 8 帧整幅微差、热点为网络 x≈770～1340 的全高纵带，后续帧由历史带下去。复现：900 历史 PDL=1/0 各 50、加并发 1080 回放干扰各 60、按回归原进程顺序（先 720 候选）30、1080 PDL=1 50——**全部 0 次不一致**。协议审计（RAW 等待覆盖、每 wave release 发布、累计目标分槽、`pdl_keep` 32 张量覆盖 C256 链、行对齐下依赖派发 acquire）未找到缺陷；理论空档记为：非对齐跨 tile 行出现时需补 gl0/gl1 invalidate。PDL 现值（仅 C256 链）：900 −0.081ms（−0.72%）、1080 −0.071ms（−0.45%）。结论：根因未定、不支持 PDL 竞态，**生产保持 PDL=1**，兜底 PDL=0 代价约 0.08ms。详见 `results/pdl-race-20260926`。

## 2026-09-26 09:12：C512 M32 装进剑星（待用户标准测试）

游戏关闭时执行 `deployments/c512-m32-20260926/install.ps1`：add-on 3d8295db（含 auto-tier）+ 双架构 c512-m32-mh/deep 模块，flags 加 `DLSS5_HIP_C512_M32=1`（auto / PDL=1 / WAVE_OWNED=1 保持）。备份 `D:\DLSSNR-Lab\c512-m32-20260926\backups\stellar-20260926-091206`。待 Zero 按标准测试（1080P 窗口 FSR 原生 AA 主菜单）读数，并核对日志替换生效。

## 2026-09-26 10:17：C512 M32 剑星实测

用户 2K 质量档（1707×961→900 档）：主菜单 57～58（C512 前 56～57），最简场景 60（上限）。日志 pid=29300：`c512_m32_active=1`、`wave_owned_active=1`、`network=1600x900`。当日 2K 质量档主菜单累计：prod8 约 47～48 → auto 分档 56～57 → +C512 57～58。

## 2026-09-26 09:15～10:40：m32-sweep——普查 16 token/wave 核，ViT project 加宽到 64 列（逐位，1080 −1.9%，900 −1.0%）

推广 c512-ffn 的"一 wave 多算、权重少读"（`HIP/experiments/m32-sweep`，`results/m32-sweep-20260926`；对照 = prod8 + wave-owned + C512_M32）。重复派发普查：C256 生产 FFN 最贵（16 次/帧，900/1080 边际 0.93/1.32 ms），其后 ViT attention 0.36/0.56、ViT QKV 0.34/0.54、decoder 投影 0.34/0.46、ViT project 0.24/0.41。
- **C256 FFN 32 token/组：null**（LINE_STORES 版 1080 +0.036）。按 FLOP 算它 ≈460 TF，已贴 FP8 峰值——算力瓶颈，少读权重没用，LDS 60 KB/181 VGPR 反拖驻留。**排序要看离峰值多远，不只看边际成本。**
- ViT QKV 三种加宽（32×64 / 32×32 / 16×64）两档不一致或变慢：wave 数不够藏延迟。decoder 16×64 变慢（2×2 上采样尾部每元素散写 4 处，加宽后串行）。
- **ViT project 16×64（每 K16 步 f32→E4M3 的 A 片段喂 4 个 WMMA）：三批 ABBA 900 −0.105/−0.112/−0.101，1080 −0.300/−0.289/−0.281 ms**，槽首尾与 16 帧动态历史逐位。手写特化版编出来不同（98 vs 160 VGPR）只剩 −0.04/−0.22，生产用实测模板原文，ISA 逐条相同。
- 接入：`hip/vit_wide_deep.inc`、模块 `vit-wide-deep`（配方 29 模块）、开关 `DLSS5_HIP_VIT_PROJ_N64`（默认 0，要求 vit_proj_frag）。NativeGameFrame 回归（900/1080 静态/移动、720 移动、900/1080 历史、关 frag 回落）全部逐帧同、计数每帧 8 次全替换。生产 host 千帧长测未跑（10:20 Zero 开了剑星，停手）。add-on 106ff3d0 + 2 模块 + install.ps1 在 `D:\DLSSNR-Lab\vit-proj-n64-20260926`，**未安装**。
- **配方缺口已补**：prod7/prod8 的 mh_fast 带 `HIP_FFN_LINE_STORES 1` 编，但 `hip/build-modules.ps1` 那行没写，按配方重编会丢 prod7 的 −0.6%。补后与 prod8 `mhfast.generated.hip` 逐字节相同。

## 2026-09-26 10:22～10:27：ViT project N64 千帧长测通过并装进剑星

`vit-proj-n64-production\regression.ps1 -TimingOnly`（生产 host，1000 帧去前 200，槽 0/3 基线、1/2 候选；两侧 WAVE_OWNED/PDL/C512_M32=1）：900 10.997→10.893ms（−0.104，−0.95%）；1080 15.511→15.232ms（−0.279，−1.80%），1080 四槽最终 rgb.f16 哈希相同。随即 `install.ps1`：add-on 106ff3d0 + 2 个 vit-wide-deep 模块，flags `DLSS5_HIP_VIT_PROJ_N64=1`，备份 `D:\DLSSNR-Lab\vit-proj-n64-20260926\backups\stellar-20260926-102640`。待用户实测。

## 2026-09-26 10:32：ViT project N64 剑星实测

2K AA（2560×1440→1080 档）：主菜单 43～44 / 最简场景 46～47（上午 42～43 / 45～46，+1 帧，与 1080 −1.8% 吻合）。2K 质量（900 档）：主菜单 57 / 最简场景 60（与 C512 后 57～58 持平，900 档只 −0.1ms 读不出）。

## 2026-09-26 10:35～10:45：剑星一直开着 ViT 自适应复用；修正"与 Daniel 打平"

核 flags 发现剑星早就是 `DLSS5_VIT_ADAPTIVE=1`（REUSE_HOTKEY=1，F8 切换；AE/EXACT 提示只附在 FPS 文字行，黄字行看不到——下次重编挪到黄字行）。`AdaptiveVitGroup` 在生产路径每帧调用。用户 2K AA 实测：AE 运动 44 / 静止 47；EXACT（F8）静止 44。**复用静止 +3 帧，运动无额外开销，保持开。**
**修正**：上午标准对照"我们 47～48 = Daniel 47～48"时我们开着 AE、主菜单静止，不公平；EXACT 下我们估计 44～45，比 Daniel 慢约 3 帧，与离线按像素折算（我们 ≈14.9ms 对其 14.0ms，约慢 6%）一致；其差额部分是时序历史（他关、我们开）的代价。今日所有游戏内读数均为 AE 状态（同状态之间的前后对比仍有效）。标准测试规则已加"F8 切 EXACT"。

## 2026-09-26 10:50～11:00：0.31 三包打完（待上传）

`Development/tools/package-031.ps1`（0.30 底包；只新增 5 个模块×双架构，取自剑星安装、每架构 29 个，其余 24 个与 0.30 相同——剑星上多出的非 packed `deep_fast.hsaco` 是旧实验残留、生产不加载，不入包；add-on 106ff3d0；模板 WAVE_OWNED/C512_M32/VIT_PROJ_N64=1、常规包 VIT_ADAPTIVE=1；源码提交 1c3950c）。产物 `D:\給網友打包`：Magpie 339,077,522 B `acd8e64b…`、OptiScaler 369,275,463 B `f53af436…`、OptiScaler-REFramework 423,711,009 B `c030bf36…`；底包逐文件核对、44 shader 变体编译、ZIP 回读、RE9 runtime 冒烟通过。清单 `Development/tools/release-031-results.json`。README 当前版本/更新记录已改好（本地未提交），等 Zero 上传夸克 + Google Drive 后填链接。

## 2026-09-26 11:19：0.31 发布

用户上传完成：夸克 https://pan.quark.cn/s/e76b8611e3cc（三包一个分享）、Google Drive https://drive.google.com/drive/folders/1xtBe_XhgF9eqBlrlIQMgWcEkzm0UKHIZ?usp=sharing；中英 README 当前版本与更新记录已填。

## 2026-09-26 10:50～12:30：ViT attention 四候选全 null；C32 prefix 分摊 1080 −0.03ms（宏并入、默认关）

`experiments/vit-attn-c32-input`（m32-sweep 派生，基线含 VIT_PROJ_N64），五候选均逐位 + 动态历史通过。ViT attention：m32 两 query tile 共用 K/V +0.08ms（并行度减半），V 转置写/8 字节读 −0.01，QK 操作数对调去 LDS 转置与 barrier ±0.03，二者叠加 ≈0——不卡访存量、V gather、同步链，卡在逐元素 exp/fp8 打包的 VALU 依赖延迟，逐位下无结构空间，不采用。C32 prefix：原来只有半 wave 算 16 个输入特征（Box–Muller 噪声），改两半 wave 同指令流分摊、g0 一次 bpermute：900 −0.01（噪声内）、1080 −0.034（6 组全负），以 `CW_PREFIX_SPLIT`（默认 0）并入 `hip/wave_owned_c32.inc`，配方未改、未进生产，下轮合包重编时打开并回归。结果 `results/vit-attn-c32-input-20260926`。

## 2026-09-26 11:20～12:40：单 wave C32 阶段账；输入宽读 + prefix split 进生产配方（−0.8～0.9%，待装）

`HIP/experiments/c32-wave-phase`（核内 SHADER_CYCLES，阶段变体与生产核同模块，生产核机器码逐条同；两档 177 次 VERIFY 全逐位）。wave 周期份额（两档一致）：输入 24.5%、FFN 37.7%、特征打包+QKV 11.6%、注意力+投影+写出 10.3%（loop 2 纯寄存器算术被编译器跨过计时点，只能合并看）、尾部 9.8%。按核：post 输入段 49%（折合全 C32 约 14%）、mapped 输入 35%。post 每 lane 每 tile 69×b32 + 16×u8 逐元素读 8 个连续通道（`if(valid)` + 4 字节对齐阻止合并）。
`CW_VEC_INPUT=1`：整行 b128/b64 读取，算术不变，VGPR 不变零溢出。`experiments/c32-vec-input` 三候选两档三组 200 帧 ABBA + 动态历史全逐位：宽读 −0.86/−0.82%，宽读 + `CW_PREFIX_SPLIT` −1.06/−0.94%（采用），仅 split −0.17/−0.21%。
生产：c32-wave1 配方（build-modules.ps1 + prepare_wave_owned.py）加两宏，跟 WAVE_OWNED 走、无新开关；双架构编译（gfx1201 7AC34418…、gfx1200 128BB82C…），gfx1201 模块 16 函数与实测候选逐条同；NativeGameFrame 7 用例 84 帧逐帧同；生产 host 千帧长测 900 −0.088ms（−0.81%）、1080 −0.140ms（−0.92%）。payload + install.ps1 在 `D:\DLSSNR-Lab\c32-vec-20260926`（前置哈希与剑星现装一致），**未安装未发包**。结果 `results/c32-wave-phase-20260926`。下一刀候选：finish/prefix 尾部（各自核 21～26%）。

## 2026-09-26 12:00：C32 vec-input 装进剑星

游戏关闭时执行 `D:\DLSSNR-Lab\c32-vec-20260926\install.ps1`（只替换 c32-wave1 双架构模块，WAVE_OWNED 路径内生效，add-on/flags 不变）。待用户实测（离线千帧 900 −0.81%、1080 −0.92%）。

## 2026-09-26 12:07：C32 vec-input 剑星实测

2K AA（→1080 档）：主菜单 44 / 最简场景 47（前 43～44 / 46～47，稳在上沿，与 −0.9% 吻合）。当日 2K AA 主菜单：42～43 → 44。

## 2026-09-26 12:05～12:20：C32 finish/prefix 尾部合并遍历——null

`CW_TAIL_QUAD`（`hip/wave_owned_c32.inc`，默认 0）：2×2 块一遍遍历，4 次 LDS 读同时供 main 与 down（原 64+64 次），写地址改 32 位偏移；ISA finish 2333→1777 行、64 位地址移位 18→0、零 scratch。两档各 3 组 200 帧 ABBA（对照 = 当前生产 c32-wave1 7AC34418；另设同源对照测噪声）：900/1080 均 −0.010ms（−0.10%/−0.07%），同源对照噪声带 −0.013～+0.024ms，**不采用**；动态历史 64 帧 bitdiff=0。尾部主体是写出量（每窗口 main 8KB + down 2KB，lane=通道 128B 连续已最优）。与 §7"转置尾部并宽"不同（那次改 lane 映射）。结果 `results/c32-tail-20260926`，实验 `HIP/experiments/c32-tail`。生产/游戏/发布包未改。

## 2026-09-26 17:00～18:10：3zwr1 AMDNR 0.3.3.2（c32w）实机对照——我们快约 9%

网友（Zero 转）：3z 称改了我们的代码、1080p 网络 17.8→15.3ms。静态看：OptiScaler 分支 + 我们 RE9 runtime（MIT 署名在）+ 加密 pak；c32w 为其声明的自有单 wave C32 核。runtime C API 计时对照卡在其 EnqueueHip 崩溃，改游戏内：其日志 `net=1920x1080 color_job=1705x960 c32w=on hist=on`，网络固定 1080 档、无复用。剑星 1080P 原生 AA 简单场景：3z 45～46，我们（晃动使复用失效）49～50；2K 质量主菜单 3z 40～41、我们 57。详见 `results/amdnr-0332-ingame-20260926`。

## 2026-09-26 18:30～18:45：HIP 导入的共享缓冲区永不归还——桥接层按档位池化

受 3z 更新日志启发实测：裸探针按桥接顺序导入/映射/释放 40 次，显存与私有内存各漏 ~3 GB，整套缓冲区一字节不还；真实 `D3D12Bridge` 40 会话切档旧行为约 73 MiB/次（1080 档 ≈93）。add-on（native_game_oneshot 每会话新帧）与 RE9 runtime（每会话 new D3D12Bridge）共用 `hip_d3d12_bridge.h`，一处修：进程级池（设备+字节+UAV），`Release` 归还不销毁，上限 ≈200 MiB；`DLSS5_HIP_SHARED_POOL=0` 回退。池化后第一轮三档后平台期（显存 ≈2530、私有 ≈310 MiB 不再涨）；fresh/复用输出哈希全同；NativeGameFrame 回归 112 个 f16 与此前逐字节同。add-on 5950fe20 部署包 `deployments/vram-pool-20260926`（未装）；RE9 runtime 可按 build-runtime.sh 重编。详见 `results/vram-leak-20260926`。

## 2026-09-26 19:14：显存池 add-on 装进剑星（待用户切档实测）

游戏关闭时 `D:\DLSSNR-Lab\vram-pool-20260926\install.ps1`：只换 add-on 为 5950fe20（0.31 源 + 共享缓冲区池 + PR #9 合并后的共享头），模块/flags 不变，备份 `backups\20260926-191447`。待 Zero 游戏内反复切分辨率/DLSS 档位看显存是否平台化。

## 2026-09-26 19:27：显存池剑星实测通过

同进程（pid 6804）网络会话 3→6（新增 3 次均 1080 档），性能计数器专用显存 11,203→11,240 MiB（+37，游戏自身波动），私有内存反降；修复前应漏 ≈280 MiB。池化在游戏内生效。

## 2026-09-26 19:50～20:30：RE9 runtime 可配置 + 接入 0.31 新核（A1）

TheAutomatic/ouco 反馈 RE9 包无法配置开关。以仓内 `src/LmxxfNrRuntime.cpp` 为唯一源：Create 时读一次 flags（白名单 DLSS5_HIP_*/SKIP_BLOCKS/FIT_LARGE/NETWORK_HEIGHT，环境优先），add-on 的 getenv 覆盖段原样搬进 `src/native_hip_env_options.h` 两边共用，默认值=0.31 模板，缺模块自动降级，状态行报告生效开关。兼容 RE9 包宿主：GetApi 收 ABI 1/2，ABI 2 给两参数 EnqueueHip 包装（PR #9 改三参数，老宿主会传垃圾队列指针）；shader/权重补 RE9 包目录布局。顺带修 PR #9 删 include 导致的 add-on 编译失败（`native_preblock_runtime.h` 补 `<cmath>`）；`hip-re9-flags.txt` NETWORK_HEIGHT 900→auto + 四新键。
验证（rt_bench 直调 C API）：旧/新/新关四组尺寸末帧哈希全同；ABBA 1920×1080 16.88→14.93 ms（−11.5%），1707×961 16.90→10.77 ms（900 档 + 新核）；24 次切档显存旧 +180/次、新 +35/次；runtime-smoke 过；部署脚本安装→回滚验证。部署包 `deployments/re9-runtime-flags-20260926`（AMD 同名 `\deploy`），未装、不发包。详见 `results/re9-runtime-flags-20260926`。

## 2026-09-26 21:00～21:17：可配置 RE9 runtime 装进 RE9 并实测

RE9 目录原为 0.29～0.31 同款宿主 0ef10229 + runtime 6e9974d7 + 旧 24 模块。先把 HIP 升到 0.31 RE9 包（每架构 29、SUMS 58 全核对；旧 HIP 备份 `D:\DLSSNR-Lab\re9-runtime-flags-20260926\pre-031-hip-backup`），再 `deploy\install.ps1 -GameDir <RE9>`（备份 `deploy\backups\20260926-210057`）。OptiScaler.log：`modules_ok=58 hip=1 ... wave_owned=1/1 c512_m32=1/1 vit_proj_n64=1/1 pdl=1 skip=3 | flags: ...`，老宿主两参数 EnqueueHip 兼容生效。缺陷：runtime 只在首帧打几何行，改设置后不再打印（下次补"尺寸变化即打印"）。
用户中画质 A/B（flags 三开关 1/0，同分档规则）：2K DLSS 高质量（≈1707×960→900 档）54 对 51～52；2K 原生 AA（→1080 档）38 对 36。新核约 +5%。flags 已改回 1。

## 2026-09-26 21:20～21:27：0.32 三包打完（待上传）

`Development/tools/package-032.ps1`（0.31 底包，取自 history；源码提交 e1d9bd3）：常规 add-on 5950fe20（显存池 + PR #9 共享头，剑星装机验证）；c32-wave1 宽读版双架构（剑星/RE9 装机同哈希 128bb82c/7ac34418）；RE9 runtime 2aedb521（读 flags、0.31 新核默认开、显存池、PR #9、老宿主 ABI-2 兼容，RE9 装机实测）+ 新 hip-re9-flags 模板；SOURCE-README 追加 runtime 源码提交。产物：Magpie 339,076,857 B `87eeae8e…`、OptiScaler 369,274,773 B `a26d1fab…`、REFramework 423,734,964 B `567b8ef9…`；底包逐文件、44 shader、ZIP 回读、RE9 runtime 冒烟通过。仓库 HEAD 的"env 选项搬家"版 add-on 未入包（待回归）。README 0.32 条目已写好（本地），待链接。

## 2026-09-26 21:51：0.32 发布

夸克 https://pan.quark.cn/s/b805e071405c ；镜像改用 Gofile https://gofile.io/d/CZ67LYIc （本版不是 Google Drive）。中英 README 当前版本与更新记录已填；tag 0.32 = e1d9bd3（打包源码提交）。同时剑星已整包解压 0.32 常规包做全新安装验证（备份 `D:\DLSSNR-Lab\stellar-fresh-032\backup-20260926-213704`，`install.ps1 -Restore`），待用户游戏内确认。

## 2026-09-26 21:55：0.32 常规包全新安装验证通过

剑星整包解压 0.32（DLSS5-AMD 目录全新、OptiScaler.ini 用包内模板）后用户进游戏：黄字正常、帧率与此前同；日志（全新 logs 目录，pid 29688）wave_owned/c512_m32/vit_proj_n64 均 requested=1 active=1。剑星现为 0.32 包原样安装（旧目录备份见上条）。

## 2026-09-27 03:00：fp8-sat-mode——MODE 饱和路线不逐位，med3 写法逐位 −0.3%

借鉴 mochizuki0323/DLSSNR-AMD（Vulkan）的"FP8 饱和转换用 MODE 位代替每值 clamp"。探针：gfx1201 上 MODE.FP16_OVFL（hwreg MODE bit 23）确使 `v_cvt_pk_fp8_f32` 对有限溢出饱和到 ±448，但 ±Inf/NaN 变 E4M3 NaN，且核内 f16 RNE 转换溢出改为 65504；gfx12 的 cvt 没有指令级 clamp 位。c32-wave1 入口设 OVFL + 去 clamp：指令 −8～−11%，900/1080 静态运动逐位，但 720-motion 输出变化；只设 OVFL 保留 clamp 同样变化 → 原因是 f16 溢出语义，不是去 clamp，**不采用**。改为不动 MODE、clamp 写成 `fmed3`（探针对 NaN/Inf 同字节）：指令 −2%，7 组 84 帧逐位，两批 ABBA 900 −0.037/−0.029ms、1080 −0.045/−0.035ms。宏 `HIP_FP8_SAT_MODE`（默认 0；3 = med3）在 `hip/c32_fused_ffn_attention.hip`，未改生产配方、未装游戏。详见 `results/fp8-sat-mode-20260927`。

## 2026-09-27 03:20～04:10：c64-block-fused——整块融合已有，差距在 VALU；W2_PACK8 逐位整网 −4%

对照 mochizuki0323/DLSSNR-AMD（整网 1080p Linux 6.0 / Windows 9.4 ms，其注释给出各宽度内核总时 C64/C128/C256 = 0.71/0.85/0.99 ms，我们 1.83/1.79/1.86）。**C64/C128 在 0.31 wave-owned 里本来就是一块一派发的整块融合**，C256 两派发，所以"融不融"不是差距来源。它单层快在：转置排布（[特征][token]，累加器即下一步 B 操作数，不走 LDS）、删 VALU（RDNA4 上 FP8 WMMA 与 VALU 不重叠）、同级多层持久化单派发（原子领 (layer,window)，只等 4 个生产者窗口；其实测收益主要在 C256）。

探针 `wmma_transpose_probe`：gfx12 fp8/f16 WMMA 交换参数与结果转置 2000 组 × 256 值 0 差异，转置排布逐位可行（难点在复刻 `w2_serial_norm` 等归约顺序）。

我们 `c64_wave2` 静态 ISA：WMMA 150 对 VALU ~3900；每个 E4M3 字节约 6 条 VALU（med3、只用一半的 `cvt_pk_fp8 v,x,x`、移位、and、cmp_neq+cndmask 做 ±0→+0、or）。`W2_PACK8`（`hip/wave_owned_mh.inc`，默认 0）：两值一条 cvt_pk 直写片段字，clamp 后 `+0.f` 代替 ±0 选择（NaN/Inf/下溢 -0 语义不变，放在 clamp 后避免与乘法收缩）。8 个量化点，C256 注意力体从同文件抽取一并生效。静态指令 −25%、VALU −30%，VGPR 不变；默认值 gfx1201/gfx1200 与 0.32 模块代码段相同。7 组 × 12 帧逐位；两批 ABBA 千帧 900 10.693→10.277 / 10.774→10.377，1080 14.995→14.385 / 15.032→14.426（约 −4%）。未装游戏、未发包。下一步：发包时配方加 `W2_PACK8 1`；同法推广 C32/C256 FFN/deep。结果 `results/c64-block-fused-20260927`。

## 2026-09-27 04:10～05:10：pack8——两值一条 cvt_pk 推广到 C32，全开逐位整网 −9%

把 W2_PACK8 的打包法搬到其余逐字节 E4M3 片段（`hip/build-modules.ps1` 加 `-ExtraDefines`，全套 29 模块按生产配方编，A 组与 0.32 装机代码段相同）。`CW_PACK8`（`wave_owned_c32.inc` 10 处片段）：c32-wave1 指令 −5.2%、VALU −7.4%、VGPR 略降；7 用例逐位；900 10.68→10.18、1080 14.98→14.24 ms（约 −5%）。`DF_PACK8`（deep_fast / vit-wide / c512-m32-deep 的 8 处 `pack()` 循环）：逐位但 ISA 只少 0.5～1.7%，计时不赚，默认 0 不采用。multihead_fast_padded 的两处在生产关闭分支里，撤回。全开 ALL = CW + W2（只换 c32-wave1、c64-wave2）：7 用例逐位；两批 ABBA 900 −0.94ms（−8.7%）、1080 −1.37ms（−9.1%）。生产配方未改。详见 `results/pack8-20260927`。

## 2026-09-27 04:19：pack8 候选装进剑星（待实测）

`deployments/pack8-20260927`：只换双架构 c32-wave1、c64-wave2（装前核对为 0.32 模块，payload 与离线验证候选同 hash）。备份 `D:\DLSSNR-Lab\pack8-20260927\backups\stellar-20260927-041916`，`install.ps1 -RestoreBackup` 还原。add-on/flags 未动。

## 2026-09-27 04:25～04:40：转置布局、持久化——判断为无明显收益，未实现

c64-wave2 已用交换操作数让累加器直接当下一操作数（FFN 展开、V），剩余 LDS 往返全是一 wave 一头下的跨头交换；单核 ISA WMMA 150 / VALU 2933 / ds 70，瓶颈是 VALU。持久化：C256 族 34 派发 1.86ms（1080），PDL 已使其 −0.09ms，额外只剩派发尾部空转，估 ≤0.1ms，成本数小时，暂不做。剩余 VALU 前几位 med3 336、`+0.f` 的 add 336、cvt_pk 240；后续小刀见 `results/transpose-persist-20260927`。

## 2026-09-27 04:45～05:05：W2_PACK8 2——`+0.f` 挪到 clamp 前，逐位 −0.6%

`clamp(x+0.f)` 与 `clamp(x)+0.f` 对所有输入同值，前者让乘法合成 fma。c64_wave2 单核 VALU −4.4%；对 pack8 全开 7 用例逐位，两批 900 −0.05、1080 −0.08～0.09 ms。未装游戏，下次发包配方用 `W2_PACK8 2`。见 `results/transpose-persist-20260927`。

## 2026-09-27 08:20：PACK8 模块剑星实测（1080P 窗口 + FSR 原生 AA）

剑星装 0.32 + `CW_PACK8`/`W2_PACK8 1` 的 c32-wave1、c64-wave2（`deployments/pack8-20260927`）。Zero 实测：
- AE（开机默认）：简单场景静止 57～58、运动 53～54，主菜单 52～53。
- **F8 切 EXACT：简单场景 53～54、主菜单 49～50**；0.32 基准 51～52 / 47～48，各 +2 帧（约 +4%，离线网络 −9%，网络约占整帧一半）。
- 黄字无 AE/EXACT 字样：已知，提示只挂 FPS 行（A 尾巴第 4 条）。

## 2026-09-27 09:00：0.33 打包

`Development/tools/package-033.ps1`（源码 2cb0ab90），以 0.32 三包为底：add-on b08cd2e3（黄字 AE/EXACT、F7 开关文字、共用 env 解析——HEAD add-on 首次进游戏，剑星/匹诺曹实测正常）、c32-wave1（CW_PACK8）+ c64-wave2（W2_PACK8 1）双架构；RE9 宿主与 runtime 沿用 0.32。三包逐文件校验、44 shader 变体通过；RE9 包 runtime-smoke 在打包后补跑通过（打包时 Magpie 开着被跳过，Magpie 空闲不影响）。结果 `Development/tools/release-033-results.json`。W2_PACK8 2 与 HIP_FP8_SAT_MODE 3 未进本包（未进游戏验证）。

## 2026-09-27 11:00：ACO ISA 对照（DGX Spark，无 AMD 卡）

在 `~/work/aco-isa/` 编 Mesa 26.2.3（仅 RADV，本地 libdrm 2.4.133，drm-shim），`LD_PRELOAD=libamdgpu_noop_drm_shim.so AMDGPU_GPU_ID=gfx1201` 得假 RX 9070 XT（coopmat + float8 齐）；源码编 glslang 16.5.0，出 mochizuki 46 条管线 SPIR-V，自写 `dump_isa` 经 pipeline_executable_properties 取 ACO 统计与汇编。对照 0.33 的 c32-wave1/c64-wave2 `.hsaco.s`。
- ACO fswin 全展开；我们 `c64_wave2_bi_bo` 有循环，按 ISA 追出的次数加权后每窗口：WMMA 456 对 ACO 416（对得上），VALU+VOPD ~7490 对 ~2199（约 3.4 倍）——C64 族 1.83 对 0.71ms 的主因。
- 我们每个 FP8 字节约 4.5 条（cvt_f32_f16 → `max x,x,x` 规范化 → med3 → +0 → 半条 cvt_pk）。ACO 用 MODE.FP16_OVFL **分段开关**（fswin64 里 5 次 s_setreg：FP8 段置 1 无 clamp，f16 收窄段前置 0）；我们 fp8-sat-mode 否决的是入口一次性设置，分段版未测。
- 其他：ACO 用 `v_cvt_pk_f32_fp8` 成对解包、`v_pk_*_f16`、`v_fma_mix_f32`；VOPD 占比 20% 对我们 15%。
候选与估算见 `results/aco-isa-20260927/README.md`、WorkingPlan 7c。未测时（假设备不执行），未动 9070。

## 2026-09-27 09:30～11:10：鬼武者 0.33 RE9 包"不生效"——换队列后任务永远不退役

诊断（9070 上 ssh + 交互计划任务起 Xbox 版、SendInput 扫描码操作；`results/onimusha-presr-20260927`）：链路本身通（FFX 输入 → NGX → lmxxf 切分 + HIP，逐帧 betweenHits/enqueueCalls 递增），`DebugView=4` 紫色在**游戏内**可见、F6 可切；**标题/主菜单背景不经超分输入，看不出效果**。Zero 那局 09:24:01 游戏重建交换链（显示/帧生成设置）后状态卡死在 `prior job not yet submitted`：任务已入队 HIP，但游戏改在另一个队列执行我们的切分列表，`Submitted()` 只认构造时的队列，任务永不退役。修：切分槽记下实际执行队列、`Submitted` 在该队列退役并触发会话在新队列重建；另加 8 次评估看门狗。宿主 aa3761f2 装在鬼武者（0.33 dxgi 留存），8 次帧生成切换 + 窗口→无边框均正常；换队列没再出现，重建路径未实测。配方 `Development/RE9/presr/host-queue-follow.py`（prepare-host 调用，输出与实测源码逐字节同）。未发包。

## 2026-09-27 11:20～12:40：fmed3 夹值（逐位，约 −0.5%）进下版配方；分段 FP16_OVFL 暂缓

ACO 对照（`results/aco-isa-20260927`）指向 E4M3 转换前的 `v_max_num x,x` 规范化：`fminf/fmaxf` 形成的 med3 前面都有一条。W2_PACK8 3 单独改 w2_z 编出来与 2 相同——规范化来自 multihead_fast_padded 的共用 `clampf/F()/q8_fused_round`。新宏 `HIP_FMED3_CLAMP`（`__builtin_amdgcn_fmed3f`，NaN 同样得 lo）：c64-wave2 规范化 1826→84，7 用例全同，比 Z（CW_PACK8+W2_PACK8 2）900 −0.03/−0.05、1080 −0.07/−0.08 ms。配方写进 `hip/build-modules.ps1`（c32-wave1 加 SAT3，c64-wave2 加 W2_PACK8 3+FMED3，c512-m32-mh、mh-fast-padded-wave(-packed) 加 FMED3），默认编译与实验集 M 逐模块代码相同，3 个旧后备顺带从源码重编。分段 FP16_OVFL（W2_PACK8 4，每片段 4 次转换前后 s_setreg）再 −0.5% 且语料逐位，但 ±Inf/NaN 输入会变 E4M3 NaN 字节（0.10 黑块保护失效的方向），暂不采用。`results/fmed3-ovfl-20260927`。

## 2026-09-27 12:39：fmed3 配方（M）剑星实测

剑星整套 29 模块换成 M（`deployments/fmed3-20260927`）。Zero：1080P 窗口 + FSR 原生 AA（EXACT）主菜单 **50～51**、简单场景 **54～55**；0.33 为 49～50 / 53～54，各 +1 帧（离线 −0.5%，读数接近分辨率下限，结论＝方向一致、无回退）。

## 2026-09-27 13:20：ACO 后续——OVFL census、成对解包、DF_PACK8（`results/ovfl-census-20260927`）

- 分段 FP16_OVFL：探针 W2_PACK8 5（非有限或 |x|>T 改写成 123）对 M 逐位——非有限、|x|>448 两档 7 用例全同，T=1 阳性对照立刻不同：语料里 C64～C256 打包输入全部有限且在 ±448 内（clamp 从未起作用，距 f16 溢出 ≥146 倍）。理论：输入均为有限 E4M3/f16 操作数的 f32 累加、RTZ f16、守护 rsq、Σexp≥1；唯一 Inf 来源是链头 RNE f16 溢出，未观测到。P（= M + W2_PACK8 4，与 O 代码段 29/29 同）两批 ABBA：900 −0.051/−0.048、1080 −0.086/−0.088 ms。只换 c64-wave2 装剑星（备份 `D:\DLSSNR-Lab\ovfl-20260927\backups\stellar-20260927-131752`），未进配方。
- `v_cvt_pk_f32_fp8` 在 gfx1201 返回 (byte0,byte0)/(byte2,byte2)（asm 与 builtin 同），成对解包不可用；ACO 在 fswin64 用了 64 次，值得告诉 mochizuki。
- v_pk_f16：站点是 Hrtz（RTZ）往返，pk f16 按 MODE 取 RNE，不做。DF_PACK8：多数站点在生产不走的分支，活的 `vit_project_frag_n64` 访存受限（VMEM 164 / WMMA 64）。
- `hip/build-modules.ps1`：-ExtraDefines 同名宏覆盖配方值（默认编译不变）。

## 2026-09-27 13:40～15:20：C64 融合核手改汇编（`results/c64-hand-asm-20260927`）

新工具 `experiments/c64-hand-asm/asm_compile.cpp`：COMGR 汇编 `.hsaco.s` → 可加载模块；P 配方 c64-wave2 原样往返逐位（仅 16 位字面量高半与 gfx10+ 忽略的 SGPR 粒度字段不同）。手改 c64_wave2_bi_bo 的 FFN 隐层循环：`x*poly` + `+0` 合成 `v_dual_fmaak_f32 …,0`、删死的 `v_mov v38/v39,0`（探针：fp8 WMMA 从不输出 −0），每窗口 −192 VALU、逐位，但 ABBA 噪声内。关键发现：**激活多项式在 g=−4 恰为 +0，x≤−4 全是 −0，`+0` 是必要的**；LLVM 不收缩 `mul+add0`。回推源码 `W2_PACK8 6`（`W2_Q8_SETF` = `fmaf(x,y,0)`，四个乘积打包站点）：12 个 wave2 变体各 −165～195 条、逐位，两批 ABBA 900 −0.013/−0.028、1080 −0.015/−0.025 ms（约 −0.2%）；默认配方代码不变。未装游戏、未进配方（剑星 P 待实测，通过后用 6 代替 4）。

## 2026-09-27 14:08：分段 FP16_OVFL（P）剑星实测通过，配方改 W2_PACK8 6

剑星装 P（c64-wave2 = W2_PACK8 4，`deployments/ovfl-20260927`）。Zero：画面无变化（运动无黑块/闪烁），1080P AA 中画质 EXACT 简单场景 54～55，与 M 同（0.5% 在读数分辨率下）。`hip/build-modules.ps1` c64-wave2 配方 W2_PACK8 3→6（= 4 + W2_Q8_SETF fma，`results/c64-hand-asm-20260927` 7 用例逐位）；6 本身未进游戏，下次发包前按惯例双架构重编 + 7 用例回归 + 装剑星确认。

## 2026-09-27 14:25：鬼武者（Xbox）RE9 前置路线可玩

鬼武者装 0.33 RE9 包 + 换队列宿主 aa3761f2 + 剑星同款模块（M + P c64-wave2，备份 `D:\DLSSNR-Lab\ovfl-20260927\backups\onimusha-20260927-140953`）。Zero：中画质 2K 质量（约 900 档）基本稳定 60 帧（疑似上限），体验舒适。RE9 前置路线首次在 RE9 以外的 RE 引擎游戏上可玩；换队列修复的"新队列重建会话"路径仍未实测触发。


## 2026-09-27（14:48 派工后）：闇交付 PDL 审计与 RE9 runtime 尾巴

派工单 `conversation/20260927/yami-dlss5-tasks-20260927.md`。PDL 原实现找到确定边界反例：uint32 累计目标回绕，旧计数直接满足新目标；host 在即将溢出时同步旧用户、清零该槽、等待清零，保留正常帧并发。上限降至 64 的隔离压力构建：900/1080 历史序列实际重置 70/64 次，各 12 帧逐位。当前 pool 的 32 引用覆盖最长 8 块链；消费者无 agent acquire、任意序自旋进展及同槽代际覆盖仍缺完整保证，不能宣布 PDL=1 已证明安全。PDL=0 完整 NativeGameFrame 7 用例 84 帧逐位；两批千帧 ABBA（固定 re9-runtime-flags 的旧模块集）900 代价 +0.056/+0.066ms，1080 +0.079/+0.079ms。默认未改、hip/ 未改。证据与官方文档依据 `results/pdl-audit-20260927`。

RE9 残余显存：`NativeTrackedResources` 对大 RGB 输入缓冲 AddRef 后永不解绑，另有 PDL 4 MiB 旗子未释放；修拥有者析构解绑、旗子释放和 pdl_keep 析构顺序。原版 24 次切档最后 3005 MiB，修后同阶段 2296；最终候选跑 120 阶段，最后 18 次 1080/720/900 分别固定 2475/2467/2443 MiB，稳态 +0 MiB/次。每阶段末帧 hash 全同；共享信号量 100 次与未执行模块加载/卸载 50 次均无显存增长，stream 复用探针无改善不采用；桥接独立重建也呈渐进平台，未强行命名驱动内部缓存。几何变化现在写独立 logs/native-re9-runtime.txt + 调试输出 + 成功通知，四组 requested/active 与 flags 路径齐；120 阶段恰好 120 行。强制 900/1080 的 24 帧 hash 与旧版同，runtime-smoke 通过。presr runtime 构建改走仓内 canonical 源。DLL ca6d6bdc 在 `D:\DLSSNR-Lab\re9-runtime-leak-20260927\LmxxfNrRuntime.dll`，未装游戏、未发包。结果 `results/re9-runtime-leak-20260927`；下次合包时取候选/从本提交重编并做整包冒烟。

## 2026-09-27 16:16：HEAD add-on 86ef4182 + c64-wave2（W2_PACK8 6）剑星实测

剑星换 add-on 86ef4182（HEAD b112239：含闇的 PDL 回绕修复与析构释放）+ 按配方编的 c64-wave2（W2_PACK8 6，gfx1201 c6a462d0 / gfx1200 17807f69），PDL=1；备份 `D:\DLSSNR-Lab\build-0927\backup-stellar-20260927-154942`。Zero：1080P 中画质原生 AA，EXACT 普通场景 54、主菜单 50～51；AE 普通场景 58、主菜单 53～54。与 P 同，无回退——W2_PACK8 6 与 HEAD add-on 游戏内验收通过。

## 2026-09-27 16:25：RE9 装 0.34 候选（宿主 aa3761f2 + runtime ca6d6bdc + 剑星同款模块）

备份 `D:\DLSSNR-Lab\build-0927\backup-re9-20260927-161816`。Zero（中画质）：2K 高质量 **58**、2K 原生 AA **41**（此前 0.31 模块 + 0.32 runtime 为 54 / 38）。日志：`net=1600x900 color_job=1712x960 modules_ok=58 wave_owned=1/1 c512_m32=1/1`。F8 无反应属预期（RE9 runtime 无自适应复用，模板 VIT_ADAPTIVE=0）。未在同一局内切档，几何日志随切档打印与切档 0 MiB 尚未游戏内验证。

## 2026-09-27 16:34：0.34 打包

`tools/package-034.ps1`（源码 9bd416fa），以 0.33 三包为底：add-on 86ef4182、58 模块（生产配方，取自剑星实装）、RE9 宿主 aa3761f2 + runtime ca6d6bdc + 重新生成的 re9-presr-source.tar.gz（含换队列修复 g_requeue）。三包逐文件校验、44 shader 变体通过；RE9 runtime-smoke 在打包时跑通，几何行 `net=1600x900 color_job=1506x848 … pdl=1/1 … applied=15`。结果 `tools/release-034-results.json`。


## 2026-09-27 17:34：C32 ACO 分段账 + 去重复量化/RTZ 向量暂存，组合逐位约 −1.4%

按 `conversation/20260927/yami-c32-aco-audit.md`，以 0.34 实装模块为基线。加入 debug 行号的汇编与生产 `.text/.rodata/.note` 完全一致，按 ISA 真实回边与源码归属分段；特别是尾部源码64次已展开成32轮，不能照源码数数。chain 每窗口 VALU+VOPD 5079，对 ACO fswin32 2061；我们 WMMA336 对256，80条差额来自三段对角残差48、Q/K固定half归约16、softmax固定归约16。激活、归一化、投影量化是向量指令大头；ACO 的不同数学路线和窗口展开供数也占差额。

3个源码候选（默认0）各过双架构编译、7用例84帧逐位、两档两批1000帧ABBA：B `CW_FMED3_CLAMP` 接近噪声留关；C `CW_DIRECT_OUT` 去掉 `F()` 后又 PACK8 的重复往返、保留精确负零归一化，900 −0.073/−0.086、1080 −0.117/−0.109ms；D `CW_RTZ_PAIR` 用现有 RTZ 转换的两个输入，保留half位模式、16B读写LDS，900 −0.110/−0.093、1080 −0.153/−0.139ms。标量探针：65536个half编码C零差异，1048576对输入D零差异；没有使用已否定的packed-half算术或MODE路线。

E=C+D 另过7用例逐位，ABBA 900 9.611→9.484 / 9.701→9.564，1080 13.344→13.157 / 13.372→13.179ms，约 −1.3～−1.4%，不相加。两宏已进 `hip/build-modules.ps1`，配方双架构重编与E代码段全同。17:34 仅换剑星 c32-wave1 两份（gfx1201 05359b6a / gfx1200 2d345933），add-on/dxgi/INI/flags 前后哈希不变；备份 `D:\DLSSNR-Lab\c32-aco-20260927\backups\stellar-20260927-173404`，安装/还原脚本同目录。游戏画面/FPS 等 Zero，未发包。结果 `results/c32-aco-20260927`、部署 `deployments/c32-aco-20260927`。

## 2026-09-27 18:22：C32 ACO 候选（闇，CW_DIRECT_OUT + CW_RTZ_PAIR）剑星实测

剑星 c32-wave1 换闇的组合（gfx1201 05359b6a / gfx1200 2d345933，`results/c32-aco-20260927`）。Zero：1080P 原生 AA，AE 普通场景 59；**EXACT 普通场景 55～56**（上轮 54）。与离线 −1.3～1.4% 同向，无回退。


## 2026-09-27 19:20：C32 第二轮，固定段 MODE + prefix 尾部，逐位再 −1.8～−2.0%

按第二份任务单，先修正旧账：chain projection 从旧876已降至448；真实10次派发按窗口数加权，prefix29.42%、post26.08%、chain20.86%、mapped11.03%、finish_dcrop6.59%、finish6.03%（指令工作量，非时间）。69的down=null不计死下采样代码。尾部SALU/WAIT高来自重复地址/裁切/循环，裁切本就wave-uniform；prefix完整窗口可直接删恒真判断，WAIT多为s_wait_alu/s_delay_alu，不等于同量级访存停顿。

真device计数census（6核×7打包点×7用例）0非有限/0超过448，最大388.088，统计版RGB逐帧同。第一版MODE intrinsic虽逐位且提速，ISA却有38个空段（开/关相邻，转换被移走），拒绝并删除该源码路径。修为HIP源内固定短段：开MODE、4次双值FP8转换、关MODE；双架构审计无f16收窄混入。65536half编码探针有限值0差异、MODE恢复0错误、后续RNE溢出仍Inf；非有限2048码不同是已知范围边界。多项式FMA的2097153点网格CPU初筛有3/66/68个FP8反例，不采用。

正式M（MODE）900 −0.145/−0.132、1080 −0.207/−0.198ms；C（prefix去重复量化）−0.030/−0.033、−0.027/−0.026；D（prefix完整窗口）−0.020/−0.008、−0.019/−0.023。组合E各过7用例84帧逐位，ABBA900 9.475→9.308 / 9.581→9.396，1080 13.169→12.917 / 13.185→12.920ms，净 −1.77～−2.01%。配方加入CW_PACK_MODE_MASK=127、CW_PREFIX_DIRECT_OUT=1、CW_PREFIX_FULL_TILE=1；默认关的代码等于基线，生产复编等于实测E。只换剑星两份C32（gfx1201 ae95bdf6 / gfx1200 e85c68c0），其它文件哈希不变，备份 `D:\DLSSNR-Lab\c32-round2-20260927\backups\stellar-20260927-192033`。游戏验收待Zero，未发包。完整账、范围计数、原始日志与复现脚本 `results/c32-round2-20260927`，部署 `deployments/c32-round2-20260927`。

## 2026-09-27 19:36：C32 第二刀（闇，固定段 MODE + prefix 去重复量化 + prefix 完整窗口）剑星实测

剑星装闇的组合（`results/c32-round2-20260927`，备份 `D:\DLSSNR-Lab\c32-round2-20260927\backups\stellar-20260927-192033`）。Zero：1080P 原生 AA，**EXACT 普通场景 56～57**（上轮 55～56），画质与之前相同。离线 900 ≈9.31～9.40、1080 ≈12.92 ms。


## 2026-09-27 20:06：第三轮，finish内部窗口快路径装剑星；ViT字节AV与复用兼容原型

闇按第三份任务单交付。post单独分段账4909条普通向量：输入772、激活1280、RGB头502；RGB的LDS已自动向量化，手写成组读取P在1080 +0.023～0.034ms，输出整窗判断Q仅−0.005ms，均不采用。finish/finish_dcrop按wave共用窗口坐标分内部/边缘两路，内部免逐像素裁切，DownCrop偶数shift守住4×4下采样语义；prefix排除。F内部finish_dcrop SALU2082→764、WAIT2634→1551，VGPR169/LDS4096/scratch0不变。三候选各7组84帧逐位；F两批ABBA900 −0.0209/−0.0231、1080 −0.0339/−0.0352ms（−0.22～−0.27%）。仅CW_FINISH_FULL_TILE=1进配方，默认关代码与round2相同、生产复编与实测F相同。20:06装剑星两份c32-wave1（gfx1201 1753400c / gfx1200 834c7095），备份 `D:\DLSSNR-Lab\c32-round3-20260927\backups\stellar-20260927-200610`；其它受保护文件哈希不变，等Zero验画面，未发包。源码已随共享目录b9bdda5提交，本轮补配方、验证与部署记录。详见 `results/c32-round3-20260927`。

ViT/C512重新导出十条ACO管线，按tile/循环量对齐。C512主投影与QKV已是字节输入，mix仍f32→half，下一步供数/精确half接口比普遍砍VALU更合适。ViT最小原型只让attention直接写FP8 AV，n64 projection一次读8字节，保留全部f32组边界/复用缓存与原数学顺序。同256WMMA：普通向量3128→764、VMEM452→388、请求读取132.5→84.5KiB/wave、VGPR160→120。双架构编译；EXACT/AE各7组84候选帧逐位，AE日志43命中+41刷新、决策逐行相同。EXACT两批900 −0.0424/−0.0458、1080 −0.0542/−0.0443ms（−0.34～−0.48%）。内部字节流与复用结构兼容，无须先压缩缓存；原型仍是成对模块的实验ABI，下一步明确byte kernel与host匹配，不直接解除旧完整byte_stream互斥。按任务允许的“账+可行性+最小原型”交付，ViT未装游戏，未与F叠加测速。详见 `results/vit-c512-aco-20260927`。

## 2026-09-27 20:12：C32 第三刀（闇，finish 内部窗口快路径）剑星实测

剑星装闇第三刀（`results/c32-round3-20260927`，备份 `D:\DLSSNR-Lab\c32-round3-20260927\backups\stellar-20260927-200610`）。Zero：1080P 原生 AA，EXACT 普通场景 **56～57**，与第二刀同（离线 −0.25%，在读数分辨率下），无回退。


## 2026-09-27 21:02：第四轮，ViT显式字节/half接口装剑星；C512 half出口无收益

闇按eda801c任务单交付。新增独立vit-stream模块，源码HIP_VIT_STREAM_KERNELS默认0、配方1；公共DLSS5_HIP_VIT_STREAM mask（1=AV FP8、2=contract F16、3=组合），host具名kernel配对，保持n64/fragment与f32 AE缓存。contract的FP8格点精确存half，QKV直接读half、投影残差同步改half；无新增重排kernel，无数学/求和/舍入顺序变化。V1/V2独立EXACT、AE各7组逐位；组合V3另对旧host+当前实装，900两批+0.0015/+0.0056ms基本持平，1080 12.9144→12.7360 / 12.9244→12.7657ms（−1.38%/−1.23%，标准1080整网过0.5%门槛）。AE运动千帧两批900 −0.0336/+0.0075、1080 −0.0396/−0.0426ms。QKV half自动展开8倍导致VGPR59→96，V4强制2倍降48、逐位，但1080少赚0.02ms，只略改善900，不采用。

四个ViT候选共672候选帧全逐位（连基线1344hash）；每个AE43复用+41刷新，336组决策逐字段同。QKV普通向量1338→350、VMEM287→223、WMMA130相同；组合投影3128→779、452→388、WMMA256相同，请求读取132.5→82.5KiB/wave。其它f32边按流量列账，优先做了AV、contract→QKV/残差两条；不把请求字节比例当DRAM利用率或整网收益。RE9共享解析、requested/active日志与flags模板同步；mask0/3的12帧hash同、齐模块/缺模块smoke通过（缺模块3/0）。双架构复编与实测V3代码相同，gfx1200仅编译。

C512主mix分段账：K512循环1120普通向量/256VMEM/256WMMA，尾部701向量/64VMEM；尝试mix→FFN half出口，原F(Hrtz)值精确保存，mixed读写减半但主mix128KiB读取不变。EXACT/AE各7组逐位，900两批+0.0145/+0.0083、1080+0.0021/+0.0055ms，明确不采用。结果不支持mixed临时张量为主要瓶颈；下一步应查packed输入/残差生产者或另做尾部敏感性/census，未使用MODE，也不强称纯DRAM或纯VALU受限。

21:02仅装剑星新add-on4151123e、vit-stream gfx1201 ad59f7be / gfx1200 0c9171ee、flags stream=3，旧模块保留（含第三刀C32），新建全套HIP校验清单。备份 `D:\DLSSNR-Lab\vit-bytestream-20260927\backups\stellar-20260927-210229`；dxgi/INI/C32哈希不变。C512候选和RE9 DLL未装游戏，未发包，画面/FPS待Zero。完整报告 `results/vit-bytestream-20260927`、`results/c512-mix-20260927`，部署 `deployments/vit-bytestream-20260927`。

## 2026-09-27 21:17：ViT 字节流（闇，DLSS5_HIP_VIT_STREAM=3）剑星实测

剑星装新 add-on + 两份 vit-stream 模块（`results/vit-bytestream-20260927`，备份 `D:\DLSSNR-Lab\vit-bytestream-20260927\backups\stellar-20260927-210229`）。Zero：1080P 原生 AA，EXACT 普通场景 56～57，**看黄字小数通常 56.7 左右，比上轮高约 0.3**——与离线 1080 −1.3%、网络约占整帧一半吻合。此后读数改看小数。

## 2026-09-27 21:26：0.35 打包 + RE9 实测

`tools/package-035.ps1`（源码 ec96774d），以 0.34 为底：add-on 4151123e、60 模块（每架构 30，新增 vit-stream）、RE9 runtime 432d8ccf（宿主 aa3761f2 不变）、模板加 `DLSS5_HIP_VIT_STREAM=3`。三包校验与 44 变体通过；RE9 冒烟因游戏运行被跳过，待补。RE9 装同款（备份 `D:\DLSSNR-Lab\release-035\backup-re9-20260927-212302`），Zero 中画质：2K 原生 AA **42**（41）、2K 高质量 **58～59**（58），同一测试画面。
- 21:38 补跑 0.35 RE9 包冒烟通过：`vit_stream=3/3 … pdl=1/1 … applied=16`，`lmxxf_nr_gpu: ok`。发布：夸克 https://pan.quark.cn/s/83e6172e6c79 + Gofile https://gofile.io/d/NnF4GitT，tag 0.35 = ec96774d。


## 2026-09-27 23:06：第五刀，C64/C128字节输入+RTZ配对+直接坐标，两档整网−0.7～−0.8%

闇按4937bac任务单完成。先实测0.35每帧214次派发，c64-wave2实际14导出（12整块+2 C256 attention）只有8核调用，四个C256整块均0次；C256 FFN/QKV在另一模块。汇编CFG自然循环加权、按实际window×wave数记账，WMMA独立公式校核456/744/1320（整块每wave）及232（C256 attention），互斥post/边缘分支按计算上界、PDL轮询只计一次，不当作实际等待周期。C64/C128 bi_bo合计约60%模块普通向量工作；激活/score/softmax/归一化仍最大，不改其数学。

B去FP8输入往返并合宽读取（保留0x7f→0xff规范化，256编码探针）；R用pkrtz双不同输入并促进残差宽读取（LDS本来就是FP8宽存，不搬C32 half布局）；C消除二维坐标扁平化后再除/取余，五几何三族四shift的2256192坐标全部相同。T完整窗口免逐像素判断、D C256直接feature虽逐位但无稳定收益，不采用。B/R/C组合E两批900 9.2865→9.2172 / 9.3504→9.2834ms（−0.75%/−0.72%）；1080 12.7133→12.6064 / 12.7195→12.6201（−0.84%/−0.78%），两档过0.5%门槛。六个主线候选共1008候选帧逐位（连基线2016hash），各AE43复用+41刷新且决策同。默认关与0.35、生产复编与实测E的代码段双架构全同。旧W2 intrinsic MODE有24个空段/整块核，记录并保持既有路径；没有扩新MODE段，各候选没有f16收窄混入MODE。

900专项用稀疏前缀16轮localABBA出族时间：900/1080 C32 2.606/3.743、C64 1.007/1.405、C128 0.995/1.386、C256 1.159/1.595、C512 1.719/1.960、ViT 1.250/1.703ms；C512份额19.5%/16.4%明显偏900。13块C512的900 token次26432、1080 33280，比例0.794高于像素比0.694，固定92次派发也更显眼。试现场检测全零padding的mix省算P，另试readfirstlane标量化U；两者都检查所有输入±0及实际half权重有限，不删attention token，不引入MODE。EXACT/AE各7组逐位，但900 P +0.214/+0.161ms、U +0.172/+0.158ms，关闭；现场扫描/归约不划算，未将其合配方。R则在900独立−0.048/−0.072ms，是本轮真实偏900的收获。

23:06装剑星仅两份c64-wave2（gfx1201 f60eaee8 / gfx1200 9a0fda18）与对应HIP校验项；add-on/dxgi/INI/flags前后哈希同，无运行开关/host/RE9 ABI改动，未发包。备份 `D:\DLSSNR-Lab\mh-round1-20260927\backups\stellar-20260927-230633`。画面/FPS待Zero，gfx1200仅编译。报告 `results/mh-round1-20260927`、`results/tier900-20260927`，部署 `deployments/mh-round1-20260927`。

## 2026-09-27 23:26：C64～C256 深挖（闇第五刀）剑星实测

剑星换两份 c64-wave2（`results/mh-round1-20260927`，备份 `D:\DLSSNR-Lab\mh-round1-20260927\backups\stellar-20260927-230633`）。Zero：1080P 原生 AA，EXACT 黄字 **57.1**（0.35 约 56.7）。离线 900 −0.72～0.75%、1080 −0.78～0.84%，同向。


## 2026-09-27：第六轮C512完成900资源账与四候选编译，GPU实测被游戏占用中断

按d1a255e任务单，以第五刀剑星实装为基线。实际派发与HIP occupancy API：设备32 MP/WGP，C512 900的1792/2240 token对应28/35窗口（此前104/135窗口不能用于本族），mix448/560组×1wave，QKV1344/1680组×1wave。mix VGPR96/LDS0/API64组每MP，总wave仅全卡容量22～27%；QKV VGPR155/LDS5456/API12组每MP，约3.5～4.4轮驻留容量。六核三批重复派发边际账900：mix0.231、FFN0.222、FFN投影0.185、QKV0.478、attention0.168、attention投影0.236ms；75次原始FP32检查逐位，不把边际成本相加成精确整帧归因。

准备R（mix RTZ与FP8配对，普通向量1871→1657，WMMA256不变）、Q（QKV去q8(F)往返，1117→939）、N（mix每wave输出32通道，组数翻倍，VGPR62；原K顺序，重复A读取增加）、L（QKV raw和输出LDS分时复用，5456→4420B，VGPR155/private0）。四候选双架构编译；默认关闭Z四模块与现场基线代码/metadata全同。ACO实际manifest为ffwd_wgw4、FM2阈值2560、投影tile32×128；它不是一味增加组数，融合/复用与数学差异需分开。

1080账本中途《33号远征》SandFall-WinGDK-Shipping启动，基线12.5→21ms。停本实验ledger，未动游戏；受污染1080结果单独留档不采用。空闲检查扩到Shipping进程，ledger每槽也检查，等待Zero关游戏后resume.ps1重跑。候选尚未GPU逐位/ABBA、未进配方、未装机、未发布。结果及续跑入口 `results/c512-round1-20260927`、`HIP/experiments/c512-round1`。剑星900测法：1600×900窗口+FSR原生AA，或2K质量1707×961→auto900；F8 EXACT，避开60上限。


## 2026-09-28：第六轮C512完成，四个候选全逐位、无稳定≥0.5%收益，不采用

00:03确认游戏关闭后，复用已过正确性、重跑中断计时，四候选两档两批ABBA与辅助账全部完成。此前33号远征污染1080、鬼武者中断R-r1两批隔离，不进结论；未确认是谁启动游戏。空闲检查覆盖Shipping/RE9/鬼武者，账本每槽也检查。

实际驱动32 MP/WGP。900/1080六主核每帧13次的重复派发边际时间（ms）：mix0.231/0.287、split FFN0.222/0.278、FFN投影0.185/0.202、QKV0.478/0.407、attention0.168/0.217、attention投影0.236/0.306；shift0.108/0.144，进入C512的pool/project一次0.011/0.025。主账各75次、辅助账各35次原始FP32全幅逐位。边际成本不直接相加为精确整帧分解；额外head pool在900的负增量属噪声，不是负耗时。逐核grid/资源/API容量完整报告见下。

R（mix RTZ+FP8配对）：普通向量1871→1657，VMEM/WMMA不变，VGPR96→97触发API驻留64→56组/MP；900两批−0.0701/−0.0197ms（−0.76%/−0.21%），1080−0.0086/−0.0100ms。Q（QKV去q8(F)往返）：1117→939、资源不变；900+0.0062/−0.0068，1080−0.0083/−0.0144ms。N（mix输出通道64→32，grid翻倍、K顺序不变）：VGPR62，但等工作量普通向量3018>1871、VMEM448>320；900+0.0230/−0.0015，1080+0.0363/+0.0458ms。L（QKV raw与byte输出复用LDS，先缓存系数）：初版别名引起DS重读，测试前修正为mode2；最终VGPR155→151、LDS5456→4420、API驻留12→14，DS174→148；900−0.0105/−0.0079、1080−0.0132/+0.0198ms。四候选均不合生产；R两批合计约0.48%，重复性不够，不能选首批过线。

四个候选双架构编译，gfx1201每候选EXACT/AE各7×12帧：672候选帧全部逐位（连基线1344hash）；每个AE43复用+41刷新，336组决策逐字段相同。计时1000帧/槽弃前200、只读首尾，未冒称全部计时帧逐位。默认关Z四模块对现场基线代码/metadata相同。没有split-K、MODE、数学重排、新运行开关或RE9改动。没有生产候选，所以没有合配方后的新帧时或新备份；只改实验与记录。剑星两架构c512-m32-deep/c512-m32-mh/c64-wave2哈希与启动快照均相同，保留第五刀，未装机/未发布。

结论：mix多拆组的供数/指令代价未被并行度抵消；Q删量化VALU没有稳定收益；L真实提升驻留仍只约0.1%。900 QKV倒挂尚未闭环，不据此声称纯DRAM带宽受限或C512已到极限。后续需换主循环供数/packed生产者/归一化调度切口，不重复已测形态。ACO实际manifest ffwd_wgw4、FM2阈值2560、投影32×128，强调复用/融合，不是单纯增组；其有效tile域和数学路线不同。完整结果 `results/c512-round1-20260927`，复现 `HIP/experiments/c512-round1`。

剑星900实测设置：1600×900窗口+FSR原生AA，NETWORK_HEIGHT=auto（或900），F8 EXACT；平常2K质量1707×961在auto下同样900。保持同中画质同机位、读黄字小数，避开60上限。本轮没改游戏设置。

## 2026-09-28 06:56：光与影：33 号远征队（Xbox，UE5）可玩

9070 装 0.35 常规包 + 剑星同款 c64-wave2（exe 在 `Content\Sandfall\Binaries\WinGDK`，游戏自带 FSR dll，常规包 EnableFfxInputs=false 默认已处理；备份 `D:\DLSSNR-Lab\e33-fresh-035\backup-20260927-233842`）。Zero：没问题，能玩。C512 第一轮（闇，`results/c512-round1-20260927`）无稳定过门槛候选、未合入：工作组翻倍变慢——C512 瓶颈不是并行度不足。

## 2026-09-28 07:05：帧时间分布日志 DLSS5_FRAME_STATS（分身）

`src/native_frame_stats.h` + add-on（pre-upscale 每次超分记一帧，原因 run/bypass/init/error/unsupported/idle）+ RE9 runtime（EnqueueHip 记 run/error）；共用解析 `NativeFrameStatsSeconds`，三模板加 `DLSS5_FRAME_STATS=0`，CONFIGURATION.md 一行。关时每帧一次比较；开时每帧一次 QPC + 固定 0.25 ms 直方图，窗口末写一行。rt_bench 1080 600 帧 ABBA：开/关/0.35 runtime 差在噪声内（12.59～12.73 ms），hash 全同。剑星换 add-on c38bcdd4 + `DLSS5_FRAME_STATS=5`（备份 `D:\DLSSNR-Lab\frame-stats-20260928\backups\stellar-20260928-070548`）。结果 `results/frame-stats-20260928`。

## 2026-09-28 07:16：帧时间日志首次实测（剑星 1080P 原生 AA）

add-on c38bcdd4 + `DLSS5_FRAME_STATS=5`（`results/frame-stats-20260928`）。
- 跑图（EXACT）：平均 17.9ms（55.8fps）、p50 18.0；多数 5 秒窗口 p99/max 28～32ms（约 1% 帧接近两帧时长），1% low 31～35fps；少数窗口干净（p99 19）。
- **站立不动（EXACT）**：平均 17.9ms、p50 18.0、**p99 18.5、max 18.5**，1% low 54.1fps；两分钟内仅 2 帧约 30ms。AE 静止复用时 16.66ms（贴 60）。
- 两种情况 NR 都是每帧执行（run=frames，bypass/error=0）。结论：跑图时的 1% 顿挫来自游戏跑动（流式加载等），不是网络；我们的帧时间抖动在 ±0.5ms 内。进图前 20 秒的秒级停顿是加载。


## 2026-09-28：mochizuki 0.0.2.2对照完成，九组逐位实验无达标组合

按 `conversation/20260928/yami-mochizuki-022.md`，基线7fcad1e/剑星第五刀内核；src留给帧时间日志，未修改。对照上游4f62a8a→228d3a6：NR_Q32_DIRECT/NR_Q32_STAGE部分确实删除真实half舍入，不只是冗余表示转换；Windows与Linux输出48.6dB是上游自己的说明，17%是离线整包差额，不能整项移植。标量反例x=1.062500119（0x3f880001），直接FP8=0x39，经half→1.0625再FP8=0x38；63488有限half编码验证往返恒等。quad打包/V转置等在我们对应路径已做；ViT packed-half分母树不同，不改原WMMA归约；持久化上下采样不重做已关路线。

30生产模块gfx1201复编对现场代码/metadata全同。按.amdhsa_kernel元数据普查990导出（初期把90个编译标记/元数据标签也算入，已纠正）；900/1080联合活跃40核、每帧214派发。全网静态转换站点按实际wave加权，已可证明I/P删除占约2.81%/2.88%；不是运行时指令百分比。经LDS的C32 residual已有RTZ half位模式存储，C512/ViT QKV raw是f32，attention half来自exp位图，不能盲删。

I去C32 mapped/post已知half输入的再收窄/拓宽，qt4后每wave省128转换；900两批+0.0026/−0.0164ms，1080−0.0014/−0.0235。P保留prefix末次RTZ half位模式并按half shuffle，不删原舍入；qt4按分支上界少56转换，900+0.0053/−0.0005、1080−0.0161/−0.0174。O给C512 mix和ViT contract各4KiB空LDS限制驻留（64/24→16组每MP），900−0.0122/−0.0130、1080−0.0068/−0.0062。组合C=I+P+O独立实测：900 9.2539→9.2414 / 9.3179→9.2909（−0.13%/−0.29%），1080 12.6134→12.5863 / 12.6380→12.6200（−0.22%/−0.14%），未过门槛。

上游tile计数器只在Linux19条管线启用，Windows0条。S按现行M32接口扩C512 projection→QKV短链，保持原PDL=1：900+0.0404/+0.0321、1080+0.0488/+0.0490ms。V0扩ViT contract→QKV并用agent acquire轮询，消费者多3处global_inv（含轮询内）：900+0.4592/+0.4594、1080+0.3862/+0.3781。随后F按现行PDL的relaxed方式做对照，首版720-motion有反例；检查发现原串行代码hidden.reset后，best-fit池可能把仍由producer读取的hidden给norm。实验host保留hidden引用并断言无别名后，F重新通过完整EXACT/AE、历史回绕与AE回绕；最终900+0.0101/+0.0174、1080+0.0142/+0.0276ms，仍不采用。F同时改了同步和生命周期，不把V0→F差额全归给invalidate。V0只保留先导记录，未作可部署实现；新代码默认保留引用，unsafe-no-keep仅复现旧缺口。

G对C512 mix/QKV做权重组优先的组间编号，组数和K序不变，512几何528384组坐标一一对应；900+0.0932/+0.0741、1080+0.1101/+0.0995。为真正对齐上游同WGP复用，再做H：C512 mix四wave/128线程一组，同64列权重，各算独立32token；无LDS/跨wave barrier，尾部wave可提前退出。VGPR96→95，无spill，运行实际13次替换/帧；900+0.0426/+0.0331、1080+0.0402/+0.0447ms，也不采用。

九组双架构编译，gfx1200仅编译；gfx1201每组EXACT/AE各7×12帧，共1512候选帧逐位，756组AE决策逐字段同（各43复用+41刷新）。压力构建新slot上限64：S每12帧回绕18/19次，V/F各23次；S/F另验证AE命中时推进计数与回绕，额外120候选帧逐位。连基线3264份逐帧hash，失败F首版已隔离。所有性能为同批两档两轮ABBA，1000帧弃前200、只读首尾；未用帧时间日志当GPU计时。

无组合稳定达到任一档≥0.5%，按任务单交账停止，不合配方、不改分派生产头、不改src/RE9/flags。现场双架构60模块hash与启动快照全部同；剑星仍第五刀+帧时间日志add-on，无新安装/备份、未发包。逐条对照、全网普查、ISA/资源、时序/压力/AE证据与复现脚本在 `results/mochizuki-022-20260928`、`HIP/experiments/mochizuki-022`。


## 2026-09-28：ACO 逐条对齐两段，激活 clamp + 有界倒数组合过线并装剑星

任务445a832，基线第五刀。纠正旧ACO目录仍是4f62a8a，本轮按0.0.2.2/228d3a6重导27条fswin管线；C32、c64-wave2、C256实际FFN模块带行号复编，对当前生产`.text/.rodata/.note`全同。按CFG循环×真实214派发加权，区分C32完整体与四个互斥边缘体，C256使用实际FFN+attn而非未调用的整块导出。选激活、softmax两条数值链，逐条ISA/数据流表在`results/aco-lineup-20260928`。

每256个激活值，C32标量槽1920对ACO1152，多出768=512个原乘/加独立舍入+256个NaN规范化；C64为1728对1152，多576=512舍入+64打包清零。两次FMA收缩已有非零FP8反例，不改。softmax保留原WMMA求和，不能照抄ACO packed-half树与单条rcp；C64通用除法在[1/256,624]的已知范围里比C32两步修正多192槽，可删除。

ACT只将C32激活clamp写成fmed3（CW_ACT_FMED3，默认0），不启用旧全局clamp开关；chain普通向量3781→3653、mapped4232→4072。R将wave核最后1/sum换成C32已穷举验证过的有界倒数（W2_BOUNDED_RCP，默认0），保留两次误差修正及原两侧和；C64 bi_bo5068→4856、C1285237→5041、C256attn1852→1632。VGPR/LDS/scratch不变。half直入M/N增加指令，ISA筛掉；M只过EXACT84帧，N未跑回归，不冒称全过。

R独立两批900−0.459%/−0.288%、1080−0.345%/−0.372%，不足门槛。组合C两批900 **9.351364→9.274342 / 9.353041→9.292394ms（−0.824%/−0.648%）**；1080 **12.669468→12.574209 / 12.673561→12.579319ms（−0.752%/−0.744%）**，两档均过线。1000帧弃前200、首尾读回；R早期r2与编译重叠隔离重跑。不同批次绝对帧时不拿来推ACT独立收益。

R/C各EXACT84+AE84，连M共420候选帧逐位/840哈希，168组AE决策相同，每组43复用41刷新。最终清理M/N实验helper，默认关Z与第五刀、配方P与实测C各双架构四文件代码/metadata全同。配方已合两个宏；gfx1200仅编译，gfx1201实测。

剑星已安装c32-wave1（gfx1201 11ed6305 / gfx1200 f67be506）与c64-wave2（643a3a7f / 5b368198），备份 `D:\DLSSNR-Lab\aco-lineup-20260928\backups\stellar-20260928-115800`。四文件回读同，另56模块及add-on/dxgi/ini/flags hash不变；未发包。游戏验收待Zero。部署`deployments/aco-lineup-20260928`，脚本`HIP/experiments/aco-lineup`。本轮够用交付，未扩到decoder/布局。

## 2026-09-28 13:52：ACO 对齐两刀剑星首测（Splashtop 远程）

剑星 1080P 原生 AA、EXACT、简单画面黄字 **57.1**。本次经 Splashtop 远程，Zero 估远程损失 1～2 帧，与本机测的第五刀 57.1 不可直接比；待本机复测。

## 2026-09-28 14:10：Daniel 闭源 v0.5.0 静态分析（分身）

安装包 39df94a0…，静态提取未运行、未动 9070。内核 86→168，几乎全部多一个 bool 模板参（Lb1=fast，无 div_scale/fixup；Lb0=reference）。默认 `Quality=fast`（UI 称 RX 9000 快约 13%）。RDNA3：gfx1100 代码对象 1.1→7.9MB，全部 `v_wmma_f32_16x16x16_f16` + 显存 f16 权重副本 + 整数位运算模拟 e4m3，寄存器快核自 09-27 起成为唯一 RDNA3 路径——+207% 即 RDNA3 从通用核换到快核，不是新算术。RDNA4 reference 版对 0.4.0 同名核：去 scratch 溢出、`v_mov`/打包大减、cvt 数不变（数值路线未动），与我们第五刀同类。新 env `DLSSNR_EXTENT`/`PAD128`：默认改按 NVIDIA 原生工作尺寸跑网络、128 对齐成回退，可能同时贡献提速与"更贴近 NVIDIA"。待查两件：我们 1080 档 1152 行是否大于 NVIDIA 工作尺寸（不逐位，需 Zero 拍板）；Daniel reference 大量 `v_fma_mix*_f16`，与我们判定"两次独立舍入是语义必须"的那段是否真符合 NVIDIA PTX（未核实）。报告 `results/daniel-050-20260928`。


## 2026-09-28：核实FMA与NVIDIA原版、原生工作尺寸；两个算术候选仅评估

按2137a35任务单，从SHA e16bcf15…1fc8e的原DLL重新提取CUBIN，核C32/C64/C128/C256的激活、softmax、范数、残差；Daniel 0.5.0各档Lb0也逐核读实际数据流。原激活是两次HFMA2＋HMUL2，softmax仿射亦HFMA2；Daniel激活实际是v_pk_fma_f16，不是凭704条fma_mix总数猜。Daniel的half平方和树、完整除法修正及投影累加模拟仍不等于已证明逐位NVIDIA。原残差以HMUL2值进入QMMA.F16初始累加器，不能概括成末尾一个float FMA。

历史闭环：09-08用户已批准exact→fast，主动删half舍入；09-10的4b80815/05c8f99为了融合核与旧fast核一致给HLSL加precise，HIP随后对实际fast CSO，非编译器意外破坏原版。旧完整1080 RGB0→70的6635520个float32再次核对原CUBIN oracle全字节同、SHA同；本轮Spark重跑普通/inpview C32原CUBIN，两份8MiB raw与历史同，inpview正确解码后65536值与单块float oracle同。只替换激活的CPU控制：当前float分步/FMA均95.4498%同原版、MAE0.00150824；half阶段舍入100%同。63488有限half输入A/F的最终FP8全同，不推广到任意float输入。

隔离AMD候选只动C32十块+C64/C128二十块激活：F为两次float FMA；H恢复输入half、两次half FMA和末次half乘法（矩阵仍当前float累加，非完整exact恢复，也未做packed-half优化）。两候选各七用例×12帧全部有限、输出全变；AE未测。两档两轮ABBA、1000帧弃200、只读首尾：F900−0.0965/−0.1015ms（−1.04/−1.09%）、1080−0.1319/−0.1349ms（−1.05/−1.07%）；H900+0.8411/+0.8389ms（约+9%）、1080约+1.25/+1.23ms（约+9.8～9.9%）。首轮测试误选旧架构子目录，整轮隔离作废；重跑flat目录每槽打印模块hash，Z与现场两模块全文件相同。

另以保留原版随机RGB真值、seed0/reset、全71块（无发布跳块）做raw输出误差：可见1080对NVIDIA，A/F/H RMSE=0.01222051/0.01220281/0.01215738，固定峰值1 PSNR=38.258/38.271/38.303dB，改善仅0.145%/0.517%；F/H对当前输出44.024/42.511dB。单帧小幅接近不能宣称游戏画质改善；F作为改变输出换约1%速度的候选交Zero，H朴素实现不合生产。

尺寸：1080原始blob有效1920×1080、处理1920×1152（原捕获器只读不改参），我们已同，按该原生合同无可省行数、收益0ms。原DLL0x18003c580按layer shape下降次数求2^count对齐步长；Daniel固定ceil64，所以1080默认1088，900默认1600×960（与我们同）。原版900计数尚未知。若另试1152→1088，少64行/5.56%处理像素，面积估约0.70ms，未实现/未ABBA；边界可经ViT影响整图与后续历史。旧1088证据是4K的encoder半尺寸，不是1080原生合同。

全证据、三方逐条表、fresh CUBIN、原版误差、32槽原始计时序列、336份逐帧hash及复现脚本在 `results/fma-vs-nvidia-20260928`、`HIP/experiments/fma-vs-nvidia`。gfx1201实测，未编/测gfx1200；现场60模块对开工快照均同，只改实验和记录，不改生产配方、不装机、不发包。


## 2026-09-28 15:39：float FMA 合生产并装剑星；新逐位基准

按e3f6863任务单和Zero批准，**09-28 起基准改为 float FMA；09-28 起基准变更：float FMA 激活**。7个fast源文件23处两层乘加显式__builtin_fmaf，覆盖C32 wave/非wave、C64/C128/C256、ViT/C512；末次乘法、量化、矩阵累加、softmax/归一化、half参考均未动。15个受影响模块双架构重编，含缺可选模块时的旧HIP fallback；旧HLSL precise保留历史对照，不再作新HIP逐位裁判，无新flags或host/RE9 ABI改动。

EXACT/AE各7×12=84候选帧全部有限，连旧基线336帧；AE84次复用/刷新决策变化1帧，43/41→44/40。1080-history第8帧relative 0.225316525→0.219200358跨0.22阈值而复用，age/reason合计3帧不同，连分数50帧不同。额外两次该12帧用例重放，24个输出及整份AE决策日志均同新基准。新goldens `results/float-fma-20260928/new-baseline-hashes.csv`（84 EXACT＋84 AE），检查器 `HIP/experiments/float-fma/check-baseline.py`；旧三道golden脚本已标历史，配方SHA256SUMS同步。

两档两轮ABBA，1000帧弃200、仅首尾读回：900 9.19493→9.08504 / 9.26532→9.15082ms（−1.20%/−1.24%）；1080 12.55121→12.39985 / 12.57806→12.43015（−1.21%/−1.18%）。16槽原始帧时已归档并独立复算均值。

**纠正上轮原版整网误差**：fma-vs-nvidia的oracle-final是post_shift=0，而其runner用3，故撤回“0.145%/0.517%改善”；局部CUBIN/ISA、尺寸及计时不受影响，旧报告加校正。此次统一post_shift=3、全部71块、seed0，以原版shift-full-oracle为裁判，历史exact采样shader按accepted SHA取自450d63b。单帧可见RMSE A 0.0080383812→P 0.0080365856；五帧off/on/off/on/off聚合0.0080368624→0.0080010754，均不劣。五帧是固定RGB/history受控开关，不冒称原输出自反馈；正常游戏式反馈由七用例覆盖。

15:39只换剑星30个HSACO（15×gfx1200/1201）和对应HIP checksum，C32 gfx1201 AA999258、C64 F9E8F0C5；回读同payload，其余30模块与addon/dxgi/INI/flags hash不变。备份 `D:\DLSSNR-Lab\float-fma-20260928\backups\stellar-20260928-153921`，部署 `deployments/float-fma-20260928`。gfx1200仅编译，gfx1201实测。不发包，本机画面/FPS待Zero，仍1080P窗口＋FSR原生AA＋F8 EXACT＋黄字小数，也补此前ACO两刀远程57.1的本机读数。完整结果 `results/float-fma-20260928`，复现 `HIP/experiments/float-fma`。

## 2026-09-28 15:49：float FMA 剑星首测（Splashtop 远程）

EXACT 黄字 56.7～57.1 来回跳，看不出比上一刀（远程 57.1）有提升。离线预期约 +0.5 帧（ACO 两刀 + FMA 合计约 −2%），落在远程读数的抖动范围内；待本机复测或用 DLSS5_FRAME_STATS 看均值。

## 2026-09-28 16:15：Daniel 0.5.0 剑星实测对照（9070 本机日志）

装法同 0.4.0（`D:\DLSSNR-Lab\daniel-050\swap.ps1`，改名我们的 dxgi.dll，放其 mod.dll；测完已切回 ours）。剑星 1080P 原生 AA，站立不动：

| | 网络 GPU（200 帧均值） | 整帧 |
|---|---|---|
| Daniel 0.5.0 fast（默认；f32 累加、e4m3 一次舍入、近似 rsqrt/rcp、硬件噪声/sRGB） | 9.4～10.0ms | 贴 60（窗口模式 DWM 刷新率上限），wait-for-capture 余 5～7ms |
| Daniel 0.5.0 reference（PTX 算术） | 11.0～11.1ms | 贴 60，余约 2.5ms（估不封顶约 14ms） |
| 我们（float FMA 版，15:48 frame-stats） | 离线约 12.3ms | 17.6ms / 56.8fps |

判断：网络本身 reference 对 reference 差约 1.2ms（~10%）；整帧差约 3ms，其中约 1.5～2ms 在网络之外（他 inline 同帧、输入输出零拷贝、拷贝+apply 0.1ms）。mochizuki 0.0.2.2 与 Daniel 0.5.0 均已快于我们。

## 2026-09-28 16:40：一帧时间账 vs Daniel 0.5.0 reference（分身，`results/frame-breakdown-20260928`）

离线完整 NativeGameFrame 回放（现场剑星 30 模块 + flags，1080=1920×1152）wall 12.32/12.36ms；由 09-27 纯 HIP 跨度 12.08 按此后三刀推算网络约 11.75ms，故网络外流水线约 0.55ms（Daniel 约 0.11）。两边整帧差约 1.1ms = 内核约 0.65 + 流水线约 0.45；此前"Daniel 整帧约 14ms、网络外差 1.5～2ms"是对其 60 帧上限下 slack 的误读，撤回。可做项：内核（闇路线）、输入零拷贝（encode 直写共享缓冲，约 0.1～0.15）、输出少一次回拷（约 0.05～0.1）、HIP→D3D 交接改 GPU 轮询（待测）。游戏内确认需 Zero 做 F6 对照（站立 30s 开 / 30s F6 直通，看 frame-stats 的 bypass 窗口）。未改代码、未装机。

## 2026-09-28 17:05：网络前后零拷贝 DLSS5_DIRECT_IO（分身）

frame-breakdown 可做项 2、3。位 1（默认开）：RGB 输入 pass 直接写 HIP 共享输入缓冲（可 UAV、静息 COMMON），桥接跳过 35MB 拷贝，HIP 后端从不读的 tile 副本不再写/分配；位 2（剑星装机开，模板关）：pre-upscale 路线 FSR 直接读 decode 的 RGBA16F 输出纹理，省回拷。时序会话、OVERLAP、非 RGBA16F 颜色自动走旧路径；RE9 runtime 不读此键。离线回放（`benchmark_vit_reuse` 加 `DLSS5_BENCH_PLAIN=1` 非时序会话，同剑星）9 组 108 候选帧逐位、AE 决策同；ABBA 两批直写快 0.02～0.05ms（−0.14～−0.40%），远小于带宽粗估，说明网络外开销主要不在拷贝本身，更可能在跨 API 交接。剑星已装 `DIRECT_IO=3`（add-on abef6155，备份 `D:\DLSSNR-Lab\zero-copy-io-20260928\backups\stellar-20260928-170538`），位 2 画面待 Zero 本机确认。`results/zero-copy-io-20260928`。


## 2026-09-28：Daniel 0.5.0 reference逐核映射，两族候选无达标收益

按21fc931任务单，先DGX离线读168导出（70 reference/69 fast/29共享）、166个host注册/329处引用。同为Clang21 revision590b9320，但选项未知；reference半精度/归约/除法与当前float FMA数学不同，未借它们改基准。命名纠正reg_vit=C512窗口、reg1d=全局ViT；默认C256 persistent chain关闭。默认主体host推导154派发：Swin46+C51264+ViT40+repack2+head1+decoder1；我方实抓214，C512跳42/43/46只13块，对方16块。三几何219行位置配对带grid/waves/资源/静态分类，复杂动态未知保留NA。

C32/C64完整循环路径上界（同1152，非硬件计数器）：我方issued982.77M/310.69M，对方1002.07M/337.24M；向量槽我方反而少，VMEM49.62M/16.54M对21.55M/8.57M。Daniel旧→新去spill是真的，但我方相应生产核已零spill。1088与1152在Daniel深层都60×36/ViT640；900为52×32/448（我方50×30/400）。Daniel post双轴shift0由host/ISA证，我方shift3多边界waves，属窗口语义差。按历史族账×浅层wave差的几何等价约C32.207/C256.084/C64.077/C128.075ms（合.443），非实测；C256/C512/ViT逻辑中间读写的带宽等价时间单列，不与整体约.65ms差额相加归因。

P：默认0 W2_PACK_NOZERO，仅实验源；借Daniel低/高半覆盖目的寄存器，无需预先清零。8活跃核资源不变，去72～76个静态向量槽，C64/128每核24个空MODE段→0，无half收窄混入；同时有互斥分支打包合并，不能只叫“一条mov”。EXACT/AE各84帧逐位、84组AE所有字段同。初轮P计时后来发现与分身zero-copy实验文件时间区间重叠，且旧guard漏benchmark-zc，不能排除并发；全部隔离作废（数值hash保留）。用户17:07明确交卡后，用新benchmark-zc/assets、DIRECT_IO=3/BENCH_PLAIN=1重测：900 +0.00642/−0.00958ms，1080−0.01019/−0.01468ms（两批1000帧弃200），仍远不到0.5%。guard已改benchmark/rt_bench前缀。

C32供数：默认0 CW_WEIGHT_CACHE mask1/2/3，QKV/投影缓存跨四qt复用，同索引/MMA顺序。六导出每wave确实少36/12/48条global_load_b64；Q/C VGPR+12～24，R+2～8，零spill，WMMA/DS/FP8数不变。Q/R/C各12帧1080-motion逐位；两档两轮200帧短筛，Q/R近噪声，C最好900约−0.19%，未做无意义的完整AE。新IO又补C两批短筛：900+0.02324/+0.01834ms，1080−0.00567/+0.01099ms，也不采用。合计228候选帧对float FMA golden同（P168+Q/R/C36+新IO P24），80有效计时槽原序列独立复算；另16旧P槽隔离。

没有合配方、没有装机、没有新备份、不发包。17:10用户说明分身已更新剑星，本轮只读核实add-on ABEF6155F703616070D20CE73D8357D2F19DDC76C3C03DA838D6C236CBBD5F74、DLSS5_DIRECT_IO=3；60内核仍与开工同。以后部署须基于该宿主重新备份并保留3，不覆盖旧C38。完整对应、host地址、循环上界、字节/毫秒条件模型、候选patch、双架构默认关代码身份与实测在 `results/daniel-kernels-20260928`、`HIP/experiments/daniel-kernels`。


## 2026-09-28 20:17：C256整块融合重开，仅1080启用，整网−1.67%/−1.63%，已装剑星

按4f0a62f7任务单，读Daniel C256 reference：8wave/窗口、32KiB LDS，普通153VGPR/零private；flags4仍private272。四qt复用权重，lower16KiB阶段复用、upper片段供attention读取（Q的命名是数据流推断）。历史“持久化已关”其实没实现；真正旧wave2融合900短筛+0.21068ms，修spill后仍慢。旧整块把同64token的前段4组×16waves变成1组×8waves，工作量不减，不能把慢因擅定为LDS冲突。

试O旧整块、L Q存LDS、B两qt共享FFN权重、BL、F1/FL四qt单hidden，共6个12帧1080-motion逐位短筛。F四qt双hidden有spill，只编译审计。B每wave FFN权重请求576→288，主力完整核VMEM1316→1028、VGPR190→154、WMMA仍1320；向量槽反增5251→5650，不冒称少算。Q LDS单独不降峰值，BL与B速度接近，F1/FL更慢。B两档短筛900+0.12965ms、1080−0.22116ms；旧O当前1080也−0.13565ms，故新组织不是全部收益来源。

最终只保留W2_FFN_QT_BATCH默认0/生产配方2，在host仅1920×1152放行C256整块。1152行、post(-4,-4)、float FMA及所有舍入/累加顺序不变，无新用户flags，900/720保持原分体PDL。16个C256块实抓整网214→198；族34包含两个上下采样，融合后18。生产runner与实测tier runner五个代码/数据段完全相同，双架构生产.text/.rodata/.note与候选B相同，宏全0与旧模块相同；其余C64/C128/attention-only的ISA资源不变。

EXACT/AE各7组×12帧共168候选帧同09-28 float FMA goldens，无NaN/Inf；AE44复用/40刷新、84行全部字段相同。加短筛共240候选帧。正式ABBA每槽1000帧弃200，DIRECT_IO3/BENCH_PLAIN1：900 9.051989→9.047189 / 9.097763→9.101487ms（持平），1080 12.326469→12.120527 / 12.340419→12.138835ms（−0.205942/−0.201584，−1.671%/−1.634%）。64短/长计时槽的原始序列已独立复算。gfx1200只编译，GPU实测gfx1201；离线只覆盖输入直写，不声称覆盖FSR输出直交。

20:16装剑星：宿主61a81c75421e9da237370971922ed5bd59692804e1138a5754454ebc5b6e686e，基于abef6155对应源码仅增加C256档位路由；c64-wave2 gfx1200 434cd8ef、gfx1201 5bcffdf6。备份D:\DLSSNR-Lab\hip-backend\c256-fusion\backups\stellar-20260928-201658；DIRECT_IO=3、输入shader、flags/dxgi/OptiScaler全保留原哈希，另58模块未变。安装前查进程、备份/载荷/读回均校验，不发包，游戏画面/FPS待Zero。C512只读找到QKV+norm+attention新合核方向，理论少13派发，需另写内核；不把此方向当本轮成绩。完整证据、复现与还原脚本在results/c256-fusion-20260928及HIP/experiments/c256-fusion。

## 2026-09-28 20:28：剑星本机实测 59（C256 融合 + 直写 IO + FMA + ACO 两刀）

9070 本机，1080P 原生 AA、EXACT、简单画面静止：黄字 **59**（第五刀本机 57.1；Daniel 0.5.0 reference 贴 60 上限）。现装宿主 61a81c75、DLSS5_DIRECT_IO=3。


## 2026-09-28 21:05：C512融合＋C64/C128权重复用，900−3.59%、1080−2.55～2.63%，已装剑星

按8c9a61db任务顺序完成前三项，余力ViT/边界未扩。Daniel C512四buffer由host闭环：270/外部→FFWD→278→conv(残差270/外部)→280→attn3→288→conv(残差280)→270；QKV只在attn3的6KiB LDS内。新c512_qkv_attention_fused每window/head两wave各32查询，122VGPR、6144B LDS、零spill，只一次组同步；Q/K逐通道32项平方和、softmax两侧树与普通1/x、FP8/half舍入边界及现float FMA均不变，AV接原projection/crop。每window/head新旧WMMA都848。删除全局QKV交界约900档81.20MB、1080档102.24MB逻辑量；单head分组使输入共享变少，ISA路径和读取请求反增，不称DRAM流量减少。实抓C512族92→79，整网900档214→201、1080档198→185。

C256的两qt FFN权重复用推广C64/C128：主力FFN权重请求192→96、320→160，WMMA456/744恒等，VGPR140不变/144→159、LDS8/16KiB不变、零spill；Sboth短筛900−0.10199、1080−0.15768ms。C512 FFN M32也实现并逐位，但VGPR113→216、LDS4160→8320，M/MD反慢0.10～0.15ms；仅删_t8无人消费float输出D只有−0.00654/−0.00251ms，均未合入。900新C256 wave16每头两wave、两平面保持32KiB、多两barrier，四导出VGPR208/200/208/200且零spill，900-motion12帧逐位但慢0.12174ms，900保留原分体PDL。

最终C=F融合＋Sboth用生产host和双架构配方验证：EXACT/AE各7×12=168帧同09-28 float FMA golden、无NaN/Inf，AE44复用/40刷新、所有字段同。独立F亦过168，8个短筛各12，共432个候选帧同golden；额外用游戏CODEC_SRGB=0配置对F/C各12帧对拍同基线，单列24帧，不混CODEC1固定夹具。每槽1000帧弃200、首尾读回的两轮ABBA：900 9.046038→8.721419 / 9.108684→8.781375ms（−0.324618/−0.327309，−3.589%/−3.593%）；1080 12.131856→11.822138 / 12.149375→11.829512ms（−0.309719/−0.319863，−2.553%/−2.633%）。80短/长计时槽原序列复算；双架构新宏默认关代码同原，生产gfx1201代码同实测F/Sboth。gfx1200仅编译核对，真卡gfx1201。

装剑星宿主257a2fdbd7fbd0472cb9e58843ee6e9a99a777f00adb0ad84b8ee6b7ebbb93ac，基于61a81c75增加C512路由；每架构c512-m32-mh/c64-wave2共4模块，gfx1201为51c2fa1a/abffcd1a，gfx1200为7d9e0068/dfdf3970。备份D:\DLSSNR-Lab\hip-backend\c512-fusion\backups\stellar-20260928-210508；DIRECT_IO=3、MAKE_RESIDENT_EVERY=60及flags/输入shader/dxgi/OptiScaler全保留原哈希，其他56模块未变。未发包，画面/FPS待Zero；驻留改0的p99实验留给Hikari/Zero，本轮未混测。报告、哈希、原始时序、ISA账与回滚脚本在results/c512-fusion-20260928和HIP/experiments/c512-fusion。

## 2026-09-28 21:14：C512 融合后剑星本机 59～60，已触 60Hz 上限

宿主 257a2fdb。1080P 原生 AA EXACT 静止：黄字 59～60，frame-stats avg 16.78～17.00ms，p50 恒 17.00（窗口模式 DWM 60Hz 封顶，上一刀 16.95）。此后 1080P 剑星读数量不出提速，改看离线/日志网络时间、更重场景或提高刷新率。p99 多数窗口回到 17.5～18.8ms（30ms 尖刺减少，可能是 MAKE_RESIDENT_EVERY 开销被空闲吸收）。

## 2026-09-28 21:17：新对比标尺——剑星 2K 原生 AA EXACT 52～53

2560×1440 原生 AA（网络 1080 档），EXACT 静止，黄字 **52～53**，宿主 257a2fdb。1080P 窗口已触 60Hz 上限，此后游戏内对比改用这个设置。


## 2026-09-28 22:09：融合收尾U2＋T已装剑星，0.36打包清单交付

按c10a79d1做ViT、边界与FFN快查。ViT P在现n64投影附byte出口删7个pack；G再合入口Gather删第8个；保持float AE边界与gate。P多32次重复FP8编码及32条byte store；Q复用首次编码并缩短byte引用，R再带入口融合，均1080-motion12帧逐位但未确定不亏，全部不取。D做C64/C128 encoder尾块＋Down，复用已消费LDS、保raw skip及H/H/F顺序，逐位但900/1080慢0.03465/0.04790ms，不取。C32/ViT FFN审了旧M2/M4/布局等结果，无新且小的切口，不重复已关实验。

采用U2（C64/C128 Up→首块56/62）与T（C32 Up→66）。每8×8高分窗口只算一次4×4低分投影，不重复大块；保原half/FP8边界、skip及K顺序。U1多余负零位图的说明纠正：原w2_canonical_byte_word只把0x7f→ff，不清0x80；U2直接原样存byte，不改数学，删位图后SGPR降至27/26。新C32/C64/C128 Up核VGPR154/137/162、LDS4/8/16KiB，零spill。实抓900档201→198、1080档185→182，共少3派发。U2独立两批短筛900−0.05481/−0.04626、1080−0.03121/−0.03990ms，虽小但确定不亏；T−0.13169/−0.12741、−0.17422/−0.17554ms，组合直接验收。

最终生产组合EXACT/AE各7×12共168帧同09-28 float FMA golden，无NaN/Inf；AE44复用/40刷新、84行所有字段同。8个独立短筛各12，合计264候选帧同golden；另游戏CODEC_SRGB=0设置12帧同现场基线（不混固定CODEC1夹具）。两轮ABBA每槽1000帧弃200、首尾读回：900档8.728834→8.558377 / 8.757739→8.575466ms（−0.170457/−0.182273，−1.953%/−2.081%）；1080档11.827253→11.578635 / 11.822831→11.559094ms（−0.248618/−0.263736，−2.102%/−2.231%）。两个模块双架构新宏关闭代码与旧模块一致；gfx1200编译，真卡gfx1201。

0.35累计另做同批ABBA：真实发布目录60模块逐个通过其SHA256SUMS，宿主4151123e/sourceec96774d；与tag HIP清单26个物理hash不同，不据此推断机器码不同。用0.35引擎源码＋同一无temporal-config测量probe、发布模块/资产，旧900输出75AABA同历史golden。累计900档9.368873→8.577554 / 9.385209→8.590563ms，省0.791318/0.794646ms（8.446%/8.467%）；1080档12.715527→11.573710 / 12.711608→11.582428ms，省1.141817/1.129181ms（8.980%/8.883%）。120个短/长/累计计时槽原序列复算；不相加逐刀百分比，也不称0.36与0.35逐位（float FMA中途获批变更）。

剑星新宿主d2290ad7426967edfd566b5c53e1e2ae580a41463b08594375079fb7b84abfdf；双架构c32-wave1/c64-wave2共4模块，gfx1201 d5cca499/c8a88d27，gfx1200 df29c19f/b6359c05。备份D:\DLSSNR-Lab\hip-backend\fusion-round3\backups\stellar-20260928-220957；DIRECT_IO3/MAKE_RESIDENT60及flags/输入shader/dxgi/OptiScaler原哈希，其他56模块未变，全部60模块与repo及冻结载荷核对。RE9 runtime7ce2bc21已编，在1707×961输入下900/1080各12帧回放末帧hash同基线（b2980ada643da964/758674a8bbd0206d），smoke通过，未装RE9。0.36清单在results/fusion-round3-20260928/package-036-checklist.md：常规/Magpie DIRECT_IO1，RE9不写；FRAME_STATS全0、其余模板默认保留，含全部hash/来源/累计ms。Hikari据此打包，当前未打包未发包；本机按2K原生AA EXACT新标尺复测。

## 2026-09-28 22:51：收尾融合后剑星本机读数（宿主 d2290ad7）

EXACT 静止：2K（2560×1440）原生 AA **54**（C512 融合版 52～53）；1080P 原生 AA **60**（触 60Hz 上限）。


## 2026-09-29 01:02：C512点运算紧凑布局，900/1080约再省2%，已装剑星

对齐Daniel深层发现“60×36有效尺寸相同”不等于实际工作量相同：Daniel FFWD/conv按135个4×4tile，我们先shift-pack到64×40后点运算也跑160tile。新compact保mix/FFN/projection原算术，先按有效raster执行，只在attention读取时按原shift映射/补零，不删padding key或改softmax。900每块1500→1504尾补齐，13块点运算26432→19552（−26.03%）；108033280→28080（−15.625%，M32 mix尾槽实际−15.0%）。attention窗口/组数不变，整网trace900保持198，1080182→169。实验C完整EXACT/AE各84帧同，84组AE决策同；生产P独立168帧也命中09-28 float FMA goldens、无NaN/Inf，AE44复用/40刷新且所有字段同；含短筛共384候选帧同golden，另游戏CODEC0现场12帧相同。

两轮千帧ABBA（弃前200帧）先C后生产P：9008.51943→8.35530（−0.16413ms/−1.927%）、8.51362→8.33801（−0.17561/−2.063%）；108011.57261→11.34437（−0.22823/−1.972%）、11.58796→11.33980（−0.24815/−2.141%）。91个kernel函数体实测/生产全同，整ELF仅函数拼接次序不同；host五代码/数据段同，默认关双架构还原同。生产c512-m32-mh gfx1200 ec9e8d92、gfx1201 4bb9b847，add-on b5ab8c3a；基于d2290ad7，DIRECT_IO=3/MAKE_RESIDENT_EVERY=60不动，01:02已装剑星，备份D:\DLSSNR-Lab\hip-backend\deep-layers\backups\stellar-20260929-010247；其他58模块、flags/输入shader/dxgi/OptiScaler原hash，60模块与仓库及现场清单全部核对。RE9 runtime隔离900/1080各12帧回放末帧hash同0.36，smoke通过，未装RE9，不发包。

R单wave寄存器FFN、RF再并mix、V消费端float打包均12帧短筛逐位但更慢：900+0.1996/+0.1406/+0.1474ms，1080+0.2648/+0.2989/+0.3370ms，关闭。Daniel FFWD单核已实际launch：非零合成graph负载下V1比我方mix＋FFN两核快约1～2.6µs，不外推模型。全16权重8388608值FP8精确，但找回旧block46/pattern2展开FP8导致10个float元素位差的原日志，RF8不构建、不重试。详细几何/计时/身份/微测与FP8证据在results/deep-layers-20260929，本机画面/FPS待Zero。

## 2026-09-29 07:53：深层紧凑布局后剑星 2K 读数未见提升

宿主 b5ab8c3a、c512-m32-mh 09-29 00:57 已装。2K 原生 AA EXACT 静止：黄字 54；frame-stats 静止窗口 avg 18.56～18.60ms，与 09-28 22:50（d2290ad7）18.55～18.72ms 持平，离线预期约 −0.24ms 未兑现。待查：场景差异 / 游戏内是否实际走到新路径 / 2K 路径是否与网络部分重叠。


## 2026-09-29 08:48：全网逐核地图，采用head分组融合H＋ViT attention转置V，已装剑星

全图按位置覆盖我方169/参考Daniel154派发，323条均通过7轮median、START/RESULT及前后guard/finite/nonzero验收。首次把scale尾区也合成±1/64造成42浅层核全零，整169条批次弃掉重跑；11个同类>30%离群项再各跑两独立进程，21个TIME合中位、保留原始日志。map-before原生独立核中位数总和我方10323.528268、Daniel10204.250706，差+119.277562µs；逐位置有效面积启发式差−283.542672µs，两者均非帧时，也不能跨几何/移位/跳块推“写法优劣”。同几何首项block30/head完整组+135.16µs，后面八个ViT attention各约+47～51µs。

H复用groupbody，原head pool＋FP16 projection两派发→一派发（900198→197、1080169→168），C512_HEAD_GROUP，512threads/98VGPR/29SGPR/16640LDS/private0；V只转置score片段排布，HIP_VIT_ATTN_TRANSPOSED_SCORE，72VGPR/16SGPR/LDS0/private0/barrier0，保400/640现导出及WMMA数序。短筛H900−.022435/1080−.118348ms，V−.011533/−.027545ms；组合首轮9008.42661750→8.39019125（−.03642625），108011.362136875→11.224219375（−.13791750，约−1.214%）。168帧EXACT/AE配对同；第二轮9008.35801625→8.337249375（−.020766875），108011.3426825→11.22686125（−.11582125，−1.021%）；两轮千帧弃200。168正式帧全部命中09-28 float FMA golden、无NaN/Inf，AE44复用/40刷新全部字段同；含短筛192帧同golden，另现场CODEC0配置12帧同。host五段与候选同，4份默认关/2份生产code sections一致。ViT QKV等剩余差距涉及FP16/FP8数学边界，不盲抄；P投影仅准备未测，不算第三刀。

新addon ba010de7，gfx1200 deep8652c8c9/mh71fcc576、gfx1201 deep4f84494e/mh8c386562；基于b5ab8c3a，DIRECT_IO=3/MAKE_RESIDENT_EVERY=60及其他flags不动，不发包，08:48已装，备份D:\DLSSNR-Lab\hip-backend\kernel-map\backups\stellar-20260929-084855；其他56模块及受保护配置原hash，60模块与仓库/现场清单核对。RE9 runtime隔离回放末帧hash同、smoke通过，未装RE9。after地图仅刷新head＋八个attention共9组，复用我方159条/参考154条原数据，不叫全网重测；after-ours-092补两次后21样本中位，after已生成，独立派发中位数合计我方10215.678893/参考10204.250706，差+11.428187µs，面积启发式−391.392047µs。head微测约24.65µs、比旧pool6.3＋projection119省约100µs，V多数70～72µs只小赚，原对Daniel的大gap仍在。完整地图、原始日志、repeat与身份/计时证据进results/kernel-map-20260929。


## 2026-09-29：自家 LLVM21 构建链，60 模块编过、168 帧逐位，未替换游戏

按3714aaac任务单完成四项。9070驱动COMGR API/文件版本3.0，verbose及现役模块都指向AMD内部590b9320/LLVM21。公开标签实查7.0.2/7.1.1是LLVM20、7.2.4是22，纠正“ROCm7.x对应21”的预设；选择公开amd-staging第一父链引入22前最后的21提交6d585d872fbd3c594da7a3c09ac9b22eef4167f6（不能证明与内部版代码距离最近）。fork加upstream，dlss5-gfx12分支文档提交94aca371a8e1已推，无编译器优化补丁。

DGX GCC13.3/CMake/Ninja，Release只AMDGPU+clang/lld，16编译/2链接，构建570秒。通过COMGR真实trace复刻Windows辅助ABI/C++14、HIP→优化BC→对象→LLD共享ELF，无SDK/设备库/fast-math；长度+内容CUID对上。脚本直接解析生产30行配方，两架构60模块全成，编译器与产物在~/work/llvm-build-dlss5-gfx12及~/work/llvm-artifacts-20260929，未入库。

对现场ba010de7快照逐核比较：每架构996个导出（含重复/后备），0个函数字节相同；静态指令合计1264742→1291362（+2.10%），392个VGPR/262个SGPR元数据变，LDS/private/参数ABI均同。1080当前37活跃导出/168派发单列，未加权静态90477→91157，C128寄存器部分降、C256及部分ViT升，不据此判速度。

独立目录用同一最新生产runner，仅切模块集：EXACT/AE各7×12=168候选帧，连基线336帧全读回、零NaN/Inf，两侧独立命中09-28 float FMA golden；AE84行所有字段相同、44复用/40刷新。首轮收集器frame用整数与golden文件名不一致，命名规范化后原检查器通过，hash未改。gfx1200只编译，回归只覆盖生产活跃路径。现场60模块及宿主/dxgi/INI/flags前后64项hash同，未安装/未发包/未测性能。

六类首补丁候选已定位pass与IEEE边界：med3/NaN规范化、范围内修正倒数、精确half往返、有限条件mul+add0、VOPD、等待/MODE依赖；先列不写。完整逐核CSV、模块命令/hash、构建日志、336帧hash与原始回归归档在results/llvm-fork-20260929，复现tools/llvm-fork。


## 2026-09-29：编译器四套对照完成，无替换候选，保留现役COMGR3

按aa0340c8及ad499a81补充执行。同一30份生产拼接源码（含最新compact/head/ViT转置），两架构共60模块：COMGR3/LLVM21 590b9320重编三段60/60与现场同；COMGR2/API2.9/LLVM20 33ab2c2f接口与gfx1201支持通过，60模块全成；公开21 6d585d87复用本会话上一轮60份与168帧证据，源码/模块/重编驱动代码身份均核；公开22选ROCm7.2.4 f58b06dc，DGX构建795秒、60模块全成。收到双COMGR补充后停自编7.1.1后备（非失败）；实验rtc工具副本只改DLL选择，生产源码和配方未动。

LLVM20 EXACT/AE各7×12=168候选帧全同golden、无非有限、AE84行同44复用/40刷新。公开21旧回归独立重验全同，性能本轮新测。每槽1000弃200、EXACT/PDL1/DIRECT_IO3/BENCH_PLAIN1，两批ABBA，完整NativeGameFrame wall ms（不是游戏FPS/纯HIP）：20的900 8.303517→8.580749 / 8.394294→8.650877（+3.339/+3.057%），1080 11.162550→11.496013 / 11.192147→11.512950（+2.987/+2.866%）；公开21的900 8.307116→8.319797 / 8.401529→8.388954（+0.153/−0.150%，持平），1080 11.179535→11.236062 / 11.195346→11.243157（+0.506/+0.427%）。32个长槽原始序列重算。

LLVM22完成七组EXACT/AE、候选168帧全有限但96不同：两模式均为900静态/运动/历史和720运动各12；1080三组两模式72帧同。AE40行字段变、复用44→22。900静态基线12帧1hash，候选12帧12hash；抽样900 frame0最大数值差0.468262/RMSE0.042658，720运动frame11最大差0.307861/RMSE0.033611（全RGBA half元素口径），不只是负零。数值门自动拒绝，22没有任何计时目录；没有为了通过改数学/配方，根因未定位，不把C256分体/PDL猜想当结论。

静态对齐每架构996导出；从最新两档197/168派发筛43活跃kernel/module对，分族VALU/VOPD/WMMA/VMEM/SALU/WAIT与资源。三候选活跃核均零VGPR/SGPR spill，LDS/private不变；C128部分寄存器降，C256最高159→20的174/公开21的181/22的198。22的C512 mix静态1047→403主要含四轮尾循环：16条转换×4仍64，增加movrels/m0，不是少算六成；代表C32/C64/C128的med3/half/div-helper/setreg数量四套一致，无证据称新编译器自动修掉现有手写绕法。

决定保留现役COMGR3，公开21留作补丁开发基点。现场60模块和四个宿主/配置文件64项前后hash同，没有装机/发包/混编候选。结果results/compiler-versions-20260929，复现tools/compiler-versions，构建和模块产物在~/work/compiler-versions-20260929及~/work/llvm-build-rocm724，不入仓。归档清理的只是PowerShell把字符串附加属性展开成76MB的冗余AE JSON；逐槽原始CSV保留、Python独立重算，原始ZIP与归档SHA都有。


## 2026-09-29：LLVM21第一刀，VOPD局部前瞻逐位，但未达对驱动0.5%

按c0a61968，版本锁公开LLVM21 6d585d87。在GCNCreateVOPD增加amdgpu-dlss5-vopd-lookahead=N（默认0，本轮4），只gfx1200/1201 wave32非strictfp；最终相邻配对遗漏的独立指令允许小范围前移，检查物理别名和隐式寄存器RAW/WAR/WAW，不越内存/WMMA/MFMA/MODE/同步/inline-asm/bundle，清掉移动指令旧kill。原后续waitcnt/hazard/delay重新生成等待，不改算术/内核/配方。两份MIR/FileCheck、5条RUN通过；C32/C64/deep三个真实模块197导出backend MachineVerifier通过，验证对象代码三段同实际候选。fork269832faf25b已推dlss5-gfx12，默认关。

默认关off与候选P双架构各60模块。off三段60/60同原公开21；P对off两架构1992导出188函数字节同、1804变，全kernel元数据同，VGPR/SGPR/LDS/private/spill/参数/波宽均未变。当前两档trace43活跃kernel/module对多513对VOPD，后续多163条s_delay_alu/少10条s_wait_loadcnt，静态净少360。按真实groups×threads/32的调用权重列账（TOPO第四列items不能当groups），不冒充动态循环/周期账。

EXACT/AE各7×12共168候选帧命中09-28 float FMA golden，连驱动基线336帧全读回/无非有限；AE84行所有字段同44复用40刷新。公共21默认关与驱动21分别两轮900/1080 ABBA，每槽1000弃200，只读首尾，共32长槽/32000计时帧原序列复算。对公共21：9008.316066→8.312584 / 8.404309→8.380732（−0.042/−0.281%），108011.215927→11.197337 / 11.245972→11.223834（−0.166/−0.197%）；对驱动21：9008.392208→8.379759 / 8.413816→8.383906（−0.148/−0.355%），108011.215111→11.218029 / 11.217114→11.234026（+0.026/+0.151%）。口径完整NativeGameFrame wall，不是纯HIP或游戏FPS。

8条前瞻只编C32/C64两个gfx1201模块作静态探针：C32多2～4对，多数只净省0～3条；C64/C128部分长2～4条，C256 attention不变。未做该探针GPU回归/计时，不当候选。结论是局部后置配对接近收益递减，寄存器分配/内存/WMMA工作均未触及，不是整个编译器的上限；没有再盲删等待或扫参数。

未达任一档对驱动≥0.5%，不改生产编译链、不装机/发包。现场64项hash同，off/P60份gfx1201实验模块hash同。源码脚本tools/llvm-patch1，结果results/llvm-patch1-20260929含补丁、2个lit结果、代码/元数据差异、逐帧hash/AE及32槽原始CSV。编译器构建时尚未提交，version仍94aca371，实际C++源码SHA/编译器SHA与fork提交对应另存，不混称原版编译器。

## 2026-09-29 16:10：Daniel 0.5.1 静态对照（分身）

新增 Swin 持久化 run 内核 `k_reg_swin_run<64/128/256>`（单次派发跨层 + 设备端就绪队列、100ms 超时、新 env `DLSSNR_SWIN_RUN(_ALL)`），很可能是 +6%/+8% 主体；reference 档去 swin_mh/swin32 溢出（private 336→80/0）；fast 档再削 cvt/VALU；ViT 新 `k_v1dl_*<2>` 每 wave 双倍 tile。reference 数学未变。对我们：持久化 run 是"C256 持久化已关"的新证据，可重开评估。未计时。换装脚本 `D:\DLSSNR-Lab\daniel-051\swap.ps1`。见 `results/daniel-051-20260929`。

## 2026-09-29 16:40：Daniel 非原生 1080P 闪烁/变糊的静态推断

群友反馈 Daniel 自 0.4.3 起非原生 1080P 闪烁变糊。静态看：他预超分时网络直接跑在任意渲染分辨率上（0.4.0 日志 1708×964），0.5.x 新增 `DLSSNR_EXTENT`/`PAD128`，默认 ceil64"原生 extent"（1080→1088），并自承部分尺寸"single-tile mode not ported"；0.4.0 基线是 PAD128——换规则的时间点与"0.4.3 起"吻合（中等证据）。另一原因：预超分无历史（history off），放大模式下 FSR 把逐帧随抖动变化的残差放大成闪烁/发软。我们只在固定几何上跑（1080=原版 1152+(-4,-4)，非 1080 缩进 720/900/1080 档），几何风险小，但 900/720 是自定几何，且预超分同样无历史（history_reset=1）——第二条风险我们也有。给 Zero 的本机对照步骤见 `results/daniel-nonnative-20260929/README.md`。

## 2026-09-29 17:21：C256持久化队列通过，带GPU恢复装剑星

任务70533d96，先拆Daniel0.5.1：一WG一窗口，一次launch跨层；设备内存head/tail/依赖计数/ready queue，只有4字节host映射错误；s_sleep2、10M realtime tick约100ms。host超时路径只报警、没有找到重算；run掩码构造默认0，不能把宣传+6%归给默认持久化。旧transpose-persist只估算未实施，“以前持久化慢”实际是单层整块融合负账。

实现encoder16–21/decoder49–54各六层。C256 run为154VGPR/48SGPR/32KiB LDS/private0，900每段624任务、1080 每段893任务；init/run/recover共三派发，整网197→179、168→162。每层独立输出保全原输入，超时abort后单WG无轮询逐层重算；映射错误计数让host禁用实例。队列发布release/acquire、全wave写出fence/barrier；回绕drain+clear+同步归零。内部替代PDL，边界普通stream，其它PDL保留。CPU逐段同步版慢0.485/0.685ms，换GPU条件恢复才赚。

canonical Q 7用例EXACT/AE共168候选帧命中09-28golden，AE84行同（44reuse/40refresh）。异步P同168帧；压力144帧含回绕、同步诊断故障、无诊断同步故障，全同，故障确实恢复且禁用，生产sp七函数与P代码/元数据同。默认关闭/缺模块各12帧同。双架构编过，9070实跑；旧c64三段不变。RE9两档off/on12帧hash同且active1，缺模块回退同，游戏未换装。

Q正式ABBA两轮，每槽1000弃200：900 8.347714→8.189269（−1.898%）、8.398949→8.235931（−1.941%）；1080 11.189376→11.125522（−0.571%）、11.204741→11.136764（−0.607%）。完整NativeGameFrame wall，原始CSV独立复算。不是游戏FPS。结果/静态证据/原始日志 `results/swin-persistent-20260929`，脚本 `HIP/experiments/swin-persistent`。

现场旧宿主实际ba010de7（任务单b5ab8c3a已过时）；校验64项后装新046e1a63、增双架构swin-persistent模块到62份，原60、dxgi和ini均同。新DLSS5_HIP_SWIN_RUN源码/三模板默认0、剑星设1，DIRECT_IO3/MAKE_RESIDENT60保留。备份 `D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929\backups\stellar-20260929-172155`，安装支持哈希校验与回滚。未发包、未启动游戏，待Zero现场观察。下一步按C128四层→C64两层评估，不自动全开。


## 2026-09-29：C128/C64持久化四stage负账，维持C256生产配置

按d7b29df2，以现装046e1a63/C256持久化为基线，独立测C128 encoder10–13/decoder57–60、C64 encoder6–7/decoder63–64。GPU直接复用上一单双架构swin-persistent泛型核，62模块与hip/SHA256SUMS全部同；隔离实验host只加小通道mask/side，C256始终两段开启，故障注入只打小通道。上采样融合首块保留，内部替代PDL、边界普通stream。

每候选先7用例EXACT/AE168帧，再短ABBA及1000弃200长ABBA。先一轮对现役宿主，发现诊断host额外读SP_*变量可能污染小差值，补两轮同一exe仅切stage对照。两轮同host变化（负数快）：C128E 900+0.291/+0.363%、1080−0.195/−0.100%；C128D 900+0.167/+0.025%、1080−0.119/+0.005%；C64E 900+0.457/+0.354%、1080−0.004/−0.115%；C64D 900+0.388/+0.295%、1080+0.155/+0.123%。对现役最好单次也仅−0.127%。四段均未过额外0.5%，不收。

实测整网trace基线179/162，单开任一C128为178/161，任一C64为180/163。C128 run159VGPR/16KiB LDS、C64 140/8KiB，均无spill，和普通核相同；HIP API理论占用率均25%不变。每段任务 C128 1581/2257、C64 3111/4453；C256 仅624/893。900 C256原六层12→3每边省9派发，小通道已逐层融合，C1284→3只省1、C642→3反增1，无法照搬其收益；没有把结构分析冒充stall周期测量。

常规672候选帧＋压力384=1056全命中0.36 floatFMA golden，AE528行同，连基线2112帧全有限。每stage两档history×EXACT/AE做强制回绕及无诊断同步的超时重算；每12帧36次真实reset，故障每实例fallback/errors/disabled各1。encoder故障runs1、decoder runs3，确认触发的是小通道。正常计时所有实例零错误/零回退；128总计时槽（96长、32短）原始CSV独立复算。

9070开工/收尾66项SHA同，剑星仍046e1a63、62模块、SWIN_RUN1仅C256、DIRECT_IO3/MAKE_RESIDENT60。未安装/新备份/发包，生产源码、RE9、配置模板不变。结果 `results/swin-persistent-c128-c64-20260929`，源码 `HIP/experiments/swin-small`；本轮交负账，不默认开C128/C64。

## 2026-09-29 19:10：鬼武者装 C256 持久化

鬼武者（RE9 路线）装 RE9 runtime 536a959a + 剑星同款 62 模块（深层紧凑 + C256 持久化），flags 只加 `DLSS5_HIP_SWIN_RUN=1`（备份 `D:\DLSSNR-Lab\onimusha-backups\20260929-185008-swinrun`）。Zero：2K 质量（900 档）中画质稳定 60 帧，GPU 占用不满 100%——新 runtime + 持久化首次真游戏跑通。


## 2026-09-29 19:47：ViT attention逐位三刀通过，模块装剑星

任务629b0555。先拆Daniel050/051 reg1d_attn<1,false>：代码字节相同，4wave/128线程组、每wave16query/head、64key一轮；Q/K blocked、V channel-major，score/P/AV寄存器化，LDS0、16个bpermute，110VGPR。reference也有QK/分母/AV的half舍入、half归约树，不能照搬成我们的float逐位路径。原约50µs是640单次attention派发差，网络每帧8次。

逐段ISA抓到源码范围丢失：clamp之后概率half仅552种正normal（0x1c20..0x3e90），仍走通用from_half，NaN/Inf/denormal分支每tile重复8遍。穷举所有可达值确认精确widening；改native half→float，再用4次成对FP8编码替8次单值编码/冗余clamp/拼字，最后转置分母与AV输出，让query在lane、严格倒数8→1；原key顺序、float累加、affine和最终RTZ保持。张量布局/派发/host/QKV不变。代码5600→2944B，VGPR72→68、SGPR16→12、LDS/private0；理论occupancy仍100%（Daniel75%）。16key静态循环branch/EXEC42→1、wait/delay133→11，VMEM18与WMMA5不变。

照抄head顺序、4wave分组、四tile预取及组合，逐字节过后大多持平/变慢，不上；native后再组合仍不如单wave。微测micro7同批：400 37.991→15.017µs、448对照49.850→16.550、640 70.770→37.885；552值域证明与123个独立job全记录。V=+1诊断移除V取数/地址/打包仅对该夹具逐位，640省约6～10µs，不冒充通用候选或纯带宽时间；还有约15µs对Daniel余差涉及V请求组织与half数学，未唯一归到每项stall。

双架构三宏默认全0三段同现役，开1仅400/640两个bytein_bout函数变，另74函数及元数据同；生产目标函数与已测probe_pair_transpose代码/ABI元数据同。EXACT/AE168候选帧全命中0.36golden，AE84行同44reuse/40refresh；C256回绕48帧同golden、AE24行同，每12帧实际24次reset、零回退/错误。RE9同一既有runtime两套module目录，两档各12帧末hash仍b2980ada643da964/758674a8bbd0206d，未换鬼武者。

C256持久化基线上两轮1000弃200 ABBA，完整NativeGameFrame wall：900 8.306088→8.117038（−2.276%）、8.314973→8.132057（−2.200%）；1080 11.206715→11.038179（−1.504%）、11.199951→11.023446（−1.576%）。MAKE_RESIDENT_EVERY60全程保留，尖峰测试未混跑；逐槽原始CSV独立复算，不能把微测8倍相加当整帧收益。

19:47备份后只装deep_fast-packed两份：gfx1200 1d816dc1、gfx1201 1750899d；宿主046e1a63、其他60模块与dxgi/ini/flags原SHA，总62模块。DIRECT_IO3/MAKE_RESIDENT60/SWIN_RUN1原样。备份 `D:\DLSSNR-Lab\hip-backend\vit-attention-20260929\backups\stellar-20260929-194730`；安装脚本带SHA检查/异常回滚/RestoreBackup。没发包、没启动游戏；GPU测试已结束。结果 `results/vit-attention-20260929`，脚本 `HIP/experiments/vit-attention`；三个编译宏默认0、生产recipe开1，无新用户开关。

## 2026-09-29：C512最终投影M32权重共用，逐位但整网变慢，负账

WorkingPlan B1 留下的未实测候选。改为不动宿主：`mh_attention_project_frag_c512` 同grid同ABI，宏 `C512_PROJ_M32`（默认0）开后每wave算两个16-token tile、共用每个K16权重片段，grid后半即返回。宏0与剑星现装模块.text/.rodata逐字节同；宏1 VGPR80→97、SGPR28→38、无LDS/spill。
逐位：EXACT/AE各168帧＋48帧回绕与现役（C256持久化＋ViT attention新核）逐帧同，AE决策同。
两轮ABBA：900 8.059→8.215、8.097→8.246（慢1.9%）；1080 10.983→11.042、10.972→11.044（慢0.5～0.7%）。权重在L2、不是带宽瓶颈，wave数减半把单wave WMMA链拉长一倍，900档token少吃亏更多。不收、不装。结果 `results/c512-proj-share-20260929`。

## 2026-09-29 21:xx：ViT QKV 五wave共享权重，逐位、1080过门槛，需换宿主未装

拆Daniel k_reg1d_qkv<0,0>：120组×256线程、每wave 32token×64列、权重进LDS、**fp8 WMMA + 每K32 half累加**，168VGPR。我方1-wave组每K16配3条b128 global读（1.5条/WMMA），主循环流水已紧，瓶颈是读取量。新导出 `vit_stream_qkv_frag_hin_w5`（宏HIP_VIT_QKV_W5默认0）：5wave同head五token tile（400/640的25/40 tile都整除5，无尾巴），权重8KB块LDS双缓冲，wave数不减，每条累加链/片段/尾部数学原样。微测640 48.8→37.0µs（Daniel 31.8）、400 32.2→26.5；数组写法/CH4/CH16都更慢，只留4寄存器CH8。只换模块的路：scale提前读、三种块重排全逐位但不快/慢5～8%。
逐位216帧（EXACT/AE 168＋回绕48）SAME；两轮ABBA 900 0.42/0.51%、1080 0.74/0.81%。需宿主按160线程发射（hip_reference_network.h 加HasFn自动探测，新旧互容），违反"宿主不动只换模块"，**未装剑星、未发包**，生产配方未开。结果 `results/vit-qkv-20260929`。

21:08 协调者批准换宿主：配方开W5，新add-on b77bbc3c、RE9 runtime 2c103f6e；复跑216帧SAME，一轮ABBA 900 −0.112ms(1.39%)、1080 −0.117ms(1.07%)；runtime三方hash同+smoke过。已装剑星（备份 hip-backend\vit-qkv-20260929\backups\stellar-20260929-210818，flags不变）与鬼武者（runtime两份+模块对齐剑星，备份 onimusha-backups\20260929-210818-vitqkv）。未发包。

## 2026-09-29 21:28：剑星 2K 原生 AA 55～56

现装宿主 b77bbc3c（深层紧凑 + 逐核地图两刀 + C256 持久化 + ViT attention 新核 + ViT QKV W5）。Zero 本机：2K 原生 AA、中画质（同之前）、EXACT **55～56**（0.36 为 54）。离线 900 约 8.5→8.0ms。

## 2026-09-30 00:xx～02:xx：900 档逐核地图 + HIP↔D3D 交接探针（分身）

**900 地图**：把 kernel-map 的 recorder patch 移植到 HEAD（recorder-v3），现役 flat-P（vit-qkv lab 31 模块）＋现役 flags 录 900/1080 各一帧（173/156 条 Run 派发；两段 C256 持久化 sp 在 Run 之外）。新增 9 个现役核类型；C256 PDL 四核消费端等待指针置 null（源码有空指针守卫）、生产端 flag 给零缓冲。Daniel 用 make-shallow/make-daniel-deep 筛 900-default（46＋108）。jobbench 7 轮中位，900 我方 173/Daniel 154/1080 我方 156 全部有效（1080 首批与交接探针同机混跑，整批作废重跑）。sp 用 HEAD 宿主加逐派发 hipEvent 估计（诊断补丁，输出 hash 不变）：事件法对每派发系统性 +43µs（173 项对照中位，p10–p90 25–54），sp 372/364 → 约 329/321µs。
结果：我方独立核和 7258.6µs（900 wall 8.03ms），Daniel 8171.6µs（含 42/43/46 288.9）。族：C32 +233、C64 +39、C128 −132、C256 −578、C512 同结构 +182、ViT −384（形状不同）。前五：c32 prefix 655、sp 650(est)、c32 post 604、c512_qkv_attention_compact 602（13 次）、c32 chain 498。900 独有：`mh_shift_pack` 13×9.9=129µs（50×30 非整窗压紧凑布局，1080 identity 无此步）。900/1080 比例多在 0.66～0.76；c512 attention 0.85（半满窗口）、ViT attention 0.30。候选：去 shift_pack（~0.1ms、逐位把握高）＞ C32 up/边界块（+64/+47）＞ C512 FFN 三核（+143，旧负账多）。

**交接探针**（`HIP/experiments/handoff-poll/handoff_probe.cpp`，同 D3D 时钟夹 HIP 段）：现行 fence 双向往返，HIP 7.4ms 时 mean 0.16～0.18ms、p50 0.12～0.16；无 HIP 对照 0.008。D3D→HIP 改 `WriteBufferImmediate`＋`hipStreamWaitValue32`：两轮 gap 7.587→7.532、7.599→7.546（−0.054ms），p99 不变差。HIP→D3D 改 `hipStreamWriteValue32`＋D3D 1 线程 compute 自旋：无界版 TDR（设备移除 0x887A0005），有界版 HIP 64MiB memset 0.03→~490ms（自旋占住调度，HIP 排不进）——Daniel 用 1 像素 draw 分片自旋就是为此。本轮两半合做未完成，按门槛（avg ≥0.1ms）不收：未改生产代码、无新开关、未装机、未发包，剑星保持 b77bbc3c。结果 `results/kernel-map-900-20260930`、`results/handoff-poll-20260930`。

## 2026-09-30 00:30～00:45：去掉 900 档 C512 的 mh_shift_pack（分身）

900 的 C512 网格 50×30=1500 不是 16 倍数，`CompactC512Body` 每块 `mh_shift_pack` 拷进补零到 1504 的缓冲（13 次 129µs）。查实 C512 块五个核全部按 token 行独立（WMMA A 行 = token；attention 只按有效 (x,y) 读写；投影 crop 跳过 y≥h），补齐行内容不影响有效输出——于是不改核，改宿主分配：Down(c256)、Up(oc512)、C512 块输出都按 16 对齐分配（`NewPad16`，bytes 仍记有效大小），`CompactC512Body` 见输入容量够就原地读，不够照旧 pack（回退）。宏 `HIP_C512_PAD16` 默认 1，诊断宏 `HIP_C512_PAD16_POISON` 把补齐行每帧写 NaN。

逐位：P 与 POISON 各 7 用例 × EXACT/AE × 12 帧、AE CSV 同，Proll/Pproll 回绕 900/1080 history × 两模式同，36 组 SAME。ABBA 900 8.030→7.918（1.40%）、8.031→7.942（1.11%）；1080 +0.08%/−0.10%（噪声）。新宿主 62803606，RE9 runtime be828151（900/1080 hash 与旧 runtime 同，smoke 过）。装剑星（只换 add-on，flags 原样，备份 `...\shift-pack-900-20260930\backups\stellar-20260930-004205`）与鬼武者（runtime 两份，备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-004205-shiftpack`）。未发包。结果 `results/shift-pack-900-20260930`。

## 2026-09-30 02:53：鬼武者 2K 质量稳定 60

宿主/runtime 62803606 / be828151（0.37 + 900 去 shift_pack）。Zero 本机久玩：2K 质量（900 档）中画质稳定 60，GPU 占用 90～95%、从未满载。

## 2026-09-30 03:45：C32 块 4 skip/下采样改存 E4M3 字节（逐位，两档过 0.5%，已装）

对齐 Daniel `k_reg_swin32<8>/<4>`：up 与块 4 边界多出来的主要不是指令而是数据格式——块 4 的 main（只给块 66 up 当 skip）和 dcrop 下采样按 f32 存，值却是 `F(v)`（E4M3 精确、无 −0）。新导出 `c32_wave1_finish_dcrop_b8d`/`c32_wave1_up_b8`（`CW_SKIP_BYTE`）与 `mh_pool_project_c32_b8`（`HIP_POOL32_B8`），源码默认 0、配方开 1；宿主 `HIP_C32_SKIP_BYTE/DOWN_BYTE` 默认 1，按 `HasFn`＋同一 `C32UpBodyPath()` 判断回退。up 的低分辨率输入是 half 语义（Daniel 用 FP8）属有损，不追。

逐位 18 组 SAME（7 用例 × EXACT/AE、AE CSV、回绕）。ABBA 900 7.9101→7.8612（0.62%）、7.9332→7.8831（0.63%）；1080 10.8614→10.7739（0.81%）、10.8828→10.7918（0.84%）。装剑星（add-on a80db313＋c32-wave1/mh-fast 两架构，flags 原样，备份 `...\c32-align-20260930\backups\stellar-20260930-034433`）；RE9 runtime fd4b2c0c（900/1080 hash 同、smoke 过）；鬼武者 runtime＋模块对齐，备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-034433-c32`。`results/c32-align-20260930`。

小件：C32 对角残差跳零（`CW_DIAG_ONLY`）在 wave-owned 核上重做，逐位，900/1080 各 −0.02～−0.03ms（0.22～0.28%），不过门槛；C256 FFN `HIP_FFN_PK_ACT 1` 逐位但测不出收益（激活写 hidden 逐字节是布局所致，要改得转置 expand，非小件）；ViT QKV 归一化换 bpermute 求和改变累加顺序不能逐位。三项合并 0.26～0.35%，均不收。`results/small-cuts-20260930`。

## 2026-09-30 08:01：C32 对角残差跳零开进生产（Zero 批准）

配方 c32-wave1 加 `CW_DIAG_ONLY 1`。在 a80db313 现役配方上 18 组 SAME（EXACT/AE 168 帧、AE CSV、回绕）；一轮 ABBA 900 −0.007ms（0.09%，噪声内）、1080 −0.038ms（0.35%）。只换 c32-wave1 两架构（30c3d107/ba026a91），宿主 a80db313 / runtime fd4b2c0c 不变；剑星、鬼武者已换，备份 `...\c32-align-20260930\backups\stellar-20260930-080147-c32skip`、`D:\DLSSNR-Lab\onimusha-backups\20260930-080147-c32skip`。`results/small-cuts-20260930`。

## 2026-09-30 08:18：本机验收（a80db313 + C32 对齐 + 跳零）

Zero：剑星 2K 原生 AA EXACT **56**（黄字 55.6～56.1，此前 55～56 偶尔 56）；鬼武者 2K 质量（900）稳定 60，GPU 约 95%。

## 2026-09-30：交接两半 GPU 同步——HIP→D3D 分片自旋反而更慢，交账

静态拆了 Daniel 0.5.1 的 HIP→D3D 半程（`SpinDraw=1`、`PredSlices=64`、`InlineWaitMs=200` 钳 50～5000；1 像素 PS 原子读标志 + 隔几次读 abort word，predication 跳过剩下的分片；超时就把这帧标脏、显示上一帧残差，预算自适应，主机看门狗写 abort；没有退回 fence 的路径）。在探针里加了 mode 6/7。mode 6（HIP 走 fence 等）每帧都超时：D3D 一开始自旋，HIP 就排不进来（`PROBE_PRESYNC` 证明标志是可见的）。mode 7（两边都轮询）不会饿死，但 HIP 7.4ms 这档 gap 7.61～7.68ms，mode 3（仅 D3D→HIP 轮询）是 7.50～7.51，fence 双向是 7.59～7.60；p99 也更差。mode 3 下交接≈0，剩下的时间是上下文切换，自旋省不掉。D3D→HIP 轮询单独省 0.05～0.08ms，不过线。没改生产代码、没加开关、没装机、没发包；剑星 a80db313、鬼武者 fd4b2c0c 都没动。`results/handoff-gpu-20260930`。

## 2026-09-30：1080 档紧凑几何 1088 行（可选档、有损、默认不开）

Zero 同意做成选项。新开关 `DLSS5_NETWORK_1080_ROWS=1088`（默认 1152；`DLSS5_NETWORK_HEIGHT=1088` 同义固定档），1080 档按 1920×1088：1080＋8 行反射，/32 级 60×34，ViT 沿用 32×20 网格、有效 30×17，post 位移仍 3。1088=2⁶×17，与 900 档 960 同属 2⁶，各级整除，只改宿主几何门（`native_network_geometry.h`、`hip_reference_network.h` 四处、`native_post70.h`、runtime flags 白名单），模块不变。
- 默认逐位：7 用例×EXACT/AE×12 帧＋回绕 18 组 SAME；RE9 runtime 默认 1080/900 hash 与 09-29 同。1088 快路径与 SWIN_RUN=0/WAVE_OWNED=0 旧路径逐帧同（几何处理自洽），SWIN_RUN 在 1088 下生效无回落。
- 整网 ABBA 1152→1088：10.736→10.261（−0.474ms，4.42%）、10.764→10.283（−0.481ms，4.47%）。比估的 0.70ms 少：ViT 仍 640 token，只省 Swin/解码器的行。
- 画质（bench 1296×720 输出，对 1152）：全帧 56～57dB（8-bit 54～55.5），最大单点 20～48/255、几十个像素、都在画面中部；底 32 行 52.5～55.6dB 略差，顶边与中部相当。
- 与 Daniel 差异：他 1088＋post 位移 0（两处偏离），我们只动行数。产物 `D:\DLSSNR-Lab\geom1088-20260930\`（add-on aa74b20b、runtime 2d561e2d），未装、未发包。`results/geom-1088-20260930`。

## 2026-09-30：D3D→HIP GPU 轮询进生产代码（新验收规则）——逐位，但整帧慢，不收

Zero 改了验收规则：小改动只要逐位、离线 ABBA 为正、p99 和另一档都不变差就收，0.5% / 0.1ms 门槛取消。按新规把 D3D→HIP 这一半做进 `hip_d3d12_bridge.h`，开关 `DLSS5_HIP_INPUT_POLL`，默认 0；add-on 和 RE9 runtime 共用这份桥接头。取 1 是每帧单独提交一条 marker 列表，取 2 是把 marker 录进输入拷贝列表；两种都有启动自检和 200ms 看门狗，出问题就退回 fence。两种模式都是 18 组 SAME。但完整帧回放两档两轮 avg 都慢 0.01～0.04ms（探针里单独测省的 0.05～0.08ms 在整帧里兑现不了），所以不收、不装，模板没动，10 分钟长跑没跑。WorkingPlan 的验收段已改成新规；交接这条线停。`results/handoff-gpu-20260930`。

## 2026-09-30 产品侧：颜色格式兜底 + flags 热重载（参照 mochizuki 0.0.2.4，未装机）

- 兜底表 `native_format_fallback.h`（只在原表说不时才查）；add-on pre-upscale 用转换 pass `native_format_convert.hlsl` 转私有 RGBA16F 再走原路线，RE9 runtime 走 RGB9E5 的私有 FP16 路线；拒绝日志带格式名；post/Magpie/XeSS 路线不覆盖。开关 `DLSS5_FORMAT_FALLBACK`（默认 1）。
- 热重载 `native_hot_flags.h`：STRENGTH/NOTICE/SHOW_FPS，每秒比时间戳，默认开；网络/模块类不热改；RE9 不适用。
- 9070：HEAD vs 新宿主 168 帧（7 用例×EXACT/AE×12）全 SAME＋AE CSV 同；RE9 runtime RGBA16F 900/1080 hash 同（b2980ada/758674a8）；10 种新格式经 RE9 runtime 过整网出图，旧 runtime 全拒；转换 pass 14 格式与 CPU 解码差 ≤1 half ULP（驱动截断）。
- 插曲：第一次跑 rt_fmt 报 native_codec_encode.hlsl not found——runtime 只在 DLL 旁 `shaders\` 找，LMXXF_SHADER_DIR 不管用；convert_smoke 初判 FAIL 是容差按 RNE 半 ULP 写的，驱动 f32→f16 存储截断，放到 1 ULP 后全过。
- add-on 8b729f22、RE9 runtime 99c8ead9，产物 `D:\DLSSNR-Lab\product-fmt-20260930\`。详见 `results/product-fmt-reload-20260930`。

## 2026-09-30：Infinity Cache / scratch arena 先量（交账，不收）

宿主已有生命周期池（pooled，best-fit 复用），900/1080 只用 30/19 个激活缓冲，占 243/291MB。单派发最大读写集合 141/203MB，全在 C32，所以 arena 的下界也超过 64MB MALL。C64 以下各段复用距离已≤64MB（LRU 模型 0.86～1.00），C32 为 0.56/0.28。Windows 没有计数器，用对照实验：`HIP_POOL_HOT=1` 优先复用最近用过的空闲缓冲，逐位 18 组 SAME，ABBA 900 +0.009/+0.011ms（慢），1080 −0.007/+0.000，不收。生产代码未改，补丁留在 `experiments/infinity-cache/pool-hot.patch`；没装机。`results/infinity-cache-20260930`。

## 2026-09-30：旧 0.5% 门槛淘汰的小正收益件重测，I+P+O 收下装机，Q 不收

按新规（逐位＋ABBA 为正＋p99/另一档不拖累）重测 mochizuki-022 的 I/P/O/C 与 c32-round3 的 Q，在现役 a80db313＋31 模块上重做为新宏（默认 0，默认编出与现装逐字节同）：`CW_INPUT_HALF 7`（post/mapped/新增 up 三处去 `float((_Float16)v)`）、`CW_PREFIX_HALF_SOURCE 1`、`C512_MIX_OCC_LDS 4096`、`VIT_CONTRACT_OCC_LDS 4096`；Q 用现存 `CW_POST_FULL_TILE`。五个候选全逐位（各 19 组 SAME）。ABBA：Q 1080 一轮 +0.0015ms 不收；O 两档两轮 −0.007～−0.019ms；I、P 单独在噪声内；C=I+P+O 900 −0.026/−0.029、1080 −0.016/−0.028ms，p99 不变差，收。配方直编 final 与候选 .text 同，再确认一轮 900 −0.030、1080 −0.016ms。只换 c32-wave1/c512-m32-deep/vit-stream 两架构（gfx1201 77d163c8/8e84f7c0/fef8a768），剑星、鬼武者已装（备份 `stellar-20260930-101608-smallwins`、`onimusha-backups\20260930-101608-smallwins`），宿主/runtime/flags 不变。补搜只多出 mhfast-wide-frag（需改宿主打包器，未重做）。详见 `results/small-wins-retest-20260930`。

## 2026-09-30：复合量化 FP8(Hrtz(x)) 换成整数掩码，逐位，收下装机

闇提出的假设：`f32→f16(RTZ)→E4M3` 能否不经中间转换直接从 float 位算。盘点最热两处都在 `wave_owned_mh.inc`（W2 注意力字节出口 ~180M、FFN contract ~165M，按"值数×转换指令"）。half RTZ 在正规段就是截低 13 位，所以 `Q8(bits&0xffffe000)` 保留两次舍入、只省 f32→f16→f32 往返。CPU＋GPU（真实指令）全部 2³² 穷举：只在负 |x|<2⁻²⁴（符号）和 8191 个 +NaN 载荷上不同；WMMA FP8 累加值是 0 或 2⁻¹⁸ 的倍数，进不来。直接一次舍入与原式在域内有 1,032,066 处不同，half 舍入不能删。新宏 `W2_Q8_MASK`（默认 0，c64-wave2/swin-persistent 配方 1），19 组 SAME；三轮 ABBA avg 900 −0.005～−0.016、1080 −0.003～−0.022ms，p99 单轮来回跳、三轮合并不差，按新规收。剑星＋鬼武者已装（备份 `…\composite-quant-20260930\backups\stellar-20260930-104107-q8`、`onimusha-backups\20260930-104107-q8`）。C32 两处域不纯（res·w），不做。`results/composite-quant-20260930`。

## 2026-09-30：C512 FFN 按 W5 组织（同组 wave 经 LDS 共用权重）——单核 900 变慢，停

闇第 ③ 条。先拆 Daniel `k_reg_vit_ffwd`：**1 wave 一组、LDS 0、无 barrier**、80 VGPR，grid (104,8)，一核做完整 FFN，hidden 就地转 FP8 在寄存器里，FP8×FP8 WMMA 每条配一条 b64——他快在数据形态和三核合一，不在组内共享。原型只做最重的 `split_mix_blocked_h16w_m32`：G=4/2 个 wave 同组同列块，每 wave 仍 32 token，half 权重 8KB 分块双缓冲进 LDS（宏 `C512_MIX_LDS_G`，默认 0 编出 .text 与现装同）。10 组逐字节同；单核三批：900 现役 15.34µs，五个变体全慢（最好 +1.2%）；1080 20.9～21.2 → G=4 最好 19.7～20.3，批间排名不稳。权重本在 L2、A 仍是 f32 占一半以上请求，900 只 47 片摊 64 CU 不匀。按任务单停，不写宿主、不装机。`results/c512-ffn-lds-20260930`。

## 2026-09-30 11:25：C256 FFN 权重 16 字节片段读取（逐位，已装）

09-23 mhfast-wide-frag 搬到现役 `swin_wave2_body`：宿主 `HIP_C256_FFN_W16`（默认 1）另打 `@ffn-frag-w16` 宽片段布局，核宏 `W2_FFN_W16` 只新增 `c256_wave2*_w16`、`sp_run256_w16`/`sp_recover256_w16` 导出，宿主 `HasFn` 有才用——新宿主＋旧模块、旧宿主＋新模块都回旧行为（各 19 组 SAME）。W 19 组 SAME；持久化 `SP_PLAN ... w16=1`、非持久化 `W2_C256 c256_wave2_bo_w16` 两路实证。三轮 ABBA 900 −0.011/−0.025/−0.017ms，1080 −0.030/−0.015/+0.003ms，p99 三轮合并两档不差，收。add-on bb7ebfd1（7ca25c98＋补丁）、RE9 runtime 88b59744（900/1080 hash 同、smoke 过）、c64-wave2/swin-persistent 两架构；剑星、鬼武者已装，备份 `...\c256-w16-20260930\backups\stellar-20260930-112518-c256w16`、`D:\DLSSNR-Lab\onimusha-backups\20260930-112518-c256w16`。`results/c256-w16-20260930`。

## 2026-09-30 11:37：复合量化推广 C512 `F(Hrtz(acc))`（逐位，已装）

`C512_F_MASK`：mix（split_mix_blocked_h16w_m32）与 contract（split_ffn_fused_fp8_t8）出口 `F(Hrtz(x))`→`F(bits&0xffffe000)`。F 对 |x|==0 给 +0，唯一差异是负 0<|x|<2⁻²⁴（+0 vs −0）与 8191 个 +NaN；CPU/GPU 2³² 穷举 other=0、GPU 对模型 0 不符。域：contract 是 E4M3×FP8 和；mix 输入是 F 输出（E4M3），half 权重 16 块最小位 2⁻⁹（依赖权重数据），乘积都在 2⁻¹⁸ 格点。ViT 出口乘过 inv，不做。19 组 SAME；三轮 ABBA 900 −0.029/−0.011/−0.012、1080 −0.018/−0.010/−0.006ms，p99 合并不差，收。只换 c512-m32-deep/deep_fast-packed 两架构（gfx1201 6FC2F5BE/2764240B），宿主/runtime 不变；备份 `...\composite-quant-c512-20260930\backups\stellar-20260930-113745-c512mask`、`D:\DLSSNR-Lab\onimusha-backups\20260930-113745-c512mask`。`results/composite-quant-c512-20260930`。

## 2026-09-30 C32 prefix/post 大核重新分账 + 两处 f32→E4M3 字节（`results/prefix-post-20260930`）

按现役模块 jobbench：prefix 900 659µs/1080 940µs、post 596/859µs；读写 148/141MB（900），按 640GB/s 访存下限 230/221µs，实测是下限 2.7～2.9 倍——算力核（VGPR 129～134、占用 8，不是瓶颈）。盘点两核张量：能逐位改窄的只有 block0 down（block1 读）与 block69 main（post 读），都是 `F(v)`；rgba/history 只经 Hrtz 用但改需 D3D 端、post 输出 half 依输出格式有损，记账。`CW_PREPOST_BYTE`（新增 prefix_b8d/mapped_b8/finish_b8/post_b8，原导出反汇编同）＋宿主 `HIP_C32_PRE_DOWN_BYTE`/`HIP_C32_POST_LOW_BYTE` 默认 1 带回退；首次漏了 Run 的 32 线程白名单导致 719，已补。逐位 X/F1/F2 全 SAME（F1 首跑 720 一帧偶发，重跑 SAME）。三轮 ABBA 900 −0.009/−0.024/−0.019、1080 −0.017/−0.021/−0.025ms，p99 合并 900 更好、1080 持平，收。单核：prefix −13µs、finish69 −6µs、mapped/post 约 0（900）。装剑星 add-on 6d059845＋c32-wave1（301d3e16/88e9b8a9），RE9 runtime 5e601d57（hash 同、smoke 过），鬼武者对齐；备份 `...\prefix-post-20260930\backups\stellar-20260930-121025-prefixpost`、`D:\DLSSNR-Lab\onimusha-backups\20260930-121025-prefixpost`。

## 2026-09-30 C32 prefix/post 按算力拆账 + prefix 字节尾向量化（`results/prefix-post-arith-20260930`）

按指令族×循环次数拆每窗口动态条数：prefix 7923 条（WMMA 304、VALU 4987、SALU 788、等待 680），post 6794（WMMA 288、VALU 4544）；转换族最大（prefix 1560）。热段前列是与 chain 共用的注意力/隐层/QKV（已挖过），prefix 独有的是尾部逐字节写：main 16 次循环 608 VALU＋336 SALU＋64 ds_load_u16＋64 store_b8、down 410 VALU（每值 15 条转换）。对 Daniel 同位核 `k_reg_swin32<20>`/`<32>`：他尾部 4×b128＋2×b64；其余差在他 f16 域成对算术（pk_mul/add/fma/max/min、fma_mix），属 fast 语义不照搬。`CW_PREFIX_TAIL_VEC`：lane 管 8 连续通道，ds_load_b128＋cw_pack8（MODE 饱和，与 site 2 同论证）＋8 字节写，down 用 fp8(F(x))≡fp8(x+0)（x 有限 half）。尾部 VALU 1018→514、SALU 390→71、store 80→10，但 ht 循环重排多 ~96 VALU；整核每窗口 7923→6745 条。宿主不变，19 组 SAME；三轮 ABBA 900 −0.046/−0.040/−0.040、1080 −0.065/−0.072/−0.074ms，p99 全变好，收。post 输入 Hrtz 成对（gfx12 读高半需 lshr，净 0）、掩码（域不纯）不做。装剑星 c32-wave1 3f9cdd24/00b1d536（add-on 6d059845 不变），鬼武者对齐，RE9 runtime 5e601d57 不变；备份 `...\prefix-post-arith-20260930\backups\stellar-20260930-123126-pparith`、`D:\DLSSNR-Lab\onimusha-backups\20260930-123126-pparith`。

## 2026-09-30 字节写出尾巴向量化推广（tail-vec）

全网扫逐通道字节尾巴：只剩 C32 `finish_dcrop_b8d`（block4）与 `finish_b8`（block69）；C64～C256、chain/mapped/up 已是每 lane 8 连续通道宽写，旧 multihead/deep 字节出口是 WMMA 列布局（需转置，非同类）。新宏 `CW_FINISH_TAIL_VEC`（配方 1）：每 lane 8 通道 ds_load_b128＋cw_pack8＋8 字节写，逐像素边界保留。逐位 19 组 SAME；三轮 900 −0.038～−0.046、1080 −0.043～−0.055ms，p99 全好。已装剑星/鬼武者，c32-wave1 8e47b814/fd8fed73，宿主与 RE9 runtime 不变。`results/tail-vec-20260930`。

## 2026-09-30 multihead/deep 字节出口 LDS 转置宽写（deep-tail）

按热度排旧"每 lane 一列"字节出口：ViT QKV w5（8 次/帧 213µs，16×b8/lane）、C512 `split_ffn_fused_fp8_t8`（13 次，8×b8）、`vit_expand_blocked_fp8_frag_bytein`（63×b8）、C256 fused FFN/QKV（9×b8）、`split_projection_frag`（13 次，32×b8）；ViT attention 生产版已是 2×b64，decoder byteout 冷。做两刀：V = QKV w5 字节先写本 wave 空闲 norm tile 再每 lane b128；S = C512 两核分块 E4M3 副本（两块相邻 512B）LDS 摆好后 b64/b128 宽写（各加 1KB LDS）。两者逐位 19 组 SAME。三轮 ABBA：V 符号不一（合并 1080 +0.005ms）不收，宏 `VIT_QKV_TAIL_VEC` 默认 0；S 六个全正（900 −0.008～−0.009、1080 −0.005～−0.028ms），合并 p99 两档变好，收 `C512_T8_TAIL_VEC 1`（deep_fast-packed 配方）。装剑星/鬼武者（deep_fast-packed 7ffaa65f/ebc7df69），宿主/runtime 不变。9070 D 盘满，清了两个已交账 lab 的帧转储。`results/deep-tail-20260930`。

## 2026-09-30 下午：9070 D 盘清理 + 剩余两个字节出口（均不收）

- **D 盘清理**（`results/lab-cleanup-20260930`）：hip-backend 592GB 里有 559GB 是 .f16/.ppm 逐位帧转储。删掉已交账实验子目录里的这些文件，共 486.7GB（1261 个子目录，清单见 csv），backups/assets/capture、fma 相关、deep-tail 以及 lab 根文件都没动。D 盘从 35GB 空闲变成约 527GiB。删完用现装 31 模块做了 A 对 A 全回归，168 帧对 `new-baseline-hashes.csv` 全部相同。
- **ViT expand 字节出口 E / C256 FFN/QKV Q**（`results/deep-tail2-20260930`）：两个都是 19 组 SAME。E 在 900 三轮稳定慢约 0.012ms；Q（LINE_STORES＋填充零块宽写）在 900 三轮是 +0.010/+0.002/+0.002。都不收，不装。C256 那 9 个 b8 其实在填充零块的冷路径上，主输出早就是 b64。列布局字节出口这条线做完。

## 2026-09-30 下午：逐核地图 v3 + C512 V 转置（朱雀）

**地图 v3**：HEAD 宿主 + recorder patch（手工重打第 2 块，W16 错位）、现装 31 模块录 900 160 / 1080 156 条，新增 10 个类型（C32 七个字节导出、C256 三个 _w16）；jobbench 316 条全有效；sp 用事件法减偏差（42.9/45.4µs）。独立核和 900 6894.8µs（今晨 7258.6），1080 9970.7（5 个间歇慢派发，按中位数修正约 9762）；整网回放 7.615 / 10.436ms。前 5（900）：sp_run256_w16 636、c512_qkv_attention_compact 615、prefix_b8d 594、post_b8 588、chain 483。候选：C512 V 转置、W16 推到 C64/C128、C512 AV 去 F。结果 `results/kernel-map-v3-20260930`。
**C512_COMPACT_VT**：V 按 [channel][token] 写 LDS，P·V 片段一条 8 字节读。静态 ds_load_u8 64→0（+32 ds_store_b8），19 组 SAME。三轮 900 −0.0040/+0.0001/+0.0036、1080 +0.0023/−0.0015/−0.0142ms，合并 900 7.6787→7.6786、1080 10.5012→10.4967，p99 不变差；900 不全正，不收，未装。`results/c512-compact-vt-20260930`。

## 2026-09-30 下午：W16 宽权重片段推广到 C64/C128（朱雀子代理）

B13。`W2_FFN_W16_SMALL`（bit0 C64/bit1 C128，默认 0）只加 `c64/c128_wave2*_w16`、`*_up_w16` 导出；宿主 `HIP_SMALL_FFN_W16` 有导出才用宽布局。静态 global_load 约 −6%。W64/W128/W3/F1/F2 以及 origin/main 宿主 H（最新源码现路径）各 19 组 SAME，诊断宿主打印五个 `_w16` 路径。ABBA 三轮：C64 900 +0.005/−0.010/+0.003、1080 −0.012/+0.001/+0.000；C128 900 −0.016/+0.004/−0.003、1080 −0.010/−0.009/−0.001。900 都不全正，按止损不收，未装。小宽度权重已在缓存内，少 load 不兑现。`results/w16-c64-c128-20260930`。

### 2026-09-30 C512 QKV-attention 去 F＋有界倒数（`results/c512-av-f-20260930`）
候选 14 扩成一个候选：AV 出口 `c5c_fp8(c5c_F(av))`→`c5c_fp8(av)`（P·V WMMA 从 +0 累加，不会出 −0；探针 8.6e9 结果 0 个 −0，V 含 0x80 的情况也覆盖了）；QKV 出口 `q8(F(y))`→`q8(med3(y+0))`（2³² GPU＋CPU 穷举 0 处不同，mul 与 +0 之间关闭乘加合并，ISA 已核）；softmax `1.f/sum`→rcp＋两步 Newton（sum∈[1/256,624]，144M 个除数逐位）。宏 `C512_COMPACT_NOF`/`C512_COMPACT_RCP`，配方都开。compact 核 1932→1545 条。19 组 SAME；三轮 900 −0.028/−0.018/−0.029、1080 −0.028/−0.023/−0.034ms，p99 合并两档都更好，收。装剑星/鬼武者 c512-m32-mh 0F28A38C/3BDB80CC，add-on 6d059845、RE9 runtime 5e601d57 不变；备份 `...\c512-av-f-20260930\backups\stellar-20260930-150412-avf`、`D:\DLSSNR-Lab\onimusha-backups\20260930-150412-avf`。

### 2026-09-30 F/往返/精确除法清理扫全网（`results/f-sweep-20260930`）
把 c512-av-f 的清理扫遍现装 31 模块：还剩 5 处、4 组（D deep_fast-packed 的 byte_F＋decoder 字节＋ViT attention 1/sum；V vit-stream QKV byte_F；M padded-wave-packed q8_fused_round；W c64-wave2/swin-persistent up 字节）。`fp8(F(x))`→`fp8(med3(x+0))` 两种 F 各 2³² 穷举 0 差；ViT sum ⊂[1/256,2048]，rcp＋2 Newton 全区间 0 差。4 组都 19 组 SAME。三轮 ABBA：D 900 −0.014～−0.038、1080 −0.011～−0.028，合并 p99 两档更好，收（配方 `HIP_BYTE_F_ADD0 1`、`HIP_VIT_ATTN_RCP 1`，静态指令 72963→67189），已装剑星/鬼武者 deep_fast-packed EEC7D4A6/54D388A7。V（900 三轮 +0.003）、M（1080 三轮 +0.007～+0.015）、W（混）不收，宏默认 0。float 出口 F、输入侧 F(skip) 证不出/不冗余，跳过。

## 2026-09-30 19:43：正确性验证通过（0.37 后 14 刀全装）

Zero（Splashtop，只作正确性）：剑星 2K 原生 AA EXACT 55.6～56.1，鬼武者 2K 质量 60、GPU 约 95%，画面无异常。

## 2026-09-30 20:30：对 NVIDIA 原版同口径画质（mochizuki ngx-verification 单帧）

用 mochizuki 0.0.2.5 公开的 Tomb Raider 单帧输入与 5090 原版输出（8-bit RGB PSNR）。先用他的 PNG 复算，45.56/47.99/49.06 dB 与公布值一致。运动序列他只发了数字、没发 NVIDIA 输出，无法复测。
发现发布网络预处理常量写死 Style=1（特征 `.0078125`=style/128），NVIDIA/他跑 Style0：发布模块原样 24.06 dB。测量版只把该常量改 0 重编（HEAD 未改版重编与现装逐位相同），1080p：全 71 块 **47.43 dB**（mochizuki 45.56），发布配方跳 42/43/46 **44.26 dB**，跳块损失 3.17 dB；AE 单帧与 EXACT 逐位同。1440/4K 我们缩到 1080 档跑，33～36 dB 由几何主导。未改生产、未装机。`results/fidelity-ngx-20260930`。

**HIP 段 roofline（09-30 晚，只测只算）**：TheAutomatic 问纯 HIP 延迟离理想多远。`DLSS5_HIP_SPAN_PROBE=1`（须写进 flags 文件，benchmark 会重置环境变量）+ 现装 31 模块：HIP 段中位 900 **7.256** / 1080 **10.065ms**；逐核独立和（v3 + 两个新模块重测）6.827 / 9.701，输出 D2D 0.035 / 0.045，空隙 0.395 / 0.319（≈2µs/派发）。bw 实测 DRAM 读 ~620、写 ~600、D2D ~570GB/s，MALL 内 1.2～2.6TB/s。模型（2.75GHz → FP8 360 / FP16 181 TF）：算力下限 2.16 / 3.09、访存下限 1.55 / 2.11 → 理想 2.16 / 3.09（实测 3.4 / 3.3 倍）；WMMA+VALU 不重叠的现实理想 4.19 / 6.01（1.7 倍）。差距大头 C512（≈3 倍）、ViT（≈2.5 倍），C32 VALU 限，访存不卡。事件法逐派发在 PDL 下失真，不能拆空隙。`results/hip-roofline-20260930`（末尾英文摘要）。

## 2026-09-30 晚 fill-cu：C512/ViT 填满度（朱雀）

- 截 grid 扫描：C512/ViT 各核一轮全驻留，无经典尾巴；延迟型核单 WG 占 45～92%，是串行链不是填满度。尾部空转上界每档 0.03～0.05ms（split_ffn、ViT qkv_w5/expand）。
- N-split（mix/proj 每 wave 32 列）与 mix K 流水：逐位但反慢/噪声，不收。decoder skip 预读：不全正，不收。
- 收 `HIP_C512_HOIST_RES 1`（attn-project 残差 33 对串行读等外提）：19 组 SAME，三轮 900 −0.022～−0.031、1080 −0.026～−0.035ms，p99 变好；已装剑星/鬼武者。`results/fill-cu-20260930`。

## 2026-09-30 晚 hoist-loads：串行读等扫全网（朱雀子代理）

- 扫现装 31 模块热核的 ISA：真串行集中在条件读（每个 `if(越界) 读` = 一分支一读一等）。wave2 C64/C128 输入暂存 8 段、up 37～50 段；C32 up_b8 33 段（还有逐元素的 upw/fw 缩放 b32）；swin-persistent 同 wave2；C32 prefix/post 等多是已成批的循环体，不是真串行。
- 收 `W2_HOIST_LOADS 15`（c64-wave2）与 `CW_HOIST_UP 3`（c32-wave1）：越界下标夹到合法地址，先读后 select。各 19 组 SAME；合并确认三轮 900 −0.043～−0.044、1080 −0.066～−0.072ms，p99 900 7.872→7.820、1080 10.747→10.690。swin-persistent 同宏 900 第 3 轮 +0.006，不收。
- 22:39 装剑星/鬼武者（只换两个模块，add-on、flags、鬼武者 runtime 不动）。`results/hoist-loads-20260930`。

## 2026-09-30 深夜：压核间空隙（gap-fusion），两刀逐位都不收

列两档派发：短核 900 60 个/638µs、1080 31 个/316µs，可融合对大多已在负账（mix→FFN、ViT pack/byte 出口、C512 PDL 功耗回吐）。G：两个 vit_gather 折进 head Down 尾与 decoder39 头（−2 派发），19 SAME，900 三轮全慢 +0.004～+0.011，不收。T：C512 t8 删无读者 f32 contract 写出，19 SAME，900 六轮 −0.021～−0.036，1080 六轮有一轮 +0.008、合并 p99 +0.003，不收。宏默认 0、宿主 `HIP_VIT_GATHER_FOLD_HOST` 默认 0，未装机，派发数不变。`results/gap-fusion-20260930`。

## 2026-10-01 凌晨：竞品网络同机同口径实测（只测）

- mochizuki 0.0.2.5 Windows：编他的离线 bench（`nr_graph` + box64 跑钉死的 glslang 16.5 + `make_native_plan` 出计划），复现自报 7.79（实测 7.81～7.86，1920×1088）；900 档 1600×960 **6.02ms**，4K 29.46。我们 span：900 7.27/7.34、1152 10.05/10.10、`ROWS=1088` 9.65/9.67。**同几何他快 1.3（900）/1.8（1088）ms，约 17～19%**，他还不跳 42/43/46；口径（连跑 500 帧一次提交）偏他，量级不够解释差距。
- Daniel 0.5.1：无离线 bench，不进游戏只能 jobbench 逐核（0.5.0 调度结构换 0.5.1 代码对象，swin_run/v1dl 测不了）：ref 900 8.21、fast 900 7.03、ref 1088 10.16、fast 1088 8.42ms（逐核和）；0.5.0 同 harness 8.20 复现 09-30 的 8.17。估整网：reference 比我们慢 0.2～1.3，fast 900 持平、1088 快 1.0～1.6。
- 游戏目录未动（state=ours）。`results/competitor-timing-20260930`。


## 2026-10-01 mochizuki 逐族对账 + C512_COMPACT_FUSEQKV（光派单，子代理）
用他 nr_graph 自带的 `--per-layer --dispatch-grid` 在 9070 上跑逐派发计时（900 5.90/5.92，1088 7.77ms），和 kernel-map-v3 按族对齐：900 差 C512 +499µs（单块 100.8 对 52.3，他 16 块我们 13 块）、派发空隙约 +300、C32 +225、C256 +107、C64 +79、C128 +74、ViT −38。C512 attention 的网格和 wave 数和他相同，差在他 Q/K/V 在一个 k 循环里 6 个累加器、X 只读一次，越界判断在循环外；我们分三趟。照他改成 `C512_COMPACT_FUSEQKV`：19 组 SAME，900 −0.022/−0.023/−0.030、1080 −0.078/−0.091/−0.094ms，p99 两档更好，收下，装剑星/鬼武者 c512-m32-mh（1201 FEEDC842 / 1200 9C4A4642）。下一步：C512 FFN 按 ffwd3 寄存器转置一核化；投影残差改字节。`results/mochizuki-gap-20261001`。

## 2026-10-01 D3D↔HIP 共队列可行性（光派单，子代理）
新探针 `HIP/experiments/same-queue/switch_probe.cpp`：游戏 DIRECT 队列把显存填充交给不同执行者做 K 次往返。4096MiB K=1 over（gap−工作）：同队列 0.014；第二条 D3D COMPUTE 队列 0.21～0.28（p50 0.17～0.25）；第二条 D3D DIRECT 0.20～0.22（p50 0.16）；HIP fence 0.38（p50 0.165，长尾一帧 7.6）。K=8 斜率三者都 ≈0.09ms/往返。**交接代价是队列间同步，不是跨 API**：同一 D3D 设备换条队列一样贵，只有录进同一命令流才免。mochizuki 省掉它是因为要求 vkd3d-proton，把网络录进 vkd3d 的 VkCommandBuffer（同一 VkQueue）。路线：D3D12 compute 重写缺 WMMA/FP8 公开通路且难逐位；Vulkan 互操作在原生 D3D12 下仍两队列；HIP 共享 D3D 队列无接口。可省上限 ≈0.15～0.19ms，整帧兑现估 0.05～0.15。结论：停线，网络外的钱转去拷贝/编解码瘦身。未改生产、未装机。`results/same-queue-20261001`。

## 2026-10-01 C512 跨块就绪队列（P）上限探针：负
编码块 23–30 去掉依赖、8 条 stream 全并发（只计时，不做候选），三轮 ABBA 900 慢 0.21–0.25ms、1080 慢 0.31–0.33ms，p99 也同样变差。连理想重叠都亏，所以 P 停手，未写队列核。见 results/c512-xblock-queue-20261001。

## 2026-10-01 下采样折进相邻核（C64/C128，W2_DOWN_FUSED）：19 SAME，但两档三轮都慢（900 +0.05～0.08，1080 +0.12ms），不收。源码在 resample-fold 分支。见 results/resample-fold-20261001。

## 2026-10-01 网络前后 D3D 段瘦身 input-slim（光派单，子代理）
`DLSS5_GAME_PROBE` 细分打点（离线回放，串行化 GPU 时间）：encode 11.0/15.1、input 23.3/32.7、neural 15.7/22.2、decode 35.9/43.6、最终拷贝 8.3/8.3µs（900/1080）；D3D 段合计约 94/122µs，网络外那 0.3ms 的大头是交接不是 pass。做了 `DLSS5_IO_FUSE=1`：decode 直接读网络 f32 输出（f16tof32(f32tof16) 同舍入），跳过 neural pass，仅非时序、非 overlap 会话。19 组 SAME；六轮 ABBA avg 全正（900 −0.004～−0.020，1080 −0.012～−0.035），但 900 合并 p99 7.791→7.811 变差（3/6 轮），按规则不收：开关默认 0、不进模板、CONFIGURATION.md 追加一行、不装机不打包。encode 并 input、去颜色→low 拷贝估计各 ≤0.01ms，未做。`results/input-slim-20261001`。

## 2026-10-01 ViT 1080 反转对账：900 是 400 vs 448 token 的几何假象；1080 attention +25、QKV +12µs/块。M32（两条 16-query 链共用 K/V）19 SAME 但三轮全慢（900 +0.20，1080 +0.145ms），不收；分支 vit-1080-gap。见 results/vit-1080-gap-20261001。

## 2026-10-01 ViT QKV TM 重排（照 mochizuki 64 token × 256 列组织）：tm2/tm4 各 19 SAME，三轮全慢（约 +0.1ms），不收；w5 的 LDS 共享权重才是现役赚点。分支 vit-1080-gap。

## 2026-10-01 C64/C128/C256 核本体差距 swin-body-gap（光派单，子代理）
对 mochizuki fswin_t：900 C64/C128 差距集中在链两端的边界核——链尾写 f32（C64 bi 104 对链内 82，C128 70.6 对 59）、Up 首块（116 / 83）、独立池化（36 / 22）；他每段一个持久化派发、残差全程 e4m3、f16 累加（非逐位）。第一刀 `W2_UP_LOW_BYTES`：解码链尾（块 55、61，post 0 已在 E4M3 格点）写字节，`c128/c64_wave2_up_lb` 读字节（cvt 回 f16 同值），宿主按导出自动选。19 组 SAME，三轮全快：900 −0.012/−0.026/−0.045，1080 −0.069/−0.023/−0.022，合并 p99 900 7.865→7.809、1080 10.611→10.584。收，装剑星（add-on FF7853DA、c64-wave2 1201 6D3AC94C / 1200 E827900C），鬼武者镜像模块、RE9 runtime 未重编（发包时重编才生效）。下一步：块 65→C32Up 字节、下采样链尾写 f16。附：input-slim 清理误删了 lab assets 副本里的 .f16 权重，已从游戏目录恢复。`results/swin-body-gap-20261001`。

## 2026-10-01 ViT QKV 加宽（w5t2/w5h2）与他真实形状的大 WG（4 wave，64×256）：全部 19 SAME，三轮全慢（BIG 最接近：900 +0.03，1080 +0.065ms）；A/A 对照干净。ViT 逐位重排线收尾，剩余差距是 half 归约的数值取舍。分支 vit-1080-gap。

- 10-01 续：`C512_FFN_ONE`（C512 mix→expand→act→contract 一个 wave 在寄存器里做完，WMMA 操作数对调、累加器直接当下一级的操作数，无 LDS），19 组 SAME，三轮 900 −0.067/−0.066/−0.062、1080 −0.058/−0.050/−0.060ms，收下并装（剑星 add-on 69A6F3C9 含 swin 5621334d；鬼武者 runtime 5D158F68）。`C512_PROJ_FB8`（投影残差读 E4M3 tile，不写 f32）两版都逐位但变慢（1080 +0.14～0.20），不收，宏默认 0。重测 HIP span 900 7.03/7.12、1152 9.78/9.80、1088 9.31/9.33ms。

## 2026-10-01 swin-body-gap 续：块 65 字节（不收）、下采样链尾 f16（收）、Up 本体（停）
`CW_UP_LOW_BYTES`（块 65→C32Up 读字节）19 组 SAME，但第 1 轮两档变慢、1080 合并持平，不收，宏默认 0。`W2_DOWN_HALF`+`MH_POOL_HALF_IN`：编码器 C64/C128 链尾（post 3 = Hrtz，f16 精确）存 f16，池化 `_hin` 和 Up skip `_sh`/`_lb_sh` 读 f16；原有函数 ISA 逐条不变；rebase 到 C512_FFN_ONE 之后重测 19 组 SAME，三轮 900 −0.048/−0.058/−0.048、1080 −0.085/−0.047/−0.050，合并 p99 两档都更好。收，已装剑星（add-on 7E19CC6B，c64-wave2 38FEEB70/DC8B6DE1，mh-packed 03003659/EBD1A712），鬼武者镜像模块、RE9 runtime 待发包重编。Up 首块本体的差距来自数值取舍（e4m3 投影、f16 混合），逐位做不了，停。`results/swin-body-gap-20261001` §5。

## 2026-10-01 尾部 + C32 差距拆账 tail-c32-gap（光派单，子代理）
尾部"其他"54.8 对 15.5µs 主要是分族口径：块 48 Up（35µs）在他那边折进 fswinpup256；同口径只有块 39 decoder 19.7 对 9.2µs。候选 `HIP_DEC_NT`（每 wave NT 个列块、A 只读一次，逐位）19 组 SAME，NT=4 三轮变慢、NT=2 有一轮 900 +0.0014，不收，宏默认 0。C32 +225 逐项：prefix +78（另池化 18）、post +64、chain/finish 各 +10～+20、up +17、块 4 −9；约 +200 是数值取舍（f32 激活/归一化快路径、fp8 输入），组织方式只剩池化（resample-fold 负账同法）和 up 分发（≤3µs），这轮不出刀。`results/tail-c32-gap-20261001`。

## 2026-10-01 C256 链两端进持久化队列（SP_ENDS）：23 组 SAME（含超时压测）；早上的基线下两档都快，但 rebase 到 C512_FFN_ONE 之后的当前基线上 1080 三轮都慢 0.045ms，不收、未装机。分支 c256-gap。

## 2026-10-01 tail-c32-gap 补：decoder 尾处理
- decoder 尾处理 LDS 转置 + 行宽读写 `HIP_DEC_WIDE`（块 39/48），19 组 SAME；1080 三轮 −0.020/−0.017/−0.030、p99 两档都更好，900 +0.007/−0.015/−0.000，按规则不收，宏默认 0，留合包。尾部线交账。

## 2026-10-01 同口径逐族地图（链内逐派发、扣事件开销 ~42µs/派发）：900 差 1.10ms（C512 +332、C128 +218、C32 +208、C256 +141、C64 +132、ViT +24），1080 差 1.96ms（C512 +492、ViT +447、C32 +398、C128 +323）；sp_run256 每层约 53µs 已与他持平。见 results/kernel-map-inchain-20261001。

## 2026-10-01 c128-c64-inchain：C64/C128 逐派发拆账 + `W2_UP_VEC`
- 链内地图四段合计差 900 +400、1080 +570µs：两端（Up 首块 +35/+52、C64 链尾 f32 +22、池化 29/19）+167/+199，其余在链中间块（链内比 jobbench 单核多 12～15µs/块，这部分真假待拆）。
- `W2_UP_VEC`（Up 尾处理：f16 成对 bpermute 64→32、skip 向量读、upw 提出循环），19 组 SAME，三轮 900 −0.014/−0.010/−0.018、1080 −0.004/−0.024/−0.025，p99 两档都更好。已收，c64-wave2 配方开；剑星装 DFABA0FA/A69F1619，鬼武者镜像，RE9 runtime 不用重编。结果 `results/c128-c64-inchain-20261001/`。
- 续：DUP 重放法（不打事件）证明链中间块成本是真的（900 C128 68.9、C64 92.8µs/实例，和事件估计一致；jobbench 偏低是单测高频）。C64/C128 剩下最大的是中间块本体。`W2_UP_DIRECT`（去 shuffle，WMMA 4 倍）逐位但三轮全慢；`W2_SKIP_BYTE`（链尾双写字节 skip，宿主按导出自动选）逐位但持平偏慢。两个都不收，宏默认 0。
- c128-phase：段重放探针 `W2_PHASE_REP` 拆 C128 中间块（900：QKV 27.7 > FFN 扩展/收缩 23.7 > attention 9.4 ≈ 输出 9.0 > 混合 6.9 > 搬入 2.5µs）。`W2_QKV_FUSE`（Q/K/V 同一个 kt 循环，C64+C128）19 组 SAME，900 ±0/−0.016/−0.019、1080 −0.014/−0.026/−0.033，合并 p99 两档都更好。已收，配方开 3，剑星 0D043F91/91F4E6B0，鬼武者镜像，RE9 不用重编。QF2 首跑 AE CSV 偶发不一致，重跑一致。
- 10-01 晨：C512 attention 消融显示 norm/softmax 段不是成本，大头在 QKV 投影段；ACO 导出他的 attn ISA，看到他 k 循环全展开、约 36 条 load 同时在路上。`C512_COMPACT_QKV_UNROLL 4` 逐位，两档六轮全负、p99 更好，收下并装（c512-m32-mh 8DB6EB04）。FFN `_w2` 同基准三轮全过，混合 6 轮后 1080 p99 +0.005，没装，待定。
- 10-01 06:43：FFN `_w2`（C512_FFN_ONE 2）按 U4 后的现装基准重测，19 组 SAME，两档三轮全负，p99 合并更好，收下并装（add-on F2A9C2C4、runtime AEF7CE53）；RE9 回放 SAME。整网 900 6.95/7.00、1152 9.64/9.68、1088 9.19/9.22ms。C512 总账：每块约 86 对 52.3µs，QKV+attention 差 19µs（流水深度/寻址），FFN 差 7µs，attention 投影差 6µs（f32 残差），线暂停。

## 2026-10-01 C512 QKV 手排深流水 + B8 慢因（光派单，子代理）
U4 的 ISA 显示：每迭代发 4 步 load，但末尾等到 0，跨迭代不重叠；A 的越界读带 18 个分支。`C512_COMPACT_QKV_DEEP 4`+`QKV_SCHED 1`：32 步全展开，4 深寄存器环，8 个基址 + 立即数偏移，越界行读 p=0 后在消费时 select 置零，WMMA 组前后加 sched_barrier。结果：VGPR 235→189（每 SIMD 6→8 个 wave），稳态 32～39 条 load 同时在路上。19 组 SAME；900 −0.020/−0.016/−0.010，1080 −0.001/−0.014/−0.010，每轮 p99 都更好。收下，装剑星和鬼武者 c512-m32-mh（1201 7C313587，1200 7907D55B），add-on、runtime、flags 没动。B8：两边同一宿主（Pfb8）重测，v1、只测读端、v3 向量化三组都在噪声内。之前的 +0.14～0.20 是两边宿主不同的伪影；B8 不赚，不收。`results/c512-qkv-pipeline-20261001`。
- 追问：他 attn QKV 段也是 fp8 WMMA，每 wave 384 条，12 个累加器，每次迭代 8 步，和我们一样，没有可换的指令类型。18µs 的差距先要用链内逐派发实测我们的核来确认，现在的数是估计。
- AE CSV 偶发：自比 8 次 + QF2 8 次都复现不了；机制是 ViT 自适应的 500ms 墙钟空闲重置（hip_reference_network.h:505），主机停顿 >500ms 会重置，CSV 变而静态场景图像不变（强制每帧重置的宿主旁证）。建议验证时把阈值设成可配/无穷。C256 QKV_FUSE（swin-persistent）VGPR 顶满，+0.05～+0.27ms，不收。`W2_FFN_QT_BATCH 4`（c64-wave2）19 组 SAME，900 −0.05～−0.08、1080 −0.06～−0.10，在新现装（F2A9C2C4）上复验仍全快，已收，剑星 BCD183D0/81D3A61C，鬼武者镜像。
- 新账本（DUP 回放，整网，现装）：900 每块 FFN 41.7 对 13.9（+28）、QKV+attn 34.9 对 23.2（+12）、attn 投影 15.8 对 7.8（+8）、FFN 投影 10.2 对 7.9（+2），合计 102.6 对 52.8。FFN 才是头号，§12 的估算把它低估了一半。1080：+16/+10/+12/+5。
- FFN 追查：900 档 376 WG / 752 wave（每 SIMD 5.9 个），占用率不受限，每个 wave 只跑一轮。WMMA 最少 16 token，"WG 翻倍"不会多出 wave，没做。消融（看整网 span）：mix 12.6、expand+contract 7.1、两段 22.4µs/块（900）；1080 是 19.9/9.9/32.7。DUP 在 900 把 FFN 高估到 42（丢了重叠），真实差距约 +9～11。`C512_FFN_PIPE 4`（全展开寄存器环）19 SAME，但三轮全慢（900 +0.06～0.08，1080 +0.15～0.18），不收。下一步：块输入 e4m3，mix 直接走 fp8 WMMA。
- C512 块输入格点检查：诊断 GRIDQ=1（mix 先 F 输入）19 SAME；对照（乘 1.001）DIFF。源码上三个来源（pool group、decoder、非 raw 投影）写出前都过 F()。结论：100% 在 E4M3 格点上。字节化设计和估算见 results §7：保守版 f16 WMMA 读字节，估 ≤0.03～0.06ms，参照 B8 的零收益，建议先量读量敏感度再改宿主。
- AE 收尾：宿主加 `DLSS5_VIT_ADAPTIVE_IDLE_MS`（默认 500，生产不变，未单独装机，下次宿主装机一起带）。regression 用 `setup.ps1 -PinIdle` 写进 flags（benchmark 会清 DLSS5_* 环境变量）；只钉一边会改变 motion 输出（旧宿主第 1 帧后必然重置），所以只在两边宿主都含开关时用。段重放复测：整核 900 73.5→68.0、1080 111.6→95.9µs；高 VGPR 下段探针失真。`W2_HIDDEN_TILES` 4（+QB2）逐位但两档三轮全慢，T4+QB4、T8 溢出，不收。
- 10-01 08:31 `C512_FFN_F8W`：mix/expand/contract 权重 100% 在 E4M3 格点上（mix 只有 76 个不同的值），块输入也全在格点上，fp8 WMMA 和 f16 WMMA 逐位一致（19 SAME）。新导出 `split_ffn_one_w2f8`，宿主打包 `@split-mix-fp8`，开关 `HIP_C512_FFN_F8W`。19 组 SAME；900 −0.013/−0.044/−0.025，1080 −0.030/−0.018/−0.041ms，合并 p99 两档都更好（7.467→7.422，10.254→10.171）。已装：剑星 add-on 20979A8D + c512-m32-deep BC9F351E/D8352712；鬼武者 runtime E923098C + 镜像模块；RE9 回放 SAME，smoke errors=0。mix 半 K 消融：时间和 K 成正比（5.6/12.6µs）。
- 全网 f16 WMMA 普查（静态）：权重矩阵 100% 在 E4M3 格点上，只有尾部 scale/bias、位置偏置和 C32 部分 ffn 不在。能换 fp8 且耗时大的：① ViT QKV（vit_stream_qkv_frag_hin_w5，224/327µs，全 f16，输入是 contract 的 F 输出，待 GRIDQ 确认）；② decoder Up39/48（约 60µs）。池化读的是 Hrtz 链尾，不行；C32 和 wave2 的 f16 是数值通路；C512 QKV 和投影已经是 fp8。见 results §9。
- 10-01 09:13 ViT QKV F8W：`vit_stream_qkv_frag_hin_w5f8`（宿主打包 E4M3 分片，fp8 WMMA，LDS 暂存字节）。三步都是 19 SAME；900 −0.063/−0.056/−0.053，1080 −0.036/−0.035/−0.027ms，合并 p99 两档都更好。已装：剑星 add-on 0D739130 + vit-stream 14619041/755EA442；鬼武者 runtime 2CB95057 + 镜像模块；RE9 回放 SAME，smoke errors=0。decoder Up39/48 F8W 三步逐位都过，但第一批有一轮 900 +0.029，重测三轮全负，按严格口径不收，宏默认 0，留待定。

## 2026-10-01 有损 fast 档 fast-tier（光派单，子代理，只测不装）
新宏全默认 0（宏 0 重编与 HEAD 逐字节同）：`CW_FAST_NUM`（C32：Hrtz 恒等 + softmax 只 rcp）、`W2_FAST_NUM`（C64/C128/C256 的 H/Hrtz 恒等 + w2_inverse 只 rcp）、`HIP_VIT_ATTN_KSPLIT`（ViT attention 两 wave 拆 key，宿主按 `_ks2` 导出探测）。逐项三轮 ABBA + 对现装逐位版 PSNR（7 case×12 帧）：C32 900 −0.08～−0.12、1080 −0.13～−0.15，52.0 dB；c64-wave2 −0.02～−0.05，53.6 dB；KS 两档变慢（1080 +0.05）不进；swin-persistent 持平不进；1088 行 1080 −0.45。fast 配方（C32+c64-wave2+DEC_F8W+1088）：900 7.242→7.131（−0.11）、1080 9.956→9.366（−0.59），p99 全好，最差帧 51.8 dB。IO_FUSE 在此 harness 改输出（35 dB），不进配方，待查。对 mochizuki 差距 900 1.11、1088 行 1.56ms。`results/fast-tier-20261001`。
- 10-01 续：IO_FUSE 的 35 dB 是 fast-tier lab 用了旧 decode shader（assets-base），换新 shader 7 case 全逐位，input-slim 的 SAME 成立（已在其 README 补复核）。C32 f16 成对激活（`CW_FAST_NUM` bit2）三轮全慢（900 +0.13、1080 +0.18，PSNR 52.2），不进：gfx12 上生产/消费都是 f32，打包拆包抵掉收益。fast 配方维持 FAST3。
- 10-01 续：今晚试玩准备。fast 配方模块两架构编好放 `D:\DLSSNR-Lab\fast-tier\fast`（gfx1201 与实测同哈希：c32-wave1 CC9E08AC、c64-wave2 00EEEC95、deep_fast-packed 3F46F85E），现装逐位版快照在 `exact`。`to-fast.ps1`/`to-exact.ps1`/`status.ps1` 同时切剑星和鬼武者（模块 + flags 追加/删除 1088 行块 + SHA256SUMS），每次切都先备份；add-on、runtime 不用换（两者都读 ROWS，DEC_F8W 按导出自选）。exact→fast→exact 往返 130 个文件哈希全一致。游戏仍为逐位档。脚本副本在 `Development/HIP/experiments/fast-tier/switch/`。

## 2026-10-01 晚 gap-map-evening：新差距地图 + C512_PROJ_DEEP（光派单，子代理）
- 整网（现装逐位，宿主 HEAD）：span 900 6.81/6.88、1152 9.50/9.56、1088 9.08/9.13ms。同口径族差（900｜1088）：C512 +284｜+400、C32 +218｜+251、C128 +151｜+174、C256 +122｜+14、C64 +89｜+80、ViT +42｜+378；合计 +956｜+1354µs。C512 QKV+attn 已不落后，大头是 attention 投影（18.8 对 7.8µs/块）。
- 前三：C512 attention 投影、ViT 1088 档 QKV+attention、C32 中间块。`C512_PROJ_DEEP`（投影 K 循环手排流水）19 SAME 但两档三轮 +0.22ms：LLVM 提前全部 B load、255 VGPR 溢出，四种写法都溢出，不收，宏默认 0。没装机。见 results/gap-map-evening-20261001。
- 续：`C512_PROJ_WN4`（attention 投影 4 wave/WG、每 wave 16 列，wave 数 ×4，与 M32 减 wave 相反）19 SAME，但两档持平偏慢（w2 900 +0.013/+0.011/−0.004、1080 +0.018/+0.006/−0.008），不收，模块/宿主宏默认 0；这条核不是 wave 数或链长受限，线停。
- 续：ViT 1088 DUP 回放（µs/实例 900→1088，他 900→1080）：QKV 27.9→42.4（他 23.6→24.4）、attention 14.6→35.6（他 14.8→24.4）、expand 26.6→39.6（他 22.7→26.8）、contract 37.1 已持平。我们 QKV/expand/project 随 token 线性涨（每 16-token tile 各读权重），attention 近似平方（每 16 query 扫一遍 K/V，他 32 query）；建议下一刀 attention 32-query 共用 K/V、只开 640 档。
- 续：ViT 线收尾（§5.2 两刀即 vit-1080-gap 的 ATTN_M32 与 TM/WT/WH/BIG，已负账，无新角度）。C32 中间块 DUP（900 chain 134.2、1088 188.3µs/块）：+16µs/块 ≈ 单核本体 +10（数值：激活/归一化 RTZ 链）+ 链内降频放大 +6；组织方式只剩 up 分发 ≤3µs，不出刀。顺修 c512-qkv-pipeline/dup.ps1 的 `$cases`/`$Cases` 同名覆盖 bug。

## 2026-10-01 下午 bitexact-pm 第 1 项：三个擦线小件（`results/bitexact-pm-20261001` §1）
DEC_WIDE/F8W 互斥原因：宿主选了 `_w` 后 F8W 判断只认不带后缀的核名，模块也没有"宽出口+fp8 主循环"核；补 `*_w_f8` 导出与宿主判断，逐位。IO_FUSE 加宿主防呆（decode shader 不认 `NATIVE_CODEC_NEURAL_BUFFER` 就拒绝融合，实测旧 shader 19 SAME、10 次 refused）。单项三轮：IOF 过、DW 过（900 −0.005/−0.012/−0.061，1080 −0.013/−0.002/−0.081），DF 不过（900 +0.026 一轮）、DWF 不过。合包 DW+IOF 六轮 avg 五负一平，但 900 合并 p99 两批都 +0.06（IO_FUSE 老毛病），合包不收、IO_FUSE 不装。装 DW 单件：deep_fast-packed gfx1201 7FDA5868 / gfx1200 E55635E2，add-on/flags/runtime 不动，鬼武者镜像，RE9 回放 SAME，fast-tier exact/fast 同步。

## 2026-10-01 下午 bitexact-pm 第 2、3 项（`results/bitexact-pm-20261001` §2–3）
派发清单：网络内 153 派发里，只有解码段 `sp_init` 与本帧数据无依赖且不在负账。`SP_INIT_PAIR`（模块宏默认 0，宿主按导出用）编码段一次清两段 state，−1 派发：19 SAME（回绕+SP_VALIDATE），900 −0.001/+0.023/+0.003，不收。旧负账复测（DEC_WIDE 新基准）：PFT（1080 三轮全慢）、W16S（各档一轮慢）、VT（900 一轮 +0.003，其余负，p99 不差）均不收。T 已作废（FFN_ONE 后无 f32 写）。模块宏 0 重编与现装 swin-persistent/c32/c512-m32-mh 代码不同（HEAD 漂移），复测里含这部分。

## 2026-10-01 下午 rebuild-baseline：装机可复现性 + 统一重定基准（光派单，子代理，没装）
按代码段比：HEAD 源码 + 配方编 62 模块，58 个与现装一致；不一致的 `deep_fast`/`vit-wide-deep`（两架构）是 09-28 旧编译、不在生产路径（共享源 deep_fast.hip 后续加默认关宏改了 `split_projection_frag` 寄存器分配）。add-on 0D739130 与 RE9 runtime 2CB95057 的代码和 e22d15a2 逐字节一致；今早"哈希对不上"真因是 MinGW ld 按输出路径哈希定 image base，已在 build-addon.sh / build-runtime.sh 钉基址 + 去时间戳（两处编译整文件同哈希）。"现装有 main 没有"的改动：无；之前"宏 0 重编≠现装"是拿文件哈希（随机 cuid）比的。现装着色器 decode / text_overlay 落后于 repo。HEAD 全量（宿主+模块+着色器）19 组 SAME，但 ABBA 六轮全慢 +0.003～+0.026ms；拆账慢在宿主（模块/着色器中性，关 SP_INIT_PAIR 仍慢，HasFn 未命中缓存后仍慢），按规则不装。整网 span 900 6.78/6.90、1152 9.47/9.55、1088 9.06/9.13ms。`results/rebuild-baseline-20261001`。
- 续（二分 + Style）：宿主变慢二分到 5a7cd0ba（fast 档 `_ks2` 探测：ViT 每帧每块一次未命中的 hipModuleGetFunction + 每次派发一个后缀比较），只换宿主三轮六连正；`HIP_VIT_ATTN_KSPLIT_HOST` 默认 0 编译掉。**Style=1 的来源**：09-06 3e480520 `preblock-live-profile.json`，RTX 机上对原版 NVIDIA 运行时（剑星，backend +0x449a0，PID 29116，启动 8 次求值，4K）抓到标量 `0xb4=0.0078125` = Style/128，即剑星实际用 Style 1；mochizuki 同为 style/128、取 0..2。`DLSS5_STYLE`（0/1/2，默认 1，非法回落 1）：模块 5 处常量改读设备常量 `dlss5_style_feature`，宿主加载后 hipModuleGetGlobal 写入，默认零额外调用。默认 19 组 SAME；Style 0 对 NVIDIA 44.26（发布配方）/ 47.43 dB（全块），哈希与 09-30 测量版逐位同；Style 2 24.79 dB。修好后宿主+Style 对现装两批六轮：系统偏慢消失（7 负 5 正，合并 avg −0.009～+0.004，p99 不差），但每批各一轮 1080 >0（+0.018/+0.014），字面规则不过，没装；AA 自比也有 +0.010，重装的判法待定。
- 续（装机，16:09）：光批准按"代码等价重装"口径（合并 avg 不慢 + 合并 p99 不差，S/S2 都过）整套换装：62 模块（build-style）、add-on 053C3589、RE9 runtime DC2D445E（df92ed49 源码，钉基址）、decode/text_overlay 着色器；带备份；RE9 回放 900/1080 old/new/fallback SAME、smoke 0；两游戏 62 模块逐文件核对 0 差，SUMS FD419A3E；fast-tier exact 已同步。从此现装 = df92ed49 + 配方。

## 2026-10-01 晚 0.39 打包（`results/package-039-20261001`）

照 0.38 流程（`tools/package-039.ps1`，以 0.38 三包为底）。载荷 = 现装：add-on 053C3589、RE9 runtime DC2D445E、62 模块（SUMS FD419A3E，两游戏 0 差）；HEAD 源码重编 add-on 与 runtime 整文件逐字节相同（钉基址生效）。shader 与仓库逐文件同。模板加 `DLSS5_STYLE=1`。三包：Magpie 340,434,944 / OptiScaler 370,632,747 / REFramework 425,210,346 字节，ZIP 读回校验与 44 shader 变体通过，RE9 包内 smoke errors=0。发现：RE9 runtime 的 flags 白名单不含 `DLSS5_STYLE`，RE9 模板那行无效（默认 1 不受影响），已写进 RE9 说明与 CHANGELOG，修白名单留下版。tag 0.39 = 55966ef2。下载链接待 Zero 补。

## 2026-10-01 夜：夜间队列（night-20261001）
- RE9 runtime flags 白名单加 `DLSS5_STYLE`（runtime 73D4C25C，改前源码重编 = DC2D445E 可复现）；默认 old/new/文件 1 SAME，文件 0 = 环境变量 0（5c42d337 / b9ac12c0），smoke 0；未装机。
- 功耗逐族 DUP×8 + ADL：功耗钉 322～328W；每周期能耗 C64/C128 最高（1.08～1.10），C32 1.04～1.06，C512 各核 0.80～0.93；降 10% 上界 C32 −0.14/−0.23ms，其余 ≤0.11；无逐位便宜候选。第一批跑到一半遇上 Zero 开游戏，作废重测（之后加了每 15 秒查游戏进程的看门狗）。
- C512 attention 投影消融（`C512_PROJ_ABLATE`，诊断，默认 0）：核内全空只省 5.6/9.3µs/块（DUP 14.5/22.8），残差读 2.5～5，写出约 0；余差在派发衔接，线停。

## 2026-10-01 夜：编译器层逐位扫描（compiler-sweep-20261001）
- 盘点：`RTC_EXTRA_OPTS` 连写 `-mllvm=X`；配方加行字段 `opts`（`-RowOpts` 才生效）与 `-ExtraOpts`；源码挂点 `HIP_KERNEL_WPE`（默认 0）。默认构建 62/62 与现装逐条同。
- 静态 8 模块×26 组：`waves_per_eu` 1/2/4 热核代码全不变；bottomup/topdown/itminreg/unroll 指令膨胀，部分组合溢出，淘汰。35 组上 GPU。
- 收：c32-wave1 `-enable-post-misched=0` + max-ilp（整网 −59/−84µs），c512-m32-deep max-ilp（−10/−20µs）。合成：19 组 SAME；ABBA 900 −0.054/−0.043/−0.081，1080 −0.089/−0.091/−0.061ms，p99 7.525→7.443、10.277→10.188。只进配方（`-RowOpts`），未装机。
- 续（10-02）：扩到全部 9 个链内模块 × 10 组（其余 22 个模块不派发，只编不测）。`-misched-postra`/igrouplp 精确求解/pre-RA 优化开关代码全不变；关 s_delay_alu/VOPD 在热模块上一律变慢（C32 关 VOPD +0.14/+0.23ms）。c64 post-RA 关（−16/−20µs）、vit-stream post-RA 关+max-ilp（−2/−14）上完整验证：19 组 SAME，但合在一起 900 合并 p99 变差，拆开各有慢轮，不收。按核细分：clang 设不了函数级 sched-strategy、post-RA 无函数级开关；而且 DUP 显示正负分在档位上、不在核上，没必要做。
- 续（10-02 第三单）：按模块换编译器。LLVM22（ROCm 7.2.4）9 个链内模块里 6 个逐位，不逐位的是 vit-stream、mh_fast（900 静态 12/12）、vit-wide-deep（720 运动 1/12）；公开 LLVM23.1.2（新编，需 `-real-true16`，否则内联汇编 v_cvt_f32_f16 编不过）只有 vit-stream、mh_fast 不逐位，ISA 上是 FMA 收缩（project_n64 16 mul→32 fma）。收：c32-wave1（带配方选项）+ c64-wave2 用 LLVM23 编，19 组 SAME，ABBA 900 −0.048/−0.072/−0.066、1080 −0.061/−0.024/−0.035ms，p99 7.460→7.405、10.187→10.169。配方加 `compiler='llvm23'` + `-PrebuiltDir`（仅 `-RowOpts`），未装机。
- 续（10-02 第四单）：LLVM23 `-ffp-contract=on/off` 与默认代码逐条同，vit-stream/mh_fast 不逐位不是收缩问题（"多的 FMA"是 v_fma_mix 加 −0，精确乘积），根因未定位。LLVM23 下重扫调度：iterative-ilp 让 clang 崩（c32 以外）；c32 现配方仍最优；c64 post-RA 关+iterative-maxocc 链内 −16/−24µs，完整验证 19 组 SAME 但 900 两轮慢、p99 7.381→7.450，不收；swin/c512/deep_fast 在 LLVM23 下关 post-RA 也拉不回来。配方不变。

## 2026-10-02：下一版候选整套（next-candidate-20261002）
main b6c508a5 全配方 62 模块（-RowOpts -PrebuiltDir；对 0.39 只 c32/c64（LLVM23）、c512-deep 变）+ HEAD add-on（=053C3589 逐字节）+ RE9 runtime 73D4C25C。对 0.39 现装：19 组 SAME；ABBA 900 −0.106/−0.125/−0.139、1080 −0.189/−0.180/−0.176ms，p99 7.455→7.332、10.347→10.143；整网 wall 900 7.40/7.44→7.30/7.32、1152 行 10.16/10.26→9.99/10.01、1088 行 9.84/9.79→9.68/9.70。包在 `D:\DLSSNR-Lab\next-candidate\`（install.ps1 带备份、两游戏同换、同步 exact 快照，-DryRun 已过）。未装机，等 Zero。

## 2026-10-02：vit-stream / mh_fast 在 LLVM22/23 下不逐位的根因（llvm23-vit-20261002）
按核拼接汇编（LLVM21 汇编里换入单个 LLVM23 核）二分：只有 `vit_stream_qkv_frag_hin_w5` 和 `mh_ffn_qkv_body` 两个 ffn c256 核出问题。原因是源码写 LDS 后用裸 `s_barrier`、没加栅栏；LLVM21 对 gfx12 拆分屏障一律补 `s_wait_dscnt 0`，LLVM22/23 不再补，别的 wave 读到还没写完的 LDS。展开、fma_mix、src2 编码、rcp_iflag 都逐项排除。新宏 `HIP_BARRIER_FENCE`（默认 0，deep_fast.hip / multihead_fast_padded.hip）给裸屏障加 WG_FENCE：LLVM23、LLVM22 都 19 组 SAME。速度：LLVM23 vit +0.11/+0.13、mh +0.37/+0.10ms（编译器本身慢，ffn c256 单份 234→848µs）；LLVM22 vit 慢，mh +3/−20µs 上完整验证 ABBA 三轮慢，不收。配方、next-candidate 不变。
- 续（同日）：审计 next-candidate。扫描器（ds 写后无 s_wait_dscnt 就 s_barrier_signal）：c32-wave1 LLVM23 0 处；c64-wave2 LLVM23 72 个核有，全是不派发的 mh_*，派发的 28 个核 0 处。仍给 c64 配方行加 `l23defines = HIP_BARRIER_FENCE 1`（只进 LLVM23 预编），派发核逐条不变；19 组 SAME，ABBA 是 A/A 噪声。没退回 LLVM21（换不来安全性，还丢 c32/c64 的收益）。next-candidate 包已换 c64（旧包备份 next-candidate-bak-20261002-prefence），DryRun 过。全仓 31 模块：LLVM21 全 0，LLVM23 下 13 个模块有，清单进 WorkingPlan 技术债。
- 续（10-02 07:59 装机）：光批准后执行 next-candidate `install.ps1`。两游戏 62 模块与包逐文件 0 差，HIP SUMS F6411153，add-on 053C3589，RE9 runtime 73D4C25C；RE9 回放 900/1080 old/new/fallback SAME（b2980ada…/758674a8…），smoke 0；fast-tier exact 已同步，两游戏 EXACT。备份 stellar-backups/onimusha-backups `20261002-075914-next`、fast-tier `backups\20261002-075914-install-next`。
- 2026-10-02 net-timing：RE9 runtime 加 GetTimings（函数表末尾，struct_size 协商，ABI 版本不变）+ GetStatus net_gpu_ms；HIP 段 hipEvent、非阻塞读上一帧；首次 GetTimings 才开始记（常开 rt ABBA 六轮全慢）。19 SAME×2、RE9 900/1080 SAME、smoke 0、懒开启 ABBA 中性；720/900/1080 = 4.66/6.53/9.24ms。runtime 3103A0A7，未装机。详见 results/net-timing-20261002

## 2026-10-02 自由分辨率开关 free-res（光派单，子代理，未装机）
TheAutomatic 要网络按游戏原尺寸跑。新开关 `DLSS5_NETWORK_FREE_RES`（默认 0）：补边照 mochizuki 复原的 NVIDIA plan walk（64 倍数，两轴都是 256 倍数时宽 +64），1088 行例外取 1152；输入左上角 1:1，右侧列由编码 shader 镜像，ViT 网格 pad4。改动：几何头、输入几何、编码/RGB 输入/时序 4 个 shader（宏门控，默认编译不变）、HIP 宿主（白名单、head 网格、640 token 上限、>4.19M 像素关 PDL）、RE9 白名单、模板、CONFIGURATION、CHANGELOG。默认：19 组 SAME×2、RE9 900/1080 SAME、smoke 0、add-on ABBA 中性（rt ABBA 末轮 1080 三轮 +0.008～+0.020，噪声量级）。开 1：8 个尺寸到 4K 都跑通，fast = 通用慢路径逐位，可重复；对 NVIDIA 1440 35.9→46.4、4K 33.3→48.5 dB；耗时 1440 1.7×、4K 3.6×。几何：1080 实测 1152 优于 1088（47.43/45.76），1440 是 1472 最好（46.41；step128 候选 42～44），单一 step 解释不了。**发现**：两轴都是 256 倍数不补那一步时没有零 ViT token、整幅偏色（1440 30.8 dB）——现有 720 档 1280×768 正是这种情况，对两种补法都只有 28 dB，待 Zero 定。`results/free-res-20261002`。

## 2026-10-02 1080 档 `pdl=1/0` 查因（光派单，子代理，未改生产）
`pdl=A/B` = 请求/实际发出过 any-order。1080 档 C256 走整块融合（fcc11736），C64/C128 两档都是整块，所以 1080 没有任何 PDL 派发，这是设计如此（add-on 也一样）。持久化接管以后 Body 里只剩 C256 15/22/48/55 这 4 块，于是重测：让这 4 块在 1080 改走分体+PDL。结果逐位一致（1080 758674a8），状态变成 1/1，但 RE9 runtime ABBA 1080 +0.076/+0.077/+0.049ms 三轮全慢，900 持平。不收，生产不动。`results/pdl-1080-20261002`。

## 2026-10-02 net-timing 第三单：并入 TheAutomatic 的计时修法（光派单，子代理，未装机）
桥接 `TimingEnd()` 在 record(end) 后、输出 signal 前立刻非阻塞 `hipEventQuery(end)`（success/NotReady 都收）。按他的调用顺序（等完队列再 GetTimings、再 Retire）在 9070 上**复现成功**：旧版 1080 PDL1/PDL0 1000 帧塌（<0.01ms）70/92 帧、<1ms 701/806 帧、中位 0.09/0.08ms，且队列等完仍读不到本帧；新版三档 × PDL 开关 0 塌、本帧可读。19 SAME×2、RE9 SAME、smoke 0、不调用时 ABBA 中性；开计时的 add-on E 组 +0.06～0.15ms（诊断功能，照收）。`results/net-timing-20261002` 第三单。

## 2026-10-02 网络外一圈拆账 outside-net（光派单，子代理，未装机）
两条路径按时间线拆（新宿主 `rt_outside`：D3D 时间戳 + QPC + GetTimings；add-on 用 GAME_PROBE + SPAN + wall）。1080 档网络外 GPU 只有 0.35～0.5ms：D3D pass add-on 0.12 / ABI 0.33、交接 0.15～0.3；串行宿主另有 CPU/发射/唤醒 0.1～0.25。wall−span 0.5ms = pass 0.12 + 交接 ~0.15 + CPU 侧 ~0.13。**ABI 多一次 35MB 拷贝**（runtime 从没开 DIRECT_IO）：改为输入直写（`DLSS5_DIRECT_IO` bit 1，默认 1），RecordInputs GPU 0.22→0.08ms，哈希全 SAME，流水线 ABBA 六轮全快（1080 −0.07～−0.08），串行中性；runtime 0FAD1343，收进 main，未装机。候选 `DLSS5_HIP_POST_SIGNAL_QUERY`（输出 signal 后 hipStreamQuery）add-on 19 SAME、ABBA 六轮全快、p99 好，runtime 流水线中性，宏默认 0 待定。TheAutomatic 的 17ms 是负载下的 GetTimings 本身。剑星 history=0 reset=100 是 pre-upscale 设计。新增集成方调用顺序文档 `include/LmxxfNrApi-call-order{,.zh-CN}.md`、游戏内不 Flush 测法 `ingame-probe.ps1`。`results/outside-net-20261002`。
- 续（晚，装机）：光拍板两刀都收。POST_SIGNAL_QUERY 改运行时开关默认 1（0 关）。HEAD add-on 7FC14ECE / runtime 3AF64892 对现装：19 组 SAME，add-on ABBA 两档六轮全快，runtime 串行与流水线六轮全快，哈希 SAME，smoke 0。已装剑星 + 鬼武者（备份 20261002-204209-outside，exact 快照同步），装后回放 SAME。

## 2026-10-02 夜 ideas-yami-ikaruga：闇/鳩三个逐位方向（光派单，子代理，未装机）
基线现装 7FC14ECE / F6411153。① C512 FFN + FFN 投影同 WG 静态融合（`C512_FFN_PROJ_FUSE`，8 wave/WG、contract 字节留 LDS，−1 派发/块）：19 SAME，但 ABBA 三轮全慢（900 +0.09～0.10、1080 +0.11～0.21ms），WG 太少、挤在少数 CU 上；跨块那一对同形状，不做。② 地址错位（宿主 `HIP_ADDR_SKEW` 诊断，256B/4KB/64KB 级、权重/张量分开扫）：全部落在 AA 噪声（±0.05）里，无冲突信号。③ C32 Hrtz 改 builtin（`HIP_C32_RTZ_ISA 2`，让 LLVM 把加宽折成 fma_mix）：GPU 2³²×5 形式×8 常数 0 差，19 SAME，1080 三轮快，但 900 一轮 +0.037、合并 p99 变差，不收。宏都默认关。`results/ideas-yami-ikaruga-20261002`。

## 2026-10-03 C32 builtin Hrtz 只给 1080 档（rtz1080，光派单，子代理，未装机）
拆账：上轮合并 p99 只有 900 变差（7.360→7.433），1080 变好（10.106→10.062）。做法：配方加 `c32-wave1-rtz`（LLVM23，`HIP_C32_RTZ_ISA 2`），宿主 `HIP_C32_RTZ_TALL` 在 1920×1152/1088 且文件存在时把它装进 c32_wave1 键，其余几何照装 c32-wave1。c32-wave1 重编 .text 与现装同，rtz .text 与上轮候选同；路由探针证明 1080 两种行数用新核、720/900 不打开。19 组 SAME；ABBA 900 +0.009/−0.005/−0.007、1080 −0.051/−0.025/−0.039ms，p99 7.252→7.247、10.100→10.037。900 代码逐条同、+0.009 在 AA 幅度内，但按"任何一轮不能变慢"不收；代码在分支 rtz1080，部署包 `D:\DLSSNR-Lab\deployments-rtz1080-20261003`（DryRun 过）待光定。`results/ideas-yami-ikaruga-20261002` 第 4 节。
- 续（10-03 03:20）：光改判过，已装剑星+鬼武者：add-on A1B28916、runtime 40DDAD7F、c32-wave1-rtz 99B0B1E2/64C9CCF6、SUMS 6674D63A；RE9 回放 SAME、smoke 0；fast-tier 同步；备份 20261003-032011-rtz1080。

## 2026-10-03 快速数值路径做成运行时选项 `DLSS5_FAST_NUMERIC`（光派单，Zero 已批，子代理，已装机默认关）
Zero 决定不发 fast 档包，改做同一套模块里的运行时选项。配方加 `c32-wave1-fast`、`c64-wave2-fast` 两行（正常行再加 `CW_FAST_NUM 3` / `W2_FAST_NUM 3`，LLVM23 预编）。`c32-wave1-rtz` 的 fast 版和 `c32-wave1-fast` 反汇编逐条相同（bit0 让 Hrtz 变成恒等），所以不另做，=1 时各档都装 `c32-wave1-fast`。宿主 `FastNumericFromEnvironment()`：=1 时换文件，文件缺失就退回正常模块，并往 stderr 写一行；RE9 runtime 的白名单加了这个键。默认 0：19 组 SAME。第一次跑 AE 批 720-motion 有 1/12 帧不同，决策 csv 相同、代码等价，判为偶发，重跑全 SAME。ABBA 900 +0.002/−0.016/+0.002、1080 −0.003/−0.029/−0.048。RE9 900 b2980ada / 1080 758674a8 SAME，smoke 0；=1 时环境变量和 flags 文件两种方式给的哈希相同。=1：900 −0.125/−0.070/−0.067、1080 −0.093/−0.104/−0.102ms；对逐位版最差帧 51.83、均值 53.07～55.46 dB；对 NVIDIA Style 0 跳块 44.26→44.23、全块 47.43→47.55。全开（=1 + 1088 行）全算 900 6.94、1080 9.29ms，对 mochizuki 6.02/7.81 差 0.92/1.48ms；再加 AE、运动序列是 6.57/8.54。已装剑星和鬼武者：add-on 9D1FA493、runtime DBAB5E88、SUMS F3EFDC16，备份 20261003-035207-fastnum。fast-tier 的切换脚本标为过时（`-Tier fast` 会拒绝）。`results/fast-numeric-option-20261003`。

## 2026-10-03 三个发布模板逐项加中英注释（只改文档，选项值未动）
package-039 用的三个模板：`scripts/hip-game-flags.txt`（常规 141 项）、`hip-magpie-flags.txt`（142 项）、`hip-re9-flags.txt`（RE9 runtime，132 项），每个 `DLSS5_` 键上方加 `# 中：` / `# EN:` 两行，文件头加两行说明；来源 CONFIGURATION.md、读取代码、README 快速模式表。有损项（SKIP_BLOCKS、1080_ROWS=1088、NETWORK_HEIGHT=900、FAST_NUMERIC、VIT_ADAPTIVE/REUSE_*、FIT_LARGE、OUTPUT_SMOOTH、FAST_TEMPORAL、HISTORY_GUARD）标了实测数字或"未实测"及因果类型。旧 DX12 网络路线的 TEST_*/FP8_*/C32_* 等标"HIP 包不走该路线，保持默认"；未入文档的 HIP_MH_*/DECODER_BYTE/VIT_BYTE_STREAM/GRAPH 等标"内部调优开关"；RE9_SNAPSHOT 及四个 TEST_MULTIHEAD/PARALLEL 键代码不读取。RE9 模板对白名单外的键注明"RE9 runtime 不读此键"，旧 0.32 白名单注释更正为当前列表。发现：RE9 白名单不含 `DLSS5_FRAME_STATS`，模板里的值对 RE9 不生效（只认系统环境变量），CONFIGURATION.md 原描述不准，代码未改。
解析器核对：add-on 环境加载（`native_game_oneshot.h`，fgets 256，只收 `DLSS5_` 开头且含 `=` 的行）、RE9 runtime 白名单（`LmxxfNrRuntime.cpp`，fgets 512 同规则）、热重载（`native_hot_flags.h`）及各处 sscanf 单键读取（行首锚定）都会跳过 `#` 行和 UTF-8 中文；BOM 只会落在首行（现为注释），反而保护了首个键。风险点是超过 255 字节的行会被 fgets 截断、续段若以 `DLSS5_` 开头会被误收，所以注释行最长 191 字节。自检：三模板改前改后的非注释非空行 diff 为空；离线模拟 256/512 缓冲、带/不带 BOM，收到的键序列与原文件完全一致。
## 2026-10-03 默认换成"不跳块 + FAST_NUMERIC=1"的评估（光派单，子代理，只测量，未改默认、未装机）
基线剑星现装（宿主 9D1FA493 那份 + SUMS F3EFDC16 模块 + 跳 42/43/46）。ABBA 三轮：不跳块 B 900 +0.200 / 1080 +0.316ms（三块的代价第一次单独量）；提议 C（不跳块+fast）900 +0.118 / 1080 +0.187ms，p99 7.297→7.526 / 10.072→10.266；D（跳块+fast）−0.077 / −0.099。对 NVIDIA 单帧 A 44.26 / B 47.43 / C 47.55 / D 44.23（沿用）。以 B 为参考 7 case×12 帧：A 均值 50.90～51.91、最差 50.69；C 53.61～56.01、最差 52.68（720-motion）；D 最差 49.32。结论：C 比 A 慢 0.12/0.19ms，换 +3.29 dB 和偏色消失，建议换。`results/default-swap-20261003`。
## 2026-10-03 默认换成"全 71 块 + FAST_NUMERIC=1"并装机（Zero 拍板，光派单，子代理）
三个模板改成 `DLSS5_SKIP_BLOCKS=` + `DLSS5_FAST_NUMERIC=1`，中英注释写明默认值、为什么（+0.12/+0.19ms 换 44.26→47.55dB）、怎么改回跳块（快 0.20/0.32ms，掉 3.3dB）；注释行按 191 字节上限拆行，非注释行只有这两个值变了。查空值语义时发现 RE9 runtime 有个坑：flags 文件里的 `KEY=` 会被 `_putenv` 当成删除，`LmxxfProductionOptions` 拿不到变量就回落到内置的 `42,43,46`，所以空值关不掉跳块（`ParseSkipBlocks` 遇到空段会抛异常，也写不出别的"空"）。改法是把源码默认改成空集，和 add-on 一致；runtime 838A8B97，main 编出来的是 DBAB5E88，和现装的一样。装机两处，用户的其它行和行尾都没动。add-on 回放：现装 flags 与 C 组逐位相同（900 B8C0AE76 / 1080 D63608E4），跳块或关 fast 都会变，假 `-fast` 文件会加载失败。RE9：写 42,43,46 时新旧 runtime 逐位相同；现装 flags 得到 skip=0、与"无文件 + 环境变量 FAST=1"逐位相同；smoke 0。ABBA 一轮 900 +0.098 / 1080 +0.168ms（C 组 +0.096～+0.138 / +0.184～+0.190）。fast-tier 的 exact 快照换成新 flags，switch/README 写明 EXACT 只表示正式模块。包内说明（package-notes）留到下次打包时改。`results/default-c-20261003`。

## 2026-10-03 叠层 DLSS5_MULTI_PASS

接手中断的上一位（worktree `wt-multi-pass`，代码已写完，09:45 的宿主是最终版）；被打断那批 P3 计时和早于最终宿主的 D/E1/EX 全部重跑。做在共享网络层 `hip_reference_network.h`（`EnqueueRaw` → `MultiPassRest`），add-on / Magpie / RE9 runtime 一处生效，RE9 白名单加键，非法值退回 1。语义按"最终输出再喂入"：第 k 遍 RGB（alpha 1）当第 k+1 遍输入，历史/seed/噪声不变；网络输出本来就是工作编码下截到 [0,1] 的图，编解码往返是恒等所以省掉。hipMemcpy2DAsync 在 Windows 上超过 2^20 行静默截断，按 2^19 行分块。默认 1：19 组 SAME，显式 =1 7/7 SAME，7/0/abc 回退并报错，ABBA 900 −0.026/+0.043/+0.002、1080 +0.021/+0.005/+0.003 判中性；RE9 900 6f96…/1080 aaa3… SAME，smoke 0。2 遍 900 13.7～13.9、1080 19.5ms；3 遍 20.5～20.7 / 29.0ms；两次哈希相同、无 NaN；对单遍 38.4～39.1 / 34.2～34.7 dB；RE9 进程显存 900 +28/+75、1080 +111/+111 MiB。已装：剑星 add-on E50D6E4A、鬼武者 runtime E200E8A6，SUMS F3EFDC16 不动，flags 末尾加三行（=1），exact 快照已同步，备份 `multi-pass-backups\20261003-102714`。`results/multi-pass-20261003`。

## 2026-10-03 WorkingPlan 重写时迁出
旧 WorkingPlan 里有、DevHistory 里没有成段记录的内容，压缩存档：
- **研究判断**：roofline（`hip-roofline-20260930`）访存不是瓶颈（纯访存下限 1.55/2.11ms），算力下限 2.16/3.09ms，计入 WMMA 与 VALU 不重叠的现实理想约 4.2/6.0ms；离理想最远 C512 ≈3 倍、ViT ≈2.5 倍。病根是单 WG 串行链不是填满度（`fill-cu`）；关小核、PDL 延伸在 325W 功耗墙下不赚；C256 持久化队列赚、C128/C64 不赚；LLVM 做不到的要源码显式写；网络外交接 0.16～0.18ms/帧，GPU 轮询整帧不兑现，线停。
- **竞品（10-01 晚）**：mochizuki 0.0.2.5 同机 900 6.02ms、1088 行 7.81～7.86ms；Daniel 0.5.1 reference 900 逐核和 8.17ms。差距分类：组织方式逐位可追的基本摸到头；剩下是数值取舍（C32 RTZ 链/e4m3 多次舍入、ViT half 归约、f16 累加）和几何口径（他 16 块我 13 块、900 448 vs 400 token、1088 行）。
- **未收的逐位候选（等新证据或合包）**：`C512_T8_NO_F32`（900 六轮正、1080 一轮 +0.008）；`DLSS5_IO_FUSE=1`（avg 全正，900 p99 不过）；`HIP_DEC_F8W`；`C512_COMPACT_VT`；方案 A（C512 块内 attention→aproj 队列，估 −0.05～−0.10ms）、F（mix→FFN→proj 一核，把握低）。V（ViT 屏障持久化）不做。
- **负账索引**（细节见各 results 与上文各节）：HIP↔D3D 交接两半、Infinity Cache arena、C512 FFN LDS 共用/M32/FFN_PIPE/PROJ_FB8/PROJ_DEEP/PROJ_WN4/SPLIT_N/MIX_PIPE/跨块就绪队列、W16 推广 C64/C128、ViT QKV 尾宽写/GATHER_FOLD/ATTN_M32/QKV_TM/QKV_WIDE、C128/C64 持久化、Swin W2_UP_DIRECT/SKIP_BYTE/HIDDEN_TILES/C256 QKV_FUSE、功耗逐族、编译器（COMGR2/LLVM20 慢、LLVM22 不逐位、调度选项除已收两项外无收）、mochizuki 0.0.2.2 各路线。
- **技术债：裸 s_barrier**（`llvm23-vit-20261002` §5）：LLVM21 对 gfx12 拆分屏障白送 `s_wait_dscnt 0`，LLVM22/23 不送。任何模块换新编译器前必须带 `HIP_BARRIER_FENCE 1` 并用 `experiments/llvm23-vit/barrier_scan.py` 扫到 0；LLVM23 下有问题的 13 个模块清单见 `source-barriers.txt`。根治 = 裸屏障全换带 WG_FENCE 的写法。
- **Zero 历次定案**：有损路线只做用户选项；原版没量化的地方不做 FP8；PDL 保持 1；稳定性只修能复现的；1088 行保持可选。
- **等待事项**：PR #12（TheAutomatic）等他改/拆；PRE_UPSCALE=auto、卧龙 2、自带 FSR 的游戏、网友统一宿主补丁照旧等。
- **公众号素材**（Zero 还没说写）：一天从被反超到追平；"逐位原来是对上一版"；照抄对手 null、逐条对齐才出刀；同口径画质不跳块胜 mochizuki；roofline 说访存不卡、病根是串行链；三家都是"人 + AI"。

## 2026-10-03 三层配置文件 default → custom → native（光派单，子代理，已装机）
Zero 定的设计：`DLSS5-AMD\` 下 `default-config.txt`（包里的模板，升级可覆盖）→ `custom-config.txt`（用户的，安装升级都不碰）→ `native-game-flags.txt`（旧文件，含义不变），后者覆盖前者、没写的沿用、缺文件跳过；系统环境变量最高。合并只写一份 `src/native_config_layers.h`，读取方全部改走它：add-on 环境加载、热重载（改为监视三个文件）、直接读文件的 15 处（提示条、快照帧、预放大、FIT、UPSCALER、显存预留、格式回退等）、lab 根目录判定（三个文件任一存在即可）、RE9 runtime（白名单顺手加 `DLSS5_FRAME_STATS`）。Magpie 用的是同一个 add-on。自定规则：同一文件同键两次取最后一行（add-on 原本如此，RE9 原本取第一行）；空值覆盖下层、写进环境等于删变量即内置默认；行长不再截 255。行为变化：add-on 里环境变量现在压过文件（原来文件覆盖环境）。环境取快照在第一次读配置时，所以热重载时我们自己 putenv 进去的值不会被当成"用户环境"。打包：`package-039.ps1` 改调新的 `stage-config-layers.ps1`（模板放成 default-config.txt，另带 `custom-config.template.txt`，包里不再有 native/custom，解压覆盖不会冲掉用户文件）；`package-release.py` 同改；包里没法"不存在才生成"，所以 custom-config.txt 只由部署脚本生成。测试 `tools/test_config_layers.cpp` 28 项 Linux/9070 都过。19 组 SAME（第一次被游戏启动打断，看门狗停了重跑）；RE9 无文件 900 6f961945 / 1080 aaa31e2d 与现装 SAME，现装 native 与"default+同一 native"SAME，custom MULTI_PASS=2 生效、native 的 1 盖回、环境变量 2 盖过 custom 1。装机：剑星 add-on 3C71B955、鬼武者 runtime A156339E，两处加 default-config.txt 与仅注释的 custom-config.txt，native 未动；备份 `config-layers-backups\20261003-105814`。`results/config-layers-20261003`。

## 2026-10-03 叠层减负 DLSS5_MULTI_PASS_SKIP_BLOCKS + 叠层热键（光派单，子代理，已装机）
A：新键只作用于第 2 遍及以后（`MultiPassRest` 里把列表并进 skip 集合，跑完换回），第 1 遍永远全网；解析失败、或字节流管线跳不了的 C64/C128/C256 块（5–22、48–65）→ 退回空 + stderr；RE9 白名单加键。第一轮测量白跑了：harness 的 flags 是旧发布配方（本来就跳 42,43,46），`42,43,46` 组和空组逐位相同；改成每组都叠当前默认（`SKIP_BLOCKS=` 空 + `FAST_NUMERIC=1`）重测。3 遍：空 21.1/29.8ms；42,43,46 −0.4/−0.5ms、对自家 3 遍全网 43.9–46.0dB；ViT+C512 上行（31–38,40–47）18.4/25.7ms（−13%/−14%）、34.1–35.0dB；再加 C512 下行（23–47）17.4/24.3ms、33.2–33.6dB。参照：3 遍对 1 遍 35.0dB，ViT+C512 上行组对 1 遍 37.5dB——跳这些块等于把后几遍的效果拿掉一大块，是另一种观感不是便宜版 3 遍。省得少的原因：能跳的是低分辨率块，钱花在全分辨率 C32/C64 链上，生产管线跳不了。DevHistory 里没有逐块画质消融，激进组是按族挑的。19 组 SAME；非法值 abc/99/10 与空组同哈希且有 stderr；RE9 900 6f961945 / 1080 aaa31e2d 不变，文件与环境变量同哈希。
B：add-on 的热重载现在也重读 `DLSS5_MULTI_PASS`，HIP 网络下一帧前切（`Network::SetMultiPass`，同值不动，graph 模式重建）；热键 `DLSS5_MULTI_PASS_HOTKEY`（默认 F9，0 关）复用 F6/F7/F8 的 GetAsyncKeyState 边沿写法，每个网络帧查一次，按下按当前遍数轮换并写 custom（替换/追加/新建，保 BOM 和换行，tmp+改名）；native 里也有该键就一起改并 stderr，系统环境变量有就 stderr 提示改不动。写完强制下次热重载（同一个文件时间刻度内写两次时间戳不变，`hk_test` 里抓到过 5/9 次没触发）。RE9 runtime 没有热重载，热键只做 add-on。测试：文件逻辑 9 种情况（hk.ps1），热键 unset/0/F10 与 base 宿主逐位同（C3B23A3E）。真按键留给 Zero。装机：剑星 add-on C511E148、鬼武者 runtime 1F7C12CD，default-config 换新模板，custom/native 未动（剑星 native 里 MULTI_PASS=3，按 F9 会连它一起改）；备份 `multi-pass-skip-backups\20261003-144436`。`results/multi-pass-skip-20261003`。

## 2026-10-03 叠层一阶外推实验（纯离线，光派单，子代理）
问题：3 遍 f(f(f(x))) 能否用 x + k·(f(x) − x) 代替。harness 整帧导出（1296x720 解码后最终输出；x 取 `DLSS5_STRENGTH=0,0`，因为不改代码拿不到网络张量），900/1080 静止、1080 运动、1080 history 四组。sRGB 空间：y1→y3 26.5～28.4 dB，最好外推（k≈2）29.0～31.1，y2→y3 31.2～34.9；增量逐遍收缩到 0.64～0.76 倍。收益全在亮部和低频（对比度），高频只 +0.3～0.5 dB，中间调还更差；解码器 STRENGTH=k,k 外推等于不做。结论：外推介于 1 遍与 2 遍之间、比 2 遍差，替代不了叠层，最多当零成本对比度选项。详见 `results/multi-pass-extrap-20261003/README.md`。

## 2026-10-03 晚 0.40 打包（`tools/package-040.ps1`，9070 `D:\DLSSNR-Lab\release-040\`，日志 package.log / verify.log）

首跑 package-040（源码提交 3dc2f60b，以 0.39 三包为底，底包逐文件先校验），经 `tools/run-package-040.sh`（等游戏退出 + gpu.lock，15 秒游戏看门狗）。载荷 = 现装：add-on C511E148、RE9 runtime 1F7C12CD、宿主 aa3761f2 不变、68 模块（RE9 包 SUMS F3EFDC16，三包模块与 HIP-SHA256SUMS 逐条同）。三包 44 shader 变体通过、ZIP 读回校验通过、RE9 包内 smoke errors=0（layers=D--）。

|包（`D:\給網友打包\`）|字节|SHA256|文件数|
|---|---:|---|---:|
|Magpie-DLSS5-AMD-0.40.zip|342,035,235|7cd2eb575dea57af7f95b0c7ed288fedc5404eff45c7aed925e538fad8d53da8|746|
|OptiScaler-DLSS5-AMD-0.40.zip|372,232,881|c500e0fa977b624bd5f57845d8752e3b20df7402f1513a393de3f40749926506|564|
|OptiScaler-REFramework-DLSS5-AMD-0.40.zip|426,881,198|10532d0dcd34467ec8a56666f4d8bdfe1b109f863b2f89e52d9ca1b96cf8d71a|568|

清单对 0.39（`tools/verify040.ps1`）：三包一致地 +7 −1——加 `default-config.txt`、`custom-config.template.txt`（配置分层）和每架构 3 个新模块 `c32-wave1-rtz` / `c32-wave1-fast` / `c64-wave2-fast`（FAST_NUMERIC 默认 1 要用），去掉 `native-game-flags.txt`（解压覆盖不冲用户文件）；包里没有 `custom-config.txt`。其余同名文件内容变化（shader、notes、模板、二进制）不算增减。
验证：干净解压后 RE9 回放（包内 runtime + 包内模块，无配置文件）900 6f961945261a355c、1080 aaa31e2dffa3a1b5，各两遍 exit 0 SAME；包布局 runtime-smoke exit 0。升级模拟：解开 0.39、写用户 custom-config.txt 并改 native-game-flags.txt，再把 0.40 解压覆盖，三包两文件哈希都不变，default-config 与模板到位。verify 首跑踩坑：runtime 只在 `<dll>\shaders` 等处找 native_codec_encode.hlsl（不读 LMXXF_SHADER_DIR），回放目录照 config-layers rt9 拷 fusion-round3 shader 后通过。`multi-pass-extrap-20261003` 的帧导出已在之前清空（out 0 文件，work 只剩日志），无可删。tag 0.40。下载链接待 Zero 补。

## 2026-10-03 游戏进程看门狗：忽略僵尸进程（tools/game-check.ps1）

起因：鬼武者退出后 `OnimushaWotS` 进程不退（18:15 起、19:23 手动杀，240MB、无窗口、不占 GPU），所有 `tasklist | findstr` 看门狗都当成游戏在跑，0.40 打包白等一小时。

改法：共用 `tools/game-check.ps1`（9070 上 `D:\DLSSNR-Lab\game-check.ps1`），参数和 findstr 一样传空格分隔的进程名片段，退出码也一样（0=有游戏，1=没有），所以各脚本只把 `tasklist | findstr /I` 换成 `powershell -NoProfile -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\game-check.ps1`。25 个 .sh（`tools/run-package-040.sh`、`results/multi-pass-extrap-20261003/scripts/run.sh`、`HIP/experiments/*/guard.sh|gpulock.sh`）已换。判定：有主窗口、或启动不到 60 秒、或独占显存 ≥200MB 才算游戏；否则打一行 `zombie game process ignored: <name> pid <pid>`（也写 `D:\DLSSNR-Lab\game-check.log`），不阻塞。

坑：**ssh 会话里 `MainWindowHandle` 永远是 0**（非交互会话看不到桌面窗口；Get-Process 列所有进程都无窗口），只靠窗口判断会把真游戏也放行。所以加了显存兜底：`\GPU Process Memory(*)\Dedicated Usage` 计数器 ssh 下可见，游戏几个 GB，僵尸为 0。今天说的"MainWindowTitle 为空"若是 ssh 下看的，本身不说明问题。

9070 验证（ssh 下）：隐藏 `cmd /c pause` 启动 2 秒 → GAME rc=0（60 秒内放行为"在跑"）；同一进程 60 秒后 → zombie ignored rc=1；`dwm`（无可见窗口但占 1313MB 显存）→ GAME rc=0；`explorer`（无窗口、显存 <200MB）→ zombie rc=1；当前真实游戏列表 → rc=1。cmd 包装形式（`>nul && (echo GAME) || ...`）两种结果都对。"有窗口阻塞"分支在 ssh 下无法直接触发，由显存分支覆盖。

没改：一批老实验 .ps1 里的 `Get-Process ... {throw 'Game running'}`（deep-layers、fill-cu、c128-empty-tile 等，一次性脚本），以后复用时改调 game-check.ps1。


## 2026-10-03 20:15：0.40 下载链接补齐（闇接手）

Zero 在上传 0.40 过程中遇到 Claude 账号停用，随后提供夸克 https://pan.quark.cn/s/d38e0f653c5a 与 Gofile https://gofile.io/d/moSf7cqf。按已完成的打包记录补齐中英文 README/CHANGELOG 下载入口及 WorkingPlan；未重打包，未修改载荷。网盘内容未独立核验。

## 2026-10-03 21:50 起：DLSS5_PRE_UPSCALE=auto（朱雀，worktree 297-preupscale-auto / branch preupscale-auto-20261003）

治"装了跟没装一样"：Forza/卧龙类列表布局（upscaler 派发后同列表还有 draw/dispatch）触发 UNSAFE → fatal → 整局纯透传。auto = 首帧探测该合同：列表尾部干净留前置（行为同 =1），不干净则粘性强决定落后置（本帧 FFX-only 重放，下一帧起后置快照路线按全新启动在 SNAPSHOT_FRAME 武装），写日志含原因。非法值回落 0（现行为），=2 冒烟保留，环境压文件。决定后某帧再违约仍走原 fatal（同强制 =1，不悄悄降级）。ASYNC：探测帧遵守现有规则（2077 查表照生效），回落后 ASYNC 不再相关；探测帧异步拷贝即使读到垃圾也无害（回落帧网络不处理、不回写游戏资源）。开销：Mode() 一次原子读/调用。实现：`native_pre_upscale.h` 新增 RequestedMode/AutoDecision/Mode/AutoDecide（决策块无 D3D12 依赖），Process 首 job 处决定；`pre-upscale-smoke.cpp` 加 auto 回落帧（捕获→ObserveWork→Execute→断言 Mode=0/Enabled=false/FFX 恰一次/读回逐字节一致/再捕获直派）。开口：regular 模板值改 auto（Magpie/RE9 保持 0 只补注释）、CONFIGURATION 新行；RE9 白名单无需动（该键本被 RE9 忽略）。验证：add-on --hip/普通两变体编译过；Linux 原生单测 11 场景 PASS（extract-auto-block.sh 逐字节抽生产代码文本）；剑星 10-03 真实日志 3340 事件 0 UNSAFE → auto 会留前置；9070 GPU 冒烟同步/异步（结果见 results/pre-upscale-auto-20261003）。19 组 SAME 结构上不适用：回归走 benchmark_main_reuse.exe，不含被改代码；模块与 runtime 未动。覆盖缺口：Forza 类真游戏 auto 实测待 Zero（下版装机建议 auto 档玩 5 分钟看日志 auto: 行）。`results/pre-upscale-auto-20261003`。


## 2026-10-03 夜～10-04：赤月派兵三路交账（Kimi K3 子代理，AGENTS.md 自动注入开灯，gpu.lock 排队）

**① 遗留候选按新规复审**：IO_FUSE / C512_T8_NO_F32 / HIP_DEC_F8W / C512_COMPACT_VT 全否——19 组 SAME 都过但合并 p99 或慢轮不过线。`C512_T8_NO_F32` 是死宏（FFN_ONE 后 0 派发）已作废；IO_FUSE 900 p99 第三次复现，线关；"留待合包"队列清空。坑：assets-base 的 multi-pass-skip 副本缺 block0-ffn.f16，继承 harness 先验存在性。`results/pending-review-20261003`（2a3056af）。

**② 包内说明文案**：4 个 package-README 改全块 + FAST_NUMERIC=1 口径，补 MULTI_PASS + 三层配置；历史段旧口径故意保留（0ff15055）。发现：仓库无 tools/package-040.ps1，实际入口 package-release.py + package-hip.ps1 + optiscaler-stellarblade.ps1；D 盘 Payload 的 package-README-magpie.txt 仓库外待同步。

**③ FAST_NUMERIC 加深（PF 全 fast 包，收下）**：VIT_FAST_NUM 宏（bit0 attention 去 Hrtz、bit1 分母裸 rcp、bit2 contract/projection 去 RNE 半）进 deep_fast-packed-fast（15）+ vit-stream-fast（4）配方，COMGR 两架构。PSNR 最差帧 52.13dB（≥50 线），ABBA 900 −0.089 / 1080 −0.100ms 三轮全快 p99 全好；宏 0 重编与现装逐字节一致，FAST=1 缺 twin 回落逐位。负账：C512 f16 残差投影逐位精确但全慢（投影族不差残差流量，同 FB8 负账）。坑：harness 宿主是 benchmark_vit_reuse.cpp；fast-numeric lab 旧 benchmark-base.exe 已漂移勿用；剑星 flags 含 MULTI_PASS=3 会污染 harness 需中和键。`results/fast-vit-c512-20261003`（0e3b72dd）。

**派活规矩更新**：子代理免 `[LOAD MEMORY]`（实测 K3 子代理能背 SVG、守铁律）；K3 底座无 Co-Authored-By 问题；交账要追加 DevHistory §12（直接改 main）。

**10-04：两分支已合 main**（fast-vit、preupscale-auto，DevHistory 冲突已解——保留各分支详细记录，删重复摘要）。下一步：装机双游戏 → run-regression 形式回归 → 0.41。

## 2026-10-03 23:23 当前 main 重编与双游戏装机（闇派兵，子代理，Zero 已授权）

赤月到用量上限后的交接：main `1311179d` 已含 fast-vit 与 preupscale-auto，本轮只编译安装，不打 0.41 包。add-on **518E34C4**、鬼武者 Content / _storage_ runtime **2176C544**；全配方重编（LLVM23 五行两架构预编 + COMGR），gfx1200/gfx1201 各 36 模块，共 72，双游戏 SUMS **9D4A2024**。重编 normal 文件哈希有差异，实际正常 7 / AE 7 / 决策 CSV / rollover 4 全 SAME（19 组）；全 71 块 FAST7 对已批准 PF 全 SAME。RE9 旧新各两遍 900 `6f961945261a355c`、1080 `aaa31e2dffa3a1b5` 全 SAME，smoke errors=0。安装逐文件读回验证、双游戏模块/SUMS 一致、fast-tier exact 全模块快照同步且双 EXACT。未代启动游戏，不能据此声称真游戏已验证。

custom/native 全部保留原哈希，default 换当前 regular 模板（PRE_UPSCALE=auto）。剑星 native PRE=1 / MULTI_PASS=3（custom 也 =3）仍覆盖 default；鬼武者 PRE=0 / MULTI_PASS=1。auto 与 F9 真游戏待 Zero。备份 `D:\DLSSNR-Lab\current-main-20261003\backups\20261003-232258`，manifest + rollback.ps1 齐备，回滚原子拿锁并查游戏。实验全程 15 秒游戏看门狗，自有 gpu.lock 已释放，帧转储已清理，二进制不入库。归档 `results/current-main-install-20261003`。

Zero 更新派活规矩：具体编译、实验、安装、归档都派子代理，主进程只调度和审交账，保护单会话上下文。WorkingPlan 已整篇重写兑现已合并/已装状态，并纠正 RE9 FRAME_STATS 已进白名单。

### 2026-10-03 23:48:16 双游戏实玩反馈（Zero）

鬼武者 GPU 占用 89～92%，Zero 感觉下降；此前约 95% 是历史读数对照，这条未明确 FPS，不能记成本轮确认稳 60。剑星 1x 仍 57～58 fps，本轮未读出帧率提高。离线网络省时已测，但不能直接当游戏帧率收益；约 0.3 fps 只是推算，不入实测账。同步本轮 results README 与当前计划。

## 2026-10-04 00:30 两遍网络预测第三遍（闇派兵，Zero授权实验及装机）

`MULTI_PASS_PREDICT=1` 仅MP3用两遍真实网络+局部secant预测第三遍，默认0、1x/2x不变。工作域x/y1/y2/y3导出；固定tile16、RGB共同r、epsilon平均1e-7、cos≥0.5、r截[0,1]、系数双线性平滑、输出clamp。实际GPU四例对真3为49.36–49.83dB（真2约41），history45.28、高频仍改善但暗区62→60dB与颜色误差略劣；同样本x相同而y1已变52.61dB，跨帧历史反馈已分岔，不称全面改善。真3默认19 SAME、MP2/3兼容SAME；预测五例两次SAME、无NaN；200帧一轮ABBA 900 20.05/20.14→13.59/13.61ms、1080 28.48/28.50→19.22/19.32，约省32%。RE9默认两档SAME、预测两档重复SAME、最终开预测smoke errors=0。

独立预测核，无裸屏障；热载/RE9白名单/三模板默认0/CONFIGURATION同步。已装剑星 **50C453C5**、鬼武者两处runtime **DD606C1A**、74模块/SUMS **067B7DAC**，exact快照同步双EXACT（只指模块）。两游戏custom PREDICT=1、MP3，native MP3；其它项/BOM/换行保留，剑星PRE1、鬼武者PRE0。F9仍切1/2/3，PREDICT=0恢复真3；剑星热载、鬼武者重启。备份 `multi-pass-predict-20261004\backups\20261004-003039\rollback.ps1`。GPU锁释放、帧转储清理，归档 `results/multi-pass-predict-20261004`；实玩待Zero，不打包不push。

编译工具坑：复用旧current-main/src/rtc_compile.exe传gfx1200却日志报ISA1201；新核改用当前源码重编rtc，两架构分别明确ISA1200/1201，hash/ELF notes已归档。0.41前查旧全模块ELF目标，别只相信配方标签，本轮未扩大重编整网；当前9070为gfx1201。

## 2026-10-04 01:07 鬼武者预测实验首帧黑屏，专属回滚后恢复（Zero实证）

Zero报启动黑屏/有不可点击弹窗。两次启动日志显示modules_ok=74、HIP初始化与PrepareFrame成功，停在首帧Record ok / pending EnqueueHip，producerSubmitted=0；没有取得弹窗原文，不能声称确切异常。读进程时游戏已退出，无需杀进程。鬼武者单独完整恢复实验前备份：根/_storage_ runtime2176C544、72模块/SUMS9D4A2024、原custom/native（MP1、无PREDICT1）；只同步oni exact SUMS/flags，剑星实验档不动。**01:07:13 Zero确认「现在鬼武者正常了」**。失败日志/配置远端保留failure-20261004，短日志归档本轮results/failure。

集成假设：首次predict hipModuleLoad在MultiPassRest热路径，此前HIP已等待游戏尚未提交的producer fence；模块加载若隐式同步GPU便循环等待，bench/smoke因producer已提交没覆盖。尚未复现，不归算法本身；构造fprintf已越过PrepareFrame，因此不是已证实的stderr弹窗。下一步只准备初始化预加载/安全热切修复及编译，用户正常游玩时不占GPU不换鬼武者载荷，待空闲受控验证。

## 2026-10-04 鬼武者首帧死锁小修已编译、未重装

撤回上一条moduleLoad首帧假设：PrepareStagedKernels已经暖跑并加载预测核。明确缺陷是两遍+预测暖跑仅分配feed0却翻索引至1；真游戏首帧用未分配feed1，Upload内部明确同步HIP stream，而该stream已等待尚未提交producer，形成循环等待；真3暖跑已分配两feed，bench/smoke producer已提交，故漏测。真2也有同样潜伏路径。

小修：ctor/安全热切提前准备两feed，热点禁Upload；核及符号初始化预加载，旧72模块默认关仍兼容。公式/HSACO不改。addon8A020EA6、runtime7FEC39CF、benchmarkA9C3EC61已CPU编译通过，仅放/tmp，**未GPU验收、未重装鬼武者**。用户回滚后正常优先，不抢GPU；待空闲受控待producer fence复现+输出回归。代码顺序/完整hash见results本轮failure/prepared-fix.md。

## 2026-10-04 01:59 肤色1x / 整体真3x保护（Zero明确不是提速，闇派兵，已装双游戏）

`MULTI_PASS_SKIN_PROTECT=1` 保存第一遍y1，原工作输入x算YCbCr软椭圆，最终混合y1与多遍；核心m1/m0显式端点，非原图混3。x经paper-white/shoulder/sRGB已经显示编码，不再gamma。公开OptiShade参数参考、独立实现：中心.405/.600、半轴.09/.11、内区≤.95硬1/外到1.45羽化、chroma .02–.06、3×3max平滑；暖背景误选/彩光漏选仍属启发式。脸裁图/最终decode确认回1x，衣服背景主体保留3。CPU/GPUmask最大5.4e-7，六组m1逐位y1，非history m0逐位多遍；history跨帧反馈需同一运行比较，未声称两运行全相同。

默认19 SAME、MP1开保护三例SAME；真/近似保护三例12帧无NaN、两例重复SAME、RE9 smoke0。100帧短ABBA新增mask+copy+blend约.25/.34ms，目的观感。先前feed死锁受控producer gate1.5秒：旧Enqueue1528.316ms/新2.005ms，解锁后正常，双feed前置准备修复实证通过。新增肤色模块与固定资源也在producer wait前准备，无核数学变化、无屏障。

已装剑星 **731B8DAE**、鬼武者两处runtime **C38B8383**、76模块/SUMS **C7EA9AC8**，readback一致、exact快照同步。两游戏custom **MP3/PREDICT0/SKIN1**，native MP3；其它配置保留（剑星PRE1、鬼武者PRE0）。F9仅剑星；鬼武者重启读配置。备份 `skin-protect-20261004\backups\20261004-015944\rollback.ps1`。归档results/skin-protect-20261004，decoded-face左1x/中3x/右保护；锁释放、原始帧清理。未代启动游戏，实玩待Zero；不打包不push。

## 2026-10-04 02:16 Zero要求关闭肤色保护（仅配置）

Zero实玩反馈：保护开启后整体效果几乎看不出来，剑星真3约27fps，决定关保护。两游戏custom SKIN_PROTECT=0，读取实际MP3/PREDICT0并原样保留；native无skin覆盖、Machine/User无skin覆盖，默认本为0。保BOM/换行/其它行，备份skin-protect-20261004/skin-off-20261004-021602；exact仅同步native/custom配置快照，DLL/模块未动，无GPU。查询时无游戏进程，不能声称运行中新热载已确认；剑星可热载、鬼武者需重启。观感实验未满足用户，本轮关闭；27fps不能直接归于mask约.34ms，真3与此前预测3口径不同。

## 2026-10-04 02:19 鬼武者再试修复后的优化3x（仅配置，Zero明确要求）

只鬼武者custom改MP3/PREDICT1/SKIN0，native MP3无predict/skin覆盖；其余项/BOM/换行保留，Machine/User无相关环境覆盖。根/_storage_ runtime读回均C38B8383（含已受控producer probe验证的双feed修复），SUMS C7EA9AC8/76模块，gfx1201预测核hash2E7F1437；无需重装DLL，无GPU，剑星不动。备份skin-protect-20261004/oni-predict-on-20261004-021943，oni exact配置快照同步。查询时无鬼武者进程，重新启动读配置；这是两遍+预测第三遍，皮肤保护关，实玩待Zero。可将custom MP1/PREDICT0回普通单遍，重启生效。

## 2026-10-04 Issue13 独立5090原版双帧取数（闇派兵，实测完成）

附件SHA通过、0评论、25文件逐项校验，CPU复算194稳定块/952569像素/HIP p9514.943205%。5090当前空闲，独立D:\DLSSNR-Oracle\issue13建direct NGX harness，旧581.15 core Init/Caps成功但Create18 OutOfDate；从官方NVIDIA libnvidia-gl615.71.09 DEB（131MiB、SHA已验）只提取配对core，未安装驱动/未改游戏，正确ABI SetFloat6/UInt4与Getter回读后Create/Eval成功。原DLL310.8 SHA E16BCF15，官方core/API报告driver616.92，实际系统驱动未升级。

先API1080/seed0输出p9512.44%、对HIP仅30dB，不能当同合同oracle。原launch观测seed默认0、Style1、post(-4,-4)、proc1152/historyoff。按附件底镜像为1152、仅preblock参数seed改1，原GPU核/模型不改，执行两帧各两遍并捕获真实input texture、block70内部FP16surface转F32；入口RGBA每值同原f16→f32（maxabs0），raw/API重复均全字节同。捕获器初用normalized坐标读实际unnormalized texture、全图恒首像素，已修逐texel并撤回该误读，修前后post不变。

原post同194块p95 **14.937534%**、MAE .00580405，HIP14.943205%/.00580724。HIP经原RTZ FP16存储后，每帧6220800值：8678全同、8680仅44值不同（max .00219727），不是全帧全逐位。证明此双帧放大也在独立原NVIDIA链，不支持生产优化/复用/大移植偏差为主要来源；仍是模型在当前输入合同下响应，不能判全部实机闪烁或鸣潮同源。rawpost是内部FP16存储后half→F32，未假称pre-half RGB32F。数据ZIP/size/hash在results/issue13-original-oracle-20261004/package.json，5090 D:\DLSSNR-Oracle\issue13\issue13-original-nvidia-20261004.zip；包无DLL/core/CUBIN权重，无外发评论、不push。

## 2026-10-04 D3D↔HIP“网络快更停滞”速度研究（用户纠正不是崩溃，闇派兵）

不改生产、不造TDR，正确fence协议+固定D3D timestamp列表，2帧在飞、memset64/256/2048MiB占位，各40弃4，另请求Sleep8（实CPU周期15.5ms）。旧HIP event出现负/近零计时，首扫差分弃；中间构建失败旧产物重复批也弃。补end非阻塞Query后六档有效：密集netGPU .051/.449/3.562ms、同D3D钟含HIP总区间 .146/.582/3.774、差分剩余 .095/.134/.212，占比65/23/6%；稀疏剩余 .191/.227/.237。没支持“更快必然绝对等待增长”，不否定Daniel特定宿主。差分不叫纯fence税，memset不冒称NN。outside-net输入.22→.08时串行剩余变大而流水线9.71→9.57，是CPU提交窗口真实案例；samequeue对第二D3D队列税说明不全是HIP。报告/有效CSV/hash/坏批隔离在results/d3d-hip-stall-20261004。GPU锁释放、游戏配置/二进制不动，不push。


### 2026-10-04 多遍直接RGBA已装；C512 LUT止损

非末遍post直接RGBA(alpha1)保原RGB数学，下一遍免feed搬运；预测/肤色支持first stride，旧模块缺入口回原路径。默认19及10组多遍兼容逐位SAME，RE9六组SAME+smoke0。真3 900/1080平均省.344/.446ms，预测3省.187/.171ms，三轮全快及合并p99改善。双游戏addon14244CEF/runtime29ED217A/76模块SUMS A09EE065；用户配置字节原样，备份20261004-084609，实玩待Zero。结果results/multipass-direct-rgba-20261004。

C512激活LUT GPU原helper生64KiB表，65536half全byte同（含非finite）、真实w2f8两档0diff。1080三轮−.326/+.333/+.001µs，无稳定收益，停止不收生产；负账results/c512-activation-lut-20261004。


### 2026-10-04 09:50:52 鬼武者直接RGBA版实玩反馈

Zero反馈「鬼武者接近49帧（900P 2k质量），3x效果不错」。现配置MP3/PREDICT1/SKIN0，实际两遍真实网络+预测第三遍；不是三遍真实计算。此前也有约49fps读数，本次未确认帧率提高，离线节省.187ms不等于实玩已读出提升。


### 2026-10-04 原生1440 C256融合门已装；ViT960止损

实际输入2560×1440/proc2560×1472/960tokens，full71 FAST1/SKIN0；只对该shape放行既有C256 wholeblock核，GPU模块/数学不改。三轮连续ABBA单遍NR frame wall17.48285→17.02935ms、p99 17.803→17.348；优化3x（两遍+预测第三遍）34.40925→33.44233、p99 34.810→33.793。纯NN GPU median分别15.96772→15.58430和32.76842→31.82376ms。wall含codec/交接/回写，不含游戏render/FSR/Present；不是已证明真2k可稳定实玩。老harness每帧读回/CPU扫图改变提交节奏，初报20/36ms保留为诊断口径、不作连续基线；同exe连续1080单遍参考wall10.13734、GPU9.28136。fixture原图来源未独立确认，motion/history是受控序列，不称新游戏抓帧。

1440 FAST0/FAST1静态及受控动/history原网络11304960 float逐位同、无NaN；正常19及RE9三档九组SAME/smoke0。初用旧R对照AE720出现4帧不同，离散决策同、score略异，保留失败；旧R A/A与同HEAD新编baseline单case过，随后同源AE7/CSV+roll4过，未定位旧runner异常根因。main addon当前重编wholeSHA未复现旧装SHA，不作源码＝旧binary证明。

原900/1080两轮control合并平均不慢；1080p99不差，900p99点估计14.319→14.363略高。新runner A/A尾14.378/14.380，跨批尾位置约.06ms变化覆盖差额，收为测量分辨率内等价，不声称全部p99改善。补证前已经装机，control接受过早，随后补一次A/A+control，不删旧读数。双游戏addonF1681283/runtimeF0A74F7D，76模块SUMS仍A09EE065；备份native-1440-optimization-20261004/backups/20261004-113833。所有配置字节保留：auto/FREE0；剑星3/PRED0/SKIN0，鬼武者3/PRED1/SKIN0。现质量模式900不会因本刀提速，真2k待用户NativeAA+FREE1决定。

DUP边际C32约5.325ms、C256约2.313、C512 FFN/投影部分约1.221、ViT族约2.168，不相加当整网份额。960已走现融合/stream/N64/w5 QKV，新增恒960入口小筛无稳定收益；只收实验记录（原512b4872，本分支fc9a74b5），不合生产。结果results/native-1440-optimization-20261004、vit960-20261004。原输出留hash/统计后清理，未删输入/权重/附件，无push/发行包。


### 2026-10-04 ViT已量化contract字节边已装；C32小刀止损

C32当前1440 prefix/post边际各约1.35ms；固定geometry/pitch入口原float同、默认0执行section同，prefix/post少74/48指令，但三轮−.00961/+.00226/−.02536ms有慢轮，停止不收生产。原型patch/results/c32-small-20261004留负账。

只收ViT已量化边：F的E4M3值直接保存byte，w5 QKV省half→float→FP8重编码，投影skip精确decode，AE缓存仍F32。65536half与254有限FP8码proof同，NaN码域外差异如实留；真实三核tuple/正常19/AE CSV/1440受控动history/3multiSkin样本/缺一入口整体fallback/RE9九组smoke均同。初始化三HasFn缓存，warmup覆盖新byte容量，不在producer等待后新增Upload/moduleLoad/sync。初手写拼接漏inc报500，经预检改canonical row构建，错误未安装。peer源c00ac6dc已合为0e98456c。

同批single三档三轮各1440样本：900 avg7.39185→7.33849ms、p99 7.674→7.660；1080 10.29676→10.20419、p99 10.625→10.516；1440 17.10425→16.97973、p99 17.409→17.280。省.053/.093/.125ms，约.7～.9%；wall含codec/交接/回写，不是游戏总帧时，也不与旧批累计百分比。

双游戏addon3A538106/runtime2844B742，76模块SUMS8E34D5D1；仅vit-stream两row双arch更新、旧入口保留。备份vit-byteedge-formal-20261004/backups/20261004-130812，配置字节保持auto/FREE0；剑星3/PRED0/SKIN0，鬼武者3/PRED1/SKIN0，exact快照同步。无push/发行包。results/vit-byteedge-formal-20261004与vit-contract-byteedge-20261004；输出hash/统计后仅清本实验输出，不删权重/输入/附件。

Issue13原NVIDIA现存数据已公开两包：[Gofile](https://gofile.io/d/FWpuapJe)，[issue回复](https://github.com/lmxxf/dlss5-on-amd-9070xt-porting/issues/13#issuecomment-5976697739)。API final保存full1920×1152 RGB32F、原post包有效1080，两阶段不可混；无GPU重跑。


### 2026-10-04 Issue13原pre-down四tile已取并回帖

最新作者test20 p95=23.315485%、每帧自身exact pre-down注入降16.327520%表明生产额外前端贡献；此前14.94%只对exact-reference近原版，不归全部闪烁于原模型。test20未给源码/commit/生效flags/模块SHA，不套79cbf484。

RTX5090空闲定向捕原block0 pre-down四tile：源(832,528)/(960,544)/(0,0)/(1912,1072)各8×8，对应down4×4×32；真实960×576两C16平面FP8，packet+f8原GPUbuffer。每帧2次2048B相同/无NaN；先一次暖Eval取得有效launch self，提交完成后Eval外准备copy，采集hook仅GPUenqueue32行copy，不Sync/CPU等待；不另取API final。原prefix16/16→32投影在fused寄存器/LDS无独立输出，不用受控权重readout伪造。没有当前已验证修复，等待test20指纹/tile对比再修。

包19241B/SHA c9dc356927a24f131f7fe9acbcb0798e7461faacce4f9a40bbaf01045276320c，https://gofile.io/d/FWpuapJe ；已回复并读回 https://github.com/lmxxf/dlss5-on-amd-9070xt-porting/issues/13#issuecomment-5977255490 。结果results/issue13-prefix-20261004/source已归档，无游戏配置/部署/驱动改动，无push。今晚鸣潮待用户观察，不替用户下载安装。


### 2026-10-04 Issue4/PR15：Enqueue恢复HIP当前device修复已备

新报告LUID正确选device1/gfx1201/HIP70260201，ready后prefix400；提交者仅addon变量、42flags/模块同的A/B/C，0.40/main各9错，Enqueue重绑后600+帧无错。采纳PR15一行hipSetDevice(hip_device)，既有try失败仍封闭退出，不改选卡/资源/kernel。HIP current device为TLS，但线程ID未实测，400标签也可来自lazyGetFunction而非已launch。

本机HIP仅9070device0（Intel核显不进HIP）；跨线程单device查询通过、900/1080八帧对fresh基线逐位同，不作双HIP复现。候选/tmp/issue4-products/dlss5-amd.addon64 SHA a810cd5194f565be68198b1f86a5777cc62e446995fa49d355c2f5661aa37444。未装Magpie/两游戏，无配置/BIOS/驱动改动，无外发/关闭issue/push。记录results/issue4-igpu-20261004，修复来源PR15/XMoon。


### 2026-10-04 RE9强度文件入口已补

DLSS5_STRENGTH加入白名单，合法两finite数0..1覆盖宿主/menu，auto/空/缺省沿原API/default；非法回宿主报告一次，API范围不扩大。addon/Magpie0..3不改，RE9文件重启、addon约1秒热载；层序不变，剑星native auto仍覆盖custom。CPUparser及900/1080默认/API .4,.6、新file/env .7,.3盖菜单/非法回退hash检查通过，smoke通过。未改网络/math/Style/遍数。

仅装鬼武者root/_storage_ runtime25A617B2，备份strength-config-20261004/backups/20261004-200004；三配置字节hash不变，未写新数值/改变现强度、MP/PRED/SKIN/geometry，剑星addon未动。results/strength-config-20261004，无push/发布。


### 2026-10-04 20:09 鬼武者强度入口版实玩确认

Zero反馈「鬼武者没异常跟之前一样」。当前runtime25A617B2、强度auto/原默认、MP3/PRED1/SKIN0，未提供新FPS；不把本次反馈记作提速或自定义强度数值验收。


### 2026-10-04 C512 w2f8 direct pack组合3已装

活跃mix/contract byte出口省F→decode→同码pack，保c512_hq/Hrtz/激活/K序，入口ar及外部compact residual不动。单mix/单tail慢轮拒，只收组合3；码域proof/27组真实FFN同、macro0双archsection同。正常19/AE CSV/1440受控动history原float/multiSkin/RE9九组smoke通过。

同058 fresh host、只模块的single三档三轮各1440样本：900 avg7.33046→7.30709ms、p99 7.677→7.624；1080 10.19529→10.15365、p99 10.521→10.475；1440 16.97888→16.87560、p99 17.300→17.225。省.023/.042/.103ms，三轮无慢/尾不差，不乘微核层数、不跨批累计FPS。

双游戏仅c512-m32-deep双arch+SUMS98960584/76模块更新，host/config字节保持，鬼武者仍25A617B2；备份c512-direct-whole-20261004/backups/20261004-210325，exact同步。结果results/c512-direct-whole-20261004及c512-direct-pack-20261004，输出留hash再清，不删权重，无push/发行包。

### 2026-10-04 23:06 剑星恢复快速3x配置

用户反馈剑星3x约27fps。核读default/custom/native：custom为MP3/PREDICT0/SKIN0，native仅覆盖MP3；Machine/User无对应环境覆盖。本次C512模块安装保留配置hash，预测关闭早已存在，不能归因此次算子改动。按用户恢复快速3x意图仅将custom PREDICT改1，保BOM/换行及其余字节；备份`D:\DLSSNR-Lab\sword-fast3-restore-20261004-230612`。当前未查到剑星进程，下一次启动读取MP3/PREDICT1/SKIN0（两真实遍+预测第三遍），未声称已测新FPS。已有约1秒热载支持；F9仅切遍数，不切预测开关。未换载荷/跑GPU/动鬼武者。

### 2026-10-04 快速3x预测默认开启

按用户要求，MULTI_PASS_PREDICT共享启动/成员及addon热载默认改1，三模板/CONFIGURATION同步。缺失/空值默认开启，显式0仍真三遍，非法值仍关闭；仅MP3实际用两遍+预测，1/2不改，4/5不扩展。源码提取CPU解析与静态路径检查通过，未跑GPU/换游戏载荷，两游戏custom此前已1。0.41需重编宿主并更新模板；历史结果默认0记录保持原样。结果`results/predict-default-20261004`。

### 2026-10-04 快速3x恢复后的实玩反馈

用户实测：剑星1x约57.6fps、快速3x约37fps；鬼武者900P快速3x约49fps，与此前一样且无异常。剑星恢复MP3/PREDICT1/SKIN0后快速3x体验已确认恢复；快速3x是两遍真实网络加预测第三遍。以上为用户实玩读数，不是同批ABBA，不据此宣称本轮算子优化带来对应FPS增益。未追加测试、编译或安装。

### 2026-10-04 README编译与配置文档校对

核当前真实脚本，更新中英文README的HIP流程：38模块/架构，五LLVM23.1.2预编译、其余COMGR21，RowOpts/PrebuiltDir、当前rtc双目标、宿主MinGW与GPU工具链、可公开复现LLVM源码构建及打包资产边界。复用scripts/CONFIGURATION.md作独立配置入口，链接三份全注释默认模板，说明预测默认1仅3x生效/显式0真三遍、skin0、强度/优先级/热载与RE9差异。已核相对文件链接、配方计数与参数；仅文档，无编译/GPU/安装/发布。

配置说明按语言拆分：scripts/CONFIGURATION.md为英文，CONFIGURATION.zh-CN.md为中文；两份互链，README分别导航，保留原配置键、默认模板与优先级/宿主差异。同时完整清理两份README自然语言混写，保留构建、双架构和完整安装条件。仅文档拆分与同义翻译。

### 2026-10-05 0.41三个完整包本地构建

按tag0.40(c81a88bc)审全部后续改动并更新中英CHANGELOG/README与包内说明，默认仍1x(MP1/PRED1/SKIN0)，只选3x才两真实遍+预测。重编addon/runtime/当前rtc；五LLVM23+33COMGR/架构全重建，76 ELF目标与两架构导出核对通过。三组900/1080静止、720运动逐位SAME；每包44shader、全文件SHA与ZIP回读通过，RE9 staged smoke退出0/4帧errors0。更新RE9源码/重编入口，保许可、宿主配套，不混玩家custom/native。三个本地完整ZIP 342904511/373102226/427749567字节，SHA/台账见results/package-041-20261005及`/home/lmxxf/work/dlss5-release-0.41/`。未安装游戏、未上传、未打tag；gfx1200未硬件实测。打包阶段脚本SHA误替换/BOM及正常stderr包装误判已修，未完成stage不作为交付。

0.41用户上传完成，正式镜像：夸克https://pan.quark.cn/s/dbda3e470f8f（分享名261005-004544243）、Gofile https://gofile.io/d/YAENU0ex。已同步中英README/CHANGELOG及台账；不修改已交付ZIP/SHA，本轮不重下载，未创建GitHub release/tag。

0.41网友使用说明存于Development/docs/使用说明/0.41.md；技术审校默认1x/仅3x预测、三包安装、强度范围、优先级与RE9重启区别，表格实际渲染通过。按公众号要求下载及文档地址全部普通可复制URL，五个GitHub main目标已只读核存在。仅文稿，不修改ZIP/配置或运行实验。

### 2026-10-05 最终共享RGB直写小刀

借用bridge最终输出，保post/predict/skin算术，中间/history/AE私有；graph/OVERLAP/input-history地址重叠旧copy。最终每帧只消除一次，不按叠层倍乘。三档3轮320弃80全部快且p99更低，NR frame wall省900 .022218、1080 .022120、1440 .132975ms；不是FPS承诺。正常19/六组合RAW/真实overlap旧路/RE9两4帧及smoke通过；graph基线PDL互斥未追，初normal误用无逐帧导出runner已更换。装剑星3C518B60、鬼武者root/_storage_4B1852F9，配置/modules逐字hash不变，备份final-output-direct-20261005/backups/20261005-070357。锁释放，帧留hash后清理，0.41包未改。results/final-output-direct-20261005。

### 2026-10-05 block4 pool→首C64字节边

保持q8(F(Hrtz(sum)))与负0，producer出口f32改byte，首C64沿已有nonW16 bi_bo读取；配对HasFn缓存/缺一全旧路，32线程调度，刀1保留。首次实验漏ISA_HALF/PREPACK前缀已隔离诊断并canonical重proof，65536half及12真实pair0diff。生产双arch去proof；三档3轮均无慢轮+p99改善，平均省.01235/.01961/.04311ms，900末轮近乎平不吹显著。正常19/多遍history skin/缺export旧路/RE9两4帧smoke全过。安装8547C07F/14BAC9FA与单mh-fast-packed双arch模块，配置字节未变，备份pool64-byte-20261005/backups/20261005-073426；锁释放/帧留hash清，0.41包不动。results/pool64-byte-20261005。

### 2026-10-05 真实1440 FAST3持久队列

CPU DAG覆盖/need≤4/1488tasks证明、同FAST3新SPtwin真实段正常recover/rollover六组0diff。仅1440 FAST1启用，FAST0/graph/缺twin全旧Body，旧900/1080normalSP不动，plan预加载在构造期。1440三轮全部快，省.089376ms，p99 16.832→16.748；七few RAW/RE9 1440单遍与预测3各4帧真命中SAME、smoke过。安装698A23A4/634FAF45，原76module逐hash不变+双arch twin到78，配置hash不变，保刀1/2。备份sp1440-fast-20261005/backups/20261005-080146，锁释放/帧hash后清，0.41已上传ZIP不动。results/sp1440-fast-20261005。

### 2026-10-05 待验证线索：history与闪烁

网友反馈：“好像还是必须得搞个temporal history，那两家默认都开着，不开就是会闪烁”。“两家”未明确指认，默认开关事实未独立核实，仅作为线索；不能据此认定history必需或闪烁原因已定。后续同seed/输入/分辨率对照history开关，结合issue13现有证据核验。用户同意后续研究mochi ViT大tile与小buffer延迟复用，本轮先记录不实现；未改默认、测试GPU、编译、安装或外发。

### 2026-10-05 网友补充：建筑亮度闪烁与跳块线索

网友明确111.mp4闪的是建筑物亮度，不是衣服；此前视频分析着重运动区域，误判了关注重点，当前两个代理正在重新分析同一建筑区域的亮度变化，尚无新结论。

网友实测跳块32–36、38“可一定程度抑闪，并较大程度保留‘两层’效果”。保留“两层”原话，不推定其对应真实两遍网络或其他实现。此反馈尚未独立复验；跳块改变网络、属于有损取舍，不能据此宣称已定位闪烁根因。默认full71及游戏配置保持不变，本次只记线索，无GPU测试、安装或外发。

网友随后按“31–38 + 41–47”做对照，反馈40后的块不影响该房顶反光，而全跳31–38时房顶该处反光基本消失。此为该场景的未独立复验线索，跳块仍属有损；消除反光不等于保留反光同时抑制闪烁，不能据此称根因或修复已确认。继续对房顶亮度重新分析，未改默认、游戏配置或公众号稿。

网友进一步反馈：31–38逐个跳任意1块仍闪；按单双编号分组各跳4块，单数组一定程度抑制中间闪，双数组一定程度抑制边缘闪。尚未独立复验，编号与网络结构仍在核对，不能推断奇偶对应shift或某单层bug；默认未改。

重新分析111.mp4同一建筑灰石/房顶高光的连续裁剪，确有亮暗反复：0.517→0.621→0.655秒为亮→暗→回亮，1.586→1.621→1.690秒为暗→亮→暗。最初关注衣服/草地并称静物相对稳定，误抓重点；撤回以此否定建筑闪烁的暗示。拍屏仍有混杂，未定位NR或temporal根因，裁图留/tmp、不复制大图入仓。

源码核对：31–38均为完整ViT FFN＋全图attention＋残差块，不是奇偶shift或功能交替，37没有特殊源码角色。网友skip干预提供该段的定位线索，但去掉反光不等于保留反光并稳定时序；尚不作根因/修复定论，默认与游戏配置未改。

2026-10-05：完整读取旧 WorkingPlan 与近期记录后整份重写，纠正0.41已发布/tag及三刀已装状态，保留Issue13版本缺口、Issue4双设备验证、gfx1200真机/720 oracle等未完成项。下一顺序为建筑房顶闪烁时序合同诊断、ViT960 contract大tile、小buffer延迟复用；当前post导出缺少原row6门控权重已列为CPU核验项。此阶段只整理计划，未运行GPU、未改默认/游戏配置或上传包。

2026-10-05：MP1时序默认关闭实验完成受控闭环：原5090合法两Eval核Reset/seed/history绑定；恢复遗漏row6 gate，原head24576半码0差，SIG跨vendor最大3ULP已量化、严格实验用NV表。原post四小gold（含对角亚像素）与软件warp/gate全float-bit0；AE0三路小NN48行＋valid1080/proc1152合成NN18行无NaN、off/reset独立基线及自重复0字节差。首批误继承AE1留diagnostic，不作质量结论。合成亮度并非普遍更稳，未称修复房顶视频；原内部history格式/内容与真实连续源仍待验证。无游戏部署/默认或0.41包变更，按顺序转ViT960大tile。5090数据/缓存全C（D源只读、极小锁例外），9070仍D，实际写入盘≥100GB。results/temporal-sequence-20261005。

2026-10-06：按既定顺序完成两项无损候选裁决。ViT960 contract两wave共享K512 FP8权重：canonical双arch baseline208VGPR/无spill，candidate256VGPR/171spill/688B private每thread，静态门拒、不GPU、不调更多tile（main64257116）。小请求≤8MiB晚一logical批复用：graph旁路/PDLrefs不动，CPU七case过；真实1440/proc1472/960tokens完整框架首ABBA A15.680819、B15.742244ms，慢0.061425，两B槽均慢于A，raw全SHA同，立即止、不收生产/安装（main661c41a9）。候选patch/源/CSV/hash已留，自身raw清理、锁释放，不删weights/输入。此前MP1时序受控阶段有原语/三路闭环但无真实视频源、合成波动不普遍改善，仍默认off、不称闪修。三项具体结论已记，当前游戏配置/载荷与0.41 ZIP/tag不变。


### 2026-10-06 mochizuki差距只读审计与后续规划

三路子代理只读研究后归档results/mochizuki-gap-audit-20261006；未跑GPU/SSH实验、编译、安装、改配置或发布。当前全71/FAST1与0.41后三刀尚无刷新竞品对照；旧事件均摊与DUP保留诊断，不作为精确族贡献。纯Network分支使用CPU chrono＋逐帧StreamSynchronize，后续先保同步加GPU端计时；批量前审pool/PDL/SP代际。当前本地mochi4f62a8a不同于旧测速d1185d2，后续先锁旧exe/SPV/plan/effective宏/源/模型与输入和边界，缺资产明确报告。规划同HIP16query数学阶梯（FAST0/当前FAST1、score halfFMA/位图、64key half分母树、确认后的AV截断/half末端）；每步数值/资源/整网门独立，有损仅研究不部署。当前分母half输入/f32累加、AV FP8输入/f32累加。只有显著资源变化才复查旧M32交互，新热点证明等待后才局部ISA排程。跨层≤4父子依赖暂无新候选；旧全空消融不是本体上界，8streams负账不泛化为所有队列上界。WorkingPlan新增上述优先顺序，保留发布/当前安装、真实时序与Issue限制、两项已止负账。


### 2026-10-06 用户优先序校准：先处理闪烁

用户明确仍优先建筑房顶闪烁。WorkingPlan将真实时序/反光场景验证恢复第一优先，mochizuki差距对账列第二优先，等待真实连续源期间只读CPU锁账作备用工作；保留已归档优化规划与负账。研究报告同步注明主线优先级。本次仅改文档排序与说明，未新跑实验、未改生产/游戏配置或载荷、未发布。


### 2026-10-06 闪烁下一步：原history身份与写入链审计

只读审计后补计划：先CPU沿backend vtable/cuGetProcAddress已有hook核texture/array/external-memory/context绑定、创建descriptor，匹配post history+0x58/motion+0x60，追保存rawRGB/blendRGB/编码。observe_temporal.inc on_launch在真实launch前查context，null不能证明资源不存在；私有接口需走D3D资源包装映射，不自行切/建context试私有handle。实验warp.hip:57的f16 RNE→f32为自定policy；live_capture冻结同输入/zeroMV、sequence合成及submission probe单次snapshot不构成连续真实color/MV/depth/jitter/exposure源。先CPU接口/元数据审计，再受控GPU取内容，真实场景仍待连续源。本次仅补文档，未新跑GPU实验或改生产。


### 2026-10-06 原版history资源与post FP16写入合同取证

子代理隔离5090原版两Eval（Reset1→0/seed0→1，Issue13既有8678/8680输入，非111.mp4）全部SUCCESS。沿原backend GetTex/GetSurface返回值直接关联D3D12Resource/GetDesc，不强切context：原history为1920×1080 RGBA16F，post另写RGBA16F surface0x8803；后段保存到history surface0x8805并生成独立API RGBA32F。第二Eval读上一帧同一history资源0x7f800008808，pre/post共用该history和独立RG16F MV。每帧history与post输出8294400half码0diff/alpha1；与API final half化RGB分别6191925/6189007码不同，history不是API最终输出域。仅清第二Eval post packet+58/+60、prefix/seed/input其余不动的控制组，首帧0diff、第二帧RGB3077213half变化，证明正常history确实包含有效post blend。

发现隔离MP1实验存储舍入错误：原CUBIN在blend后SUST.P格式化写，无显式F2F；同核同输入输出FLOAT4/HALF4对照，zeroMV/+1px各1024值RNE差496/RTZ0diff，亚像素RNE差576/RTZ0diff。有限正RGB工作域原post HALF surface实际RTZ，不能沿实验默认RNE。已交集成代理修隔离temporal_store，非生产部署/默认修改，也不称房顶已修。八份4KiB可重放gold、source/build/cubin/输入/SHA、真实绑定与读回log、大型raw外置hash见results/history-contract-20261006。完整探针只在hook外完成读回和原state恢复，故不计性能；C盘约784GB写cache，D旧源51文件元数据无变，锁释放/无游戏结束。真实连续源、后续Reset/缺MV/曝光变化与MP3政策仍缺，本阶段不追加重复SIG/head/warp门。


### 2026-10-06 MP1原型RTZ修正与实际codec回放工具链

按history-contract原CUBIN HALF4受控gold，隔离temporal_store由RNE改显式RTZ，保存内部gate-blend有效RGB/alpha1；该错误只在未部署原型，不能归因现装游戏闪烁。9070四组closed/zeroMV/+1px/亚像素store对原gold float-bit0。新增共享MP1租约状态与CPU first/reset/resize/failure/missingMV双policy门；missingMV合同与MP3分遍/共享仍未定。实际NativeGameCodec/RgbInput/TemporalFeed/Coordinates shader转换synthetic1280×720单帧重复两次hash同/finite/alpha1/proc768 mirror同；UV转pixel位移会有6.1e-5残差，prepared改直接UV入口避免往返。prepared三路×两seed×两帧12行finite、独立baseline/repeat byte0，不作质量/性能结论。统一real-sequence manifest封存/显式recipe与converted receipt/index接线，保留seed null、upscale0和source identity未核为blocker；raw FFX directfit未跑FSR、jitter/depth未应用的范围显式记录。采集入口b439efc6/adbb2bf2只CPU链接与保守守门、未GPU采集/部署。GPU实验使用原子锁/game-check/15s看门狗/D约412GB，未遇游戏、锁释放；生产默认/玩家配置/现装载荷/0.41包不改。results/temporal-replay-contract-20261006保留CSV/日志/SHA/receipt，WorkingPlan更新；真实连续roof源仍pending，本阶段停止增加合成案例。


### 2026-10-06 旧mochi0.0.2.5完整资产锁定与提交口径纠正

恢复/tmp/claude-1000/ct/mz的d1185d25141b1714d7837151b6fa782e6427568b真实旧源码（tracked clean），local旧up/mz与9070competitor-timing-20260930/mz共70资产逐SHA同，七日志也同；旧exe8ad3ac1c…/model2b41c888…和三plan/48网络SPV/markers齐，不升级HEAD/不改旧资产。glslang16.5+quad+NR_Q32_DIRECT1隔离CPU复编48/48SPV逐字节同，C32 direct0不同；有效宏已锁。

撤回09-30竞品报告及本日早先审计“mochi500帧一次提交”的假定：d1185d2 nr_graph.cpp:3921默认chunk1，runner按单pass submit→fencewait；actual旧exe反汇编r9指向字面1/r8指向--chunk，旧mz2未指定chunk。打印“123dispatches, one submit”指单pass固定文案，不代表500pass合批。0.1～0.3ms提交差估额不能继续解释旧差距；未来batch仅新控制诊断。发现旧CLIgradient/style0与我GameCodec冻结HDR不同输入/控制，noise-field在对手build一次计算而我prefix逐帧计算；900 ViT448对400、旧跳块C51213对16亦须重摆。noise旧09-19消融0.0175/0.02975ms负账保留，当前组织虽变也不先称缓存必赚。完整source/recipe/48重编/remote/local manifest/原七log/actualexe反汇编证据见results/mochi-old-lock-20261006。无新GPU轮/配置/安装或push；下一步同encoded fixture、full71 FAST0/1 MP1AE0historyoff同步纯网络短账。


### 2026-10-06 0.41-a默认关闭history接入及旧对账校准

用户授权regular临时包给网友试，未授权本机现装变更。源码freeze1a22ee96：regular FFX pre-upscale MP1可选fullgate，TEMPORAL_HISTORY_EXPERIMENT默认off、MV_UNJITTERED1为显式实验前提；有效internal blend RTZ/alpha1历史，bridgeUV carrier固定8B，warmup失效，热MP3旧Body seed0、回1cold。720/1080 core first/reset/hot/off及独立gate全部bit0 finite；实际Frame720缺MV/曝光变/gap等cold门bit0。参考gate1080最短8帧GPU均9.1459→14.1795ms，明确+5.03ms成本，无质量/FPS承诺。regular84模块包仍在隔离stage；stock gfx1200发现27错target，打包按当前canonical与041 identity修正，不复制错误target。canonical source/defines/compiler/opts比对ab8e3e82：29row完全同，10row变化/新增（包含post tap/poolbyte/include变化/SPfast），report在history-trial-041a-20261006。未装游戏、配置与正式041不动。

按mochi-old-lock-20261006/9d94c9e3完整旧source/exe/70资产锁证，旧500帧一次submit说法是打印文案误读，实际默认chunk1逐帧submit+fence wait；0.1～0.3ms提交猜额撤回，不能解释旧差。48网络SPV同toolchain重编bit同，C32 direct/quad1及ViT NR_ACC_F16=0已锁，不归因AV每块half截断。WorkingPlan与早先审计报告同步校准，旧历史正文保留并追加纠正。


### 2026-10-06 当前900共同encoded输入同步纯NN首账

原子单队列受控首两ABBA：F0/M/M/F0与F1/M/M/F1，各80暖160测。当前core1a22ee96/staged普通stock39，full71/MP1/PRED0/SKIN0/AE0/graph0/historyoff、Style1/seed0；旧mochi锁d1185d2/8ad3ac1c…、显式chunk1。共同half-exact encoded synthetic gradient1600×900，我HIP按1798-y镜像到底1600×960；M --in-image格式RGBA32F/NEAREST、不运行runtime_encode，CPUvalid/pad逐位证明。并非真实游戏源。

GPU均值FAST0我6.706866对M6.017463、差0.689404ms；FAST1我6.628813对M6.028481、差0.600331ms。CPU均值另列6.884184/6.142481与6.790059/6.156988，不用CPU中位减GPU均值。四HIP160CSV全正/finite、首尾0bitdiff且同FAST跨processSHA同；M四slot RGBA全finite/alpha1/SHA同。剩余差距未因果拆清：900 ViT400对448、noise预生成/逐帧、Vulkan复用commandbuffer/HIP逐帧host发dispatch、output padding/存储与数学均未完全同。HIPwarm后首raw短idle使前5略高，160均值比后155高0.007～0.011ms；正式表不扣、不刷新轮，无真实clock锁频证明。

首次启动被packager rtc_compile门拦（未GPU/未lock），等自然退出再运行；D411GB实际写/cache、无正常游戏结束，15秒game watchdog。两ABBA即止，旧mochi元数据无改/锁释放；只清自身raw输出并保输入/weights/原logs/model/SPV与全SHA，本地/tmp保raw。报告/scripts/CSV/普通module与asset SHA见results/sync-network-gap-20261006。未安装玩家载荷或动配置，不把三刀跨批相加/FPS承诺。另独立静态核双arch六history新ELF的目标/export/SHA与receipt同；legacy marker off/on都移除、首backup跨切换恢复的源审见results/temporal-package-review-20261006，未新增GPU。


### 2026-10-06 ViT数学阶梯B/C负账与稀疏stage扰动线索

当前FAST1 canonical深核隔离B只half score FMA/map，C再64key半分母树、保16query/原FP32 QK/AV。真GPU独立gold161795score及64query×400/640 denominator全部halfcode0diff；双archA/B68VGPR、C62，无LDS/private/spill。1088/640 full71/MP1/AE0/history0首ABBA：B平均+0.007611ms、p99−0.015198，C+0.036425/p99+0.028335且两C均慢，按门不收、不D、不旧M32扩扫。raw有限/自重复bit0，单共同synthetic相对A PSNR52.20/52.63dB；无性能候选不扩画质/900刷轮。实际640 ISA A/B/C WMMA5/5/4、VMEM22同、VALU216/228/247、bpermute0/0/4；Bscalar转换/floatclamp往返与C更多halfadd/shuffle是执行组织代价，不判纯数学更贵，62VGPR不认已提高occupancy。结果vit-math-stair-20261006。

随后隔离当前host在C51223–30或ViT31–38仅一pair，保常规totalpair；无插/C512/无插/ViT/无插五slot，整个执行pdl_calls0/ordered，raw同finite。无插约8.901/8.898/8.918ms，插C512 total8.741、插ViT8.794ms，stage raw0.6305/1.2796ms；明显负扰动约1.8/1.3%，不均摊修正为真实族份额。下一仅C512起点无pair/空pair/nonblockingquery/匹配CPUdelay，检提交节奏而非直接收插桩刀。初smallrunner误用PS$args造成Usage、修arguments后通过；sparse隔离header重复include由复制EnvOptions一致入口修正，非GPU数学失败。所有GPU按单队列lock/gamecheck/15s看门狗/D约409GB，释放后交下家；生产/玩家配置/安装/正式包不改。


### 2026-10-06 1080同步首账与锁定ViT数学合同

共同half-exact encoded gradient1920×1080、Style1/seed0、full71/MP1/AE0/historyoff，双方逐帧submit；first raw移到warm之前，80暖160测。1088同640token首ABBA：FAST1我8.880759对M7.867191、差1.013568ms；FAST0我9.025781对M7.882941、差1.142840ms。生产1152我FAST1/0为9.344975/9.491284ms，对M固定1088为7.891163/7.902309，处理高不同明列不可作同工作量归因。全CSV正值/有限，首尾与重复process逐位一致；CPU单列，无锁频证明，不新增矩阵。source/input/module/model/flags/边界与noise成本见results/sync-network-gap1080-20261006。

锁定d1185d2实际SPV确认QK/AV FP32 cooperative accum，NR_ACC_F16=0，half score FMA与64key half分母树，P恢复natural key后AV，只有出口ctx/inverse/product半化，不补猜中途half截断。小CPU独立树/出口gold与实际source/SPV身份见results/vit-math-contract-20261006；source-RNE gold不冒充原驱动逐值证据。62与68VGPR按gfx12 wave32 granule24均分配72，不支持occupancy提升。


### 2026-10-06 B2半clamp去转换真实短筛

B数学同域表达式消除half→float clamp→half往返，COMGR21真实640 VALU228→213、转换16+16→8+8，资源68VGPR同/分配72。GPU161795score独立gold0halfcode差；1088同full71 A/B2/B2/A均值delta−0.006105ms、p99+0.054664ms，两个B2不都快于两A，弱短筛暂不收不formal。整网B2对先前B逐floatbit0差；对A合成baseline PSNR52.1965、maxabs0.0348168，不作为生产画质验收。锁释放exit0，源/ABI/dualarch SHA/原CSV/原ISA与CPU有限域边界见results/vit-score-halfclamp-20261006。未部署。


### 2026-10-06 C2 keyperm保持C数学的真实gold与短筛

仅640完整chunk：Krow置换就地half分母/P恢复natural，再原AV；COMGR总静态405→398、VALU247→251、DS动态16→6/64，VGPR56仍allocation72，400原C指令完全同。四fixture含±0，实际逐层QK/P/denprefix/AV/finalbyte全0差/有限，整网对前C逐floatbit0差。1088 A/C2/C2/A首ABBA delta−0.004771ms/p99−0.068848，但两C2不都胜两A，弱短筛不收不formal。相对当前A合成PSNR52.632604/maxabs.0335403，非生产画质验收。source/COMGR实际ISA/dualarchSHA/tracegold与CSV见results/vit-den-keyperm-20261006；CPU44001/GPU38113均exit0锁释放，队列交integrator，无部署。


### 2026-10-06 C32norm转置CPU权威baseline校准

最小原型6ed1ae68旧-S CPU169→193VGPR不是实际active ELF；撤回allocation192→216/occupancy变坏说法。补完整canonical WindowsABI/C++14/-real-true16/rowopts/BC→-c internalize→link，A实际hsaco SHA f46b8af2…ee52与stock c32-wave1-fast逐byte相同，FAST3/type/RTZ身份真锁。真实A/T prefix128→128、chain131→129、post132→128，均allocation144；LDS4096→4608。真ISA chain1030→1119、prefix1517→1536、post1524→1544，三者DS+36、rsq16→2。静态止依据为恢复FP8片段DS/总指令/LDS增加，非VGPR占用退步；未GPU/未数学同值claim。新actual-object-isa-summary与命令/ELF身份覆盖旧-S资源结论，见results/c32-norm-transpose-20261006。


### 2026-10-06 C32safeT实际占用与gold首门失败

撤回仅多指令/DS就静态判性能的早停，fd6a201b补safeLDS fences、occupancy与gold。受控GPU4288：实际HIP A三kernel16blocks/multiprocessor、safeT均14，真实LDS4096→4608边界；不是性能裁决。unitgold零fixture六层0，首signedfinitefixture rawQKV/half-square0，但sum/inverse/normalized/FP8各512diff，最早sum表示/索引失败。按门stop，±0/Inf后续fixture没跑、actualprefix没跑、整网ABBA零槽，不声明数学等价或性能胜负；锁释放exit1立即交formal。matrix/原stdout/occupancy/API身份与failure见results/c32-norm-transpose-20261006/hardware-firstgate，后续仅CPU查f16WMMA布局不凭FP8布局套求和。


### 2026-10-06 C32 QKV片段轴校正与范数失败定位

从已capturefixture1独立复算input/w ±1/8 F64denseDot，旧rawtrace每ci16×16转置还原后512项0差，证明A真正token=lane%16/feature=ci16+gr8+e。此前“C32 lanefeature需转置”判断反了，撤回；layout纯byte恢复证明同样建立在错轴假设，不作productioncontract证。half平方均1/1024整数倍，32项exactCPU整数sum与实际旧sum512项0差，各lane8个sum相同；safeT的sum0拿错逻辑轴，非FP32累计精度差。原C32已tokenlane，直接保持旧QKV/half-square/twoWMMA，只hoistrsq(sum0)可能才是最小表达式；当前只CPU定位不编新候选不GPU，仍需全gold再性能。见results/c32-norm-transpose-20261006/layout-resolution.json与resolve_layout.py，旧捕获immutable。

### 2026-10-06 提交事件完整框架正式门与尾部关联

- 同C512起点空timedpair的纯NN控制正，单非blocking query/匹配1us CPU延时负；不能由此断言Windows驱动必flush。完整NativeGameFrame/原codec/当前FAST1/full71/MP1/AE0/history0、既有真实HDR冻结输入，900/1152短ABBA均值与p99正、first/last同SHA且finite。
- 同batch T/U不支持untimed优于timed；timed正式三round320弃80：900平均三轮均快且p99均降，1152平均均快但round3 p99+0.08934ms，按门不收、不刷paired同variant。用户安装/config与正式/临时ZIP未变。
- 现有尾数据NET分布p99降、wall尾升，但旧logger未写tag且Poll返回最近完成值，不能保证逐frame关联/CPU唯一归因。tag在bridge仅记录标签、无去重，因此全0本身不阻止elapsed更新。下一隔离single timed event同位置/少一次Record，新logger同一次原snapshot打印currentframe/tag/匹配ready，不新增query/sync。CPU链接通过，GPU尚未执行；实际optional失败回退/owner-drain生命周期helper独立准备。
- 结果与原数据：results/submission-pacing-20261006、results/framework-submit-pair-20261006。仍有约900 0.6ms/同1088 1.01ms对手残差，无足够新生产优化。


### 2026-10-06 C32原布局范数rsqrt hoist首账

只H保QKV/half-square/twoWMMA原顺序，rsq(sum0)每lane一次，无transpose/新DS/LDS。canonicalA hsaco逐byte stockFAST1同f46b8af2…ee52；模型201assets/modules/commoninput SHA门全过。实际prefixISA1517→1480、rsq16→2、DS23/LDS4096/VGPR128同0spill，HIP A/H三kernel真实occupancy均16。8unit含±0/±Inf/half-square边界六层0diff且all8sum每lane同；真实prefix实际weights/FFN/encodedinput trace0/有限，全NN first0。93415初prefixCLI多传W报Usage未执行，修PH-only后12716全门exit0锁释放。1088 A/H/H/A warm80测160：8.901741/8.839896/8.844241/8.904607ms，delta−0.061106/p99−0.024127，两H均快两A；所有prefix与四process首尾raw SHA相同/finite/repeat0。首筛真实收益未formal、未扩档/默认/部署；结果source/gold/CSV/ISA/模型与载荷身份见results/c32-norm-hoist-20261006，队列交integrator，不与B2/C2跨批收益相加。

### 2026-10-06 单timed marker与实际lease接线首门

- single同C512位置仅1event/1Record，完整framework既有HDR/当前FAST1/full71/MP1/AE0/history0首900ABBA160弃80：wall平均−0.162513ms、合并p99−0.01925ms，only-ready NET平均−0.120672ms。四slot全部160/160tag=i+1匹配，first/lastSHA同/finite；42116exit0/LOCK_RELEASED。仍首筛，p99余量小未收。
- b4a803c3真实共享lease18CPUcase与748787e9实际HIPops adapter fake ABI注入过；新隔离safe版本不再Create/Record throw through bridge。private friend-only在bridge.Create末尾noexcept配置，直接Network不启用事件；warm/Wait显式ownerdevice，bridge析构先wait再Close，失败保整个Network/桥资源。实际device/runtime失效只保证继续旧NN尝试，不保证恢复。
- safehelper同exe1152首ABBA：wall平均−0.188544/p99−0.11173ms，only-ready NET平均−0.131454/p99−0.158580ms；640tag匹配/raw同/finite/active1无API异常，2447exit0/LOCK_RELEASED。与旧900throwprototype为不同源码，不能跨批比幅度。结果439a0105，results/framework-single-event-20261006。
- 已备same-safeexe一次正式round320弃80及ready-only analyzer，每轮即时检查尾部后才下一轮；尚未跑正式/normal19/动态fallback，多设备硬件未证。不改生产默认、现装/config/0.41-aZIP，不将首screen认已追平mochi。

### 2026-10-06 single safe900正式首轮负账

- 实际safelease/HIPadapter同exe正式900none/on/on/none320弃80，A7.093942/7.135950、B7.121513/7.150271ms，平均+0.020946ms、合并p99+0.10405ms；matchingNET平均+0.015632/p99+0.009636ms。1280/1280tag当帧匹配，allrawbit0/finite，无记录错配借口。
- 按门首轮即止，不跑1152formal/剩余轮/normal19/计时off重刷，不默认收。旧throwprototype900与safe1152positive首屏如实保留，各自source分列；不能把跨源码/批次初筛覆盖当前正式负账。当前O1/NET_TIMING1条件不推canonicalO2/默认游戏计时off。
- session42446exit0/LOCK_RELEASED，results/framework-single-event-20261006/formal-safe900-round1原CSV/tag日志/hash及largest-wallframes归档。玩家现装/config/ZIP未动。下一优化按根进程排独立normhoist门，不将两个未收候选相加。

### 2026-10-06 校准pulse诊断与实际APP条件（CPU准备）

- 已正式负账仅O1/NET_TIMING1条件；不能据此判APP无效，也不能拿旧positive首屏判APP有效。paired/single诊断线仍封存，无GPU重刷。根进程随后要求准备一次必要实际APP条件，等独立HnormAPP双档门后再决定执行。
- prepare_app恢复原NativeGameFrame benchmark loop、canonicalO2/static、NET_TIMING0/allprobes0，完全无GetTimings/GetStatus/Poll/SetTag；禁lazy-enable诊断入口。保原directIO/async/inputpoll0与默认post_signal_streamquery。新增普通CPU计数并退出打印pulseCreate/Record/Destroy及outertimerAPI数，未新增query/sync。O2完整链接0，实际counter版本adapter/leaseCPU ASAN/UBSAN faulttests过，toolingparser能拒非零诊断query，非GPU/质量实验。
- 权威原O2/HDR/fullFrame/模块overlay参数已交math代理做HnormAPP主测；本代理没有上传或执行APPpulse，以免扰正在GPU窗口。app-cpu-preparation.json绑定source/exeSHA，玩家配置/载荷/ZIP未改。

### 2026-10-06 撤回safe900性能负账归类：运行时未生效

- 新APP900 O2/NET0权威退出计数候选Create1/Destroy1/Record0/drain0，stderr frame-scope-fallback；outertimer APIs0、正常post_signalquery160，raw同/finite。平均−0.01776/p99−0.01439ms无有效Record，不能归pulse。40018exit0/LOCK_RELEASED。
- 回看a792f33c旧safe900formal原stderr也有fallback，先前只看构造active1与正常NN时序而错归性能负账。现明确撤回single Record性能失败断言；保留原CSV/数值/历史记录，不删负数据，归类为eligible/fallback门。旧无guardprototype900和safe1152为分离条件，不相互补证。
- pdl_calls在实际AnyOrderAPI处累计；ctor0不保证C64/C128/C256后C512marker处0，pdl_anyorderfalse也不是GPU完成证据。CPU加一次性runtime requested/active/rejectmask/pdl/record尝试成功数；startup改initialized/pending-first-record。默认baselinePDL1未关，900保守unsupported。下一1152真正on/off需actualRecord=N、pdl0、资源销毁平衡，不能创建事件就认已启用。此处修正未新跑GPU。


### 2026-10-06 Hnorm真实APP900三formal严格尾门失败

原O2/NET_TIMING0/真实1296×720 HDR完整NativeGameFrame，stock/H，320帧弃80，每轮ABBA原cold/全CSV/raw保留。R1 14321 mean−0.0449291667/p99−0.11656ms过，R2 57250 −0.0492479167/−0.07877过，R3 89525 mean−0.0451625但p99+0.000140ms(+0.14µs)严格门fail立即止，不舍入0/不临时容差/不刷/不挑槽。全部first/last frame SHA相同/finite/invalid0，三轮exit0锁释放。现有native-hip日志最终四pid明确fast1/wave_owned_active1/processing1600×960/hip_device0/modulesA,H,H,A，Factory FastTwin c32-wave1与H实际文件/exports/source锁同，非pulse伪on/非coldcallee；genericMH缺fasttwin是双方stock原路。三轮均值改善真实记录但验收未完成；900normal19/history/normalRTZGPU回归没启动，1152短p99负账保持，不收生产/不称全目标完成。见results/c32-norm-hoist-framework-20261006/formal-summary与active-route原日志。


### 2026-10-06 H900 p99 CPU测量分辨率校准

不新性能轮/不改CSV/不改临时容差，审三formal原数据与实际O2exe。steady_clock::now实际gettimeofday→getntptimeofday，以µs值乘1000成名义ns；原CSV壁时全部整数µs。轻CPU同compiler probe min/gcd1000ns，QPF10MHz/100ns另读但不是此walltimer路径。R3+.14µs是exactDecimal插值非float误差：A475/476序统计7255/7326µs，H7269/7274，权重.21，端点差+14/−52合成+.14。低于1µs实际量化，仅正号不能证明真实尾退步；解释为测量层未分辨/兼容0，非无限future统计等价。控制A3−A0 p99三轮−35.74/+47.76/+43.31µs；三轮全1440/arm pooledp99A7333.44/H7258.86µs，差−74.58，不用pooled静默替旧逐轮门。旧按严格正号停是真历史；root据新误差证据决定能否继续900兼容门。1152+73.99µs独立负账不随此放过。原表/时钟反汇编/QPF/CSV SHA见results/c32-norm-hoist-stat-audit-20261006。

### 2026-10-06 ordinaryDown边界修正后真RecordN APP首双档

- 独立6ecf9a0c primary审与根进程授权：pdl_calls非pending，原C256链后普通Down→原C512起点可测试单marker。只knownDown普通Run成功后立per-Enqueueflag/当前anyorderfalse；保PDL1及原graph/MP/full71/history-used等限制，不换位置/新mode，不关 baselinePDL。
- 实际90051314数据门 cold/warm/改真实HDR(+shift7/gain1.01)+seed7/return，A/B5帧逐位0finite，candidateRecord5成功/PDL20/firstprefix2/currentanyorder0/资源balance；MP3initMask128零events，legacyhistory冷首Record1后mask1回退，对应全raw0finite。非自然时序质量结论。
- sameO2NET0scope真on90028126 mean−0.092794/p99−0.19514ms，115281547 −0.092088/−0.12544ms，160弃80；两B均快，各Record160成功160/createDestroy1/siteAccepted160，diagnosticouterAPI0、原postquery160；900PDL640、1152PDL0，raw同finite。均exit0/LOCK_RELEASED给H900compat，尚未正式/默认收，不与H收益相加。
- H900计时裁决采用f38c3cb4：1us原计时量化、round3p99插值+0.14us保留不改/不抹数，低于分辨率且全三roundpooledp99−74.58us、controls漂移35–48us，根进程裁测量内持平进900-only兼容；1152+73.99us仍负。此方法不是随意增加容差，不称三轮全部p99负。整体追平目标未完成。

### 2026-10-06 trueAPP单marker正式round1双档

- 完全同e30ad811数据/首筛源码与O2NET0 exe、原Stock/PDL1/full71，none/on/on/none320弃80：900mean−0.081840/p99−0.11964ms；1152mean−0.090679/p99−0.05103ms。两档each两B均快，两侧对应raw同finite；candidateRecord/siteattempt/accepted320(CreateDestroy1/drain1)，80warm+240steady无额外NNwarmup，所有outertiming/span/poll APIs0、正常post_query320；900PDL1280/firstprefix2，1152PDL0。
- 95590/92559各exit0/LOCK_RELEASED，给H900compat准备队列。必要round2/3尚未执行，本轮未提前默认收。独立当前execlockasm确认gettimeofday1us量化，同f38c3cb4原样端点/插值方法；现p99负变化119.64/51.03us明显高于分辨率，不借GPU分项。原cold samples全部保留。
- ordered-boundary-app各formalround1目录CSV/log/SHA、clock-contract/asm归档；goal未完成，不与Hprefix结果相加，无配置/安装/ZIP/push。
