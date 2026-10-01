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
