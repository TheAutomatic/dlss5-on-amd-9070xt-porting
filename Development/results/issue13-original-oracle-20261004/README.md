# Issue13：独立RTX5090原NVIDIA数据（2026-10-04）

原 nvngx_dlssnr.dll 310.8.0.0，经官方NGX core 615.71.09独立目录在真实Windows RTX5090执行完整网络；未改驱动或游戏。模型/内核数学不改，只将原preblock launch seed从API默认0设置为附件要求1。

输入两张附件encoded原帧，f16→f32无重编码、不翻图，底部按2158-y镜像为1152。API创建1920×1152；实际入口texture前1080行捕获与原帧每个RGBA值精确相同。Style1(.0078125)、history/motion0、post(-4,-4)、scale .03125、rgbmode1均通过原launch参数观测。每帧执行两遍，rawpost/API输出均逐字节重复一致。

`*.input-capture.rgba32` 是原实际入口采样转float32，1080×1920×4；`*.original-post.rgb32` 是原block70 **内部FP16 surface朝零存储后**，只half→float32取RGB，1080×1920×3，尚未API最终后处理。它不是requested的pre-FP16-store RGB32F，不混用API最终RGB32F。GPU输入和输出行顺序保留。

同附件指标：952569稳定像素、194稳定块，原post残差p95=14.937534%，HIP=14.943205%；MAE .00580405/.00580724。HIP按相同RTZ FP16存储再比较，每帧6220800值：8678全相同，8680有44值不同，最大.00219727，不能称全部逐位一致。

这对输入的放大也存在于独立原NVIDIA链，明显不是生产优化/复用特有，不支持移植大偏差是其主要来源。但仍是原模型在当前输入契约下的响应，不能据双帧证明全部实机闪烁原因、也不证明鸣潮同源；没有用时间平滑掩盖问题。

运行 `python verify_original.py`（NumPy）复算hash与指标。来源/参数/输出SHA见manifest.json，不包含原DLL/core/模型权重。原API最终输出有额外合成，其初值seed0 p95=12.44%不能替代本post结果。完整原调用和capture源码、log在仓库Development/HIP/experiments/issue13-original-oracle与results/issue13-original-oracle-20261004。
