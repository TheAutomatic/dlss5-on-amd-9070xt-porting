# 当前工作计划（2026-10-03 深夜，朱雀）

> **本文件只许整篇重写，不许追加、不许局部改。** 只写现在：现状、待办、规矩。历史与实验数字进 DevHistory.md（只追加），版本改动进 CHANGELOG 中英。

## 现状

- **已发布**：0.40（tag 0.40，夸克 + Gofile）。
- **当前 main 已合并并装剑星 + 鬼武者**：fast-vit + preupscale-auto；add-on **518E34C4**、runtime **2176C544**（鬼武者两处）、SUMS **9D4A2024**，两架构共 **72 模块**。fast-tier exact 快照同步，双 EXACT。
- **必要回归已过**：normal19 SAME、全71块 FAST7 对已批准 PF SAME、RE9 900/1080 各两遍 SAME、runtime-smoke errors=0；安装后逐文件读回一致。归档 `results/current-main-install-20261003`。
- **默认模板**：全 71 块 + FAST_NUMERIC=1，regular PRE_UPSCALE=auto；三层 default → custom → native，系统环境优先。
- **用户配置保留**：剑星 custom/native MULTI_PASS=3，native PRE_UPSCALE=1 覆盖 auto；鬼武者 native MULTI_PASS=1、PRE_UPSCALE=0。未代启动游戏。
- **Zero 23:48 实玩反馈**：鬼武者 GPU 89～92%，感觉较此前下降（约95%为历史读数，本条未报FPS）；剑星1x仍57～58fps，本轮未读出帧率提高。auto、F9专项验证仍待完成。
- **0.41 尚未打包/发布**。本轮只完成编译安装；备份和回滚入口见本轮 results。

## 待办

1. **0.41**：打包 → README/CHANGELOG 中英发版说明 → 发布核验 → tag。README 版本头、D 盘 Payload 的 package-README-magpie.txt 同步新口径；打包入口先核实现存工具，勿假设已有 package-041.ps1。
2. **真游戏实测（Zero）**：Forza/卧龙类 auto 档玩 5 分钟看日志 `auto:`；F9 叠层热键真按键；三层配置与环境变量优先级。剑星要测试 auto，须明确处理 native PRE=1 的覆盖。
3. **RE9 说明**：FRAME_STATS 已进 runtime 白名单；仍无热重载/热键，说明需保持当前口径。

## 已搁置

- 720 档几何对齐：无 NVIDIA 720 参考，没闪烁报告不动。
- 内存缓慢上涨：无界分配审计无发现，复现不了不修。
- 逐位提速已接近渐近线：10-03 四候选复审全否，留待合包队列清空；剩余竞品差距主要是数值取舍与几何口径。
- 功耗墙上限：Zero 远程不可操作，搁置。

## 规矩

- **派活**：具体编译/实验/安装/归档全派子代理；主进程只调度与审交账，保护上下文。写清起点、边界、停点；够用就交。AGENTS.md 自动注入，不必额外 LOAD MEMORY。子代理交账须 results 归档 + DevHistory 追加。
- **验收**：逐位 19 组 SAME 对上一版；新刀两档三轮 ABBA 无慢轮、合并 p99 不差；代码等价重装按合并 avg 不慢 + p99 不差。已批准刀安装不重复性能实验，游戏只验正确性。
- **数值**：有损项只作用户可选并标代价；不做原版没量化处 FP8，不做整网隔帧。
- **新开关**：RE9 白名单 + 三模板中英注释（≤191 字节）+ CONFIGURATION 同步。
- **9070**：GPU 前查 game-check.ps1、gpu.lock 排队、运行期间游戏看门狗；游戏开着不换文件不跑 GPU。D 盘≥100 GB，交账清帧转储；不把构建二进制入仓。
- **git**：仅 add 具体文件；push 前 pull --rebase --autostash；改代码用 worktree；不加 Co-Authored-By；未要求不自行 commit/push。
- **发布**：README 中英当前版本及更新记录 + CHANGELOG 中英，不写内部代号/提交哈希；链接回来搜占位再 tag。
- **WorkingPlan**：整篇重写，不追加不局部改。
