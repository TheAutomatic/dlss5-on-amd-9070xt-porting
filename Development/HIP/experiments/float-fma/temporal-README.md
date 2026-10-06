# 原版五帧 off/on/reset 比较

范围：完整 71 块，1920×1080 输入反射至 1920×1152，post shift=3，seed=0，固定 RGB/history，按 off/on/off/on/off 切换。不是历史输出回灌，也不是游戏画质验证。A/P 共用同一原版 oracle，未把当前 fast 输出冒充 NVIDIA 真值。

原始 fixture 来自 `Development/prepare_native_temporal_valid1080.py`：原捕获 RGB、左右翻转 RGB 作为 history、seed=7308 的 [-0.75,0.75] motion；原 CUBIN 整网分块输出在 `release/native-temporal-valid1080`。`Development/validate_native_temporal_network70.py --shift3` 可重验旧 AMD exact 五帧与原版 post70 输出逐字节相同。两份 oracle SHA 固定在 compare 脚本中。

现存 rcpaccum/positionfma sampled-history 是修正前失败产物，不能复用。因此 sampler runner 调用旧 exact D3D 坐标/采样器，shader 从 git `450d63b` 提取，SHA 与旧 accepted manifest 完全匹配。只重新计算前处理；不重建旧全网络。

准备：

```sh
python3 Development/HIP/experiments/float-fma/temporal-prepare.py /tmp/float-fma-temporal
x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -IDevelopment/HIP Development/HIP/experiments/float-fma/temporal-network.cpp -o /tmp/temporal-network.exe
x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -municode -Isrc -include src/native_shader_cache.h Development/HIP/experiments/float-fma/temporal-sample.cpp -ld3d12 -ldxgi -ld3dcompiler -lole32 -luuid -o /tmp/temporal-sample.exe
```

把 fixture 和两个 exe 传到 AMD 的隔离目录，游戏关闭、其他 GPU 测试结束后运行（路径示意）：

```powershell
.\temporal-sample.exe .\fixture\shaders .\fixture .\fixture\sampled-history.f32
.\temporal-network.exe <assets> <modules-A> .\fixture\input.f32 .\fixture\sampled-history.f32 .\result\A
.\temporal-network.exe <assets> <modules-P> .\fixture\input.f32 .\fixture\sampled-history.f32 .\result\P
```

fixture 原 RGB/history/motion 各 33,177,600 字节，倒数表 33,554,432 字节；sampled-history 35,389,440 字节。每个网络输出 5×26,542,080 字节。下载后：

```sh
python3 Development/HIP/experiments/float-fma/temporal-compare.py --release release <result>/A <result>/P
```

比较器检查非有限值、off/on 重放一致性、原 oracle SHA，报告逐帧及所有五帧加权 RMSE；另列前 1080 行可见区域 RMSE。初始 CPU 自检：把原 oracle 按 off/on 次序作为输入，聚合 RMSE=0。GPU 运行由主进程排队，准备阶段未运行 GPU。
