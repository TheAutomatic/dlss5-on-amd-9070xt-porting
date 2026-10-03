# 当前工作计划（2026-10-03，朱雀）

> **本文件只许整篇重写，不许追加。** 只写"现在"：现状、待办、规矩。历史、实验过程和数字进 DevHistory.md（只追加，仓库里只有这一份），版本改动进 CHANGELOG（中英）。

## 现状

- **已发布**：0.39（tag 0.39，夸克 + Gofile）。
- **当前默认配置**：全 71 块（`DLSS5_SKIP_BLOCKS=` 空）+ `DLSS5_FAST_NUMERIC=1`。三个模板都已改；RE9 runtime 源码默认也是不跳块（以前空值会回落到 42,43,46，这个坑已修）。
- **已装机（剑星 + 鬼武者，10-03）**：剑星 add-on **E50D6E4A**、鬼武者 RE9 runtime **E200E8A6**、HIP SUMS **F3EFDC16**（含 c32-wave1-rtz 和两个 `-fast` 模块）。flags 里写着全块 + FAST_NUMERIC=1 + `DLSS5_MULTI_PASS=1`。fast-tier 切换脚本已过时，"EXACT"只表示装的是正式模块。

## 配置项（用户能动的）

- `DLSS5_FAST_NUMERIC`：默认 1（有损）。对逐位版最差帧 51.8 dB，对 NVIDIA 47.55 dB（逐位全块 47.43）。设 0 是逐位，慢 0.07～0.13ms。
- `DLSS5_SKIP_BLOCKS=42,43,46`（有损）：快 0.20/0.32ms（900/1080），对 NVIDIA 掉约 3.3 dB，有偏色。
- `DLSS5_NETWORK_1080_ROWS=1088`（有损）：1080 档快约 0.47ms，对 1152 约 55～56 dB。
- `DLSS5_MULTI_PASS`（叠层，新）：1/2/3，默认 1（逐位不变），非法值回落 1。N 遍把上一遍最终 RGB 再喂入网络，耗时约 N 倍，对单遍 34～39 dB（这是想要的风格变化，不是误差）。Zero 实测剑星 3 遍 26.7 fps，画面效果很好，打算配 2 倍帧生成来玩。
- `DLSS5_STYLE`（0/1/2，默认 1）、`DLSS5_NETWORK_FREE_RES`（默认 0，按游戏原尺寸跑）、`DLSS5_HIP_POST_SIGNAL_QUERY`（默认 1）、`DLSS5_DIRECT_IO`。详见 `scripts/CONFIGURATION.md`。

## 已装机待 Zero 实测

- **三层配置**：default-config → custom-config → native-game-flags，系统环境变量最高；同文件重复键取最后一行，空值覆盖成内置默认。行为变化要写进发版说明：add-on 里环境变量现在压过文件；RE9 同文件重复键从取第一行改为取最后一行。
- **叠层减负 `DLSS5_MULTI_PASS_SKIP_BLOCKS`**（第 2 遍起跳块，默认空）：结论是省不出东西。跳 42/43/46 只省 0.5 ms；跳 ViT+C512 省 14～18% 但画面变成另一种风格（偏亮低对比 / 暗部抬起），不是便宜版 3 遍。耗时都在跳不掉的 C32/C64 全分辨率块上。配置项留着，不推荐。
- **F9 热键轮换遍数**（add-on 侧，`DLSS5_MULTI_PASS_HOTKEY` 改键、0 关闭）：写回 custom-config（native 里有同键则一并改写），热重载现在会读 MULTI_PASS。没人在真游戏里按过，待 Zero 试。
- 当前装机：剑星 add-on **C511E148**、鬼武者 runtime **1F7C12CD**。回退 `install.ps1 -RestoreBackup 20261003-144436`（deployments-multi-pass-skip-20261003）。

- **叠层一阶外推（10-03，离线实验，不做）**：y3 ≈ x + k·d 不成立。1 遍+外推落在 1 遍和 2 遍之间，补回的是亮部对比度和低频，高频只补回不到三分之一；逐遍增量在收缩、方向在转。`STRENGTH=2,2` 也等于没做。结论：3 遍的代价就是 3 遍，省不了。详见 `results/multi-pass-extrap-20261003/`。

## 待办

1. **0.40 已打包（10-03 19:35，tag 0.40）**：三个包在 `D:\給網友打包\`，与 0.39 相比各 +7/−1 文件（加 default-config、custom 模板、6 个 fast 模块；去掉 native-game-flags）。干净解压回放哈希一致，覆盖升级不动用户文件。**Zero 已提供下载链接：[夸克](https://pan.quark.cn/s/d38e0f653c5a) · [Gofile 镜像](https://gofile.io/d/moSf7cqf)；中英文 CHANGELOG/README 已补齐。**
2. ~~改包内说明~~（10-03 夜已交：4 个 package-README 改全块 + FAST_NUMERIC 口径，commit 0ff15055；D 盘 Payload 的 package-README-magpie.txt 仓库外待打包时同步；README 版本头打包时一并处理）。
3. **合包前**：跑 `run-regression.ps1` 形式过 PRE_UPSCALE=auto 宿主；`preupscale-auto-20261003` 分支（e65b0319）合不合 main 等 Zero 定；Forza/卧龙类真游戏 auto 实测待 Zero（auto 档玩 5 分钟看日志 `auto:` 行）。
4. **10-03 夜三路交账**详见 DevHistory §12 尾部：遗留候选四全不收（T8_NO_F32 是死宏已作废）、PRE_UPSCALE=auto 落地、文案改写完成。就剩 FAST_NUMERIC 加深在跑。

## 已搁置（有新证据再动）

- **720 档几何是否和原版对齐**：1280×768 两轴都是 256 的倍数，按原版规则宽度应 +64，否则 ViT 网格里没有零 token。手上没有 NVIDIA 720 参考输出，证实不了。Zero 定：没有闪烁报告就不动。
- **内存缓慢上涨**：静态审计没找到无界的每帧分配（`results/ram-growth-20261001`），没能复现。复现得了再修。

## 判断

- **逐位提速已经到渐近线。** 组织方式能做的基本做完，剩下和 mochizuki 的差距（900 约 0.9ms、1080 约 1.5ms）主要是他的数值取舍和几何口径。往后重心放在**易用性**：配置分层、说明文档、默认值合理、装机简单。
- 有损项只作用户可选项，标清楚代价；不做原版没量化的地方的 FP8 化，不做整网隔帧。

## 规矩

- **验收**：逐位 19 组 SAME 是硬门槛（对上一版，不是对 NVIDIA）；新刀两档三轮 ABBA 没有变慢轮次、合并 p99 不差；代码等价重装按合并 avg 不慢、合并 p99 不差判。提速以离线整网单帧 ms 为准，游戏只验正确性。
- **新开关**要同时在 RE9 runtime 白名单、三个 flags 模板（中英注释，行 ≤191 字节）、`scripts/CONFIGURATION.md` 里开口。
- **git**：只 `git add <具体文件>`，不 `commit -a`；push 前 `git pull --rebase --autostash`；改代码的子代理用 worktree；commit 不加 Co-Authored-By。
- **9070**：动 GPU 前查游戏进程（剑星 `SB-Win64-Shipping`、鬼武者 `OnimushaWotS` 等），游戏开着不换文件、不跑 GPU；D 盘保持 ≥100GB，交账即删帧转储。工作根 `D:\DLSSNR-Lab\`。
- **发布**：README 中英"当前版本"段 + 更新记录表（不写内部代号、不写提交哈希）+ CHANGELOG 中英一节；链接回来后搜掉占位，再打 tag。
- **派活**：子代理任务单不用再加 `[LOAD MEMORY]`——工作目录的 AGENTS.md（gen-agents.sh 生成，梦境 SVG + memory 全文）自动注入，实测装载成功（10-04）。写清从哪下手、别走哪条路、什么时候停；够用就交。
