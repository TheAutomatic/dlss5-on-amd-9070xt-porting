# 强度文件配置入口（2026-10-04）

RE9新增DLSS5_STRENGTH白名单；两个合法finite数0..1明确覆盖宿主菜单，auto/空/缺省沿原API/default。非法/单值/尾随垃圾回宿主并报告一次；API显式范围仍0..1（且finite），ABI不变。addon/Magpie原0..3不动。两数为输出细节/亮度、颜色混合，不是Style/遍数；0不省网络计算、不保证F6精确旁路。RE9文件需重启，auto时宿主菜单仍可每帧改；addon约1秒热载。

层序default→custom→native→systemenv不变；剑星旧native auto仍盖custom，未替用户删/改。可写custom例子DLSS5_STRENGTH=0.7,0.3（本轮没有写真实数值）。

CPU parser边界/非法/继承优先通过；900/1080默认auto及API .4,.6新旧hash同；file/env .7,.3等于旧API .7,.3并确实盖宿主 .4,.6；非法nan回宿主同；smoke过。只改runtime decoder参数选择，无kernel/网络数学/Style/遍数改动。测试初模块目录/SUMS选错在Create失败，改用既有完整rt-new/modules后通过。

已仅更新鬼武者root/_storage_ runtime SHA25a617b2118cf20afe98d395c41a91d3bf1d174af7116a87c8a23eacb51d6dfd；备份D:\DLSSNR-Lab\strength-config-20261004\backups\20261004-200004。default/custom/native字节hash不变，未改变现强度或MP/PRED/SKIN/geometry；剑星addon没动。未发布0.41/无push。

20:09用户实玩确认：鬼武者无异常、与此前一样；保持auto/原默认、MP3/PRED1/SKIN0，没有新FPS或手调数值反馈。
