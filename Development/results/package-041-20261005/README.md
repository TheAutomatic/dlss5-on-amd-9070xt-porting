# 0.41本地完整包

发布基线tag0.40=c81a88bc8534f7193df08ec3cae21d06d10d285d。源码冻结ffecb5c1，发行文档/配方ab8e3e82；构建时未上传、未打tag、未安装游戏；后续用户已上传下列镜像。默认明确MP1/PRED1/SKIN0；只有选择3x才两真实遍+预测，显式PRED0真三遍。

本地文件位于`/home/lmxxf/work/dlss5-release-0.41/`，Windows原件在`D:\給網友打包\`；完整SHA见SHA256SUMS及packages.json。

| 类型 | ZIP | 字节 | 文件数 |
|---|---|---|---|
| Magpie便携 | Magpie-DLSS5-AMD-0.41.zip | 342904511 | 776 |
| 普通OptiScaler | OptiScaler-DLSS5-AMD-0.41.zip | 373102226 | 594 |
| RE9专用OptiScaler/REFramework | OptiScaler-REFramework-DLSS5-AMD-0.41.zip | 427749567 | 601 |

两架构各38模块：五LLVM23.1.2+33COMGR21，当前rtc重新编译。全部76 ELF目标/双架构导出集合正确；900/1080静止+720运动三组新runner逐位SAME。每包44shader编译、全文件SHA/ZIP回读通过；RE9 staged smoke实际退出0、4帧errors0，实际配置MP1/PRED1、actual_network_passes1。gfx1200仅编译/ELF验，不冒称硬件实测。

宿主：addon a3515ea003e6cbba8d5f6f271083005c1fabdcc1641d5d370b84e910e71d34cf；runtime 65280756ffda70cfb77641759d757a8c7238efcbaee8065c34d885bc07135bc6；RE9配套OptiScaler host保留aa3761f2cdb0d9a4653732bd430019ff421b3ce9471fe3697b553dc6d71714a2。重建RE9源码包及canonical runtime重编脚本，保GPL/MIT许可。包不含实际玩家custom/native，sources/configuration/custom-config.txt仅版本控制模板。

打包诊断：首次脚本计数替换误改shader SHA，恢复源码实算值；重写累积BOM已统一单BOM；RE9正常stderr在PowerShell Stop被误判，现只对该原生smoke临时Continue并严格核实际退出码。这些错误发生在未完成stage，最终ZIP均完整通过。临时帧将只清本轮输出，模型/权重保留。

用户提供的0.41正式镜像：[夸克](https://pan.quark.cn/s/dbda3e470f8f)（分享名261005-004544243） · [Gofile](https://gofile.io/d/YAENU0ex)。本轮只记录入口，未重下载大包，网页工具无法读取内容，不声称重新验证下载。已交付ZIP及SHA不变，未创建GitHub release/tag。
