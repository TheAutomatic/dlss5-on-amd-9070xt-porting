# 0.39 打包清单（10-01 晚）

脚本 `Development/tools/package-039.ps1`（9070 `D:\DLSSNR-Lab\release-039\`，日志 `package.log`），源码提交 55966ef2（tag 0.39）。以 0.38 三个 ZIP 为底（先逐文件校验底包）。**默认设置下与 0.38 逐位相同**（19 组 SAME，见 `results/rebuild-baseline-20261001`）。Zero 10-01 晚游戏验收：剑星 2K AA 55.6～56.1 → 57～58 帧、无闪烁；鬼武者 GPU 占用 <95%。

## 载荷（= 现装，且可由源码逐字节复现）

|对象|来源|SHA256|
|---|---|---|
|常规/Magpie add-on|剑星现装；HEAD 源码 `scripts/build-addon.sh … --hip`（DGX 交叉编译，钉基址）重编**整文件逐字节相同**|053c3589a29b08315e17159dc1f0a09dd177b34924bc177535c952c6f98063de|
|RE9 runtime|鬼武者现装（Content 与 `_storage_` 两份同）；HEAD `scripts/build-runtime.sh` 重编**整文件逐字节相同**|dc2d445e92e78055b7f209d98d405f90154c84b4d792da368464b4c5f29374a5|
|RE9 dxgi 宿主|0.38 RE9 包内沿用|aa3761f2cdb0d9a4653732bd430019ff421b3ce9471fe3697b553dc6d71714a2|
|HIP 模块|剑星现装 62 份（每架构 31），鬼武者现装逐文件 0 差；现装 SHA256SUMS 两游戏都是 fd419a3e；清单 [HIP-SHA256SUMS](HIP-SHA256SUMS)。代码段对 df92ed49 配方的核对见 rebuild-baseline|—|
|shader|仓库 `shaders/`（拷到 `release-039\shaders`）；剑星现装 assets 里每个 .hlsl/.hlsli 与仓库逐文件相同（含 decode A70789A1、text_overlay 8D20C7F5）|—|
|RE9 源码包|HEAD 上 prepare-host.py + bundle-source.py 重生（43,632,979 字节；`upstream.json` 已 checkout 还原）|—|

## flags / 包内改动

- 三个模板（仓库 `scripts/`）加 `DLSS5_STYLE=1`，脚本逐行核对。其余同 0.38。
- **RE9 注意**：RE9 runtime 读 flags 文件只放行 `DLSS5_HIP_*`/SKIP_BLOCKS/FIT_LARGE/NETWORK_HEIGHT/NETWORK_1080_ROWS（`src/LmxxfNrRuntime.cpp` ~312 行），`DLSS5_STYLE` 不在白名单——模板那行是无效占位（默认本来就是 1，结果不受影响）。RE9 包说明与 CHANGELOG 已写明“要换风格设系统环境变量”。要改成可配需改 runtime 白名单（会换 runtime 哈希），留给下版。
- package-notes 六份加 0.39 节。

## 结果（9070 `D:\給網友打包\`）

|包|字节|SHA256|文件数|
|---|---:|---|---:|
|Magpie-DLSS5-AMD-0.39.zip|340,434,944|9ea84c665d270cd45e24184729b8272c152485df462a1528539ed778d41849f5|739|
|OptiScaler-DLSS5-AMD-0.39.zip|370,632,747|43e545725d370e005d8865ae95943c60b2ce3abe577856f1e8450ab6ef42b51e|557|
|OptiScaler-REFramework-DLSS5-AMD-0.39.zip|425,210,346|4b98414299fc43195a19bc1f9c1034cdd00f3aa66c1fc294902a38cdc52db7c3|561|

三包 44 个 shader 变体编译通过，ZIP 读回逐文件 SHA256 通过，文件数与 0.38 相同。RE9 包内 runtime smoke（900，32 帧）：`swin_run=1/1`、flags applied=18、SP_STATS runs=4 fallback=0 errors=0、`lmxxf_nr_gpu: ok`（包内冒烟，不是 RE9 游戏实测）。未改任何游戏安装目录。

## 上传

夸克 / Gofile：待 Zero 上传；README/CHANGELOG 下载处写“链接待补”。
