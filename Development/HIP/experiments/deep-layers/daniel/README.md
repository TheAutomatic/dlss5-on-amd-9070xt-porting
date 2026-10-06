# Daniel FFWD synthetic microbench复现

只含源码，不含二进制、模型、完整ISA。依赖项目Development/HIP/hip_api.h及hip_device_properties.h、MinGW交叉编译器；运行需要Windows HIP7及gfx1201。

```bash
bash build-microbench.sh /path/to/wechat/assets/297 /tmp/deep-micro-build
```

主进程确认GPU空闲后，在Windows运行：

```powershell
.\microbench.exe .\daniel-gfx1201.hsaco 60 36 200 3 D:\production-gfx1201
.\microbench.exe .\daniel-gfx1201.hsaco 52 32 200 3 D:\production-gfx1201
```

production目录需c512-m32-deep.hsaco和deep_fast-packed.hsaco。省略最后目录则只测Daniel A/B。

A=Daniel普通FFWD V1，B=V2，C=我们mixM32→FFN_t8两核。A/B等覆盖grid分别P×8与ceil(P/2)×8，线程32；C mix grid ceil(tokens/32)*8线程32，FFN grid tokens/2线程128。每组20次warmup，再capture 200次串行调用为HIP graph，图warmup后事件围绕一次GraphLaunch计时，3轮ABBA分别比较A/B与A/C。C的us_per_launch表示完整两核组合，不是单个kernel。

输入±.25，权重±1/64，确定性xorshift；Daniel全部FP8，我们输入float、mix/expand half、contract FP8。参数与字节偏移见代码/header。所有buffer双侧guard、FP8 NaN/未覆盖哨兵、float finite检查；输出hash只记录。退出0代表检查通过，不代表实际模型逐位。

结果严格为有限非零合成负载；不代表真实模型延迟、不同数学的画质、或按层数相乘的整网收益。Guard验证越界写，不能证明无越界读。读取真实packed模型是另一项工作。
