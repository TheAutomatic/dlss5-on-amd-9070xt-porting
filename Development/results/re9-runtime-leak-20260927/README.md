# RE9 切档日志与残余显存（2026-09-27，闇）

## 结果

修复了两处真实生命周期遗漏：**RGB 输入缓冲的驻留名单额外引用未解绑**，以及 **Network 的 4 MiB PDL 旗子未释放**。最终候选 120 次三尺寸循环，最后 18 次三个尺寸分别固定在 2475 / 2467 / 2443 MiB，**同尺寸稳态增量 0 MiB/次**。所有尺寸阶段的末帧哈希与原实现相同。

这是本驱动、固定模块集、三档循环的实测平台；不声称任意游戏/驱动都保证同一峰值。前几十次仍有逐渐减小的分配增长，不能把第 24 次时的局部斜率当作永续泄漏。

最终 DLL：`D:\DLSSNR-Lab\re9-runtime-leak-20260927\final2\LmxxfNrRuntime.dll`，SHA256 `ca6d6bdcfd29199014ef1ab14c5a14f5e81679b57da99062536f0fdc76b53fda`。根目录另放同一交付副本。**未装游戏、未发包。**

## 来源与修复

1. `NativeCreateCommittedResource` 对 ≥32 MiB 的 default buffer 无条件 AddRef 并放进 `NativeTrackedResources`，供 MakeResident 使用。`NativeGameRgbInput` 每次 1080 档创建 tiles/color 两块大缓冲；析构只放自己的引用，驻留名单永久留住旧资源。新增 `NativeUntrackResource`，在拥有者还持有引用、GPU 已完成时从名单移除并释放名单引用；RGB 输入析构解除 tiles/color，codec 自有 output 同样配对（覆盖大尺寸 buffer-output 路径）。不对借用的 source 解绑。
2. `Network` 在 `opt.pdl` 下分配 `16384*64*4=4 MiB`，旧析构完全没释放。现在同步后释放，构造后段失败也清理；`pdl_keep` 在 Api/stream 仍有效时明确清空。此修改同时惠及常规 add-on 的重建。
3. 原有 HIP 导入共享缓冲池继续使用。本轮没有另加资源池。

隔离证据：

- 共享 fence import/destroy：100 次；加入实际 HIP wait/signal 再 100 次。两组显存均 175.348→175.348 MiB。`semaphore-0.log` / `semaphore-1.log`。排除了这个探针下的信号量泄漏。
- 29 模块反复加载/卸载 50 次、无派发：显存 175.348→175.348 MiB。`module.log`。该结果只排除未执行模块的加载/卸载，不能单独排除执行时的驱动缓存。
- 临时 stream 复用候选 24 次的显存轨迹与直接创建/销毁一致，**不采用**。`stream-pdl1.log`，隔离源码生成器 `build-stream-probe.py`。
- 只建真实生产 bridge、执行网络 warm-up 再销毁（无 codec/PSO）：24 次也有逐渐饱和的增长，末 6 次销毁后均为 1886.0 MiB，见 `bridge.log`。这把剩余暂态缩小到桥接/网络/驱动生命周期，不能归咎于 codec PSO。
- 分段销毁探针显示 codec 销毁后驻留名单归零；日志 `diag-pdl1.log`。剩余缓慢增长最终在延长测试中平台化；具体驱动内部缓存类别未继续归因，不把它叫成已证实的 PSO 或 HIP allocator 缓存。

## 切档日志

成功 PrepareFrame 后，输入宽高或网络有效/处理几何改变才记录一次：

`lmxxf: geometry net=1600x900 color_job=1707x961 proc=1600x960 wave_owned=1/1 c512_m32=1/1 vit_proj_n64=1/1 pdl=1/1 skip=3 | flags: ...`

- 独立文件：`DLSS5-AMD\logs\native-re9-runtime.txt`（开发环境回落 `D:\DLSSNR-Lab\logs`）；同时 OutputDebugString，GetLastError 留成功通知供宿主转记。
- 四组均是 requested/active。前三组保留模块缺失前的 requested；PDL active 来自 warm-up 实际 PDL 调用计数。GetStatus 同步用这组真实状态。
- 补上输入不变但网络处理档位变化时的重建判断，避免日志显示新尺寸而 bridge 仍保留旧尺寸。
- 60 阶段×8 帧那轮日志恰好 60 条，没有逐帧刷屏；`geometry.log` 保存那轮证据。最终 120 阶段的日志另存 `geometry-final2.log`。

## 对照

固定资产/模块：`re9-runtime-flags-20260926/new/DLSS5-AMD/native-game-tiled-assets`，所有变体相同；来自 0.31/0.32 的既有测试集，不冒充 M/W2_PACK8 6 的性能测试。C API harness 是既有 `rt_bench.exe`，ABI 2。

| 变体 | 尺寸阶段数 | 第 24 阶段（900 档） | 说明 |
|---|---:|---:|---|
| base（当前源修改前重编） | 24 | 3005 MiB | 复现旧增长 |
| fix（解绑+释放） | 24 | 2296 MiB | 同样 24 次低 709 MiB；末段仍在增长 |
| final2 | 120 | 2296 MiB | 到第 103～120 阶段各档固定，900 档 2443 MiB |

final2 最后六轮：1080=2475、720=2467、900=2443 MiB，每轮完全相同。跨尺寸的用量差不是泄漏，比较同尺寸相邻轮。

输入 → 网络档位的末帧 FNV-1a（最终候选对原基线）：

| 输入 | 档位 | hash |
|---|---|---|
| 1920×1080 | auto→1080 | `5f58c6763129daf6` |
| 1280×720 | auto→720 | `1041b80449791547` |
| 1707×961 | auto→900 / 强制900 | `082162677c863395` |
| 1707×961 | 强制1080 | `92d97ecf3d414a45` |

120 阶段的每个末帧均与对应旧 hash 相同。长切档测试每尺寸只跑 2 帧，因此 `mean_ms` 包含初始化，不用作性能读数。PDL 独立性能比较见 `../pdl-audit-20260927/`。

最终 PDL 关闭的小测状态确为 `pdl=0/0`，输出 hash 不变（`final2-pdl0.log`）。

最终 runtime-smoke 与强制档位的 24 帧哈希检查见 `final2-smoke.log`、`final2-hash-*.log`。

## 复现与下次发包

- 实验脚本在 `Development/HIP/experiments/re9-runtime-leak/`；`run.ps1 -Variant final2 -Rounds 40 -Frames 2` 复现 120 阶段；`verify.ps1` 做独立 smoke/强制档位检查。
- `bash scripts/build-runtime.sh <out>` 构建仓内唯一生产源。`Development/RE9/presr/build-runtime.sh` 改为调用同一入口，不再编译旧上游 runtime 补丁副本；prepare-host 的 third_party 快照同时复制 canonical `.cpp` 和 API 头。
- 下个 RE9 包取本候选或从本提交重新编译；保持既定宿主 aa3761f2 与待发模块配方，重新做整包 runtime-smoke。已有目录里不直接覆盖游戏文件。
- 这些头文件也影响 add-on；本轮完整 NativeGameFrame 七用例逐位通过（见 PDL 报告），下次发包按原规矩重编 add-on 并实机验收。
- `manifest.json` 记录各 DLL 与最终源文件 SHA256；`measurements.csv`、原始日志保留分阶段数据。`diagnostic.py` 是临时分段测量变体，不进入生产。
