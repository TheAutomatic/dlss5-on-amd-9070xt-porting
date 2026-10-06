# 锁定mochi ViT数学合同与小gold（2026-10-06）

源严格d1185d25141b1714d7837151b6fa782e6427568b；actual g_vitattn.spv SHA8993390a…，已经48shader重编逐字节锁定。此处只CPU查源/实际SPIR-V和生成小gold，不新增GPU、不动生产模块。

## 实际宏与runtime mode

NR_QT32/NR_VWAVES1/NR_KC64/NR_VTRANS1/NR_VPRENORMALIZED1/NR_VPACKED_DEN1/NR_VKPERM1/NR_VOUT_VEC1/NR_VBDA1。源默认NR_ACC_F160、NR_VQP0、NR_VKMASK0、NR_VLATE_SHUFFLE0、NR_VPB160。host vattn-mode默认5（nr_graph.cpp1443），prenorm后p.mode=5&~1=4（2624）：不interleave、没有256概率gain，floor=6.198883056640625e-5。不是按宏名字猜f16累积。

actual SPIR-V的QK/AV OpCooperativeMatrixMulAddKHR均输出float32矩阵；存在half accumulator-layout容器只为保存概率，不能因此称WMMA half累加。NR_ACC_F16条件下的中途AV截断未在有效路径启用。

## Score

vit_attn.comp125-132：先把score f32转换到half，half fma(scale=.08953857421875,bias=1.708984375)，half clamp[1.439453125,1.9775390625]；用half码(u&0x3ff)<<4得到概率半码1c20..3e90。actual SPV为OpFConvert v2half→Fma v2half→FClamp v2half→pack/shift，不是f32 FMA后只在最后投half。

固定半系数的CPU63488有限half score检查：exact F64 sum→half与sum→f32→half全0差，clamp后也0差；仅这个固定系数域，不是普遍“没有双舍入”定理。B的独立大边界gold由实施代理另备，此处不重复生成大测试集。

## 64-key denominator tree

实际完整chunk走include/vit_attn_vt_chunk.glsl91-110。令H为本gold的half-RNE：每16key先pair_j=H(p_j+p_{j+8})，j0..7；四tile按顺序累积成a_j。even=H(H(H(a0+a2)+a4)+a6)，odd=H(H(H(a1+a3)+a5)+a7)；chunk=H(even+odd)，den=H(den+chunk)。NR_VKPERM把4-7与8-11 K行交换以就地算pair，P随后在136-146回自然键序，AV仍K16原顺序。

自然布局用另一half-wave交换概率来算pair，与permuted布局有限正概率的操作数/加法次序相同；不要改为顺序640次half加、balanced sum或float归约。640有10个完整chunk、pad_keys0；400尾16不是这份exact640 gold，不借空padding冒充448模型。

8×640概率输入/8个最终den/8×10chunk前缀half码分别在probability-8x640.f16、denominator-8.f16、denominator-8x10-prefix.f16。包括min/max/奇偶/稀疏/前后倒序/跨chunk扰动；8行全部区别于naive顺序half加（例如all-max1050 vs1016.5），能抓真实归约顺序错误。参考从自然key identity构造，binary64精确加后逐步投half，独立于实施helper的lane/shuffle写法。

## AV exit及符号

完整AV一直FP32累加。vit_attn.comp534/541：inv=half(1.f/max(den,floor))；ctx_exit=half(ctx_fp32)；product=half(ctx_exit*inv)，再half clamp到±448/转换E4M3。actual SPV对应OpFDiv float→OpFConvert half；ctx→half、OpFMul half，最后nr_quant_e4m3。**不要把它改成ctx_f32乘half inverse后才half，也不要新增每tile AV half截断。**

160个小scalar输入含正负0、正负subnormal边、half舍入中点、±448、±65504及有限ctx到half溢出。av-exit-gold-160x3.u16分别是ctx_half/inv_half/product_half；源语义下符号和RNE次序可核。这里只封存half阶段，不伪造末端FP8字节或实际LLPC除法精度。

## 半精度gold范围

小gold以RNE定义可测试实验。实际SPIR-V未显式声明FPRoundingMode/Denorm控制；我们没有新导Windows LLPC ISA或跑其primitive。因此它证明源与SPV的dtype/运算树，不宣称实际旧driver每一bit已经对这些CPU gold接受。NaN/Inf输入、最终FP8 signed-zero/NaN及divide近似需实施小GPUprimitive核，不用有限正den域代替全域。

## 32query组织需要的状态

NR_QB2，每wave32query：ctx[2][2]为四个16×16 F32 matrix片段，每lane32个f32 context组件；Q片段qfr[2][2]常驻；part[2][4]为8个packed half2、den[2]逐chunk状态。640分10×64key chunks、每chunk四K16 tiles；一次V片段供两个query blocks，score→P→AV留寄存器。prenormalized/transposed路径不需要Qnorm LDS或概率LDS；32query优势与half packed计算/den状态减少耦合，不能仅用QT32名义把旧M32负账换标题再扫。

证据actual-pipeline.json/actual-spv-snippets.txt/source-sha.json与对应源码行；den_gold.py可CPU重生成小den gold。阶段B只变score，C只变归约树，D才变确认后的出口；资源/新增partial状态要分别记，stage性能必须看实际当前整网，不把本数学合同等同已优化。
