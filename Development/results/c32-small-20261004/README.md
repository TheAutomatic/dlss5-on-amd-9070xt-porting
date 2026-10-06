# C32固定1440小筛：不收生产

当前prefix/post DUP边际约1.346/1.359ms，chain约1.28、mapped约.276、finish族约.632；up_lb未触发，不以该零增量当实际up成本。固定1440 geometry/pitch/postshift3/.03125新增出口，原RGB运算不改；default0 .text/.rodata/.note与现装一致。prefix少74指令、VGPR128→127；post少48指令、VGPR132不变。静态11304960原float同。

三轮增量−.00961/+.00226/−.02536ms，有慢轮，止损不收、不进入19、不安装。原型保存在experiments/c32-small/candidate.patch，不改生产C32。不因其它ViT刀通过把这刀偷偷合入。
