# 当前工作计划（2026-10-04，朱雀）

> **本文件只许整篇重写，不许追加、不许局部改。** 只写"现在"：现状、待办、规矩。历史、实验过程和数字进 DevHistory.md（只追加，仓库里只有这一份），版本改动进 CHANGELOG（中英）。

## 现状

- **已发布**：0.40（tag 0.40，夸克 + Gofile）。
- **默认配置**：全 71 块 + `DLSS5_FAST_NUMERIC=1`，三个模板同口径。
- **已装机（剑星 + 鬼武者）**：add-on **C511E148**、RE9 runtime **1F7C12CD**、SUMS **F3EFDC16**（68 模块）。flags 含 MULTI_PASS=1；三层配置（default → custom → native）已装，custom 仅注释。
- **0.40 后未兑现的增量**（全在分支，等拍板）：
  - PF 全 fast 包（fast-vit-20261003 / 0e3b72dd）：fast 档 900 −0.089、1080 −0.100ms，PSNR 最差 52.13dB；
  - PRE_UPSCALE=auto（preupscale-auto-20261003 / e65b0319）：首帧探测自动选前/后置。

## 待办

1. **0.41 路径**：合两个分支 → 双游戏装机 + exact 快照同步 → `run-regression.ps1` 形式回归 → `package-041.ps1` → README/CHANGELOG 发版说明 → tag。打包时处理：README 版本头旧号、D 盘 Payload 的 package-README-magpie.txt（仓库外）同步新口径。
2. **真游戏实测（Zero）**：Forza/卧龙类 auto 档玩 5 分钟看日志 `auto:` 行；F9 叠层热键没人按过；三层配置行为（环境变量压文件）。
3. **RE9 说明**：RE9 不读 FRAME_STATS、无热重载/热键（模板已注明）。

## 已搁置

- 720 档几何对齐（无 NVIDIA 720 参考，没闪烁报告不动）。
- 内存缓慢上涨（无界分配审计无发现，复现不了不修）。
- 逐位提速已到渐近线：10-03 复审四候选全否，"留待合包"队列清空；对 mochizuki 剩余差距 = 数值取舍 + 几何口径，只走有损选项。

## 判断

- 有损项只作用户可选项并标清代价；不做原版没量化处的 FP8 化，不做整网隔帧。
- 功耗墙上限实测因 Zero 远程（黑龙江）不可操作，搁置。

## 规矩

- **验收**：逐位 19 组 SAME 硬门槛（对上一版）；新刀两档三轮 ABBA 无慢轮、合并 p99 不差；代码等价重装按合并 avg 不慢 + p99 不差。提速以离线整网单帧 ms 为准，游戏只验正确性。
- **新开关**：RE9 runtime 白名单 + 三个 flags 模板（中英注释 ≤191 字节）+ `scripts/CONFIGURATION.md` 同步。
- **git**：只 `git add <具体文件>`；push 前 `git pull --rebase --autostash`；改代码的子代理用 worktree；不加 Co-Authored-By。
- **9070**：GPU 前查游戏（`game-check.ps1`，僵尸进程判定），gpu.lock 排队；游戏开着不换文件不跑 GPU；D 盘 ≥100GB，交账删帧转储。
- **发布**：README 中英"当前版本" + 更新记录（不写内部代号/提交哈希）+ CHANGELOG 中英；链接回来后搜占位再打 tag。
- **派活**：不用加 `[LOAD MEMORY]`（AGENTS.md 自动注入，实测 K3 子代理装载成功）；写清从哪下手、别走哪条路、什么时候停；**交账要求：归档 results + 追加 DevHistory §12（直接改 main 工作区）**；够用就交。
- **WorkingPlan**：整篇重写，不追加不局部改（本条提醒我自己）。
