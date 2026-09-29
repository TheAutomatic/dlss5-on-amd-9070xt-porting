# 全网位置配对schema（未填时间）

生成：`python3 build-position-map.py --repo <297> --out <目录>`。
输入是deep-layers最终1080 topology（169行），Daniel旧dispatch静态重建的1080-daniel-default native1088分支（154行）。没有重新改Daniel网格冒充原生路径。

产物：

- position-map.csv：136个可加总comparison group，每行两侧dispatch IDs/job IDs/完整核名及实际shape数组，时间空白。
- dispatch-jobs.csv：323个真实派发条目。O001..O169为我方trace顺序；D001..D154是两份Daniel schedule的稳定行枚举，**不是执行时间顺序**；网络位置以block/phase/group_id为准。
- coverage.json：169/154均一次且仅一次归属，没有漏派发/重复派发。

## Job/计时关联

稳定job_id为 `ours.1080.b023.ffwd.0`、`daniel.native1080.b023.ffwd.0` 一类；同一ffwd组我方第二核为`.1`。
测量job可去重复，只要kernel、参数shape/flags、grid/threads、合成负载全部一致；将其ID放measurement_job_id。
Daniel浅层的measurement_job_id已接daniel-shallow.json里的`daniel-1080-daniel-default-blockN`。深层/我方测量尚未生成，不编造ID。
建议timings表字段：measurement_job_id, backend, kernel, shape_signature, grid_x/y/z, threads, graph_repeats, rounds, median_us, status, guard_ok。

每个group的两侧时间分别是所列各实际dispatch的中位数之和（当前calls均1），delta=ours−Daniel。重复调用按地图条目次数加权，不能将同一kernel只算一次。
这不是整帧GPU延迟：cache、并行、graph调度环境不同。失败/未测job留空，不能填0；只有skip组我方真实0派发可填0。

## 边界与跳块口径

按不能单独拆分的融合边界成组：4+down+5、8+down+9、14+down+15、22+down+23；30+pool/head；47+up+48、55+up+56、61+up+62、65+up+66。
这些组包含完整两侧相关kernel，不从融合kernel内虚构某个子阶段耗时；各真实派发只属于一个group。
42/43/46各四个Daniel阶段独立保留，我方0派发，比较策略skip_difference_exclude_implementation_rank。它们属于图结构/配方差异，不是“我们的核更快”。
ViT入/出Gather与两次Daniel repack均保留。包含两端的完整bracket是我方50对Daniel42，不能混用49/40的旧族边界账。

## 几何与面积折算

native1080：Daniel处理1920×1088，我方1920×1152；浅层各级有效H分别544/576、272/288、136/144、68/72。C512两者60×36，ViT都是640。
每个job保留实际grid/threads。浅层Swin另给actual_window_count/window_token_capacity；单核配对行有actual_window_work_ratio，避免只按有效像素比错误外推窗口取整。
例如C256两边某些位移同15×9窗口，另一些是我方16×10对Daniel16×9；“1152/1088”不是每个Swin核实际矩阵工作的统一倍率。
area_ours_over_daniel是**有效面积启发式**，不是实测或严格工作归一。跨深浅层边界组的倍率不同，标量留空，area_ratio_by_block_json保留各位置倍率；不能把整组盲乘一个数。
post还存在Daniel shift0与我方(-4,-4)差异，即使改同样行数也不等价；单列，不纳入严格同尺寸结构排行。
深层默认同有效尺寸也须检查真实tile容量与ABI（例如mix末半tile、attention窗口数），`same_valid_shape_check_work_abi`不表示算术/输出等价。

严格同尺寸排行先用eligible_exact_shape_rank=1的可测组；浅层另给带明确area-estimate标签的排行。native总耗时差仍可以列，但不能解释成全是实现差距。

## 默认ViT valid/padded计数已核

host03daa6/03daad读取level6 object218/21c，03db14/03db1b写object378/37c；乘积写370，再ceil64写374。
DLSSNR_VIT1D_TOKENS未设时03cfd0返回0，不走content重算分支。因此native1080 valid640/pad640；native900 valid448/pad448，不能猜成540/416。
显式`DLSSNR_VIT1D_TOKENS=content`才按frame474/478的ceil64更改valid范围。本地图只记默认。

## 候选约束

计时前不预判前两名。若大差距落在C512 FFWD，R/RF寄存器供数刚测过更慢，FP8展开有旧10-float反例；不能直接重开同方案。ViT producer pack P/G/Q/R和consumer float V均已失败。地图若仍将这些阶段排前，应先查此次同尺寸job与真实负载/布局差别，再选新的结构切口。
