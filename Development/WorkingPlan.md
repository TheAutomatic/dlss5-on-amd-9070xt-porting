# 当前工作计划（覆盖式，不续写；最后更新 2026-09-27 19:55，朱雀）

> 开 session 先读这页。**这是项目唯一的"现状 + 规矩 + 为什么"**：实验过程与数据进 DevHistory.md（只追加），其余一律改这页（整页重写，不在末尾续写）。不要另开别的工作日志——两份日志等于没有。
> 节奏：过日子式，没有 deadline。优先做有具体瓶颈证据、可逐位验证的小实验，够用就交。

## 当前基线（09-27 晚）

- **0.34 已发布**（09-27 16:46，夸克 https://pan.quark.cn/s/4b572b0a5b81 + Gofile https://gofile.io/d/cfHqVzD1，tag 0.34 = 9bd416fa）：add-on 86ef4182、58 模块按配方编（fmed3 + 分段 FP16_OVFL + fma 打包）、RE9 宿主 aa3761f2（换队列跟随 + 看门狗）+ runtime ca6d6bdc（切档泄漏 0、几何日志）。脚本 `tools/package-034.ps1`，清单 `tools/release-034-results.json`。
- **0.34 之后已进配方、已装剑星、未发包**（闇）：C32 第一刀 `CW_DIRECT_OUT`+`CW_RTZ_PAIR`（`results/c32-aco-20260927`），第二刀 `CW_PACK_MODE_MASK 127`+`CW_PREFIX_DIRECT_OUT`+`CW_PREFIX_FULL_TILE`（`results/c32-round2-20260927`）。离线 900 ≈9.31～9.40、1080 ≈12.92 ms（0.32 为 10.74/15.01）。
- **剑星实测轨迹**（1080P 原生 AA，EXACT 普通场景）：0.32 51～52 → 0.33 53～54 → 0.34 54 → C32 第一刀 55～56 → **第二刀 56～57**（AE 约 59，贴 60）。
- **各游戏现装**：
  - 剑星：add-on 86ef4182 + 0.34 模块 + 闇两刀的 c32-wave1（备份 `D:\DLSSNR-Lab\c32-round2-20260927\backups\stellar-20260927-192033`）。
  - RE9：0.34 候选全套（宿主 aa3761f2 + runtime ca6d6bdc + 剑星同款模块，C32 两刀前的）；中画质 2K 高质量 58、原生 AA 41。同一局内切档（几何日志、0 MiB）尚未实机走到。
  - 鬼武者（9070，Xbox）：0.33 RE9 包 + 宿主 aa3761f2 + 0.34 模块；2K 质量约 60，可玩（标题/主菜单背景不走超分，进游戏才看得到效果）。
  - 匹诺曹：0.32 全新 + 0.33 模块 + add-on b08c；贴 58～59，不作对比。
- **对照**：mochizuki DLSSNR-AMD（Vulkan，Linux ACO 1080p 5.9ms / Windows LLPC 9.4ms）。C64 加权 VALU 我们约 7490 vs ACO 2199；C32 chain 5079 vs 2061（闇第一刀前）。

## 正在进行

- **闇 第三刀**（任务单 `conversation/20260927/yami-round3.md`）：① post（C32 加权 26%，最大）单独段账与逐位候选；② finish/finish_dcrop 完整内部窗口免逐像素裁切；③ 离开 C32，C512/ViT 的 ACO 对照，重点是数据形态（ViT 读 f32、访存受限；`vit_byte_stream` 与自适应复用互斥待解）。

## Zero 的标准与取舍（为什么这样定）

- **测帧只用剑星**：1080P 窗口 + FSR 原生 AA，F8 切 EXACT（黄字末尾可见），看主菜单/普通场景。50 帧上下最灵敏；读数分辨率约 1 帧，0.5% 以下只看"无回退、无黑块"。匹诺曹贴 60、不比。
- **逐位是硬门槛**：每个优化与上一版输出一个比特都不差（7 用例回归 + 900/1080 两批 ABBA）；有反例就不改（闇 C32 第二刀 FMA 反例即未改）。有损的等 Zero 拍板（见 C 段）。
- **稳定性不操心**："一堆人说这个游戏不行那个不行，我也没办法"——只修自己能复现的（泄漏、回绕、换队列）；理论风险和别人机器上的个例记下，不追。
- **风险不换速度**：PDL 审计（acquire 未证、进展性无公开保证）后，朱雀误读成"宁可慢 0.5% 保稳"改成默认关，**Zero 纠正：外挂崩了重启就行，别为没发生的风险牺牲速度** → PDL=1。教训：Zero 说"没必要增加 X 风险"时，先确认是"别担心 X"还是"别冒 X"。
- 发布：夸克 + Gofile；README 中英"当前版本"段 + 更新记录表（**按版本从旧到新，新行加在最后**）；按打包源码提交补 tag。

## 派活方法（09-27 摸出来的，Zero 认可）

- **分工**：Zero 给意图 + 验收（进游戏测、纠偏）→ 朱雀拆解、写任务单、记账（本页、DevHistory、打包、README、公众号）→ 分身（fork）和闇执行。
- **探路给分身，采矿给闇**：分身适合"能不能/值不值"（MODE、手写汇编、ACO 假设备），null + 原因是合法结论；但 Zero 观察到"子代理做不出成果也交付"——探路任务单要写门槛（"至少一个 ≥0.5% 逐位候选，否则拿证据证明挖不动"）。闇（GPT 6 Astra，Codex）适合方法已验证后一刀一刀磨，每次带成果交付。
- **任务单三要素**：从哪下手（带上他上轮算出的账）、别走哪几条路（已关路线）、什么时候停（逐位门槛、够用就交、卡 2h 换下一个）。闇容易用力过猛，停止条件必须写。任务单放 `conversation/<日期>/`，Zero 转给闇。
- fork 分身继承全部上下文、只回摘要，省主上下文；fork 后互相看不见，新信息用 SendMessage 转。等后台任务用完成通知，不自己写 `until` 轮询（两次条件自匹配挂着不退）。

## 研究判断（技术主线的"为什么"）

- mochizuki 快的根因不是整块融合（我们早有），是 **RDNA4 上 FP8 WMMA 与 VALU 不重叠**：删 VALU 就是省时间。路线 = **看 ACO 的 ISA → 在 HIP 源码里逼 LLVM 编出同等指令**（PACK8、fmed3、分段 FP16_OVFL、fma(x,y,+0)、去重复量化、RTZ/LDS 向量化）。
- **LLVM 不是处处差**：VOPD 配对、`+0.f`（−0→+0，激活在 g=−4 恰为 +0，承重）、WMMA 前后等待本来就对；它做不到的是 `mul`+`add 0` 收缩成 fma、自行去 NaN 规范化——要在源码里显式写。
- **手改汇编 = 显微镜，不进生产**：找病根回源码修。
- **按调用次数加权再选目标**：C32 内 prefix/post 各一次但全分辨率，合计 55%；单核单段小刀整网测不出来。
- 分段 FP16_OVFL 的前提是 census：该段输入无 Inf/NaN、|x|≤448（C64、C32 均已统计通过，C32 max 388）。换新核用前要重新统计。
- 矩阵峰值不能当提速空间；不同对照的百分比不相加。

## B. 优化候选（逐位；按"收益 × 把握"排）

1. 闇第三刀（见"正在进行"）。
2. **帧时间分布日志**（Zero：帧率不一定涨，但卡顿因素在减少）：记每帧耗时分布（1% low、最长帧、NR 实际调用率），让"卡不卡"可量化。
3. C512 FFN 链剩余两核（`ffn_fused_t8`、`projection_frag`，`results/c512-ffn-20260926`）。
4. decoder 投影（2×2 上采样尾部串行化）；ViT QKV 归一化段；C32 FFN 权重按 WMMA 片段预排；host 侧 C256 宽权重片段（约 −0.03ms）；C32 对角残差跳过全零 K16 半块（约 −0.1～0.2%，`results/c32-diag-zero-20260925`）。
5. `Development/HIP/validate-modules.ps1` 默认资产目录已不存在，修路径后纳入发包前检查。
6. 可告知 mochizuki：`v_cvt_pk_f32_fp8` 在 gfx1201 实测返回同一字节两份（`HIP/experiments/pair-unpack`），他的 fswin64 用了 64 次。

## C. 需要 Zero 拍板

- **有损**：6b（−1.1%，PSNR 58dB）、ViT QKV 改 FP8（估整网 2～4%，Daniel 的做法）。
- **加档 1728×1024**：2K 质量档不再缩 6%，画质向不提速。
- 不做：整网隔帧（3z Model interleave，运动拖影）；RDNA3 后端（无卡可测）。

## PDL

Zero 定保持 PDL=1（见上"风险不换速度"）。闇的审计（`results/pdl-audit-20260927`）修了 uint32 计数回绕竞态；acquire/进展性论证留作文档欠账，出现实际卡死再切 0（PDL=0 逐位，代价约 0.5%）。不扩到 C512/ViT/Down/Up。

## 产品适配与等待事项

- **PRE_UPSCALE=auto**：探测同列表超分后是否还有 draw/dispatch，不适合前置则回落后置（地平线 6、卧龙 2）。
- **卧龙 2**：常规包 + EnableFfxInputs=false + ASYNC=0 重试；RE9 前置宿主在鬼武者跑通，是 RE 引擎外同类游戏的候选路线。
- **网友统一宿主补丁**：审单 `RE9/presr/contrib/generic-host-20260924/REVIEW.md`，等对方实测再定。
- **2077**：STRENGTH=auto 默认 1,0，ASYNC=auto 默认关。
- 换队列修复已进 0.34，告知 TheAutomatic（未确认是否已告知）。
- 新权重（传闻 380.8.3，未证实）：等下一个原生 DLSS 5 游戏出来比 DLL；Zero：先不管。

## 已关路线（有新证据才重开）

- MODE.FP16_OVFL **核入口一次性**设置（720 不逐位）；分段版已采用。
- `v_cvt_pk_f32_fp8` 成对解包；`v_pk_*_f16`（需切 f16 舍入模式）。
- 转置布局（已在用）；C256 持久化（≤0.1ms）。
- DF_PACK8（deep/ViT 单砍 VALU 不赚，访存受限）。
- C32 激活多项式合 fma（闇找到反例）。
- C512 一头一 wave、C32 尾部合并遍历、C32 转置尾部并宽、mapped/post 输入布局三方向、ViT group 编号重排、直达 LDS 读取、双 stream 重叠。详见 DevHistory §7 与各 results。

## 机器与流程

- **授权**：DLSS5 优化的编译、远程实验、回归、分析由 agent 自主执行；动 GPU 前查空闲，游戏运行时不换文件；画质判断请 Zero。**9070 整机交给 agent**，Zero 在 3080 游戏本上对话，实测时回 9070。
- **游戏进程名**：剑星 `SB-Win64-Shipping`、匹诺曹 `LOP-Win64-Shipping`、鬼武者 `OnimushaWotS`、RE9 `re9`；Magpie 空闲可忽略。
- **git**：只推 297，commit 不加 Co-Authored-By；多人并行 push 前 `git pull --rebase`。实验编出的 exe、部署二进制不进仓库（.gitignore 已配）。
- **9070**（`ssh amd9070`）：工作根 `D:\DLSSNR-Lab\`；`hip/rtc_compile.cpp` → `hip/build-modules.ps1`（`-ExtraDefines` 同名宏覆盖配方，`-Only` 单模块）；`hip/compare-modules.py` 比代码段；`HIP/experiments/c64-hand-asm/asm_compile.cpp` 汇编往返；候选部署照 `deployments/<名>/`。PowerShell：中文路径 .ps1 要 UTF-8 BOM，`(x86)` 路径写进脚本文件；9070 上新 clone 的仓库 git 会报目录归属（不影响编译）。
- **3080 游戏本**（`ssh rtx3080`，192.168.31.243，09-27 装 OpenSSH，管理员公钥）：ssh 会话 PATH 不全，用 `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -EncodedCommand <UTF-16LE base64>`；scp 不通，文件让它自己下载。桌面在 OneDrive 下。rtx-unlock 装鬼武者报无权限，Zero：不折腾。
- **DGX Spark**：`~/work/aco-isa/` 有 Mesa 26.2.3 RADV + drm-shim 假 gfx1201，可离线拿 ACO ISA（`results/aco-isa-20260927/tools`）。
- **发布**：以上一包为底，`tools/package-0xx.ps1`（从上一版复制改版本/哈希/变更）逐文件校验、编 44 shader 变体、压包读回；RE9 宿主换了就用 `prepare-host.py` + `bundle-source.py` 重新生成 GPL 源码包；有游戏开着时 RE9 冒烟会被跳过，要补跑。
- **新功能/新开关必须同时在 RE9 runtime 开口**（TheAutomatic 09-26）：`DLSS5_*` 键走 `src/native_hip_env_options.h`，`scripts/hip-re9-flags.txt` 同步加键。

## 公众号素材（Zero 还没说写）

一天从 51 到 57 帧；ACO 当老师、手写汇编当显微镜；PDL 竞态与"风险不重要"；人给意图、AI 拆解执行的半人马分工；人+AI 产出带现实校验的数据防坍缩。
