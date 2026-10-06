# 主力Swin循环加权补充

计数统一用 census.py。自然循环按每条ISA所属循环的迭代次数乘积加权，正确处理C32 4×8、C64/128 4×4嵌套。分支未做路径选择，结果始终称“路径总和上界”，不称实际执行数。

|每wave路径和上界|我们C32 chain|Daniel C32 ref<0>|我们C64 bi_bo|Daniel C64 ref<0>|
|---|---:|---:|---:|---:|
|issued_static|5397|6280|8081|9189|
|vector_slots|4093|5369|5273|6662|
|WMMA|336|256|456|416|
|VMEM|320|129|452|219|
|VMEM_read_bytes_per_lane_static|2784|772|3920|1492|
|VMEM_write_bytes_per_lane_static|64|64|64|128|
|DS|16|88|140|156|
|WAIT|905|374|1728|1631|

C32 chain循环4、8、4次；前两个嵌套。C64/128五循环都是4次，前两个嵌套；WMMA总数分别456/744，与独立公式一致。Daniel C32<0>两个4次循环，C64<0>三个4次循环。

这里没有按窗口工作量和grid归一，也没证明两边写入相同张量范围，不能把每wave差解释成整网节省。数学路线也不同（我方float FMA、Daniel reference半精度/完整除法）。尤其不能据此说我们VALU更多：两个普通核的路径和上界恰好都更少，VMEM和WMMA更多才是可追查的方向。

ours-family-loop-weighted.json按当前40活跃核表中的真实waves做族加权，覆盖范围也记录。C32六核与C64/C128的这批wave2核全部给出scenario路径上界；C256两核的PDL spin暂按一次，故只能称条件上界，实际spin次数没有静态上限。

C32 post尾t=lane;t<64;t+=32为2次；ASM v8=lane|0xffffffe0，+32的carry控制两次迭代。dcrop full尾16次且downcrop已展开，edge尾32次并另有16次downcrop循环（s6=0,+1,==16）。C256普通核输出ci循环两次，嵌套qt四次。C32 finish尾16次和32次是互斥路径，文件保留两个scenario，族汇总每个metric取max而非相加；循环外的互斥块仍累加，因此该上界较松。无GPU计时证据，毫秒差保持NA。
