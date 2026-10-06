# C512及小核共用权重：等工作量账

## F融合

单位一个64token窗口、一个head。新F两wave，每wave QKV384+attention40=424，合848 WMMA。旧m32 QKV一wave为32token×双head×单part，归一到窗口/head是3wave×256=768；attention四wave×20=80，合848。数学工作量恒等，静态52不是动态。

全局QKV逻辑写入减少6144B，读入消除至少完整6144B张量；但融合由双head共享输入改为单head，输入读取重复会增加。按ISA全活跃lane请求宽度的路径和：旧read165632B、新212992B；旧write8192B、新2048B。请求字节不是DRAM字节，不能称“总global读取减少”。

F只有一次组同步。旧m32 source每group两个tile，归一化/打包各三次同步，加第二tile开始一次，共7次；等量3个QKV group为21个group-sync，加attention的3次。这个是等工作量的group同步次数，不是延迟相加，原group大小也不同。

旧c512-m32-mh所有既有导出ISA文本及VGPR/LDS/private/spill/SGPR均相同；逐项证据f-account.json，新增F不污染原导出。

## S64/S128/Sboth

已对主力bi_bo按实际自然loop计数：旧qt4×ht4，新qtbatch2×ht4，后面三个循环各4。其余边界路径仍作为路径和上界。

|族|WMMA旧/新（每wave）|FFN权重load请求旧→新|每lane FFN权重字节旧→新|VGPR旧→新|
|---|---:|---:|---:|---:|
|C64|456/456|192→96|1536→768|140→140|
|C128|744/744|320→160|2560→1280|144→159|

两族权重请求都真实减半，C128寄存器增加15；LDS不变（8/16KiB），无spill。完整资源表resources.csv。

## M32 C512 FFN

源码C512_T8_M32将每组token16→32，新增expanded[2][4]与hidden[2][16*260]。展开j4×K4×m2=32 WMMA，收缩K16×m2=32，总64/每wave；旧每wave展开16+收缩16=32，但覆盖仅16token。新一组=旧两组，等工作量WMMA不变。

权重每wave展开16次16B片段+收缩16次8B片段=384B/lane，新仍384B服务双token tile，旧等量两wave共768B：权重请求减半。输入数据和输出数据总量不因此减半。

代价：VGPR113→216，LDS4160→8320，private0/spill0。M/MD都是216VGPR、8320LDS；不要把无spill等同占用率不下降。资源/源码即可说明，此处不捏造缓存命中或毫秒收益。
