# C512 direct pack组合3已收（2026-10-04）

只改活跃w2f8 mix/contract两个byte出口，省F量化→float解码→同码重编码；c512_hq/Hrtz/激活/全部WMMA K序保留，入口ar pack及外部compact residual不动。单mix/单tail有慢轮拒；仅组合3收。码域证明与27组真实FFN0diff见同级c512-direct-pack-20261004；macro0双arch执行section同。

同一个058ec7c1 fresh host，仅module不同；每槽320帧弃80，三轮ABBA各边1440样本：900 avg7.33046→7.30709ms、p99 7.677→7.624；1080 10.19529→10.15365、p99 10.521→10.475；1440 16.97888→16.87560、p99 17.300→17.225。省.023/.042/.103ms，三轮全快/合并p99不差；wall为完整NR路径，不含游戏render/FSR/Present，不乘微核层数或跨批累加收益。

正常19（AE CSV/roll同）、1440静态/受控motion/history原float同/NaN0、三multi/skin样本同、RE9三档九组SAME/smoke0。canonical仅c512-m32-deep/COMGR21 maxILP双arch；host/kernel ABI无改。

已装双游戏，仅模块+SUMS；76模块SUMS98960584。备份D:\DLSSNR-Lab\c512-direct-whole-20261004\backups\20261004-210325\rollback.ps1；exact同步。addon/runtime与三配置字节hash保持（鬼武者runtime25A617B2仍在），未改network/MP/predict/skin/strength。输出hash后仅清实验输出，未删权重/输入，未发布/push。
