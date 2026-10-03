# PRE_UPSCALE=auto：首帧探测自动选前置/后置路线（2026-10-03）

治"装了跟没装一样"：前置路线被安全检查拒绝后游戏是纯透传（Forza Horizon 6、卧龙 2 的列表布局：
upscaler 派发后同列表还有后续 draw/dispatch，`native_pre_upscale.h` 的 UNSAFE 判定 → fatal → 整局透传）。
`DLSS5_PRE_UPSCALE=auto` 让首帧自己探测这个合同：列表尾部干净 → 留前置；不干净 → 自动落后置路线并写日志，
不再静默死亡。

代码：worktree `297-preupscale-auto`（branch `preupscale-auto-20261003`，基于 0ff15055）。

## 机制

- `RequestedMode()`：环境变量 / flags 文件取值 `1`/`2`/`auto`/`0`，非法值回落 0（现行为）；环境压文件（原顺序不变）。
- `Mode()`：`auto` 未定时表现为 1（前置语义，Capture/Execute 照常工作）；`AutoDecision()` 粘性强决定
  （0 未定 / 1 确认前置 / 2 落后置），决定后 `Mode()` 返回生效值。
- 决定点在 `Process()` 处理**第一个**被捕获的 job 时：`following_work>0`（派发后同列表还有工作）→ 决定=2，
  本帧按 FFX-only 重放（原 FFX 不变、网络不跑、游戏资源不动），从下一帧起 `Enabled()==false`，
  后置快照路线按全新启动接管（在 `DLSS5_SNAPSHOT_FRAME` 武装，默认 120，与 PRE_UPSCALE=0 行为一致）；
  `following_work==0` → 决定=1，锁死前置（之后某帧违约仍走原 fatal，与强制 =1 相同，不悄悄降级）。
- ASYNC 交互：探测帧遵守 `DLSS5_PRE_UPSCALE_ASYNC` 现有规则（2077 怪癖查表照常生效）；回落后前置路线整体关闭，
  ASYNC 不再相关。探测帧即使异步拷贝读到垃圾也无害——回落帧网络不处理、不回写任何游戏资源。
- 开销：`Mode()` 每次调用多一次原子读；`following_work` 计数器本来就存在。逐位路径（HIP 核、运行时 DLL）
  一行未动。

## 验证

### 1. 编译

- `scripts/build-addon.sh ... --hip` 与不带 `--hip` 两个变体均通过（mingw 交叉编译）。
- 基线（改动前）`--hip` 构建 a30306bc…；改动后 198765f5… / 3c3b5414…（仅日志串差异）。

### 2. 代码级单测（Linux 原生，本机）

`Development/HIP/experiments/pre-upscale-auto-20261003/`：
- `extract-auto-block.sh` 从 `src/native_pre_upscale.h` **逐字节**抽出 auto 决策块（RequestedMode/AutoDecision/Mode/AutoDecide/Enabled），
  缺任一函数即失败——测的是生产代码文本，不是副本。
- `test_auto_decision.cpp`：11 个场景（每场景独立子进程，因为文件配置是函数级 static 只读一次）全部 PASS：
  未设→0、=1 强制（后续违约仍 fatal 语义）、=0、非法值→0、=2 保留、auto 探测两分支（tail-of-list 留前置 /
  有后续工作落后置且粘住）、flags 文件 auto / 大小写敏感（AUTO 非法）/ 环境压文件 / 文件 =2。

### 3. 可用前置案例：剑星真实日志（9070）

`sb-native-pre-upscale.txt`（2026-10-03 06:12 会话，523 KB，真实游戏）：`analyze-pre-upscale-log.py` 结论
events=3340、UNSAFE_or_fatal=0——整场没有任何违约帧，auto 会正确留在前置路线。首帧即
`captured: experimental no-following-consumer contract` → 第 2 帧 processed=1。

### 4. 不可用案例：GPU 宿主路径模拟（9070，真 D3D12 设备）

`Development/pre-upscale-smoke.cpp` 扩展：原 6 帧（F6 边沿/旁路/迟到旁路/following_work 守卫）后新增
auto 回落帧——捕获成功 → `ObserveWork`（同列表派发后有 draw，Forza 布局）→ Execute/Process →
断言 `AutoDecision()==2 && Mode()==0 && !Enabled()`、FFX 恰好重放一次、GPU 读回逐字节一致；
再补一帧断言钩子已惰化（Capture 返回 false、直派 FFX 成功）。同步/异步两模式。

9070 实测（RX 9070 XT，真 D3D12 设备，`gpu.lock` + `game-check.ps1` 纪律）：
- `smoke-sync.log` / `smoke-async.log`：原 6 帧断言（F6 边沿/直接旁路/捕获后关闭/迟到旁路/pending 发布清除/
  following_work 守卫/每帧 FFX 恰一次/4096 个 half 读回全一致）全部保持；auto 回落帧
  `PRE_UPSCALE_AUTO_FALLBACK_SMOKE_PASS`——捕获成功 → 同列表派发后 ObserveWork → Execute/Process 后
  `AutoDecision()==2、Mode()==0、Enabled()==false`、FFX 恰好重放一次、读回 different=0；
  下一帧 Capture 返回 false、直派 FFX 成功（钩子惰化）。同步、异步两模式均 PASS。
- add-on 侧日志（`D:\DLSSNR-Lab\logs\native-pre-upscale.txt`）实测行：
  `event=auto: work follows the upscaler in the same list; switching to the post-upscale route (this frame replays FFX only; the post route arms like a fresh start, at DLSS5_SNAPSHOT_FRAME)`。
- 首跑失败一次：exe 未静态链接缺 DLL（0xC0000135），`-static` 重编后过——与改动无关。

### 5. 19 组 SAME 回归

**本改动结构上不影响该回归**：19 组 golden-hash 回放走 `benchmark_main_reuse.exe`
（`D:\DLSSNR-Lab\hip-backend\network-fixed-shapes\regression.ps1`），其源码不含
`native_pre_upscale.h`；被改代码只编进 add-on（`native-submission-order.addon64`），回归链路不加载它。
HIP 模块与 RE9 runtime DLL 逐字节未动（git diff 可证）。发包前若要形式上过一遍回归，跑
`run-regression.ps1` 即可，预期 trivially SAME。

### 6. 性能中性

add-on 每帧 `Mode()` 调用次数为个位数，新增一次原子读；探测不新增任何 GPU/文件工作。
ABBA 规则面向核改动，本改动无核。GPU 冒烟（第 4 节）同时是回归证据：原 6 帧行为断言全部保持。

## 覆盖缺口（照实写）

- **真游戏验证待 Zero 实测**：Forza/卧龙类列表布局的游戏里 auto 自动转后置（本环境的模拟只到 D3D12 宿主路径）；
  剑星留前置已由真实日志反推证明，但新二进制在剑星里跑 auto 也还没装过（不许装机）。建议：下版装机时
  剑星/鬼武者用 auto 档各玩 5 分钟，看 `logs\native-pre-upscale.txt` 的 `auto:` 行。
- 探测只看**同列表**尾部；跨列表消费（Black Myth SPLIT_SUBMIT 场景）不是 UNSAFE 判定的输入，auto 不改变这条。
- 第一个被处理 job 之前的捕获失败（描述符读不出、扩展链、格式不符等）不参与决定——它们本来就是透传，行为同 =1。

## 同步开口

- `scripts/hip-game-flags.txt`：值改 `auto`（注释说明探测与回落）。
- `scripts/hip-magpie-flags.txt`、`scripts/hip-re9-flags.txt`：值保持 0，注释补上 auto 说明。
- `scripts/CONFIGURATION.md`：新增 `DLSS5_PRE_UPSCALE` 行（RE9 runtime 不读此键，无白名单改动）。
- RE9 runtime 白名单：无需改动——该键本就被 RE9 忽略（`LmxxfNrRuntime.cpp` LoadFlagsFileOnce 的 allowed 列表
  不含它，注释里已点名），auto 是新合法值不是新键。

## 9070 工作目录

`D:\DLSSNR-Lab\pre-upscale-auto-20261003\`：`pre-upscale-smoke.exe`、`run-auto-smoke.ps1`、
`smoke-sync.log` / `smoke-async.log`、实验脚本与剑星日志副本。
GPU 纪律：`gpulock.sh` 拿 `D:\DLSSNR-Lab\gpu.lock`（≤30 分钟等待），拿锁前后跑 `game-check.ps1`。
