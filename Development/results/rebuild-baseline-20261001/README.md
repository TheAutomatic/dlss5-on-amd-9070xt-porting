# 装机可复现性 + 统一重定基准（rebuild-baseline，2026-10-01 下午）

结论：**源码 + 配方能复现现装，只差 add-on 链接基址（已修）和两份不加载的旧模块；但 HEAD 宿主比现装宿主（e22d15a2）ABBA 稳定慢 0.01～0.02ms，按规则不过，什么都没装。**

## 1. 逐个比对（HEAD bb3a5381 源码 + 当前配方 vs 剑星现装；鬼武者 62 个与剑星逐码一致）

比的是代码段（`.note/.rodata/.text`，`hip/compare-modules.py`；文件哈希因随机 `__hip_cuid` 永远不同）。明细 `module-compare.txt`、`installed-vs-head-hashes.txt`。

| 件 | 一致 | 不一致 | 原因 |
|---|---|---|---|
| 62 模块（31×2 架构） | **58** | 4：`deep_fast`、`vit-wide-deep`（两架构） | 现装是 09-28 03:28 的旧编译；共享源 `deep_fast.hip` 之后改过（63a84002/b0312ac2/e4c3ecb1/754acc44 往里加了默认关的宏），默认路径下 `split_projection_frag` 寄存器分配变了（只差这一个核几十条指令）。两件都**不在生产路径**：`deep_fast` 是非 packed 回退件，`vit-wide-deep` 只在 `vit_proj_n64` 开时才加载。HEAD 编出来的才是"源码对应件"，不是现装有 main 没有的改动 |
| add-on 0D739130 | 代码与 **e22d15a2**（ViT QKV F8W 那单）逐字节一致 | HEAD 不一致 | ① HEAD 宿主之后又进了 DEC `_w_f8` 判断、IO_FUSE 防呆、SP_INIT_PAIR、PROJ_WN4/KSPLIT 探测——全在 main。② **今早 d2d9a7cf≠7E19CC6B 的真因**：不是路径字符串，是 MinGW ld 的 auto-image-base 用**输出文件路径的哈希**定基址（现装 0x3480f0000，我们 0x2f02c0000），所有绝对地址都变；另外 `.edata` 嵌了输出文件名。同一提交钉住基址后 `.text/.rdata/.data/.reloc/...` 全同，只剩时间戳 |
| RE9 runtime 2CB95057 | 代码与 e22d15a2 逐字节一致（同样钉基址 0x2d0dc0000） | HEAD 不一致 | 同上（宿主头文件是同一份） |
| assets 着色器 | 64 个与 repo 一致 | `native_codec_decode.hlsl`（现装 3762D2F1 = 22ea56fd 之前，HEAD A70789A1 多 IO_FUSE 分支）、`native_text_overlay.hlsl`（现装 09-12 版，HEAD b45daad6 多 RGB10A2 模式） | 现装落后于 repo，不是 repo 缺东西 |

**"现装有、main 没有"的改动：一件也没有**。以前几单说"宏 0 重编 581A0CEF ≠ 现装 8911ECD3"是拿文件哈希比的（cuid 随机），按代码段比 swin-persistent / c32 / c512-m32-mh / deep_fast-packed 都和现装一致。

修复（本单提交）：`scripts/build-addon.sh` 加 `-Wl,--image-base=0x3480f0000 -Wl,--no-insert-timestamp`，`scripts/build-runtime.sh` 加 `-Wl,--image-base=0x2d0dc0000 -Wl,--no-insert-timestamp`。现在不同目录、不同输出路径编两次 add-on，整个文件哈希相同（5c66f493）。`pecmp.py` 是 PE 分段比较工具。

## 2. HEAD 全量 vs 现装（宿主 + 62 模块 + 两个着色器）

- 逐位：**19 组 SAME**（7 用例×EXACT/AE×12 帧 + AE CSV + 900/1080 回绕，两边 `-PinIdle`）。
- ABBA 三轮（`abba.txt`）：900 +0.026/+0.014/+0.010，1080 +0.009/+0.003/+0.011，合并 p99 900 7.463→7.491、1080 10.221→10.249。**六轮全慢，不过。**
- 拆账：
  - SO（现装宿主 + HEAD 模块 + HEAD 着色器）：900 −0.017/+0.003/+0.005，1080 −0.019/−0.003/−0.009，合并 p99 两档更好 → 模块/着色器中性（符合"代码逐字节同"）。
  - HO（HEAD 宿主 + 现装着色器）：900 +0.006/+0.023/+0.001，1080 +0.012/+0.019/−0.011 → **慢在宿主**。
  - H0（HEAD 宿主编译期关 `HIP_SP_INIT_PAIR`）：仍慢，不是 SP_INIT_PAIR。
  - AA（现装宿主对自己）：900 −0.023/−0.027/−0.003，1080 +0.010/−0.092/+0.007——本 harness 噪声 ±0.03，候选槽略占便宜，HEAD 宿主相对 AA 偏慢约 0.02～0.04。
  - 怀疑 HasFn 未命中不缓存（`_ks2` 探测每帧每个 ViT 块调一次 hipModuleGetFunction）：加了未命中缓存（宿主，逐位，19 SAME），**复测仍慢**（900 +0.028/+0.000/+0.003，1080 +0.005/+0.023/+0.038）。缓存留在源码里（正确且无害），但不是原因。
- 宿主 e22d15a2→HEAD 只有 29 行改动，热路径上只是几次字符串比较/HasFn；没找到能解释 0.01～0.02ms 的东西，可能是 exe 布局/对齐。**没继续追**。

## 3. 装机：没装
按规则"不过就交账"。剑星、鬼武者、fast-tier `exact\` 都没动，flags 没动。

下一步建议（等光/Zero 定）：
1. 退一步只做"等价重装"：add-on/runtime 用 **e22d15a2 + 钉基址** 编（与现装代码逐字节同，等于没换），62 模块用 HEAD 编（58 个代码同、2×2 个不加载）——这样"现装 = 某个提交 + 配方编出来的"立刻成立，不涉及性能。
2. 或者先二分 e22d15a2..HEAD 的宿主改动（5 个提交）找慢点，再整体换。

## 4. 整网单帧（`wall.txt`，gap-map-evening 方法，1000 帧弃 200，span = SPAN_PROBE 中位）

现装（宿主 e22d15a2 + 现装模块）：

| 档 | span 两次 | wall 中位两次 |
|---|---|---|
| 900 | 6.78 / 6.90 | 7.29 / 7.39 |
| 1080（1152 行） | 9.47 / 9.55 | 10.01 / 10.10 |
| 1080（1088 行） | 9.06 / 9.13 | 9.60 / 9.67 |

HEAD 同轮插测：span 900 6.88/6.93、1152 9.55/9.59、1088 9.10/9.15（与现装交替跑，第二遍整体热漂约 +0.1，单帧数只作现状记录，判快慢看 ABBA）。

## 文件
脚本 `Development/HIP/experiments/rebuild-baseline/`（buildall/fetch/setup/go/go2/go3/wall/install/rt9 .ps1，addon-at.sh，pecmp.py，gpulock.sh）。lab `D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001`（`build-head\` = HEAD 62 模块，`installed\` = 现装快照，帧转储已清）。

## 5. 第二单（光追加）：二分宿主变慢 + DLSS5_STYLE

### 5.1 二分（只换宿主，两边都是现装模块，三轮 ABBA，`abba.txt` 的 bisect 段）
e22d15a2→HEAD 之间动宿主的提交只有 3 个（加上我的 b4807156）：

| 宿主 | 900 三轮 | 1080 三轮 |
|---|---|---|
| 5a7cd0ba（fast 档：`_ks2` 探测） | +0.004 / +0.021 / +0.007 | +0.003 / +0.011 / +0.001 |
| 91535da2（+PROJ_WN4，默认 0） | 与上同量级 | 同 |
| 449bbab3（+DEC `_w_f8` 判断、IO_FUSE 防呆、SP_INIT_PAIR） | +0.015 / +0.013 / +0.009 | −0.013 / +0.022 / +0.004 |

第一步就六轮全慢，后面的提交不再加慢。5a7cd0ba 的宿主改动只有 KSPLIT 两处：ViT attention 每帧每块 `HasFn("deep_fast",…"_ks2")`（未命中，不缓存，每次调 hipModuleGetFunction）+ `Run()` 每次派发多一个后缀比较。修法：`HIP_VIT_ATTN_KSPLIT_HOST`（默认 0）把这几处编译掉（fast 档已搁置，KSPLIT 本身也没收）；HasFn 未命中缓存保留。

### 5.2 DLSS5_STYLE
- 来源：09-06 提交 3e480520 的 `preblock-live-profile.json`——在 RTX 机上对**原版 NVIDIA 运行时**（剑星，backend +0x449a0，PID 29116，启动 8 次求值，4K）抓的标量参数 `0xb4 = 0.0078125`，即 Style 1/128；mochizuki `nr_graph.cpp` 同样是 `s434 = style/128`，style 取 0..2。所以 Style=1 是剑星实际用的设置，不是我们猜的。
- 实现：模块里 5 处写死的 `.0078125f`（`c32_fused_ffn_attention.hip`、`prefix_fast.hip` 两处、`wave_owned_c32.inc`、外加参考件 `prefix_reference.hip`）改读设备常量 `dlss5_style_feature`（初值 1/128）。宿主 `Api::LoadModule` 在 `DLSS5_STYLE` 为 0/2 时用 `hipModuleGetGlobal` 写入；未设、`1`、或不是恰好 0/1/2（含 `7`、`1.5`）都不写（回落 1，非法值打一行 stderr）。默认路径零额外调用。旧模块没有这个符号就忽略。DX12（非 HIP）旧链路的 `LIVE_PROFILE` 没动。
- 只有 10 个模块代码变（c32-wave1、c32_fused_ffn_attention(-packed)、c32_prefix_reference、prefix_fast × 两架构），其余 52 与 HEAD 同。
- 逐位：宿主 S + style 模块 + HEAD 着色器，**19 组 SAME**（默认 Style）。
- 开关生效（`style-psnr.txt`，fidelity-ngx 同口径，1080p 单帧对 NVIDIA）：Style 0 发布配方 **44.26 dB**、全 71 块 **47.43 dB**，输出哈希 76915EC5 / 29920953 与 09-30 改常量测量版逐位相同；Style 1 / 未设 / 7 / 1.5 全是 AE7E3118（= 现装输出），24.06 dB；Style 2 24.79 dB（8DDA12C1）。

### 5.3 S（宿主修好 + Style）对现装 ABBA
| 批 | 900 | 1080 | 合并 p99 900 / 1080 |
|---|---|---|---|
| S（含 19 组） | +0.014 / −0.007 / −0.020 | −0.017 / −0.018 / **+0.018** | 7.512→7.490 / 10.293→10.258 |
| S2（复测） | −0.010 / −0.012 / −0.005 | **+0.014** / +0.003 / −0.004 | 7.477→7.474 / 10.244→10.242 |

系统性的变慢没了（之前 6/6 正，现在 12 轮 7 负 5 正，合并 avg 两批两档 −0.009～+0.004，p99 合并都不差），但每批都有一轮 >0，**按"三轮无变慢"的字面规则不过，没装**。参考：同一宿主对自己（AA）三轮里 1080 也有 +0.010 / +0.007，这条规则对"代码相同的重装"本身就过不了——需要光/Zero 定：重装（代码等价）是否按 p99 + 合并 avg 判。

## 6. 装机（16:09，光按"代码等价重装"口径批准）
- 装：两游戏 62 模块 = `build-style`（df92ed49 源码），剑星 add-on **053C3589**、两个着色器（decode A70789A1、text_overlay 8D20C7F5），鬼武者 RE9 runtime **DC2D445E**（含 `_storage_`）；flags 不动。add-on/runtime 由 df92ed49 编，钉基址，可逐字节复现。
- 核对（`verify.ps1`）：剑星/鬼武者 62 模块与 build-style 逐文件 0 差，SUMS 都是 FD419A3E；add-on、runtime、着色器哈希与源一致；fast-tier status 两游戏 EXACT，`exact\` SUMS 同步。
- RE9 回放：900 old=new=fallback b2980ada…、1080 758674a8… SAME；smoke exit 0（SP errors 0）。
- 备份：`D:\DLSSNR-Lab\hip-backend\rebuild-baseline-20261001\backups\stellar-20261001-160904-rebuild`、`D:\DLSSNR-Lab\onimusha-backups\20261001-160904-rebuild`、fast-tier `backups\20261001-160904-install-rebuild`。
- 注意：fast-tier `fast\` 下的 c32-wave1/c64-wave2 仍是旧 fast 配方编的，没有 Style 常量；切到 fast 档时 `DLSS5_STYLE` 对 C32 预处理不生效（会静默保持 1）。
