# Daniel gfx1201 离线 census

168 核：最后 bool 分组为70 reference、69 fast、29 shared。模板最后 bool 为质量分支；shared是否被reference调用仍需调度证据。
自然循环1036个，282个满足常量初值、唯一步进、唯一回边、无内部条件分支的保守证明；35核可计算循环展开后的静态路径总和上界。其他核动态未定。上界包括互斥分支，不能当实际执行数。

VMEM bytes为每条指令每活跃lane的数据宽度，尚未乘wave活跃掩码；不是DRAM实测流量。VOPD issued每对一条、slots每对两槽。mov统计为含mov的issued行，含dual pair时不能等同move槽数。scratch是VMEM子集。

0.4.0 对照通过去掉新增尾bool匹配符号；表保留新增核未匹配情形。当前我们floatFMA与Daniel reference的half/PTX数学不同，不能把全核差视作写法收益。

编译器producer完全相同：clang 21.0.0git / AMD-Lightning-Internal 590b9320a5be90e40268759c6203c01fde121e68；不代表flags相同。

|核|旧→新VGPR|旧→新scratch bytes|静态issued差|mov issued差|scratch指令差|
|---|---:|---:|---:|---:|---:|
|_Z12k_reg_swin32ILi0ELb0EEv9VarParams|168→163|56→0|-969|-341|-24|
|_Z13k_reg_swin_mhILi64ELi0ELb0EEv9VarParams|168→164|144→80|-439|-383|-45|

上面两核分别2个、3个循环，均证明4次；展开路径上界 issued 分别6280、9189，WMMA分别256、416。可给父任务按实际调用wave加权，但结果仍为上界而非时间。

没有GPU测试、没有改生产、没有改共享文档。
