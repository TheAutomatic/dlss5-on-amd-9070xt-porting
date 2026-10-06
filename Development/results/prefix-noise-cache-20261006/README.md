# Seed0 prefix noise cache：同域成立，900首筛负账，停止

当前prefix为CW_PREFIX_SPLIT inline C32，不是独立prefix_fast。独立候选机械复用当前GPU Box–Muller/RTZ helper，缓存raster half4(g1,g2,g0,+0)的uint2，RGB/history/style每帧重读。显式context、seed0、同instance几何、style/exposure bits及reset epoch守门；nonzero seed/graph/experimentalhistory回旧核，无production默认/安装/config/ZIP变更。

LLVM23 CPU两FAST变体+MinGW完整链接通过；baseline128VGPR→cache127，均4KiB LDS、0spill/private。cached原noise log/sqrt/cos/sin消失，WMMA48仍同；新增90012.288MB、108816.712MB每帧读，不能只算省SFU。CPU全65536half packing和五几何window→raster permutation通过，无CPU高斯近似冒充GPUgold。

9070单队列、100GiB/game/15s看门狗：1088与900 FAST0/1 seed0/1/ffffffff半码gold0diff/finite，seed1实际含1负零并保留；完整prefix main/down的history0/1、exposure1/2与reset epoch0/1上下文均0diff，seed1回旧路。曝光/reset gold每组disable→enable，并未单独声称warm-key transition全压力门。新context参数不是缓存RGB/时序算法。stock/patched-old/cache各首尾raw全SHA同。

|首ABBA FAST1|A平均ms|B平均ms|变化|
|---|---:|---:|---:|
|1920×1088/640|8.914243|8.898674|-0.015569（-0.175%）|
|1600×960/400|6.655314|6.662606|+0.007292（+0.110%）|

900平均退步，即止。不做1152/formal/反复刷轮，不选性忽略负档。900合并p99虽6.9765→6.9499，也不覆盖均值失败。1088小正不能当可靠普遍收益，更不能解释约1ms差的大头。旧noise零化null不是缓存实测，两者证据分开。

原导出字节初看不同比较后，FAST0/1 normalized prefix ISA均仅一个PC-relative style地址即时数改变：代码与style绝对位置移动，但4-byte style值与原prefix.note逐字段同，其余指令/寄存器/调度同；不是额外数学刀。整个rodata/.note因新增kernel不相同。A/B首账使用同patchedmodule的mode0/1，stock单槽只验raw正确，不将未配对stock时间相减报收益。

harness初次argc失败由PowerShell automatic input变量遮蔽；900首次flags路径不匹配导致gold前module查找失败，均已核原因/修同一文件，不是候选性能轮。成功slot不覆盖，基于实际tool handle续poll。raw留下SHA，日志/CSV、source/build/resource身份在本目录；无GPU锁残留。候选源保experiments/prefix-noise-cache供机制复现，未收生产。
