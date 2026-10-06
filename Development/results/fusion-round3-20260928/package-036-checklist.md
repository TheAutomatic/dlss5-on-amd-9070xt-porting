# 给Hikari：0.36实际打包清单

本文件供编写 `Development/tools/package-036.ps1`。代码、模块、逐位回归、累计计时及runtime实验验证已完成；**尚未打包、未发包**。所有证据以 `Development/results/fusion-round3-20260928/` 为准。

## 最终载荷

|对象|实际来源|状态|
|---|---|---|
|常规/Magpie add-on|`D:\DLSSNR-Lab\hip-backend\fusion-round3\dlss5-amd.addon64`|已装剑星|
|RE9 runtime|`D:\DLSSNR-Lab\hip-backend\fusion-round3\re9-runtime-final\LmxxfNrRuntime.dll`|已编译并通过实验smoke，未安装RE9|
|HIP模块|`D:\DLSSNR-Lab\hip-backend\fusion-round3\re9-runtime-final\modules\gfx1200`及`gfx1201`|每架构30，共60，实物已与repo及冻结载荷核对|
|flags|当前`scripts/hip-game-flags.txt`、`scripts/hip-magpie-flags.txt`、`scripts/hip-re9-flags.txt`|覆盖旧0.35模板，不改本轮默认值|
|RE9 dxgi宿主|保留0.35 RE9基包的`dxgi.dll`并验下列hash|Api.h相对0.35无diff，ABI不变|

完整SHA256：

```text
add-on  d2290ad7426967edfd566b5c53e1e2ae580a41463b08594375079fb7b84abfdf
runtime 7ce2bc21cde9c5c5f026ebd96eefa72b4e18699aad4c30239bdc2af5776bcfdc
input shader 5be59a4130e66e9f9f4d370843ef080e0783042d1f730b7a06c072421c92c2b6
RE9 dxgi aa3761f2cdb0d9a4653732bd430019ff421b3ce9471fe3697b553dc6d71714a2
```

权威表为 [package-036-payload.json](package-036-payload.json)、[modules-036.csv](modules-036.csv)、[HIP-SHA256SUMS](HIP-SHA256SUMS)（完整60条SHA256）。payload中的flags hash是剑星现场配置身份，不要当成三套发布模板共同hash。三套模板各自生成清单。

## 三套发布flags

|flag|常规|Magpie|RE9|
|---|---:|---:|---:|
|DLSS5_DIRECT_IO|1|1|不写|
|DLSS5_MAKE_RESIDENT_EVERY|60|60|未设|
|DLSS5_FRAME_STATS|0|0|0|
|DLSS5_HIP_PDL|1|1|1|
|DLSS5_HIP_WAVE_OWNED|1|1|1|
|DLSS5_HIP_C512_M32|1|1|1|
|DLSS5_HIP_VIT_PROJ_N64|1|1|1|
|DLSS5_HIP_VIT_STREAM|3|3|3|
|DLSS5_VIT_ADAPTIVE|1|0|0|

DIRECT_IO=1是输入直写；temporal/overlap不适用时自动沿旧路径。输出bit2仅供pre-upscale调用、同尺寸RGBA16F等条件的FSR直交；剑星现场3不推广为发布默认。Magpie不请求FSR输出直交，RE9独立runtime不走NativeDirectIo。MAKE_RESIDENT本轮保留模板值。

## 0.35之后实际进入生产的内容

- `5be634cf`：W2_BYTE_INPUT_LOADS、W2_RTZ_PAIR、W2_DIRECT_COORDS。
- `21a3931d`：常规及RE9 FRAME_STATS（发布关闭）。
- `9a82385f`：CW_ACT_FMED3、W2_BOUNDED_RCP两项生产宏。
- `328e1081`：float FMA激活，09-28更换逐位基准；不能声称0.36与0.35输出逐位相同。
- `5515b102`：输入直写与可选FSR输出直交，匹配输入shader。
- `fcc11736`：C256整块融合与FFN权重复用，1080启用；900/720维持分体。
- `7aef4a8e`：C512 QKV+attention融合、C64/C128 FFN权重复用。
- 本轮最终仅U2/T：C64/C128及C32上采样与首块融合。

`ac22c282`是审计/null结果，去清零/锁MODE没有合配方。ViT P/G/Q/R、D down、此前M/MD/W16等未取用候选不带入包。

## 已完成验证与累计收益

真实0.35发布目录60模块全部通过该包SHA256SUMS.txt；add-on4151123e对应release.json source ec96774d。与tag HIP manifest的26/60物理hash差异不能自动解释为代码错误，累计使用真实发布二进制，留证 `035-release-hashes.csv`。

累计两轮1000帧/槽ABBA，数据来自 `summary.json`：

|档位|第一轮0.35→最终|第二轮0.35→最终|累计省时|耗时下降|
|---|---|---|---|---|
|900|9.368873→8.577554ms|9.385209→8.590563ms|0.791318 / 0.794646ms|8.446% / 8.467%|
|1080|12.715527→11.573710ms|12.711608→11.582428ms|1.141817 / 1.129181ms|8.980% / 8.883%|

这是同批累计实测，不是逐刀相加。EXACT/AE及自适应决定见 `frame-hashes.csv`、`adaptive-decisions.csv`；runtime最终900/1080与smoke见 `runtime-final-900.log`、`runtime-final-1080.log`、`runtime-smoke.log`。双架构默认关闭代码一致与模块身份见 `module-code-identity.json`。gfx1201真卡验证，gfx1200编译/身份验证。

## Hikari实际打包操作

1. 以0.35三套包为底；以真实存在的 `Development/tools/package-035.ps1` 为参考写0.36脚本；替换release目录、载荷路径、版本、完整hash与配置来源。不能只改Version参数，旧脚本硬编码0.35宿主/runtime及release-035目录。
2. 以最终源码构建44个发布shader，使用匹配输入直写版本；核对输入shader身份。三包都带所需匹配shader，不能沿用旧0.35二进制。
3. 从最终源码重新生成source bundle，纳入生产recipe和新导出；不夹带实验二进制、完整ISA、RGB转储。
4. 60模块从上述冻结实物取，生成实际包内manifest；与 `modules-036.csv`、`HIP-SHA256SUMS`全量核验。不能沿用旧tag的物理hash清单。
5. 当前三套模板覆盖旧模板，生成各包文件级SHA256SUMS；生成ZIP后解包读回核验全量文件，并完成常规/Magpie/RE9各包smoke。

剩余工作是这些实际打包步骤。不要再次将已完成的网络/EXACT/AE/runtime验证标成未完成，也不要把打包smoke写成已在RE9游戏安装测试。
