# ViT已量化contract字节边（2026-10-04）

contract原本F输出已在E4M3格点，却经half保存再在w5 QKV转换/重编码。现直接保存F内部byte，QKV读byte，投影skip精确decode。求和/量化/舍入不变；AE缓存和输出仍F32。构造期三配对HasFn全真才启用，缺一个整体回旧half。当前初始化warmup覆盖新容量，没有新热路径Upload/moduleLoad/sync。

peer proof：65536half原/新byte及decode0diff；254有限FP8（含±0）回环全同，2NaN码域外1差明确保留，producer F夹饱和总输出有限。真实三权重tuple两档+960全同。normal19使用同HEAD ed5295fe fresh compiler基线全部SAME（AE CSV/roll同）；1440 FAST0/FAST1静态/受控motion/history raw同，缺单project入口实际fallback0 raw同；三multi/skin样本同；RE9三档九组SAME+smoke0。

|single NR frame wall|旧→新平均ms|旧→新p99ms|
|---|---:|---:|
|900|7.39185→7.33849|7.674→7.660|
|1080|10.29676→10.20419|10.625→10.516|
|1440|17.10425→16.97973|17.409→17.280|

每档三轮ABBA/槽320帧弃80，各边1440样本，三轮全快、合并p99不差。只首末读回，wall含codec/交接/回写，不含游戏render/FSR/Present；GPU摘要另留。省.053/.093/.125ms，约.7～.9%，不拿跨批17.029等数字累加收益、不推实玩FPS。

canonical build-modules.ps1仅vit-stream两row，COMGR正确rtc双arch；所有旧入口保留。早期手写拼接漏vit_stream.inc导致缺旧入口500，预检抓住并改canonical拼接；该错误未装游戏、不是数值失败。

已装双游戏addon3A538106/runtime2844B742、76模块；备份D:\DLSSNR-Lab\vit-byteedge-formal-20261004\backups\20261004-130812\rollback.ps1。配置字节保留：auto/FREE0；剑星3/PRED0/SKIN0，鬼武者3/PRED1/SKIN0，exact快照同步。C32固定几何阴性只归档，不合生产。输出先留hash/统计再删，不删输入/权重/用户附件。没有发行包/push。
