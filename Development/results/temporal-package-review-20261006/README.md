# 0.41-a history可选接入：独立合同审查（2026-10-06）

审查对象是施工中的工作树源码；快照SHA见reviewed-source-sha.json。此次只读代码/官方FFX合同并写独立结果，不GPU、不改实现/默认/已装游戏/ZIP。实现者负责另行编译与GPU回归；本审查不能代替它们，更不等于已治实景闪烁。

## 已修且已独立复核

| 项目 | 施工初期问题 | 当前源码结果 |
|---|---|---|
| 激活传参 | Frame.Create遗漏新experiment尾参，永久fallback | Create明确传resources->experimental_temporal |
| 新旧历史语义 | 旧feed是f32存储/仅prefix，没有原postgate | 新路只复用motion feed/UV坐标，HIP自持history；不创建/执行旧sampler/smooth/guard/store |
| UV footprint | 旧桥按RGBA16F约定校验和复制16B/像素，UV只有8B | InputContract和CopyBufferRegion固定按ExperimentalTemporalConfigured()取8B；不按动态Active选择，MP切换不会把UV解释为旧RGBA历史 |
| HIP allocation | New(n)实际n×4字节，history/prefix/raw误按byte-count传入，4倍容量 | history/prefix/raw用4 float/像素，logit半码按ceil(count/2) float容量；32half feature用16float/像素保持正确 |
| MP1→MP3热切换 | tap保护直接throw；旧历史跨遍数沿用风险 | experiment允许SetMultiPass；进入MP3/skin等inactive走EnqueueRaw(input,nullptr,output,seed0)，清ready；Frame在选seed/UV前轮询Hot状态并清prior；回MP1冷帧 |
| warmup前史 | 全零warmup可能成为首帧history | PrepareStagedKernels在warmup Enqueue后InvalidateExperimentalHistory，首真实帧仍cold/seed0 |
| motion scale/geometry | 构造期常量可能错误沿用 | OneShot在source/motion/render维度或declared scale变化ResetForNewSession；Frame也对初始scale再拒历史 |
| exposure/缺MV/断帧 | 未转交元数据，旧history可能错域 | pre路径转交preExposure/reset/frame_id；曝光值改变、缺MV、非法metadata/帧号跳变冷history；不猜曝光缩放 |
| MV资源state | prefix采样必须在实际可读状态 | experimental pre路线围住采样把j.states[2]转NON_PIXEL_SHADER_RESOURCE，再恢复；OFF不加此转换 |

空TemporalConfig、post-upscale、XeSS、无FFX pre metadata不会激活新路。缺UV时本帧不读取旧history；HIP仍可以存本帧cold结果，Host严格决定下一帧是否把UV交给HIP。两层ready不表示GPU已CPU同步完成，正确性依赖同HIP stream和既有桥fence有序交接；新路未增加不受控多stream读取。

## 原数学与域

history保存内部Network RGB经gate blend后有效区域，RTZ到half再精确扩大成f32 RGBA/alpha1；不是API最终decode输出域。原格式与RTZ证据在../history-contract-20261006，不能退回旧feed的f32或默认RNE存储。

HIP warp_uv使用规范化UV、21bit坐标/8bit采样权重、五tap；prefix使用归一化RGB。post保raw五tapΣ与reciprocal，先一次FMA(recip,Σ,-currentRGB)，再一次FMA(gate,delta,currentRGB)。gate用恢复row6原权重与NV sigmoid表；只把匹配的半特征交给gate，不用AMD近似EXP2/RCP冒充原逐位SIG。

## MV单位、符号与范围

FFX提供当前像素到上一帧位置的vector，因此previousUV=currentUV+scaledMotion。网络像素位移=rawMV×declaredMotionScale×fitExtent/renderExtent，再乘1/networkValidExtent成为UV；FFX这里保持+号。固定MVScale=1时raw是render像素，Scale=renderExtent时raw是归一化位移，两者不能混成一个固定单位。

这点有AMD官方primary支持：[FSR3 upscaler manual](https://gpuopen.com/manuals/fidelityfx_sdk/techniques/super-resolution-upscaler/)，提供previous-current motion及render-size scale示例；[FSR2 input资源/Providing motion vectors](https://gpuopen.com/manuals/fidelityfx_sdk/techniques/super-resolution-temporal/)明确current→previous方向与scale的意义。以上是标准FFX合同，不等于已验过网友房顶场景中的非零MV。

FFX默认要求motion不含jitter；JITTER_CANCELLATION是**context创建flag**，dispatch Description.flags(+428)不能冒充它。当前没有取得该创建flag，新包额外要求DLSS5_TEMPORAL_MV_UNJITTERED=1显式声明；未声明则fallback，声明后仍只是用户选择的实验前提。仅记录当前jitter，不擅加/减jitterdelta。它没有depth遮挡门、反应性mask或完整原NGX exposure重映射；不同depth inverted/range不参与本warp，不能宣传已复刻这些机制。

## 临时说明必须写清

1. 0.41-a是独立试验包，正式0.41下载/ZIP/tag不改；history开关默认关闭。
2. 对照在同一场景、相同尺寸/强度/full71/FAST设置下进行；先MP1，设置experiment=1、MV_UNJITTERED=1，并关闭AE/skin/graph/overlap/FAST_TEMPORAL/旧smooth/guard。两项新声明都需重启。
3. **启动时必须MP1**：以MP3启动会永久不加载新twin，后来F9改1x不够，需要重启。MP1启动后F9→2/3会明确回空间旧Body，返回1x重新冷history。
4. 让网友查看temporal-history-experiment.txt的active/history/reset/reason，避免把未激活或不断reset当成“history没作用”。开与关都提交同处房顶录屏，并另外看移动/遮挡是否拖影；降低反光强度不等于保留反光并稳定。
5. 没有该网友的真实连续source，原语/synthetic门不能写成房顶已修。当前只支持regular FFX pre-upscale试用，不把RE9/XeSS或MP3当已支持。

## 门前尚需实施者交账

- 默认OFF、缺assets/无metadata/未声明MV前提与独立旧baseline exact；配套新模块/asset hash、gfx1200/gfx1201目标与输出默认隔离。
- 新regular游戏bridge完整首帧/重复/reset/缺MV/曝光跳变/尺寸变化；MP1→2/3→1当前帧fallback及回来cold；支持Normal与FAST两种模块。
- 不用现有隔离sequence的通过记录替代新bridge这一门。实际GPU/包验收结论应另附结果路径，未交账前本文件只给源级“已修/范围限制”的结论。
