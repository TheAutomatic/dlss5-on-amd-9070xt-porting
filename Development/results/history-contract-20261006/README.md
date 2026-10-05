# 原版 history 格式、内容与 FP16 写入合同（2026-10-06）

本次得到真实原版内部资源证据，并发现 MP1 实验 history_store 的 RNE 政策与原版 RTZ 不同。没有修改生产模块、默认、游戏配置或 0.41 包；没有声称修复真实房顶闪烁。

## 已证明

- 原插件 SHA e16bcf15…、成功 core615/nvngx.dll SHA52a68acc…，同既往合法原版入口。真实5090 1920×1080 两次 NGX Eval 全 SUCCESS，Reset1→0；pre seed 字段 +0xc8 为0→1。输入为既有 Issue13 8678/8680 RGBA16F，与111.mp4无关；MV独立全零RG16F、depth独立R32F常数1。
- 原版私有 backend 实现在插件内，vtable slot21/RVA0x5d640返回texture handle，slot22/RVA0x5d5d0返回surface handle。hook只观察CPU参数/返回值，原调用透传，不切换/创建CUDA context。返回handle与同次D3D12Resource指针直接绑定，再用真实GetDesc核格式，**不是由handle低位猜资源**。
- post surface `0x8803` 对应 tex5：DXGI_FORMAT_R16G16B16A16_FLOAT，1920×1080。后段输入texture `0x7fa00008804`仍为同一tex5。history保存目标surface `0x8805`为tex0，同为1920×1080 RGBA16F；API最终surface `0x8806`为tex2/RGBA32F。
- 第二Eval前，history `0x7f800008808`绑定同一tex0；MV `0x7fa00008809`绑定独立真实RG16F motion资源。pre/post使用同history/MV handle。第一Eval均空history/MV。post计算网格241×145但纹理有效1920×1080。
- 每次Eval原命令提交完成并等原D3D fence后，在hook外按跟踪的真实resource state做只读copy并恢复原state。两帧的history tex0与post surface tex5各8294400个half码完全相同，alpha恒1、全finite。API最终输出half化后与history RGB分别6191925/6189007码不同，不能把API final域保存为原history。
- 输出链是：上一帧tex0作为history读入；本帧post另写tex5；post后将tex5保存到tex0并生成独立API final tex2。两Eval观察中history资源没有pingpong替换，也没有post直接边读边写tex0。这里的保存/输出段通过原backend资源读写绑定和实际内容一致性确定；不是声称观察到一个普通CopyResource调用。
- 控制组只在第二Eval替换**局部post packet**，清除+0x58/+0x60；prefix、seed、输入、权重及其余packet字段保留。第一帧history与正常组0差，第二帧RGB3077213 half码变化。这排除了“两个hist/post相同只是history关闭”的解释：正常组确实保存有有效post blend的输出。

## 发现的舍入错误

原post SASS在blend之后直接 `SUST.P.2D.STRONG.SM.IGN` 格式化写surface，未显式F2F。由指令名不能擅定RNE/RTZ。

本次用**同一个未修改原CUBIN**（feb368ff…）、同weights/input/color/history/MV，把输出surface FLOAT4与HALF4交叉对照，HALF4读回再精确扩大成f32。现有controlled fixtures的history/color是half-exact；零head使gate可控，未重复SIG/head/warp接受门。

| case | 输出数 | 相对RNE不同 | 相对RTZ不同 | 未经half舍入的值数 |
|---|---:|---:|---:|---:|
| history关闭 | 1024 | 0 | 0 | 0 |
| 零MV | 1024 | 496 | 0 | 768 |
| +1像素MV | 1024 | 496 | 0 | 768 |
| (+.25,+.375)亚像素MV | 1024 | 576 | 0 | 768 |

因此本模型有限正RGB工作域的原post FP16存储应使用**RTZ**。当前隔离MP1 `temporal_store` 的 `float((_Float16)rgb)` 默认RNE需改成显式RTZ；此修正属于原版合同恢复，不能据此声称房顶闪烁已经修复。本次没有推论负数/NaN/无穷格式化surface的全域语义。

## 证据与复核

- normal/close-post-launch.txt：全部kernel名称、原pre/post packet、backend texture/surface到D3D资源指针、D3D创建格式和读回copy顺序。
- normal/close-post-eval.log：合法Eval及每个readback的resource、format、state和大小。
- packet-summary.json、history-data-check.json：实际绑定/seed及完整数据比较。
- gold/：八个4KiB原post FLOAT4/HALF4输出；rounding-check.json；CPU检查入口：`python3 Development/HIP/experiments/history-contract-20261006/check_rounding.py Development/results/history-contract-20261006/gold`。
- rounding-fixture-hashes.json保存原CUBIN、helper、输入、weights及gold全部SHA。原helper源码为同仓 post-history-gate/original_post_history_oracle.cpp；已存在HALF_SURFACE开关。原weights/gate来源继续沿gate-assets.json，未拟合权重。
- 大型真实history/post/API raw不入git，保存于5090 C两个隔离目录及本地/tmp/history-contract-20261006/{normal,closed}；完整SHA/大小见large-raw-hashes.json。
- build.sh和build-hashes.json记录隔离探针源、MinHook对象和编译依赖。执行binary wholeSHA66415f14…；补注释后的复编wholeSHA不同（PE时间等），但.text两侧同c20fb3e2…，不得声称整个binary一致。

所有GPU轮均初始game-check、D共享原子gpu.lock；完整两Eval探针有15秒游戏看门狗，post-rounding小探针各限时15秒并只结束自身进程，实际均秒内结束。正常游戏未结束。实测C可写/cache盘约784GB，D约84GB，只读旧源/DLL，极小共享锁例外。两个完整取证组D原源51文件元数据均无变化；结束锁不存在。hooks有CPU日志开销，hook外增加只读copy/fence，故这批不用于性能或FPS推论。

## 尚缺

真实111.mp4连续输入/MV/jitter/exposure/reset；真实反光稳定与遮挡拖影质量；缺MV恢复、后续Reset/resize、曝光域变换的完整原版序列行为；MP3历史分支政策。两帧与小gold不能替代这些验收。
