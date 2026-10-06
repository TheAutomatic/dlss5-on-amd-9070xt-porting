# 900 C256 wave16候选

生成器 `make-wave16.py` 从当前生产wave_owned_mh.inc派生，只写本目录`c256_wave16.inc`；未改仓库、未编译、未跑GPU。无需MAKE相关变更。

将inc追加到c64-wave2源码最后（或紧跟wave_owned_mh.inc也可），加`W2_C256_WAVE16 1`；默认宏0，不产生新入口。保持生产`W2_FFN_QT_BATCH 2`、`W2_ROLL_QUERY 1`、`W2_DEFER_Q 0`和所有其他算术宏。

四导出：`c256_wave16`、`c256_wave16_bi`、`c256_wave16_bo`、`c256_wave16_bi_bo`，参数完全同原c256_wave2。**block=512threads**，grid仍窗口数`(workw/8)*(workh/8)`；不能沿原Run c256默认256线程走。只为900候选host显式路由，1080仍现产线B。

16wave/窗口＝每head两wave，各负责两个16-token tile：head=tid/64、qt0=(wave%2)*2。FFN沿现B的2qt共享权重，所有expanded的kt、contract的ht/tile、projection的kt顺序不变。

QKV阶段：Q保留自己两qt共8dword；K写plane1自己两qt；V先留own_v。三个part全完成后，本wave把自己的feature两qt读到saved_feature（8dword），全组barrier保证各head的feature读完。随后每wave读同头完整4qt K到寄存器，自己的V写plane0覆盖已死feature，第二次barrier保证全部K读取结束且V可见。最后各wave读完整V，attention只算自己的两qt，AV写plane1。原projection前的全组barrier照旧；投影残差从saved_feature取，交叉头AV仍从plane1取。

资源目标：两16KB LDS平面不变32KB；比旧整块多两次barrier，不重算QKV。每wave Q寄存器16→8dword，增加saved_feature8dword；K/V仍各16dword。准确VGPR及spill由编译器决定，不能仅按此存活账宣称不增加。更宽组会改变驻留与尾批，900收益需实测。

正确性检查点：

- 两wave独占head内不相交qt，无新原子；head间K/V/feature slots也不相交。
- 第一新barrier之前只读plane0；第一之后才写V，避免其他head仍读feature。
- 第二新barrier之前所有K读取完成；第二之后attention才能将plane1重用为AV。
- V平面之后只读，不需要第三新barrier。
- original input/crop/post、所有舍入边界及输出ABI保持；首次请逐位再计时。
