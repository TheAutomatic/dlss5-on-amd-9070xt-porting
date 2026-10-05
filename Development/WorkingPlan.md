# 当前工作计划

更新：2026-10-05。此文件整份重写，保存当前状态与尚未完成事项；历史过程见 DevHistory.md。

## 工作规矩

- 具体编译、实验、安装、归档交子代理；主进程只调度与审交账。
- 有人提 PR，能合入就尽量合入。
- DevHistory 只追加；WorkingPlan 整份重写。公开记录只写客观工程事实。
- 单队列使用 GPU：先 game-check、原子 gpu.lock、15 秒游戏看门狗，实验实际写入/缓存盘至少 100GB（9070仍用D；5090本次小探针用C，D数据只读、共享锁极小例外）。游戏运行时不抢 GPU、不换载荷、不结束正常游戏；继续独立 CPU 工作。
- 无损候选保持 K 累加顺序、舍入、FP8 编解码、NaN 与正负零合同。先小筛，有可靠收益才进正式门；慢轮或尾延迟退步不刷轮掩盖。
- 性能使用连续 TimingOnly、首尾读回，中间不扫描图像；坏事件负值批隔离。微核与 DUP 边际不相加当整网或 FPS。
- 默认不变、配置逐字保留；安装前备份、安装后 readback 与 exact 快照同步。短记录后及时提交，不 push、不改外层仓、不擅发布。

## 已完成的发布与当前安装

- 0.40 基线 tag 为 c81a88bc。0.41 已构建、三包验证并交付；台账提交 523723fd，二进制源码标记 ab8e3e82。正式 annotated tag `0.41` 指向 523723fdb3fa5b322beb1cc9dcfd3f8183eaf334，已仅推该 tag。
- 0.41 三包在 `/home/lmxxf/work/dlss5-release-0.41/` 与 Windows `D:\給網友打包`，SHA256SUMS/发布台账齐全。镜像已记录于 70ebd402：夸克 https://pan.quark.cn/s/dbda3e470f8f ，Gofile https://gofile.io/d/YAENU0ex 。已上传 ZIP 不再修改。
- 发布默认为 MULTI_PASS=1、MULTI_PASS_PREDICT=1、SKIN_PROTECT=0。预测只在选择 3x 时执行两遍真实网络并预测第三遍；显式 PREDICT=0 为真实三遍，1x/2x 不受影响。
- 发布包为 38 模块/架构、共 76；每架构五行公开 LLVM23.1.2，其余 COMGR LLVM21，双架构 ELF 目标已核。旧 rtc 忽略目标的问题已通过当前源码重编工具与目标检查处理，不再列为待发布阻碍。
- 发布后的三刀已完成：76750a80 最终 RGB 共享输出免一次 copy；9bbd3749 block4 pool→首 C64 字节边；c756f296 仅真实 1440/FAST1 的同数学 SP-fast 持久队列。各自数值、正式平均/p99及必要宿主兼容门通过，收益不能跨批相加为 FPS 承诺。
- 当前双游戏已装第三刀：剑星 addon 698A23A4，鬼武者根及 _storage_ runtime 634FAF45；开发载荷共 78 模块（旧 76 不变，新增双架构 SP-fast），与已发布 0.41 的 76 区分。最新回滚脚本：`D:\DLSSNR-Lab\sp1440-fast-20261005\backups\20261005-080146\rollback.ps1`。
- 当前玩家配置与发布默认不同：剑星、鬼武者均 MP3/PREDICT1/SKIN0，HEIGHT=auto/FREE_RES=0，强度未改。剑星 F9 只切 1/2/3 遍数；文件约 1 秒热载。鬼武者无 F9、无文件热载，修改需重启。
- 既往实玩剑星 1x 约57.6fps、快速3x约37fps；鬼武者900P快速3x约49fps、强度更新后无异常。均为用户观察，未提供三刀后的同场景 ABBA/FPS 验证。
- PR15 已正式 merge 8a6c7bc1，保留贡献者作者；Enqueue 入口恢复已选 HIP device，0.41 已含。RE9 强度文件数字覆盖已含；auto/缺省继续尊重宿主参数。中英文 README/配置页与公众号使用说明已完成。

## 第一项：建筑房顶闪烁（受控阶段已闭环，真实场景待验证）

1. 当前证据：111.mp4 是约4.11秒、119帧、29fps的竖幅拍屏最终画面，没有原始网络输入、MV/depth或开关 A/B。不能伪造网络复现或由视频直接归因 HIP。
2. 重新跟踪同一房顶表面后确认局部亮度反复。1.586/1.621/1.690 秒 roof Y=96.6/116.2/98.1，UI=79.78/79.87/81.55；第一步 roof 跳变明显大于参考 UI。最初关注人物运动/草地而暗示静物稳定已纠正。拍屏曝光、透视、游戏自身 TAA/高光仍有混杂。
3. 网友场景线索尚未独立复验：跳32–36、38部分抑闪；全跳31–38房顶反光基本消失；40后块对该反光无影响；31–38单跳任意一个仍闪；奇偶各跳4块分别抑中间/边缘。31–38实际均为同形完整全局 ViT，无奇偶 shift，37没有特殊结构。删除反光不等于保留反光并稳定时序，跳块不是无损修复。
4. 尚待确认网友使用 `DLSS5_SKIP_BLOCKS`（全遍）还是 `DLSS5_MULTI_PASS_SKIP_BLOCKS`（第二遍以后）；不猜。该缺口不阻碍独立时序代码分析。
5. 当前原生 pre 路径每帧 reset=true/seed0；可有 prefix history 输入，但没有原版 motion 重投影与门控 post history。OUTPUT_SMOOTH 是独立近似，不能代称完整原时序。
6. 新确认资产缺口：当前 post70-head.f32 仅 RGB 的3×32；原生16×32权重中 row6 为非零 history gate，但现 unpack 只导出 row0/2/4。原 blend half=0.73974609375。已独立恢复 gate32、保RGB96不变；原SASS确认两K16 HMMA.F16及SIG/blend/FFMA合同。真实5090两Eval确认Reset1→0、seed0→1与history/MV空→非空。标准CUDA查询当前context为空，原私有history格式/内容仍待直接确认。
7. mochi ReShade History 默认1；History0仅关闭 post blend，prefix history 与 seed推进仍存在。低层 API 默认不同；网友所谓另一家未具名，默认状态未独立核实。
8. 已完成默认关闭的MP1实验：纯空间、prefix-only、prefix+gate三路，固定seed0/逐帧seed拆因子。小合法NN48行、valid1920×1080/proc1152合成NN18行全finite；off/first/reset对独立当前基线0字节差，自重复0字节差。仅有效RGB存历史，padding镜像/后处理有效区分离。首批继承模板AE1已隔离为diagnostic；正确VIT_ADAPTIVE=0重测过。
9. 原post16×16 closed/zeroMV/+1px/对角亚像素gold与软件5tap/严格gate全float-bit0；head24576控制特征半码0差。AMD SIG最大3ULP差已量化，实验严格用NV half域表。原型保rawΣ×reciprocal的融合减RGB顺序，F64 head仍参考实现。均值/同geometry波动分开；18行1080合成数据不显示普遍抑波动，不宣称闪修。
10. 未改默认、未装游戏、未改0.41包。尚需真实连续输入/MV/jitter/exposure/reset与真实反光/遮挡拖影验证、原内部history内容/格式、MP3各遍历史规划；仅保留实验原型，不把跳块当无损方案。结果见results/temporal-sequence-20261005及post-history-gate-20261005。该缺真实源不阻碍下一独立优化，已按顺序转第二项。

## 第二项：ViT960 contract 大 tile（当前CPU原型准备）

- 与已否的 attention 恒960常量化不同，研究当前 contract_frag_bout 的16token×64列 wave tile；参考 mochi ≥768 token的大 tile路径，保 K1024四段边界、每段累加顺序、skip初始化、FAST_H及 FP8/正负零合同。
- 当前该核约208 VGPR。首选两wave各16tokens共享同64列K512 FP8权重（32KiB LDS），不直接单wave增加acc；四K1024 partial边界/各lane原顺序不变。先核寄存器、LDS与barrier成本，不能用上游44.7→40.4µs微核数字许诺整网收益。
- 新导出限定960 token、配对 HasFn 缺失整体旧路回退；400/640不变。先真实 contract/QKV/projection tuple 逐位，再短微核与整网筛；无稳定收益即止。

## 第三优先：小 buffer 延迟复用（尚未实验）

- 当前 Network::New best-fit 可立即复用；研究≤8MiB buffer晚一个 dispatch复用的 cold-age策略，与 mochi Vulkan案例区分，HIP收益待测。
- 必须明确 shared_ptr池的租约/最后消费、PDL keep、graph、跨 stream寿命，不能把对象析构误当用户归还；限制额外显存与 CPU开销。
- 第二项结束后才实施有界 A/B；不重写整个 allocator，不凭上游投影局部耗时承诺整网改善。

## 其他未完成事项与限制

- Issue13：独立5090原版 exact合同双帧 p95约14.94%已闭环，原入口一致、原post FP16 surface已抓。不能据此解释所有 production闪烁。Test20报告23.315485%、注入各自 exact pre-down降16.327520%，但其源码/commit/effective flags/module SHA尚缺；取得指纹后再定位。prefix16/投影32是原核寄存器/LDS中间值，不能用CPU仿写冒充未改原模型输出。公开数据与tiny pre-down包在 https://gofile.io/d/FWpuapJe 。
- Issue4：贡献者双HIP设备 A/B/C证明入口绑定修复；本机只有一个HIP设备，真实双设备与线程ID验证仍缺。LUID选择本已正确，400标签可能来自懒 GetFunction而非launch，不泛称跨adapter问题。issue未擅关闭。
- gfx1200：模块目标头已核，真实对应硬件运行仍待；不拿gfx1201验证代替。720几何独立NVIDIA oracle仍待。
- AE720旧runner曾漂移；同HEAD fresh基线正常/AE/CSV/roll已过，旧产物异常未定位。无新具体证据不扩大重查。
- 真2K FREE_RES=1真实游戏观感/整帧成本待玩家选择；当前FREE0，不悄然把900配置切2K。HDR、FG、长期运动/遮挡质量不能由少帧离线门推广。
- PRE_UPSCALE auto 的 Forza/WoLong实玩待确认；剑星 native PRE1仍覆盖auto。剑星 native STRENGTH=auto覆盖custom数值的层级需设置时明确，不能擅改层级规则。
- 内存增长尚未复现；D3D/HIP固定交接税与占比已有研究，不推普遍速度越快必停滞或HIP无解，不开展新TDR试验。
- 已封存负账：C512 LUT、C32固定几何、ViT960 attention常量化、其他LLVM23行盲扫、IO_FUSE尾延迟、无效C512_T8宏、DEC_F8W/COMPACT路线。只有新瓶颈证据才重开；已收 directRGBA、ViT byteedge、C512 directpack、1440融合及三刀不重复当新候选。
