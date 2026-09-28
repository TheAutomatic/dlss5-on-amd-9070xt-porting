# C256循环加权

Z/L: qt4 × ht4；B/BL: qtbatch2 × ht4 × Ksub4，后面三个qt循环各4。ISA与源码共同确认。嵌套逐行乘积，不能拿静态WMMA 510→498说少计算。

|bi_bo 每wave|Z|B|BL|L|
|---|---:|---:|---:|---:|
|loop_path_sum_upper/issued|11078|10981|11025|11045|
|loop_path_sum_upper/vector_slots|5251|5650|5636|5237|
|loop_path_sum_upper/WMMA|1320|1320|1320|1320|
|loop_path_sum_upper/VMEM|1316|1028|1028|1316|
|loop_path_sum_upper/DS|356|356|368|368|
|loop_path_sum_upper/DS_read_bytes_per_lane|4672|4672|4736|4736|
|loop_path_sum_upper/DS_write_bytes_per_lane|256|256|320|320|
|ffn_ht_loop_executed/WMMA|576|576|576|576|
|ffn_ht_loop_executed/VMEM|576|288|288|576|
|ffn_ht_loop_executed/VMEM_read_bytes_per_lane|4608|2304|2304|4608|

FFN ht loop没有特征输入/最终输出global操作，其VMEM是权重读请求。per-lane字节乘32可得全活跃wave逻辑请求量；缓存复用未知，不能当DRAM流量。全核边界路径仍累加为上界。

Q LDS相对差异应比较L-Z、BL-B的DS read/write；这些量不含bank conflict或真实延迟。
