# PDL tile 旗子审计（2026-09-27，闇）

## 结论

**原实现：存在竞态。** 可以构造明确触发条件：同一个 Network 长期运行，使任一 uint32 累计目标回绕。上一代旗子的大值满足新一代的小目标，消费者无需等新生产者完成便进入计算。`wrap-witness.json` 是按源码整数运算和比较规则生成的有限反例；没有冒称在短游戏测试里复现过。

本轮修复了回绕：`PdlSlot` 加法将溢出时，先同步该 stream 的所有旧任务，清零对应槽，再同步清零完成，最后从新目标开始。只清一个槽；进入新代前不存在旧读者/写者。正常帧只多一个主机整数比较。压力构建将上限降到 64，验证同一 drain/clear 路径。

**修复回绕不等于完成 PDL=1 的安全证明。** 消费端仍是 relaxed 轮询 + `s_barrier`，没有生产后 acquire；跨 launch 的自旋进展性也没有找到 Windows gfx12 的公开保证。因此不能把修后版本标为“已证明安全”，也不能无条件称“安全但依赖经验”。可立即采用的完整保守路径是现有 `DLSS5_HIP_PDL=0`：不发 `_pdl`/旗子路径，恢复同 stream 的普通 launch 顺序。本轮实测它的逐位结果和代价；**未改生产默认值、未动 hip/ 内核、未装游戏**。

## 1. 对象与代次

审计 `Development/HIP/hip_reference_network.h` 的 `PdlSlot`、`Body`、`AttentionFast`、`Run`、`RunGraph`、`New`；以及 `hip/multihead_fast_padded.hip`、`multihead_fused_attention.hip`、`wave_owned_attention_{setup,exports}.inc`。

- 槽键 `(kind,c,ww,hh)`，每槽 16384 个 uint32，最多 64 槽；不是按帧清空的环形队列。`pdl_total[slot]` 每次增加该生产者每组 wave 数，GPU 每 wave 增加 1。
- FFN 是 `c*2/32`；旧 attention 是 C64=8、C128/C256=16；wave-owned C256 attention=8。一个 Network 的 kernel 配置固定，host 目标与对应导出相符。
- 网络切档创建新的 Network；跨帧同一 Network 继续累加。跨帧可以靠末段普通提交与下一帧普通入口排序，但这并不会阻止整数回绕。
- 同槽相邻使用至少隔几个 launch 只是静态距离，不能推出旧代所有组都完成。严谨保留并发的版本需要证明每个槽/每个 tile 的代际依赖覆盖（含 padding tile），或为代次分槽并在复用前建立完成依赖。单纯给计数加一个代次字段，不会自动解决缓冲区覆盖或等待者占满设备的问题。

## 2. 张量与 pool

`New` 仅复用 `use_count()==1` 的 pool 条目；PDL 每个 `Body` 留住 input、ffn、producer_norm、out，共 4 个引用，最多 32 个，即 8 个 Body。当前最长相关链是 C256 的 15–22 与 48–55，各 8 块；Down/Up 和下一链头走普通提交。因此当前拓扑的 pool 保护比“隔四个 launch 应该够”强：一条链结束前其全部 Body 的四类对象都受保护，下一段第一次可能覆盖它们的工作位于普通有序边界之后。

这是**当前固定拓扑**的结论，不能推广到任意延长的链。链内新开临时 tensor、helper 返回前释放、kernel 重复派发诊断、跳块/改图或扩大并发范围，均须重审。PDL=0 下按正常流顺序，host 提前归还 pool 不等于 GPU 提前覆盖：后续写入排在先前读之后。

另修生命周期：析构先同步，再清 `pdl_keep`，释放漏掉的 4 MiB `pdl_flags`，然后释放 pool/模块/stream；避免引用拖到 Api 成员生命周期之后。构造后段失败也释放已分配旗子。

## 3. 发布与可见性

生产者每 wave 做 `fence(release, agent)`，随后 lane0 对旗子做 relaxed 原子加。消费者部分 lane relaxed 读到目标，随后整个 workgroup 执行 `s_barrier`。`s_barrier` 解决组内到达，不是跨组/跨 launch 的 agent acquire。

旧说明“派发包入口已经 invalidate”需要额外前提：从入口到读到各个旗子期间，没有其他 wave/group 或预取把尚未完成的数据缓存进来，也没有编译器把读取提前。C256 的 256B 特征、768B QKV 单 token 对齐，使跨 tile 共享缓存行风险较低；这解释了既有实验表现，**不构成公开内存模型中的 release/acquire 同步边**。

若继续保留 PDL 并发，最小内核层补强应在成功等待后执行 agent acquire，并保证只参与轮询的 lane/wave 把可见性正确传给其余读者；发布端同时核实 wave leader 的原子发布覆盖整个 wave 的存储完成。不能只把某个 leader 的 load 改 acquire 就称整个组已获取。此修改涉及 Hikari 的 hip/ 工作区，本轮不混改。仍需独立解决代次复用与进展性；acquire 本身不防自旋死锁。

## 4. 哪些是公开保证

- [HIP execution control](https://rocm.docs.amd.com/projects/HIP/en/latest/reference/hip_runtime_api/modules/execution_control.html)：`hipExtAnyOrderLaunch` 明确允许任意顺序；不能把普通 stream 的有序执行承诺无条件套在它上面。
- [HIP programming model 7.1](https://rocm.docs.amd.com/projects/HIP/en/docs-7.1.0/understand/programming_model.html)：普通同 stream 操作按提交顺序执行。PDL=0 的依赖排序建立在此 API 合同上。
- [ROCR AQL packet header](https://rocm.docs.amd.com/projects/ROCR-Runtime/en/docs-6.1.2/api-reference/api.html)：barrier bit 要求此前同队列包完成后才启动当前包。这是 AQL 语义参照，不是声称 Windows HIP 内部全部照搬 Linux ROCr。
- [LLVM AMDGPU GFX12 memory sequences](https://llvm.org/docs/AMDGPUUsage.html#amdhsa-memory-model-code-sequences-gfx12)：agent acquire 的实现要求等待原子读取完成后做对应 cache invalidate，再读数据；release 有自己的存储完成/可见性要求。入口较早的 invalidate 不等同于读取新旗子后的 acquire。
- [HIP workgroup scheduling](https://rocm.docs.amd.com/projects/HIP/en/develop/understand/programming_model.html)：workgroup 的执行次序不是确定序。未找到“前一任意序 launch 的全部组一定先被派发”“自旋消费者一定给尚未派发的生产者留槽位”的公开承诺。只有源码顺序和几十/几千帧实测不够证明这一点。

## 5. 验证

实验脚本：`Development/HIP/experiments/pdl-audit/`。复用 `benchmark_vit_reuse.cpp` 的完整 NativeGameFrame 回放，固定生产模块集（re9-runtime-flags-20260926/new；双侧相同），WAVE_OWNED/C512_M32/VIT_PROJ_N64=1，adaptive/graph=0。本次隔离的是 host 同步策略，不是新核性能。

- 720 移动、900/1080 静态与移动、900/1080 连续历史，7 组×12 帧，PDL=1 与 0 的 84 个候选帧逐位同，见 `correctness.txt`。
- 性能：两档各两批 ABBA，1000 帧/槽，去前 200；只首尾读回。数据见 `results.csv`，最终数值见后续结果段。
- 回绕压力：同源码仅把比较上限改为 64，在两档历史序列逐帧比较，并计数确认重置路径发生；数据见后续结果段。

原先偶发历史异常没有被此次审计归因；计数回绕也不能用来解释那个短会话。测试无差异与协议有边界反例可以同时成立。

### ABBA 结果

| 档位 | 第一批 PDL=0 增量 | 第二批增量 |
|---|---:|---:|
| 900 | +0.05633 ms（+0.52%） | +0.06636 ms（+0.61%） |
| 1080 | +0.07909 ms（+0.53%） | +0.07889 ms（+0.53%） |

每批四槽输出末帧 SHA256 一致；不是声称所有计时帧都读回比较过。完整逐帧检查是前述独立的 84 帧回归。数字只代表本次固定模块集，不替代 M/W2_PACK8 6 的发包基准。

### 回绕压力结果

900 历史序列实际重置 70 次，1080 重置 64 次，各 12 帧均与正常 PDL=1 基线逐帧同 SHA256。上限 64 仅存在隔离构建 `/tmp/pdl-audit-20260927`，生产仍是 UINT32_MAX。见 `correctness.txt`；`build.sh` 由当前源码生成该压力版。
