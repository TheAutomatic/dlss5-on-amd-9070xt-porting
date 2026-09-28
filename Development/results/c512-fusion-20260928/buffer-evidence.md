# Daniel C512四buffer角色（默认reference四核路径）

基于0.5.0 `mod.dll` host反汇编，object字段与rsp临时字段分开核对。

|对象字段|实际角色|host地址证据|
|---|---|---|
|+270|当前块输入/上一块输出；最终conv写回；首块可用外部输入替代|042f56、043a6c、043d8b–043d92|
|+278|FFWD输出，第一conv主输入|042f64–04301a、043a54–043a5b|
|+280|第一conv输出feature；attn3输入；最终conv残差|043a83–043a8a、043b19→043cab、043d69–043d76|
|+288|attn3输出；最终conv主输入|043b20–043b27→043cb3–043cb8、043d69–043d76|

闭环：270/外部 → FFWD → 278 → conv（残差270/外部）→ 280 → attn3 → 288 → conv（残差280）→ 270。

最终conv的关键证据：`movdqu object+280,xmm0; pshufd 0x4e; movdqa xmm0,args+0`，将相邻280/288互换，得到主输入288、残差280；args+24=270为输出。四buffer不是Q/K/V/output；QKV位于attn3内部6KiB LDS。

构造函数每块分配8192×P字节：900为851968B，1080为1105920B。容量不等于每次实际访问量，更不等于DRAM流量。
