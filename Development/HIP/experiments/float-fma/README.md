# 09-28 float FMA 生产基准

任务：`conversation/20260928/yami-float-fma.md`。源起点 `e3f6863`，既有现场为ACO两刀。

- `hip/` 的7个fast源文件、23处激活显式float FMA，最终乘法、量化、累加及half reference不变。
- 15个受影响模块全部双架构重编（清单在build.ps1），包含非wave/缺可选模块的HIP fallback；没有新开关。HLSL precise旧基准不作为新HIP逐位裁判。
- `snapshot.ps1`只读复制现场60模块，并记录addon/dxgi/INI/flags；`build.ps1 -Arch gfx1201|gfx1200`编译后构成30模块完整flat-P。两个架构可在计时开始前并行编译；计时不可与编译重叠。
- `run.ps1`：EXACT/AE七用例各A/P×12帧，输出改变获准；有限值必须通过。随后900/1080各两轮1000帧ABBA，弃前200，首尾读回。游戏进程每槽检查。
- `collect.ps1`/`collect-adaptive.ps1`→`analyze.py <结果目录>`记录168个P帧的goldens与AE决策变化。`check-baseline.py <未来collected frame-hashes.csv> --set P`检查此后逐位优化；输入、seed、history、flags必须一致。
- **09-28 起基准改为 float FMA。** 正式manifest：`Development/results/float-fma-20260928/new-baseline-hashes.csv`，84 EXACT＋84 AE，gfx1201。旧validate-modules*.ps1里的三道hash保留作历史，不再判断本版。
- 对NVIDIA单帧与多帧使用`oracle.ps1`和`temporal-*`。全部71块、相同post_shift=3，旧exact采样shader和原CUBIN真值的SHA锁定；五帧是固定RGB/history的off/on/off/on/off，非自反馈。游戏反馈序列由上面的运行时七用例覆盖。`temporal-README.md`写明编译及数据准备。
- 上轮fma-vs-nvidia整网误差比较曾以shift0 oracle对shift3 runner，已在原报告加校正；本轮必须用`shift-full-oracle.f32`。局部CUBIN与旧计时不受影响。
- 部署：`Development/deployments/float-fma-20260928`，仅30个变更HSACO（15×双架构）和checksum；备份、基线校验、回读、异常回滚。宿主与配置不变，不发包。

远端实验根：`D:\DLSSNR-Lab\hip-backend\float-fma`。EXE、完整像素产物、生成HIP/ISA保留远端；源、摘要、hash及计时序列入仓。
