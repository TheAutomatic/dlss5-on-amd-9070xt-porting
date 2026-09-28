# Daniel全族加权账

family-weighted.csv 是静态×推导waves；family-loop-covered.csv 是可证循环展开部分×推导waves。后表covered_calls/waves不足全族时只能看覆盖部分，完整族动态上界为NA。VMEM字节是每活跃lane请求宽度加权，不是实际DRAM流量。所有毫秒差为NA。

Swin/C512/global ViT分族来自dispatch host映射：global ViT=reg1d；C512=reg_vit。

|几何|族|调用|waves|static issued×waves|loop覆盖calls|loop覆盖waves|完整loop上界|
|---|---|---:|---:|---:|---:|---:|---:|
|1080-daniel-default|C128|12|25620|101005636|0|0|NA|
|1080-daniel-default|C256|16|17856|64894968|0|0|NA|
|1080-daniel-default|C32|10|131314|580227472|10|131314|946580680|
|1080-daniel-default|C512|64|46592|61816608|0|0|NA|
|1080-daniel-default|C64|8|33396|144095004|8|33396|318766644|
|1080-daniel-default|ViT|40|48640|40824320|0|0|NA|
|1080-daniel-default|ViT-repack|2|4096|1294336|0|0|NA|
|1080-daniel-default|decoder|1|320|366400|0|0|NA|
|1080-daniel-default|head|1|640|235520|0|0|NA|
|1080-matched-ours|C128|12|27084|106776132|0|0|NA|
|1080-matched-ours|C256|16|18848|68520224|0|0|NA|
|1080-matched-ours|C32|10|139010|614258960|10|139010|1002073640|
|1080-matched-ours|C512|64|46592|61816608|0|0|NA|
|1080-matched-ours|C64|8|35332|152447388|8|35332|337242948|
|1080-matched-ours|ViT|40|48640|40824320|0|0|NA|
|1080-matched-ours|ViT-repack|2|4096|1294336|0|0|NA|
|1080-matched-ours|decoder|1|320|366400|0|0|NA|
|1080-matched-ours|head|1|640|235520|0|0|NA|
|900-default|C128|12|18972|74806484|0|0|NA|
|900-default|C256|16|13312|48429888|0|0|NA|
|900-default|C32|10|96642|426930716|10|96642|696582260|
|900-default|C512|64|56064|50192960|0|0|NA|
|900-default|C64|8|24644|106323596|8|24644|235218716|
|900-default|ViT|40|55552|49077504|0|0|NA|
|900-default|ViT-repack|2|4096|1294336|0|0|NA|
|900-default|decoder|1|224|256480|0|0|NA|
|900-default|head|1|448|164864|0|0|NA|

900静态规模排序：C32 > C64 > C128 > C512 > ViT > C256；1080两几何：C32 > C64 > C128 > C256 > C512 > ViT。只排规模，不排速度瓶颈。

同几何完整循环路径上界对照：900 C32 ours683590895 vs Daniel696582260 issued，C64 ours216723564 vs Daniel235218716；1080 matched C32 ours982773555 vs Daniel1002073640，C64 ours310692212 vs Daniel337242948。两族我方issued上界均更少，但VMEM请求约两倍；后续应查布局/张量中间写回，不是只追VALU条数。边界waves仍有小幅差异，这不是逐wave同工作量证明。

排行只表示静态工作规模，循环展开差异会改变排序，不能拿这个比值推算时间。默认154派发是host推导；生产若覆盖flags/MP阈值，必须重新选路径。C32所有使用flags均可证4次循环（20为lg+scc1的同义回边），可完整加权；C64/128边界变体存在复杂路径时保持NA。
