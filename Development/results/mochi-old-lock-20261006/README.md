# 旧mochizuki 0.0.2.5完整锁账与提交方式纠正（2026-10-06）

恢复了旧源码和实际测速产物，**推翻“旧mochi把500帧塞进一次提交”的假定**。本次未GPU跑网络、未改生产/游戏或对手旧资产；只读SSH取文件SHA，本地isolated CPU重建shader。

## 原资产已经恢复

- 源码 `/tmp/claude-1000/ct/mz`，HEAD **d1185d25141b1714d7837151b6fa782e6427568b**（2026-09-30提交，tracked clean，仅旧g.tgz untracked）。不是 `/home/lmxxf/work/aco-isa/mz` 的4f62a8a。
- 本地旧产物 `/tmp/claude-1000/ct/up/mz`；9070旧目录 `D:\DLSSNR-Lab\competitor-timing-20260930\mz`。
- 两边exe/model/三plan/网络与runtime/temporal SPV及markers **70文件逐SHA全部相同**；另外七份旧运行log与本地ct/mzlogs逐SHA同。remote-manifest.json包含现场cache SHA；cache不作为模型身份。旧README所谓model/cache已清理与本轮现场不符，不能据它猜不存在。
- 实测旧nr_graph.exe **8ad3ac1cfd5d83f58fb9a223e21d7a970118518839bada3abcaba66af5e8d153**；model pack599 entries、147756560B，SHA **2b41c888cf4155b8958c665ba64018ab0bd25c85fc71a2b6db86d0d04d1f7fbd**。模型/二进制不复制入git。
- glslang16.5.0 x86 binary经已有box64 wrapper。锁定source recipe、quad/preprocess/full-unroll、NR_Q32_DIRECT=1，在隔离/tmp输出重编**48/48网络SPV与旧产物逐字节同**，10.2秒；原SPV不覆盖。C32改NR_Q32_DIRECT=0则不相同，=1相同，证明这个有效数值选项；ViT这项0/1产物相同。
- source-manifest.json、pipelines.json、rdna4.sh、toolchain.json、local/remote-manifest.json及network-rebuild-check.json完整锁定源/产物/宏。首次Python导入产生的临时__pycache__已清理，后续脚本禁写bytecode；原tracked源/SPV/exe/model均未改。

## 旧测速逐帧提交，不是500帧一次提交

1. 原脚本original-mz2.ps1只指定warmup50/repeats500，没有指定--chunk。
2. d1185d2的nr_graph.cpp:3921明确默认--chunk=1；nrvk.hpp:1078-1107将repeats拆成单pass的run_graph_once。
3. actual exe反汇编exe-chunk-default.asm：0x140027b21把r9设为.rdata的ASCII“1”，0x140027b2f把r8设为“--chunk”，调用arg→atoi后存runner.chunk。这不是用新HEAD推断旧exe。
4. run_graph_once每pass执行vkQueueSubmit→vkWaitForFences→query results；GPU段TOP_OF_PIPE到BOTTOM_OF_PIPE，CPU提交/等待开销另在measurement wall。默认chunk0同样被run_graph解释为per1；若新诊断要batch，必须显式chunk>1。
5. log“123 dispatches, one submit”是**一个pass**的固定打印文案，并不能证明500pass合批。完整七log见logs/；例如900第一轮GPUtotal2994.955ms/500，wall3117.372ms。

因此撤回旧报告把提交方式估为0.1～0.3ms差距来源的推断。未来batch可以作为新的同实现控制实验，但不是解释这份旧差距的既定事实。不可由GPU与wall的差自动分摊某族耗时。

## 其他已锁定的口径差

- 旧输入未传--in-image，原host生成RGB=(x/width,y/height,0.5)、alpha1的gradient（nr_graph.cpp:3623-3665）；我们旧span用1296×720真实冻结HDR经GameCodec。这不是同输入。
- 旧style默认0、img-seed0；当前生产常用Style1；旧我们跳42/43/46，对手full71。新full71对照不要继续沿用“我13个C512、他16个”的旧算量。
- 900双方raster1600×960，但我们ViT400，对手plan为28×16=448；1080对手1920×1088/640tokens，我们默认1920×1152/640。同raster不意味着同token/同数学工作量。
- 对手noise seed0 field在build阶段一次生成，不在计时graph中；当前HIP fused prefix逐帧Box–Muller。这是实际供数/成本边界差，不能全归为“半精度数学”。**不据此宣称缓存有收益**：旧09-19零噪声消融仅9000.0175/10800.02975ms，同漂移量级；当前wave-owned/FAST/LDS形状已经变化，有新prefix热点证据才重新诊断。旧负账在history/DevHistory-full-20260923.md:2615。
- actual windows ViT shader QK与AV使用FP32 cooperative accum（NR_ACC_F16默认0、重编SPV确认），分母仍64-key half树、末端half倒数/乘法。不能把未经确认的AV中间half截断塞进“mochi数学”实验。
- shader编译后的Windows driver ISA不是本轮导出；SPV齐不代表ACO ISA代表Windows LLPC。

## 下一轮可比性与入口

旧host已经支持--in-image（valid extent的RGBA32F），不用升级mochi或修改旧源。可把一个**共同已编码工作域**1600×900RGBAf32输入交给mochi，HIP按现合同镜像底部填到1600×960；设置双方Style1/seed0/full71/MP1/AE0/historyoff，当前FAST0与FAST1分开。先验证加载字节/SHA、底padding和各自finite/repeat输出，再同批交错测。

同步纯NN首轮双方逐帧提交/同步；我方GPU首尾events夹Enqueue，另列CPU wall，输入只上传一次、输出首尾读回；mochi用锁定exe同--chunk1的GPU平均。旧HIP CPU chrono pure_hip_median不能直接拿来与mochi GPU均值相减。新900账明确标“同raster/不同ViT tokens”；若要同token热核研究，另用640合法attention输入，不能为凑数字随改整网plan。

还要核当前模块/flags/模型来源和output边界：mochi graph含其fused image input/output及固定noise预生成，我方Net输入到RGB包含原prefix noise和可能末尾D2D。跨实现数值允许不同，输出域对齐之前不拿PSNR作画质结论。三刀不能跨批累计为新差距。

CPU重复锁账入口：Development/HIP/experiments/mochi-old-lock/lock_and_rebuild.py SOURCE ASSETS ISOLATED_OUTPUT [--rebuild]。严格拒非d1185d2/dirty tracked源，rebuild只向ISOLATED_OUTPUT写，绝不运行nr_graph.exe。GPU对账入口单独准备，尚未跑新GPU轮。
