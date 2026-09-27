# C32 第三轮：post 分账与 finish 内部窗口快路径

基线：C32 round2 已在剑星验收 EXACT 56～57，c32 gfx1201 `ae95bdf6` / gfx1200 `e85c68c0`。本轮采用 **F：CW_FINISH_FULL_TILE=1**，两档整网约 −0.22～−0.27%；post 两个候选不采用。

## post 独立分段账

当前 post 每窗口普通向量指令4909，WMMA288。通过与基线机器码相同的 `-gline-tables-only` 输出追溯源码，循环 qt4 / hidden8 / attention4 / RGB尾部2；VOPD 一条双发射按一条指令计，WAIT 是指令数而非周期。源与汇编在远端 `build-A` / `base-debug.hsaco.s`；baseline-phases.json 保留所有类别。

| 段 | VALU+VOPD | VMEM | LDS |
|---|---:|---:|---:|
| 输入低分辨率特征+skip合并 | 772 | 72 | 0 |
| FFN expand / contract 周边 | 96 | 128 | 0 |
| 激活与hidden打包 | 1280 | 0 | 0 |
| feature RTZ与打包 | 164 | 0 | 8 |
| QKV矩阵周边 | 48 | 52 | 0 |
| Q/K归一化与打包 | 496 | 4 | 0 |
| score / exp | 664 | 32 | 0 |
| softmax | 472 | 0 | 0 |
| AV | 32 | 0 | 0 |
| 投影与量化 | 204 | 40 | 16 |
| RGB地址 / 点积 / 输出 | 32 / 400 / 70 | 0 / 48 / 12 | 0 / 8 / 0 |
| 控制与未归属 | 179 | 0 | 0 |

post 输出头是每像素32通道按固定顺序累加三个颜色，末端是f32 RGB，不是还有一次FP8往返。读取 residual 的32个half，LLVM已自动合成四个128-bit LDS读取/像素，因此手写成组读取未进一步减少LDS数。RGB三个f32虽相邻，但像素跨度12字节，不能强行写16字节覆盖下一像素。没有修改求和、倒数修正、多项式或舍入。

## 三个候选

- **P / CW_POST_HEAD_VEC**：每8通道读h8与权重组，按原通道顺序累加。post普通向量4909→4878，LDS仍32、VMEM仍388；1080实际变慢，关闭。
- **Q / CW_POST_FULL_TILE**：输出头按整窗判断一次，完整内部窗口不做逐像素检查，边缘保留检查。post内部普通向量约4879、LDS32、VMEM388，收益约0.005ms，不采用。
- **F / CW_FINISH_FULL_TILE**：只作用finish/finish_dcrop；内部窗口将main与down各自的循环编译为无裁切路径，边缘保留原逐像素检查。prefix明确排除，post不变。默认0，生产配方开1。

P/Q 是前期共享lambda版本的实验，包含未启用快路径的finish编译形态变化（额外减少约80～95 SALU，但两者均不采用）。最终源码关闭所有新宏时，与round2基线 `.text/.rodata/.note` 双架构全同；F测试前已经换成隔离后的最终版本，完整七组及两批测速都针对该版本。`build-F-original` 仅为未运行的早期编译产物，不计入结果。

内部判据：`tx>=sx && ty>=sy && tx+8<=width+sx && ty+8<=height+sy`，都是wave共同参数。DownCrop再要求sx/sy偶数，确保主输出8×8与下采样4×4窗口同在界内；奇数shift回落原路径。当前finish系sx=0、sy=4，900/1080约96.7%/97.3%窗口走内部路径。边缘仍执行原坐标、原裁切及原RTZ顺序。

| 内部窗口 | 普通向量 A→F | SALU A→F | WAIT A→F | LDS |
|---|---:|---:|---:|---:|
| finish（实际down=null） | 4619→4587 | 1657→723 | 2267→1428 | 88→88 |
| finish_dcrop | 5115→4992 | 2082→764 | 2634→1551 | 152→152 |

快、慢两条尾部不能相加；ledger.py显式选择内部路径，finish的空down分支及被下沉的最后一个down store也排除。分支连接处按保守上界计，非逐周期模拟。VGPR分配169、LDS4096B、scratch0保持不变。主体WMMA均336。

## 逐位与耗时

每个候选双架构编译，gfx1201七组（900/1080静态与移动、720移动、900/1080连续历史），每组12帧：三候选252帧全部逐位，连同基线504个帧哈希。90行测量记录，所有计时槽首尾hash一致。gfx1200无实机，仅编译。

ABBA每槽1000帧，弃前200；图关闭、自适应关闭、PDL=1，完整NativeGameFrame回放。数值是相对同批A的候选减基线，单位ms。

| 候选 | 900批1 / 批2 | 1080批1 / 批2 | 决定 |
|---|---:|---:|---|
| P | +0.0053 / −0.0131 | +0.0338 / +0.0228 | 不采用 |
| Q | −0.0045 / −0.0079 | −0.0045 / −0.0048 | 太小，不采用 |
| **F** | **−0.0209 / −0.0231** | **−0.0339 / −0.0352** | **采用** |

F整网：900 **9.3252→9.3043 / 9.4305→9.4074**；1080 **12.9471→12.9132 / 12.9917→12.9565**。温漂存在，收益以各自ABBA差为准；不足一帧的改动，游戏主要验画面和无回退。

## 配方与部署

新宏默认0，仅 `CW_FINISH_FULL_TILE 1` 合入c32-wave1配方。生产双架构复编与实测F代码段相同；部署采用实测二进制（gfx1201 **1753400c** / gfx1200 **834c7095**），不换复编后仅CUID不同的文件。

部署根 `D:\DLSSNR-Lab\c32-round3-20260927`，只换两份c32-wave1及对应校验项，安装时备份并核对add-on/dxgi/INI/flags哈希。备份路径见部署目录installed.json。游戏画面/FPS由Zero验收，未发包。

## 复现与证据

- 实验根 `D:\DLSSNR-Lab\hip-backend\c32-round3`：modules-A/P/Q/F、build-A/P/Q/F、hip-base、clean-Z、production，完整RGB/CSV保留远端。
- `Development/HIP/experiments/c32-round3`：构建、七组回归、两批ABBA、分段/循环统计、汇总脚本。baseline已归档，stage.ps1不会覆盖它。
- 本目录：逐帧hash、测量CSV、原始correct/timing日志、启动身份记录、资源占用、指令账、summary.json。
- ViT/C512的第3部分另见 `../vit-c512-aco-20260927/README.md`。
