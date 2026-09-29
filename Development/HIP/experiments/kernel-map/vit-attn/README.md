以下为候选设计记录；最终编译、逐位、计时和部署结论见 `Development/results/kernel-map-20260929/README.md`。

# ViT attention：直接产生转置score

唯一候选`HIP_VIT_ATTN_TRANSPOSED_SCORE=1`，默认0。只修改现有400/640 bytein_bout导出调用的新body，不改ABI/host/grid/其他fused变体。prepare.py生成完整deep_fast.hip及kernel.patch；生产配方实验时deep_fast-packed加入该宏即可。

基线一wave16query，每16key通过2个FP8 WMMA得到score，写1536B double-buffer LDS、组同步后按转置地址读回。640token循环40轮，400为25轮。Daniel reg1d_attn<1,false>为每组4wave64query、LDS0、VGPR110，ISA没有barrier/DS load/store，有16个静态bpermute，说明无需全局或LDS概率矩阵。

候选把score的WMMA(q,y,acc)改成WMMA(y,q,acc)，输出布局立即转置为“query在lane row、key在e”。相同exp位公式直接生成原denominator/PV输入fragment，删中间LDS写/读及barrier。没有换近似倒数，没有改affine/clamp/RTZ/FP8 pack，denominator每keytile一次half WMMA、PV两次FP8 WMMA及K顺序保持，最终F(Hrtz(acc*inv))保持。每输出点两个FP8向量点积仅交换乘法操作数；硬件WMMA是否逐位必须由EXACT/AE确认，不以代数恒等冒充验证。

输出acc/PV方向未改，最终store索引也未改。新body只保留寄存器数据；编译后先核LDS=0、barrier=0、WMMA动态计数相同及无spill，再同输入逐位及两档计时。无需打包P/G/Q/R，也无新输出张量。

旧“8次bpermute”草案有源lane索引问题，已删除，不作为候选。当前只交一个转置WMMA候选。没有GPU执行，没有生产仓编辑。
