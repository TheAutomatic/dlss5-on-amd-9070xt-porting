# 0.41-a 临时完整普通包

最终ZIP SHA256：`62943839ed969497636e814ed4ec7dd295991e7bfe7d90281b78d67732adcee4`，374749280字节、625文件、84模块。两端路径及冻结源码见 package-receipt.json。旧22b4版本已同路径替换，不交付。

默认关闭；仅普通包FFX前处理MP1试验。MV不含jitter是显式实验假设，未检测context flag；没有深度遮挡门。1080受控8帧短测约增加5.03ms，不代表游戏FPS或正式ABBA。未本机安装、未改玩家配置、正式0.41不变、无push/tag/release。

全文件ZIP读回及Windows最终SHA通过。两架构84 ELF目标通过；开发stock发现的27个gfx1200错目标仅在包内以24个同canonical源的正式041模块＋3个当前canonical定向编译修复。gfx1201不变。新时序twins导出相同；旧c32-wave1-fast有一个未调用cold tap额外导出，已单列，没有宣称全部stock严格同源或gfx1200硬件实测。

网友必须用根目录 temporal-history-test.ps1，在关闭游戏后执行 `-Mode off` / `-Mode on` 并各重启。两档备份移走旧temporal-history.txt，OFF为受控pureSpatial；off→on→off保留首备份，`-Mode restore`一次恢复初始配置与marker。marker存在/缺失、BOM/native遮蔽、首backup、恢复、新文件清除、环境拒绝及失败回滚的Windows隔离fixture已通过。

下一优先是网友同场景history反馈；后续优化以当前版本同口径首账为起点，不能把本包称为房顶已修复。
