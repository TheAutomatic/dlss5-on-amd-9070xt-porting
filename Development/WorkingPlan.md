# 当前工作计划（覆盖式，不续写；最后更新 2026-10-01 晚，朱雀）

> 开 session 先读这页。**这是项目唯一的"现状 + 规矩 + 为什么"**：实验过程与数据进 DevHistory.md（只追加），版本改动进 CHANGELOG（中英两份），其余一律改这页（整页重写，读一遍再重写，该删的删）。
> 节奏：过日子式，没有 deadline。优先做有具体瓶颈证据、可逐位验证的小实验，够用就交。

## 当前基线（0.38，09-30 发布）

- **0.38 已发布**：夸克 https://pan.quark.cn/s/6856d875bbe9 + Gofile https://gofile.io/d/lzsqfUiE，tag 0.38（源码 e1b1a18c）。清单 `results/package-038/checklist.md`、`HIP-SHA256SUMS`；脚本 `tools/package-038.ps1`（下次复制它）。0.38 相对 0.37 全逐位（14 刀，详见 CHANGELOG 0.38），900 派发 179→162、1080 162→158；唯一有损项 `DLSS5_NETWORK_1080_ROWS=1088` 可选、默认 1152。
- **0.38 之后已装未发包**（剑星/鬼武者 09-30 22:00～22:39，逐位 19 组 SAME，两档三轮全正、p99 变好）：
  - `HIP_C512_HOIST_RES 1`（attn-project 残差初始化外提，multihead-fast-padded-wave-packed gfx1201 47F00EBA）：900 −0.022～−0.031、1080 −0.026～−0.035ms（`results/fill-cu-20260930`）。
  - `W2_HOIST_LOADS 15`（c64-wave2 48B6FA8B）＋`CW_HOIST_UP 3`（c32-wave1 020B2B0D）：合并 900 −0.043、1080 −0.066～−0.072ms（`results/hoist-loads-20260930`）。
- **离线（10-01 晚，现装逐位档同口径，`results/gap-map-evening-20261001`）**：HIP span 900 **6.81/6.88**、1152 行 **9.50/9.56**、1088 行 **9.08/9.13ms**；wall 900 7.33/7.41、1152 10.05/10.11、1088 9.62/9.68ms。今早（FUSEQKV 前）span 900 7.27、1152 10.05、1088 9.65 → **一天快 0.42 / 0.52 / 0.55ms（约 6%）**。0.38 时 span 7.256 / 10.065。
- **游戏本机（逐位档）**：剑星/鬼武者 = 0.38 网络 + 09-30 三刀 + 10-01 全部逐位刀（见下条）。最后一次装机 10-01 09:13：剑星 add-on 0D739130、鬼武者 RE9 runtime 2CB95057（RE9 回放 SAME，smoke 0）。剑星 flags `DIRECT_IO=3`、`MAKE_RESIDENT_EVERY=60`、`SWIN_RUN=1`、`FRAME_STATS=5`。fast 档模块与切换脚本在 `D:\DLSSNR-Lab\fast-tier\`（`to-fast.ps1`/`to-exact.ps1`/`status.ps1`，`exact\` 是现装逐位快照，装新刀要同步它），游戏当前是逐位档。RE9 仍 0.35 全套；33 号远征队 0.35 常规包。
- **10-01 下午 bitexact-pm 装机**：`HIP_DEC_WIDE 1`（deep_fast-packed gfx1201 7FDA5868 / gfx1200 E55635E2，模块级，add-on 0D739130 与 RE9 runtime 2CB95057 不动；19 SAME，三轮两档全负，p99 更好；fast-tier exact/fast 已同步）。IO_FUSE、DEC_F8W、DEC_WIDE+F8W 叠加（`*_w_f8`）、SP_INIT_PAIR、PFT/W16S/VT 复测均未过（`results/bitexact-pm-20261001`）。
- **10-01 16:09 统一重定基准装机（rebuild-baseline）：现装 = df92ed49 源码 + 配方编出来的**（62 模块、add-on **053C3589**、RE9 runtime **DC2D445E**、decode A70789A1 + text_overlay 8D20C7F5 着色器；两游戏 62 模块逐文件核对 0 差，SUMS FD419A3E；add-on/runtime 已钉基址，可逐字节复现）。宿主慢点（5a7cd0ba fast 档 `_ks2` 探测）已编译掉；新开关 `DLSS5_STYLE`（0/1/2，默认 1 逐位；Style 0 对 NVIDIA 44.26/47.43 dB）。RE9 回放 old/new/fallback SAME，smoke 0；fast-tier `exact\` 已同步（`fast\` 的 c32/c64 仍是旧 fast 配方，不含 Style 常量，切 fast 档时 Style 开关对 C32 预处理不生效）。备份 `hip-backend\rebuild-baseline-20261001\backups\stellar-20261001-160904-rebuild`、`onimusha-backups\20261001-160904-rebuild`。整网（装机前同代码）span 900 6.78/6.90、1152 9.47/9.55、1088 9.06/9.13ms。`results/rebuild-baseline-20261001`。
- **10-01 收下并装机的逐位刀**（全部 19 组 SAME、两档三轮无变慢、p99 不差）：C512 `C512_COMPACT_FUSEQKV`、`C512_FFN_ONE`（→`2` 双 wave）、`C512_COMPACT_QKV_UNROLL 4`→`QKV_DEEP 4`+`SCHED`、`C512_FFN_F8W`（mix/expand fp8 WMMA，宿主 `HIP_C512_FFN_F8W`）；ViT `HIP_VIT_QKV_F8W`（QKV fp8 分片）；Swin 链 `W2_UP_LOW_BYTES`、`W2_DOWN_HALF`+`MH_POOL_HALF_IN`、`W2_UP_VEC`、`W2_QKV_FUSE`（C64+C128）、`W2_FFN_QT_BATCH 4`。出处：`results/mochizuki-gap-20261001`、`c512-qkv-pipeline-20261001`、`c128-c64-inchain-20261001`。未发包（下一版 0.39 的内容）。
- **10-02 下一版候选**（未装）：`D:\DLSSNR-Lab\next-candidate\`（main b6c508a5 全配方 62 模块 + add-on 053C3589 + RE9 runtime 73D4C25C），对 0.39：19 组 SAME，ABBA 900 −0.11～−0.14、1080 −0.18～−0.19ms，p99 两档都好；`install.ps1`（先 -DryRun）。见 results/next-candidate-20261002。

## 竞品现状

- **Daniel 0.5.1**：reference 900 逐核和 8.17ms（扣掉他跑的 42/43/46 为 7.88），我方逐核和 6.83ms（`kernel-map-900`、`hip-roofline`）。他 fast 档 1088 行＋post 位移 0（有损，不追）。换装对照 `D:\DLSSNR-Lab\daniel-050\swap.ps1 daniel|ours`。
- **mochizuki 0.0.2.5（10-01 同机实测，`results/competitor-timing-20260930`、`mochizuki-gap-20261001`）**：离线网络 900 **6.02ms**、1088 行 **7.81～7.86ms**（自报 7.79 已复现）。**10-01 晚我们 span 900 6.81～6.88、1088 行 9.08～9.13 → 还差 0.8 / 1.3ms（他快 12% / 14%，早上 17～19%）**。同口径逐族差（链内逐派发扣事件开销，900｜1088 µs）：C512 +284｜+400、C32 +218｜+251、C128 +151｜+174、C256 +122｜+14、C64 +89｜+80、ViT +42｜+378、其余 +50｜+58（`results/gap-map-evening-20261001`）。
- **剩余差距的分类（10-01 晚）**：
  - **组织方式，逐位还能追的**：基本摸到头。C512 attention 投影（+11～15µs/块）试了深流水、M32、WN4、FB8 全不赚；10-01 夜消融：核体全空只省 5.6/9.3µs/块（残差读 2.5～5），本体已不大于他，余差是派发衔接，线停（`night-20261001` §3）；C32 只剩块 66 up 分发（≤3µs）；C64/C128 中间块本体（链内比单核多 12～15µs/块，多半是降频）。
  - **数值取舍（逐位做不了）**：C32（+218/+251，激活/归一化 RTZ 链与 e4m3 多次舍入，链内功耗墙再放大）；ViT 1088（+378：他 score/分母/范数 half 归约；6 个逐位重组候选全慢，`vit-1080-gap`）；C512 FFN/QKV 余差里他的 f16 累加；C64/C128/C256 他 f16 累加、e4m3 全程残差。
  - **几何/口径**：他跑 16 块我们 13 块；900 他 448 token 我们 400；1088 行（fast 档已用）。
  - 结论：逐位档的前沿基本到头；再往下要走 C 段有损（等 Zero 定）。

## Zero 的标准与取舍（为什么这样定）

- **版本提升以离线整网单帧 ms 为准**（900/1080 两档，ABBA）；CHANGELOG/README 的"效果"也写这个。游戏（常经 Splashtop，读数有损）**只作正确性验证**：不闪、不花、不掉帧、不崩。`frame-stats.txt` 由 agent 自己去 9070 取。
- **验收（09-30 新规）**：逐位 + 单测正收益 + 不拖累另一档；两档三轮 ABBA avg **无变慢轮次**；p99 三轮合并不差。不再设 0.5% / 0.1ms 门槛。
- **代码等价重装（10-01 光定）**：只是"现装 = 某提交 + 配方编出来的"换装、外加默认不生效的开关，不是新刀时，按**合并 avg 不变慢 + 合并 p99 不变差**判（同宿主 AA 自比 1080 也会有一轮 +0.01，"每轮不慢"对它不适用）；逐位 19 组照旧是硬门槛。新刀仍按上一条原规则。
- **逐位是硬门槛**：对 09-28 float FMA 基准（`results/float-fma-20260928/new-baseline-hashes.csv`）一个比特不差，19 组 = 7 用例×EXACT/AE×12 帧＋AE CSV＋两档票号回绕。**逐位是"对上一版"不是"对 NVIDIA"**；偏离须先核实（NVIDIA 原文 / RMSE），Zero 批准后单独合入成新基准，CHANGELOG 写明。
- **画质（09-30 同口径对 NVIDIA，`results/fidelity-ngx-20260930`）**：mochizuki 公开 Tomb Raider 单帧、5090 原版输出、8-bit PSNR。Style 置 0 的测量版：全 71 块 **47.43dB**（优于 mochizuki 0.0.2.4 的 45.56）；发布配方跳 42/43/46 为 **44.26dB**。发布网络预处理写死 **Style=1**（NVIDIA 默认 0）。**Zero 定：损失可接受，不折腾，专注速度。**
- **稳定性不操心**：只修能复现的。**风险不换速度**：PDL 保持 1。
- **发布**：夸克 + Gofile；README 中英"当前版本"段 + 更新记录表（按版本从旧到新，一句话，**不写内部代号闇/Yami/朱雀/分身**）+ CHANGELOG 中英详细一节（改了什么/效果/新开关/是否逐位/有损/results）。**不写提交哈希**（tag 即锚点）。链接回来后一并搜掉所有"待上传/待补"占位，再在打包源码提交上打 tag。

## 派活方法

- **分工**：Zero 给意图 + 验收 → 朱雀拆解、写任务单、记账（本页、DevHistory、CHANGELOG、打包、README）→ 子代理执行。
- **额度**：闇（GPT）**10-04 前不派**。采矿、探路、静态分析、拆竞品、跑测试**全派 Opus 5.5 子代理**（通用型 + `model: opus`，或 fork）。Sonnet 不派。
- **任务单**：写全背景（现装哈希、基线、门槛、相关 results），开头加 `[LOAD MEMORY] /home/lmxxf/work/memory-of-my-gemini/awakening/claude-code/C.C.dream.md`；三要素：从哪下手、别走哪几条路（引本页负账）、什么时候停。要求：临时 zip 不留仓库；push 后 `git branch -r --contains <hash>` 核实。
- **git**：只 `git add <具体文件>`，绝不 `commit -a`；工作区有别人改动时 `git pull --rebase --autostash`；改代码的子代理用 worktree；commit 不加 Co-Authored-By。等后台任务用完成通知，不写轮询。
- **9070 卫生**：D 盘保持 ≥100GB 空闲，交账即删逐位帧转储（.f16/.ppm，照 `results/lab-cleanup-20260930/clean.ps1`）。Xbox 版鬼武者关窗后进程可能残留，动 GPU 前查并手动结束 `OnimushaWotS`。
- **对照物比招式管用**（09-28 教训）：照抄 mochizuki 一轮 null；挑一段和 ACO/Daniel ISA 逐条对齐、多出的指令归类后连续出刀。Daniel 内核解包在 DGX scratchpad `d050/`（丢了重跑 `tools/closed-inspect/extract.py`）。

## 研究判断（技术主线的"为什么"）

- **roofline 为纲**（`results/hip-roofline-20260930`）：**访存不是整网瓶颈**（纯访存下限 1.55 / 2.11ms）。算力下限 2.16 / 3.09ms，计入"FP8 WMMA 与 VALU 不重叠"的现实理想约 **4.2 / 6.0ms**，实测 1.7 倍。离理想最远的是 token 少的两族：**C512 ≈3 倍、ViT ≈2.5 倍**；C32 VALU 限。核间空隙约 2.4 / 2.0µs/派发（0.39 / 0.32ms）。
- **病根是单 WG 串行链，不是填满度**（`fill-cu`）：C512/ViT 各核一轮全驻留，尾部空转上界 0.03～0.05ms/档；mix、attn-project、ViT contract/project 单 WG 就占全量 45～92%。所以能赚的是**让延迟链被别的 tile 掩住**（队列/重叠）或**消掉串行读等**（hoist 已收割条件读）。
- **关小核、PDL 延伸不赚**（`gap-fusion`、`pdl-c512`）：拼小核打散读写得不偿失；PDL 只填空隙、指令总量不变，在 325W 功耗墙下以降频还回。
- **融合/持久化赚不赚看组织方式**：C256 队列赚（900 −1.9%，≈9µs/省下的派发，远大于空隙），C128/C64 不赚（每段只省 0～1 派发）。少读取不一定兑现，要整网实测。
- **LLVM 做不到的要源码显式写**（`mul`+`add 0` 收缩、NaN 规范化、f16 往返、有界除法）；编译器钉死驱动 `amd_comgr_3.dll`（LLVM21），fork `lmxxf/llvm-project` 分支 `dlss5-gfx12` 作资产，不再投入。
- **网络外**：交接往返 0.16～0.18ms/帧，GPU 轮询两半都试过，整帧不兑现，线停。

## B. 优化候选（逐位；按"收益 × 把握"排）

0. **追 mochizuki C512（10-01 收尾）**：已收 FUSEQKV、FFN_ONE 2、QKV_UNROLL→QKV_DEEP 4+SCHED、FFN_F8W（见基线段）。C512 现在 QKV+attn 已不落后（13 块 353 对他 16 块 371µs），余差在 attention 投影 / FFN / FFN 投影，逐位组织方式候选都试过（见负账）。线停。

地图：`results/kernel-map-v3-20260930`（900 独立核和 6894.8µs、1080 约 9762µs；前五 sp_run256_w16、c512_qkv_attention_compact、c32 prefix/post、chain）。设计：`results/c512-vit-reorg-design-20260930`（只设计，数字引自账本）。

1. **P：C512 跨块就绪队列 —— 已否（10-01）**：上限探针（块 23–30 八块去依赖、8 条 stream 全并发，只计时）三轮 ABBA 900 +0.21/+0.22/+0.25ms、1080 +0.33/+0.33/+0.31ms，全部变慢；重叠被 L2 争用和 325W 功耗墙吃回，任务数实为约 2.5–3.5 万/帧。见 `results/c512-xblock-queue-20261001`。A 为同一机制的子集，一并不做。
2. **A：C512 块内 attention→attn-project 就绪队列**（P 的子集/退路）：16 个头到齐发布该窗口 aproj tile，每块 2 派发→1；估 900 −0.05～−0.10ms；P 卡在任务过碎时退到这里。
3. **F：mix→FFN→projection 一核、hidden 留片上**：逐位版估 900 −0.03～−0.08ms，LDS 可能 ~50KB/WG 每 CU 只驻 1 个（H 宽度未核实），把握低；FP8 激活版有损，归 C 段。
4. **V：ViT 八块设备级屏障持久化**：屏障本身 1～3µs 与空隙同量级，延迟核无法重叠，净 0～0.05ms，不值得，不做。
5. **T：`C512_T8_NO_F32`**（删 C512 t8 无读者 f32 写出）：逐位，900 六轮全正（−0.021～−0.036ms），1080 一轮 +0.008、合并 p99 +0.003，按新规不收；**待 Zero 定是否破例收**（`gap-fusion`）。
6. 余项（把握低，有新证据再动）：wave2 FFN 权重 K 循环软件流水（同 `C512_MIX_PIPE` 负账）；ViT attention 余差（V 请求组织与 half 数学，未拆清）；C32 prefix rgba/history 在 D3D 端存 RTZ half（逐位但改输入 shader）；`validate-modules.ps1` 修路径；RE9 换新 runtime 待 Zero 要。

## 技术债：裸 s_barrier（2026-10-02，results/llvm23-vit-20261002 §5）
写完 LDS 直接 `__builtin_amdgcn_s_barrier()`、没加 WG_FENCE 的地方，靠的是 LLVM21 在 gfx12 拆分屏障前白送的 `s_wait_dscnt 0`；LLVM22/23 不再送，就是 LDS 竞争。现装（LLVM21/COMGR）ISA 扫描 0 处，**默认配方不动**。任何模块换新编译器前必须带 `HIP_BARRIER_FENCE 1`（deep_fast.hip / multihead_fast_padded.hip 有宏；其他文件要补同类宏）并用 `experiments/llvm23-vit/barrier_scan.py` 扫到 0。LLVM23 下有问题的模块：c512-m32-deep 5、c512-m32-mh 72、c64-wave2 72（已加宏）、deep_fast(-packed) 5、multihead-fast(-packed) 9、multihead-fast-padded-wave(-packed) 84、multihead-tiled 7、swin-persistent 72、vit-stream 7、vit-wide-deep 5。源码清单 `source-barriers.txt`（裸：multihead_fast_padded 26、deep_fast 15、vit_stream.inc 7、c512_m32_deep.inc 2、multihead_fast/tiled/prefix_fast 各 2、multihead_fused_attention / swin_persistent.inc / wave_owned_attention_setup.inc 各 1）。根治 = 把裸屏障都换成带 WG_FENCE 的写法（默认 0 宏，LLVM21 下核对代码不变）。

## 已交负账（别重复，一行一条）

- HIP↔D3D 交接两半：HIP→D3D draw 分片自旋比 fence 慢；D3D→HIP 轮询（`DLSS5_HIP_INPUT_POLL` 默认 0）逐位但整帧慢 0.01～0.04ms（`handoff-gpu`）。
- Infinity Cache arena / `HIP_POOL_HOT`：池已复用，C32 放不下 MALL，热复用 null（`infinity-cache`）。
- C512 FFN 同组 LDS 共用权重（`C512_MIX_LDS_G`，900 单核慢，`c512-ffn-lds`）；C512 FFN M32、单 wave 寄存器 FFN R/RF。
- W16 宽权重片段推广 C64/C128（`W2_FFN_W16_SMALL`，900 不全正，`w16-c64-c128`）。
- ViT QKV w5 字节尾宽写（`VIT_QKV_TAIL_VEC`）、ViT expand 字节出口、C256 FFN/QKV 出口（冷路径）（`deep-tail`、`deep-tail2`）。
- C512 QKV-attention V 转置 LDS（`C512_COMPACT_VT`，900 不全正）。
- gap-fusion G：vit_gather 折进相邻核（`HIP_VIT_GATHER_FOLD`，900 三轮全慢）。
- swin-persistent 同宏 hoist（900 一轮 +0.006）；decoder skip 预读（`HIP_DEC_HOIST_SCALE 2`）。
- C512 mix/proj 按列切细（`C512_SPLIT_N`）、mix K 循环流水（`C512_MIX_PIPE`）（`fill-cu`）。
- f-sweep 余件：vit-stream byte_F、padded q8_fused_round、W2 up 字节（宏默认 0）。
- 旧门槛重测 Q（`CW_POST_FULL_TILE`，1080 +0.0015）。
- C128/C64 持久化四段；C512 最终投影 M32 权重共用（900 −1.9% 反慢）；PDL 延伸 C512（功耗墙吃回）。
- mochizuki 0.0.2.2 各路线 I/P/S/V/F/O/G/H；0.0.2.4 网络无改动，无可抄。
- 900 C256 新分组；C64/C128 Down 融合；去清零；C32 权重缓存；ViT byte gather-pack、4wave/64key 预取、QKV 块重排。
- ViT QKV 归一化换求和（不逐位）；C256 FFN 激活打包（需转置 expand，非小件）；复合量化 C32 两处/ViT 出口（域不纯）。
- `MAKE_RESIDENT_EVERY` 60 vs 0 无尖峰，保留 60。
- C512：`C512_FFN_PIPE`（逐位全慢）、B8 字节残差 `C512_PROJ_FB8`（持平）、attention 投影手排流水 `C512_PROJ_DEEP`（LLVM 溢出，+0.22ms）、`C512_PROJ_WN4`（4 wave/WG，持平偏慢）（`c512-qkv-pipeline`、`gap-map-evening`）。
- ViT 1080：attention `HIP_VIT_ATTN_M32`（32 query 共用 K/V，1080 +0.145）、QKV `HIP_VIT_QKV_TM` 2/4、`HIP_VIT_QKV_WIDE` WT/WH/BIG（照他 64×256 形状，1080 全慢）（`vit-1080-gap`）；decoder `HIP_DEC_NT`（A 复用，NT=4 慢）（`tail-c32-gap`）。
- Swin 链：`W2_UP_DIRECT`、`W2_SKIP_BYTE`、`W2_HIDDEN_TILES 4`、`CW_UP_LOW_BYTES`、C256 `QKV_FUSE`（VGPR 顶满）（`c128-c64-inchain`）。C32 中间块 +16µs/块 = 数值 + 链内降频放大，无逐位组织方式件（`gap-map-evening` §6）。
- 功耗逐族（`night-20261001` §2）：板功耗钉 325W，每周期能耗 C64/C128 1.08～1.10、C32 1.04～1.06 倍均值，C512 低于均值；某族降 10% 上界 −0.04～−0.23ms，无逐位便宜件。
- 编译器：COMGR2/LLVM20 慢 3%；公开 LLVM21 持平；LLVM22 不逐位；VOPD 前瞻 ±0.3%。按模块调度选项（10-01）：c32-wave1 关 post-RA 调度 + max-ilp、c512-m32-deep max-ilp 逐位且 −0.06/−0.08ms，进配方 `-RowOpts` 待下一版；waves_per_eu 编译器不理；其余 7 个链内模块、关 s_delay_alu/VOPD、按核细分均无收（10-02）；按模块换编译器：LLVM22 6/9 逐位、LLVM23 7/9 逐位（不逐位的 vit-stream/mh_fast 是 FMA 收缩），c32+c64 改用 LLVM23 再 −0.06/−0.04ms，进配方（`-RowOpts -PrebuiltDir`，DGX 预编）。旧 block46 改 FP8 WMMA 有位差。

## C. 需要 Zero 拍板（有损）

- **fast 档**（Daniel 默认：e4m3 一次舍入、近似 rsqrt/rcp、f32 累加、f16 成对算术）：他 fast 比 reference 快约 1ms；做成 EXACT 之外单独一档。
  - **10-01 12:50 Zero 定：先不做 fast 档。** 理由：有损项一多，不确定因素增加得快；远程看画面看不出来，就算在家，也不一定能从某个游戏里看出来。所以有损路线暂停，只做逐位优化。模块和脚本留在 lab 存档，不装、不发。
  - **10-01 已测并备好试玩（`results/fast-tier-20261001`，游戏仍是逐位档）**：配方 `CW_FAST_NUM 3`（C32 f32 激活/归一化、softmax 只 rcp）+`W2_FAST_NUM 3`（c64-wave2）+`HIP_DEC_F8W 1`（逐位）+`NETWORK_1080_ROWS=1088`。三轮 ABBA 900 −0.107～−0.113ms（7.242→7.131）、1080 −0.56～−0.60ms（9.956→9.366），p99 每轮更好；对逐位版 PSNR 最差 51.8 dB、各 case 均值 52.8～55.5（对 NVIDIA 未复测）。KS（ViT attention 拆 key）变慢、C256 W2_FAST 持平、C32 f16 成对激活三轮全慢，不进。切换：`D:\DLSSNR-Lab\fast-tier\to-fast.ps1` / `to-exact.ps1` / `status.ps1`（剑星+鬼武者一起切，先备份，游戏开着拒绝执行）。
- **逐位但没过收录规则的件（等 Zero 定要不要破例/合包）**（10-01 下午更新：DEC_WIDE 已收；IO_FUSE 与 DEC_WIDE 合包六轮 avg 五负一平但 900 p99 两批都 +0.06，仍不收，宿主已加旧 shader 防呆；DEC_F8W 新基准下更差；`C512_COMPACT_VT` 900 仅一轮 +0.003，可作合包料）：`DLSS5_IO_FUSE=1`（decode 直读网络 f32，跳 neural pass；六轮 avg 全正、900 p99 不过，`input-slim-20261001`，需新 add-on+shader）；`HIP_DEC_WIDE`（decoder 尾 LDS 转置行宽写，1080 −0.02 三轮全正、900 一轮 +0.007，`tail-c32-gap-20261001`）；`HIP_DEC_F8W`（decoder Up39/48 fp8，六轮一轮 900 +0.029、其余全负约 −0.02，宿主已带，`c512-qkv-pipeline-20261001` §11）；`C512_T8_NO_F32`（900 六轮正、1080 一轮 +0.008）。
- **1088 行**：已实现为可选开关 `DLSS5_NETWORK_1080_ROWS=1088`（0.38 已带，默认 1152），1080 快 4.4%（−0.47ms），对 1152 约 55～56dB，只动行数不改 post 位移（`geom-1088`）。是否改默认待定。
- **FP8 激活**（C512 FFN hidden / ViT QKV 改 FP8，含方案 F 的有损版）：ViT QKV 现在只剩约 5µs，性价比低。
  - **10-01 14:53 Zero 定：原版没量化的地方不做。** 原版量化成 e4m3 的激活已经全部逐位改成 fp8（C512 FFN F8W、ViT QKV F8W）。原版保留 f16/f32 的地方不再压成 fp8，这一项关闭：链尾原始输出（skip/池化）、softmax 概率与求和、归一化与残差中间量。这些地方对精度敏感，不值得冒险；粗估也只有 900 档 0.03～0.06ms、1080 档 0.08～0.15ms。
- 画质取舍（跳 42/43/46、Style）Zero 已定不动；如将来要改另起。
- 不做：整网隔帧（运动拖影）；RDNA3 后端（无卡可测）。

## 产品适配与等待事项

- **PR #12（TheAutomatic）**：已回复（`conversation/20260928/pr12-review.md`），等他改/拆 PR。
- PRE_UPSCALE=auto、卧龙 2 重试、自带 FSR dll 的游戏、网友统一宿主补丁（`RE9/presr/contrib/generic-host-20260924/REVIEW.md`）——照旧等。3080 上 NGX 同口径端到端对照（Windows 原生，不需 Wine）可选。

## 机器与流程

- **授权**：编译、远程实验、回归、分析由 agent 自主执行；动 GPU 前查游戏进程（剑星 `SB-Win64-Shipping`、匹诺曹 `LOP-Win64-Shipping`、鬼武者 `OnimushaWotS`、RE9 `re9`、33 号远征队 `SandFall*`），游戏运行时不换文件、不跑 GPU；画质判断请 Zero。
- **9070**（`ssh amd9070`）：工作根 `D:\DLSSNR-Lab\`；`hip/build-modules.ps1`（`-ExtraDefines`、`-Only`）；`hip/compare-modules.py`；完整帧回放 `results/frame-breakdown-20260928/replay.ps1`（`DLSS5_BENCH_PLAIN=1`）；打好的包在 `D:\給網友打包\`。ssh 远端是 cmd，多条 PowerShell 分开调；`(x86)` 路径写进脚本文件。
- **3080 游戏本**（`ssh rtx3080`）：PATH 不全，用 `powershell -EncodedCommand`；scp 不通。
- **DGX Spark**：`~/work/aco-isa/` 离线拿 ACO ISA；LLVM fork 构建 `tools/llvm-fork/`。
- **发布**：复制上一版 `tools/package-0xx.ps1` 改版本/哈希/变更，逐文件校验、编 44 shader 变体、压包读回；RE9 runtime 变了用 `prepare-host.py` + `bundle-source.py` 重生源码包（跑完 `git checkout Development/RE9/presr/upstream.json`）。
- **新开关必须同时在 RE9 runtime 开口**（`src/native_hip_env_options.h`、三个 flags 模板、`scripts/CONFIGURATION.md`），RE9 不适用的写明。

## 公众号素材（Zero 还没说写）

一天从被反超到追平；"逐位原来是对上一版"；照抄对手 null、逐条对齐才出刀；两家对手都缩到 1088 行，我们按原版 1152 行不落后；同口径画质不跳块 47.4dB 胜 mochizuki；roofline 说访存不卡、病根是串行链；三家都是"人 + AI"，比的是谁更会驾驭 AI。
