180037a03: movss xmm1, dword ptr [rip + 0x50961]
180037a0b: mulss xmm1, xmm7
180037a0f: maxss xmm1, xmm0
180037a13: mulss xmm7, dword ptr [rip + 0x50a4d]
180037a1b: minss xmm7, xmm1
180037a1f: movss dword ptr [rsi + 0x78], xmm7
180037a24: call 0x18007cba0
180037a29: cmp byte ptr [rsi + 0x423], 1
180037a30: jne 0x180037b04
180037a36: mov dword ptr [rsp + 0x60], 0
180037a3e: mov edx, 0xfc
180037a43: add rdx, qword ptr [rsi + 0x428]
180037a4a: lea rcx, [rsp + 0x60]
180037a4f: mov r8d, 4
180037a55: mov r9d, 2
180037a5b: call 0x18007cce0
180037a60: mov r9d, dword ptr [rsp + 0x60]
