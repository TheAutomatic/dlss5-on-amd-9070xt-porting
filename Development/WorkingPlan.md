# 当前工作计划（覆盖式，不续写；最后更新 2026-09-27 14:40，朱雀）

> 这里只记当前状态、下一步和等待事项；实验过程与完成记录进 DevHistory.md。开 session 先读这页。
> 节奏：过日子式，没有 deadline。优先做有具体瓶颈证据、可逐位验证的小实验，够用就交。

## 当前基线（09-27 午）

- **0.33 已发布**（09-27 09:00，夸克 https://pan.quark.cn/s/6bb64e46ab67 + Gofile https://gofile.io/d/8yAjJX1b，tag 0.33 = 2cb0ab90）：add-on b08cd2e3（黄字 AE/EXACT、F7 开关屏幕文字、共用 env 解析），c32-wave1 `CW_PACK8` + c64-wave2 `W2_PACK8 1`；RE9 宿主/runtime 沿用 0.32。脚本 `tools/package-033.ps1`，清单 `tools/release-033-results.json`。
- **生产配方（`hip/build-modules.ps1` 默认）= M + `W2_PACK8 6`**：CW_PACK8 + HIP_FP8_SAT_MODE 3（C32 med3）+ HIP_FMED3_CLAMP + 分段 FP16_OVFL + 乘积打包 fma(x,y,+0)；3 个后备模块已从源码重编，下个包可完全从源码复现。离线网络：900 ≈9.62、1080 ≈13.39 ms（0.32 为 10.74/15.01）。
- **标准测试**：《剑星》1080P 窗口 + FSR 原生 AA，F8 切 EXACT（黄字末尾可见），看主菜单与简单场景。读数分辨率约 1 帧，0.5% 以下的改动只能看"无回退、无黑块"。
- **各游戏现装**：
  - 剑星：0.33 add-on + M 全套 + c64-wave2 = P（W2_PACK8 4）；EXACT 主菜单 **50～51**、简单场景 **54～55**（0.32 为 47～48 / 51～52）。
  - 匹诺曹：0.32 全新 + 0.33 模块 + add-on b08c；1080P 最低画质也贴 58～59，不作对比。
  - 鬼武者（Xbox）：0.33 RE9 包 + 换队列宿主 aa3761f2 + 剑星同款模块；中画质 2K 质量约 60 帧，可玩。
  - RE9：0.31 HIP + 0.32 runtime（未随 0.33 更新）。
- **对照**：mochizuki DLSSNR-AMD（Vulkan，Linux ACO 1080p 5.9ms / Windows LLPC 9.4ms）；折算我们 1080 约 12.6ms（1152→1080 行），与其 Windows 版差约 1.3 倍。C64 按循环加权 VALU 我们约 7490 vs ACO 2199（WMMA 相当）→ 差距在 FP8 转换/打包周边的普通算术。

## A. 下个包（0.34）必须做

1. **按配方双架构重编全部模块**，7 用例逐位回归 + 900/1080 ABBA，装剑星确认（`W2_PACK8 6` 首次进游戏）。
2. **RE9 包带换队列修复**（宿主 aa3761f2，`results/onimusha-presr-20260927`）：鬼武者重建交换链后换队列提交，旧宿主任务不退役、NR 停到重启；修复 = 跟随实际队列 + 8 次看门狗。"新队列重建会话"路径尚未实机触发。发包说明加"鬼武者（Xbox）实测可用"；告知 TheAutomatic。
3. **RE9 runtime 尾巴已修，待入包**（闇，`results/re9-runtime-leak-20260927`）：尺寸/档位变化记录 net/color_job/四组 requested/active/flags 路径；解绑 RGB 输入的驻留名单引用并释放 PDL 4 MiB 旗子。120 次切档末 18 次各档平台，稳态 +0 MiB/次；多尺寸 hash、runtime-smoke 通过。候选 `D:\DLSSNR-Lab\re9-runtime-leak-20260927\LmxxfNrRuntime.dll`（ca6d6bdc），未装游戏；presr 构建入口已统一到 scripts/build-runtime.sh。
4. `Development/HIP/validate-modules.ps1` 默认资产目录已不存在，修路径后纳入发包前检查。
5. 发包流程照旧：以上一包为底逐文件校验；**有游戏开着时 RE9 冒烟会被跳过，打完要补跑**（0.33 就是补跑的）。

## B. 优化候选（逐位；按"收益 × 把握"排）

1. **C32 融合核 ISA 审计**（c32-wave1，整网最大头 34%）：用 C64 那套方法——循环加权 VALU 统计 + ACO 对照 + 手改汇编当显微镜（`HIP/experiments/c64-hand-asm` 的 asm_compile 往返零成本），找出 LLVM 未收缩/多余的段，回源码修。
2. **ViT 生产者直接写 E4M3**（`vit_byte_stream` 路线）：DF_PACK8 不赚是因为 ViT 真在跑的核读 f32 输入、访存受限（VMEM 164 vs WMMA 64）；ACO 的 gemm 读生产者写好的 E4M3 字节。难点：与自适应复用互斥，需兼容。
3. **帧时间分布日志**（Zero 09-27：帧率不一定涨，但卡顿因素在减少）：add-on / runtime 记每帧耗时分布（1% low、最长帧、NR 实际调用率），让"卡不卡"可量化，也用来验证换队列/显存池这类稳定性修复。
4. C512 FFN 链剩余两核（`ffn_fused_t8`、`projection_frag`，`results/c512-ffn-20260926`），先读 ISA 定性。
5. decoder 投影（0.34/0.46ms，2×2 上采样尾部串行化）；ViT QKV 归一化段（0.34/0.54ms）；C32 FFN 权重按 WMMA 片段预排；host 侧 C256 宽权重片段（约 −0.03ms，`mhfast-wide-frag-20260923`）；C32 对角残差跳过全零 K16 半块（约 −0.1～0.2%，`results/c32-diag-zero-20260925`，攒着合包）。
6. 已知外部信息：`v_cvt_pk_f32_fp8` 在 gfx1201 实测返回同一字节两份（`HIP/experiments/pair-unpack`），ACO 在 mochizuki 的 fswin64 里用了 64 次——可告知作者。

## C. 需要 Zero 拍板

- **有损**：6b（−1.1%，PSNR 58dB）、ViT QKV 改 FP8（估整网 2～4%，Daniel 的做法）。看 PSNR + Zero 游戏内看画质。
- **加档 1728×1024**：2K 质量档不再缩 6%，画质向不提速；每加一档多一套特化核与黄金 hash。
- 不做：整网隔帧（3z Model interleave，运动拖影）；RDNA3 后端（无卡可测）。

## 研究判断（09-27 校准）

- **RDNA4 上 FP8 WMMA 与 VALU 不重叠**（mochizuki 实测，我们 PACK8 −9% 印证）：删 VALU 就是直接省时间；我们的差距在 FP8 转换/打包周边，不在矩阵乘。
- **LLVM 不是处处差**：VOPD 配对、`+0.f`（−0→+0，激活在 g=−4 恰为 +0，承重）、WMMA 前后等待本来就对；它真正做不到的是把 `mul` 与 `add 0` 收缩成 fma、自行去掉 NaN 规范化——这类要在源码里显式写（fmaf、fmed3）。
- **手改汇编 = 显微镜，不进生产**：找到病根回源码修；手改稿是对某版 .s 的补丁，源码一改就作废。
- **单核单段的小刀测不出来**：一个核一段循环省 3% VALU，整网不到 0.1%；要测得出，改动得覆盖多核或多族。
- 矩阵峰值不能当提速空间；未解释时间也不能直接列为必要损失。不同对照的百分比不相加。

## PDL（维持现状，不扩大）

**审计已交付**（闇，`results/pdl-audit-20260927`）：原实现存在 uint32 计数回绕提前放行的竞态，已在 host 加“溢出前同步→清槽→同步”；上限降至 64 的压力版两档共 134 次重置、24 帧逐位。pool 的 32 引用覆盖当前最长 8 块链；但消费者缺 agent acquire、任意序自旋进展与同槽代际覆盖仍未形成完整文档证明，**不能盖章 PDL=1 安全**。现成保守方案 PDL=0 已过 7 用例 84 帧逐位；固定旧模块集两批 ABBA 代价：900 +0.056/+0.066ms，1080 +0.079/+0.079ms。**Zero 09-27 定：保持 PDL=1**——外挂崩了重启即可，不为未发生的理论风险牺牲速度；回绕竞态已修，acquire/进展性论证留作文档欠账，出现实际卡死再切 0。C512 不采用，不铺开 ViT/Down/Up。

## 产品适配与等待事项

- **PRE_UPSCALE=auto**：探测同列表超分后是否还有 draw/dispatch，不适合前置则回落后置（地平线 6、卧龙 2）；探测帧的原超分执行与回滚要处理好。
- **卧龙 2**：装回后试常规包 + EnableFfxInputs=false + ASYNC=0；同列表后续 draw 是已确认障碍。RE9 前置宿主既然在鬼武者跑通，可作为 RE 引擎以外同类游戏的候选路线。
- **网友统一宿主补丁**：审单 `RE9/presr/contrib/generic-host-20260924/REVIEW.md`，等对方实测游戏与帧率再定。
- **2077**：STRENGTH=auto 默认 1,0（只转亮度），ASYNC=auto 默认关；持续看动态场景反馈。
- 网友反馈：超宽屏 FIT_LARGE、9060 实机、RE9 帧生成/HDR；issue 来了照旧处理。
- 新权重（传闻 380.8.3，未证实）：等下一个原生 DLSS 5 游戏出来比 DLL（SHA / WEIGHTS_HT 153 条 / 15 个 CUBIN / 层尺寸）；Zero 09-27：先不管。

## 已关路线（有新证据才重开）

- MODE.FP16_OVFL **核入口一次性**设置（f16 收窄溢出语义变，720 不逐位）；分段开关版已采用。
- `v_cvt_pk_f32_fp8` 成对解包（gfx1201 返回同字节两份）；`v_pk_*_f16`（我们的 f16 是 Hrtz 往返，需切舍入模式，每值省不到 1 条）。
- 转置布局（C64～C256 已在用）；C256 持久化（估 ≤0.1ms，PDL 已拿走大部分）。
- DF_PACK8（deep/ViT 逐位但不赚，访存受限）。
- C512 一头一 wave、C32 尾部合并遍历、C32 转置尾部并宽、mapped/post 输入布局三方向、ViT group 编号重排、直达 LDS 读取（工具链不支持）、双 stream 重叠（Windows HIP 不并发）。详见 DevHistory §7 与各 results。

## 机器与流程

- **授权（09-25）**：DLSS5 优化的编译、远程实验、回归、分析由 agent 自主执行；动 GPU 前查空闲，游戏运行时不换文件、不跑测试台；画质判断请 Zero。**09-27 起 9070 整机交给 agent**（Zero 改在 3080 游戏本上对话/玩游戏），剑星等游戏的实测仍由 Zero 回 9070 时做。
- **游戏进程名**：剑星 `SB-Win64-Shipping`、匹诺曹 `LOP-Win64-Shipping`（不是 LiesofP）、鬼武者 `OnimushaWotS`、RE9 `re9`；Magpie 空闲可忽略。
- **git**：只 commit/push 本仓（297），commit 不加 Co-Authored-By；多个分身并行时 push 前 `git pull --rebase`。
- **9070**（`amd9070`）：工作根 `D:\DLSSNR-Lab\`；模块编译 `hip/rtc_compile.cpp` → `hip/build-modules.ps1`（`-ExtraDefines` 同名宏覆盖配方）；模块比对用 `hip/compare-modules.py`（比代码段，不比文件 hash）；汇编往返 `HIP/experiments/c64-hand-asm/asm_compile.cpp`；候选部署照 `deployments/<名>/`（payload + install.ps1 + 备份/还原）。PowerShell：含中文路径的 .ps1 要 UTF-8 BOM，含 `(x86)` 的命令写进脚本文件再跑。
- **DGX Spark**：`~/work/aco-isa/` 有 Mesa 26.2.3 RADV + drm-shim 假 gfx1201（`LD_PRELOAD=libamdgpu_noop_drm_shim.so AMDGPU_GPU_ID=gfx1201`），可离线拿 ACO ISA 作参照（`results/aco-isa-20260927/tools`）。
- **发布**：以上一包为底，`tools/package-0xx.ps1` 逐文件校验、换文件、编 44 shader 变体、压包读回；= 夸克 + 一个海外镜像（0.32/0.33 用 Gofile，以 Zero 给的为准）；README 中英"当前版本"段 + 更新记录表（**按版本从旧到新，新行加在最后**）；按打包源码提交补 tag。
- **新功能/新开关必须同时在 RE9 runtime 开口**（TheAutomatic 09-26）：`DLSS5_*` 键统一走 `src/native_hip_env_options.h`，`scripts/hip-re9-flags.txt` 同步加键；发包前在 RE9 日志核对 requested/active。
- **后台等待**：等后台任务用完成通知，不自己写 `until` 轮询（09-26/27 两次轮询条件自匹配、挂着不退）。
