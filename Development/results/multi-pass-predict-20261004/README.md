# 两遍网络预测第三遍（2026-10-04，可选实验档，剑星保留、鬼武者已回滚）

`DLSS5_MULTI_PASS_PREDICT=1` 仅在 `MULTI_PASS=3` 时生效：真实跑两遍，预测第三遍；默认0仍是真3遍。1x/2x不变，尊重第二遍原有skip配置。不是精确3x，不作画质承诺。add-on支持热加载，RE9需重启。日志写选项、请求遍数/实际网络遍数。

参数固定：16×16不重叠patch，RGB一起拟合 `r=Σ(d1*d2)/(Σd1²+count*1e-7)`；`Σd1²>=count*1e-7`、方向cos≥0.5且正相关才使用，否则r=0；r截[0,1]，patch中心系数双线性插值避免拼接，`clamp(y2+r*(y2-y1),0,1)`。独立两核，无屏障；已有内核数学不动。保留Tensor引用避免额外整图copy，引用按帧释放，只有小gain图常驻。

真实网络工作域导出x/y1/y2/y3（12帧最后帧，seed/history同一遍内不变）。先试滑窗8/16/32，再量实际GPU tile16+平滑版本，以下只报实际版：

|场景|真2x对真3x dB|预测对真3x dB|高频误差改善dB|
|---|---:|---:|---:|
|900静止|41.05|49.66|5.54|
|900运动|41.60|49.52|5.13|
|1080静止|41.32|49.36|4.44|
|1080运动|41.44|49.83|4.78|
|1080 history|41.67|45.28|1.37|

无history四例暗区/颜色误差也改善；history暗区PSNR反而62.0→60.0dB，红绿差误差0.00109→0.00122，不能称全面改善。同history样本x逐位相同、第一遍y1已不同（52.61dB），说明跨帧输入条件已分岔，与预测输出进入历史反馈相符。只有这张真实捕获的五种序列，不外推到所有游戏。最终解码图对真3x线性PSNR39.59–43.74dB；裁图未见明显糊/偏色，纹理局部仍有差异。shots中gpu-detail依次x/真2/预测/真3/差值×8，decoded为预测/真3，带gamma仅用于预览。

默认normal19全SAME（7+AE7+AE决策CSV+roll4）；真MP2/3各两case SAME；候选五case×两次自重复SAME、无NaN。200帧ABBA、前32帧不计：900真3 20.05/20.14ms，预测13.59/13.61；1080真3 28.48/28.50，预测19.22/19.32，约省32%。一轮足以确认此实验档省时，不是三轮正式逐位提速验收。RE9默认900/1080 SAME、预测两档各两次SAME，最终开启预测的runtime-smoke errors=0。最终重编仅将分支挪入既有skip作用域，空skip运算未变。

安装：剑星add-on `50c453c5b0cf93fa031b175fbcb6b3705a9b5b4ddd8c95bf80034adc81a8feab`；鬼武者两处runtime `dd606c1ac649d6d16c651c4000fe50f0c3c2d8600a896defd1edcec30d7fff1a`；两架构74模块，双游戏SUMS `067b7dac65766462db2119b7c46c9902aaea31cf0899f23f6de3530a684715de`。原72模块未变，仅加预测核；exact全模块快照/SUMS/native快照同步，双EXACT仅表示正式模块，不表示当前实验选项逐位。

安装时两游戏custom PREDICT=1、MULTI_PASS=3，native MULTI_PASS=3，其余参数及BOM/换行保留；剑星PRE=1、鬼武者PRE=0。无native PREDICT覆盖。F9仍切1/2/3；同3x对比时编辑custom的PREDICT=0/1，剑星热载、鬼武者重启。恢复0即可真3x。未代启动游戏，实玩帧率/观感由Zero校准。

回滚：`D:\DLSSNR-Lab\multi-pass-predict-20261004\backups\20261004-003039\rollback.ps1`，完整原文件/配置/exact备份；最终binary patch沿用此正常版备份。锁释放、原始帧清理，统计/哈希/裁图留存，无二进制入库。新rtc从当前`hip/rtc_compile.cpp`编译，hash与新核ELF e_flags见compiler-identity.json、两份ELF notes。旧复用rtc传gfx1200却报ISA1201，新工具分别报ISA1200/1201；0.41前需核对旧常规模块全部ELF目标，本轮不重编整网（9070为gfx1201）。

## 01:07 实玩失败与恢复

鬼武者预测档启动首帧黑屏/不可点击弹窗，PrepareFrame与modules74初始化成功后停在pending EnqueueHip，未取得弹窗原文。游戏已自行退出时执行鬼武者专属完整回滚至2176C544/72模块/9D4A2024与原MP1配置，剑星不动。Zero01:07:13确认正常。GPU未运行、无强杀进程。失败短日志见failure，完整原日志/配置远端failure-20261004保留。热路径首次hipModuleLoad遇未提交producer fence形成同步死锁为待证假设；离线smoke没覆盖该集成场景，不能判算法失败。
