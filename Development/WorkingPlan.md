# 当前工作计划

更新：2026-10-06（只读优化差距审计后）。此文件整份重写，保存当前状态与尚未完成事项；历史过程见 DevHistory.md。

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

## 当前优先顺序：解释mochizuki差距（本轮仅研究与规划，未执行新实验）

1. **锁账与同步纯网络对照**：当前0.41＋三刀/full71/FAST0与FAST1，对锁定mochi0.0.2.5旧exe/SPV/plan/effective宏/源/模型与输入。当前本地mochi4f62a8a不是旧测速d1185d2，缺资产明说。固定valid/proc/token/有效块、MP1/PRED0/SKIN0/AE0、Style/seed/history；统一GPU边界与D2D口径。纯Network现分支CPU chrono＋逐帧sync不是GPU timing，保同步加GPU事件；无逐核事件、首尾读回。旧差距与事件均摊/DUP仅诊断，不认精确贡献。
2. **提交交叉对照**：先每帧同步；pool复用/PDL keep/SP代际安全审核通过后才1→8→500批量，不能直接删sync。GPU均值与CPU吞吐分别列，同实现输出逐位不变；错误/坏事件/增长即止。
3. **同HIP16-query数学阶梯**：FAST0/当前FAST1→仅score halfFMA/位图→64key half分母树→配方确认后的AV截断/half末端。当前分母/AV为f32累加。每步数值、资源、整网平均/p99独立记账；新增状态/资源不能称纯数学，有损研究不部署，B/C无收益不自动D。仅显著资源变化才复查旧M32交互。
4. **局部ISA排程**：新热点账证明等待段后再做，不预估收益。跨层窗口≤4父子依赖，不能简单寄存器跨层，暂无新候选；旧全空消融是整网边际并改变下游，不是本体上界；8streams负账不泛化为所有队列严格上界，不重开旧线。

具体证据、最小实验门与止损见results/mochizuki-gap-audit-20261006。以下独立质量事项与两项已止负账继续保留。

## 建筑房顶闪烁（受控阶段已闭环，真实场景待验证）

1. 当前证据：111.mp4 是约4.11秒、119帧、29fps的竖幅拍屏最终画面，没有原始网络输入、MV/depth或开关 A/B。不能伪造网络复现或由视频直接归因 HIP。
2. 重新跟踪同一房顶表面后确认局部亮度反复。1.586/1.621/1.690 秒 roof Y=96.6/116.2/98.1，UI=79.78/79.87/81.55；第一步 roof 跳变明显大于参考 UI。最初关注人物运动/草地而暗示静物稳定已纠正。拍屏曝光、透视、游戏自身 TAA/高光仍有混杂。
3. 网友场景线索尚未独立复验：跳32–36、38部分抑闪；全跳31–38房顶反光基本消失；40后块对该反光无影响；31–38单跳任意一个仍闪；奇偶各跳4块分别抑中间/边缘。31–38实际均为同形完整全局 ViT，无奇偶 shift，37没有特殊结构。删除反光不等于保留反光并稳定时序，跳块不是无损修复。
4. 尚待确认网友使用 `DLSS5_SKIP_BLOCKS`（全遍）还是 `DLSS5_MULTI_PASS_SKIP_BLOCKS`（第二遍以后）；不猜。该缺口不阻碍独立时序代码分析。
5. 当前原生 pre 路径每帧 reset=true/seed0；可有 prefix history 输入，但没有原版 motion 重投影与门控 post history。OUTPUT_SMOOTH 是独立近似，不能代称完整原时序。
6. 新确认资产缺口：当前 post70-head.f32 仅 RGB 的3×32；原生16×32权重中 row6 为非零 history gate，但现 unpack 只导出 row0/2/4。原 blend half=0.73974609375。已独立恢复 gate32、保RGB96不变；原SASS确认两K16 HMMA.F16及SIG/blend/FFMA合同。真实5090两Eval确认Reset1→0、seed0→1与history/MV空→非空。标准CUDA查询当前context为空，原私有history格式/内容仍待直接确认。
7. mochi ReShade History 默认1；History0仅关闭 post blend，prefix history 与 seed推进仍存在。低层 API 默认不同；网友所谓另一家未具名，默认状态未独立核实。
8. 已完成默认关闭的MP1实验：纯空间、prefix-only、prefix+gate三路，固定seed0/逐帧seed拆因子。小合法NN48行、valid1920×1080/proc1152合成NN18行全finite；off/first/reset对独立当前基线0字节差，自重复0字节差。仅有效RGB存历史，padding镜像/后处理有效区分离。首批继承模板AE1已隔离为diagnostic；正确VIT_ADAPTIVE=0重测过。
9. 原post16×16 closed/zeroMV/+1px/对角亚像素gold与软件5tap/严格gate全float-bit0；head24576控制特征半码0差。AMD SIG最大3ULP差已量化，实验严格用NV half域表。原型保rawΣ×reciprocal的融合减RGB顺序，F64 head仍参考实现。均值/同geometry波动分开；18行1080合成数据不显示普遍抑波动，不宣称闪修。
10. 未改默认、未装游戏、未改0.41包。尚需真实连续输入/MV/jitter/exposure/reset与真实反光/遮挡拖影验证、原内部history内容/格式、MP3各遍历史规划；仅保留实验原型，不把跳块当无损方案。结果见results/temporal-sequence-20261005及post-history-gate-20261005。该缺真实源不阻碍独立优化；本轮已按顺序完成下面两项裁决。

## ViT960 contract 大 tile（静态负账，已止）

- 与旧 attention 恒960常量化不同：尝试两wave各16tokens共享64列K512 FP8权重32KiB LDS，保四K1024 partial、skip、FAST_H与byte出口原顺序。
- canonical双arch实际baseline208VGPR/0spill/0private/4KiB LDS；候选256VGPR/171spill/688B private每thread/32KiB LDS。静态门直接拒，不跑GPU、不给上游微核数字作整网承诺、不扫更多tile参数。
- 候选仅保实验源码与ISA资源/hash，生产未改、未安装。记录main64257116，results/vit-contract960-20261005。无新瓶颈证据不重开。

## 小请求晚批复用（真实1440短筛负账，已止）

- 默认0实验宏；≤8MiB请求只在原use_count1/足够capacity集合再排近期possible-use块，包含较大capacity。用logical launch-batch：连续DUP一批、SP init/run/recovery一批；非launch P可多延迟，不能当物理GPU完成/精确lastuse。graph旁路，PDL引用条件不变，不提前复用/释放。CPU七case过。
- 同源A0/A1、相同当前39/gfx1201模块，实际valid2560×1440/proc2560×1472/960token，full71/FAST1/MP1/PRED0/SKIN0/AE0。完整框架连续首尾读回、160帧/槽弃80：首ABBA A15.680819→B15.742244ms，慢0.061425ms，两B槽均慢于两A；raw全SHA相同。
- 策略实际命中recent_rejects34560/进程。按门立即止，不刷剩余轮、不跑无意义正常19/额外档、不改生产/安装。candidate.patch、CPU模型、CSV/hash齐；自己实验raw清理，weights/输入未动，锁已释放。main661c41a9，results/pool-coldage-20261006。
- 上述三项本轮均有具体结论；用户游戏载荷/config与0.41发布ZIP/tag不变。闪烁真实场景仍待连续源/实玩，不写已修复。

## 其他未完成事项与限制

- Issue13：独立5090原版 exact合同双帧 p95约14.94%已闭环，原入口一致、原post FP16 surface已抓。不能据此解释所有 production闪烁。Test20报告23.315485%、注入各自 exact pre-down降16.327520%，但其源码/commit/effective flags/module SHA尚缺；取得指纹后再定位。prefix16/投影32是原核寄存器/LDS中间值，不能用CPU仿写冒充未改原模型输出。公开数据与tiny pre-down包在 https://gofile.io/d/FWpuapJe 。
- Issue4：贡献者双HIP设备 A/B/C证明入口绑定修复；本机只有一个HIP设备，真实双设备与线程ID验证仍缺。LUID选择本已正确，400标签可能来自懒 GetFunction而非launch，不泛称跨adapter问题。issue未擅关闭。
- gfx1200：模块目标头已核，真实对应硬件运行仍待；不拿gfx1201验证代替。720几何独立NVIDIA oracle仍待。
- AE720旧runner曾漂移；同HEAD fresh基线正常/AE/CSV/roll已过，旧产物异常未定位。无新具体证据不扩大重查。
- 真2K FREE_RES=1真实游戏观感/整帧成本待玩家选择；当前FREE0，不悄然把900配置切2K。HDR、FG、长期运动/遮挡质量不能由少帧离线门推广。
- PRE_UPSCALE auto 的 Forza/WoLong实玩待确认；剑星 native PRE1仍覆盖auto。剑星 native STRENGTH=auto覆盖custom数值的层级需设置时明确，不能擅改层级规则。
- 内存增长尚未复现；D3D/HIP固定交接税与占比已有研究，不推普遍速度越快必停滞或HIP无解，不开展新TDR试验。
- 已封存负账：C512 LUT、C32固定几何、ViT960 attention常量化、其他LLVM23行盲扫、IO_FUSE尾延迟、无效C512_T8宏、DEC_F8W/COMPACT路线。只有新瓶颈证据才重开；已收 directRGBA、ViT byteedge、C512 directpack、1440融合及三刀不重复当新候选。
