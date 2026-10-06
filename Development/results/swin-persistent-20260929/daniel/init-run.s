18003e993: mov r14d, eax
18003e996: mov dword ptr [rsi + 0x438], eax
18003e99c: test r14d, r14d
18003e99f: jg 0x18003e9ab
18003e9a1: mov dword ptr [rsi + 0x438], 1
18003e9ab: lea rcx, [rip + 0x5d516]
18003e9b2: call 0x18005fca4
18003e9b7: test rax, rax
18003e9ba: je 0x18003e9ca
18003e9bc: mov rcx, rax
18003e9bf: call 0x18005df88
18003e9c4: mov dword ptr [rsi + 0x1d8], eax
18003e9ca: test r15d, r15d
18003e9cd: jne 0x18003ea03
18003e9cf: test byte ptr [rsi + 0x421], 1
18003e9d6: je 0x18003ea03
18003e9d8: cmp dword ptr [rsi + 0x1d8], 0
18003e9df: je 0x18003ecaa
18003e9e5: lea rcx, [rip + 0x5d458]
18003e9ec: call 0x18005fca4
18003e9f1: test rax, rax
18003e9f4: je 0x18003ea12
18003e9f6: mov rcx, rax
18003e9f9: call 0x18005df88
18003e9fe: mov r14d, eax
18003ea01: jmp 0x18003ea18
18003ea03: mov dword ptr [rsi + 0x1d8], 0
18003ea0d: jmp 0x18003ecaa
18003ea12: mov r14d, 0x64
18003ea18: mov dword ptr [rsp + 0x70], 0
18003ea20: lea rdx, [rip + 0x4aa89]
18003ea27: lea rcx, [rsp + 0x70]
18003ea2c: mov r8d, 0x40
18003ea32: xor r9d, r9d
18003ea35: call 0x18007cd30
18003ea3a: mov eax, dword ptr [rsp + 0x70]
18003ea3e: imul eax, r14d
18003ea42: imul eax, dword ptr [rsp + 0x294]
18003ea4a: cdqe
18003ea4c: imul rax, rax, 0x51eb851f
18003ea53: mov rcx, rax
18003ea56: shr rcx, 0x3f
18003ea5a: sar rax, 0x25
18003ea5e: add eax, ecx
18003ea60: cmp eax, 2
18003ea63: mov r15d, 1
18003ea69: cmovl eax, r15d
18003ea6d: mov dword ptr [rsi + 0x238], eax
18003ea73: mov dword ptr [rsp + 0x70], 0
18003ea7b: lea rdx, [rip + 0x4aa36]
18003ea82: lea rcx, [rsp + 0x70]
18003ea87: mov r8d, 0x40
18003ea8d: xor r9d, r9d
18003ea90: call 0x18007cd30
18003ea95: mov eax, dword ptr [rsp + 0x70]
18003ea99: imul eax, r14d
18003ea9d: imul eax, dword ptr [rsp + 0x294]
18003eaa5: cdqe
18003eaa7: imul rax, rax, 0x51eb851f
18003eaae: mov rcx, rax
18003eab1: shr rcx, 0x3f
18003eab5: sar rax, 0x25
18003eab9: add eax, ecx
18003eabb: cmp eax, 2
18003eabe: cmovl eax, r15d
18003eac2: mov dword ptr [rsi + 0x23c], eax
18003eac8: mov dword ptr [rsp + 0x70], 0
18003ead0: lea rdx, [rip + 0x4a9e9]
18003ead7: lea rcx, [rsp + 0x70]
18003eadc: mov r8d, 0x80
18003eae2: xor r9d, r9d
18003eae5: call 0x18007cd30
18003eaea: mov eax, dword ptr [rsp + 0x70]
18003eaee: imul eax, r14d
18003eaf2: imul eax, dword ptr [rsp + 0x294]
18003eafa: cdqe
18003eafc: imul rax, rax, 0x51eb851f
18003eb03: mov rcx, rax
18003eb06: shr rcx, 0x3f
18003eb0a: sar rax, 0x25
18003eb0e: add eax, ecx
18003eb10: cmp eax, 2
18003eb13: cmovl eax, r15d
18003eb17: mov dword ptr [rsi + 0x240], eax
18003eb1d: mov dword ptr [rsp + 0x70], 0
18003eb25: lea rdx, [rip + 0x4a99c]
18003eb2c: lea rcx, [rsp + 0x70]
18003eb31: mov r8d, 0x80
18003eb37: xor r9d, r9d
18003eb3a: call 0x18007cd30
18003eb3f: mov eax, dword ptr [rsp + 0x70]
18003eb43: imul eax, r14d
18003eb47: imul eax, dword ptr [rsp + 0x294]
18003eb4f: cdqe
18003eb51: imul rax, rax, 0x51eb851f
18003eb58: mov rcx, rax
18003eb5b: shr rcx, 0x3f
18003eb5f: sar rax, 0x25
18003eb63: add eax, ecx
18003eb65: cmp eax, 2
18003eb68: cmovl eax, r15d
18003eb6c: mov dword ptr [rsi + 0x244], eax
18003eb72: mov dword ptr [rsp + 0x70], 0
18003eb7a: lea rdx, [rip + 0x4a94f]
18003eb81: lea rcx, [rsp + 0x70]
18003eb86: mov r8d, 0x100
18003eb8c: xor r9d, r9d
18003eb8f: call 0x18007cd30
18003eb94: mov eax, dword ptr [rsp + 0x70]
18003eb98: imul eax, r14d
18003eb9c: imul eax, dword ptr [rsp + 0x294]
18003eba4: cdqe
18003eba6: imul rax, rax, 0x51eb851f
18003ebad: mov rcx, rax
18003ebb0: shr rcx, 0x3f
18003ebb4: sar rax, 0x25
18003ebb8: add eax, ecx
18003ebba: cmp eax, 2
18003ebbd: cmovl eax, r15d
18003ebc1: mov dword ptr [rsi + 0x248], eax
18003ebc7: mov dword ptr [rsp + 0x70], 0
18003ebcf: lea rdx, [rip + 0x4a902]
18003ebd6: lea rcx, [rsp + 0x70]
18003ebdb: mov r8d, 0x100
18003ebe1: xor r9d, r9d
18003ebe4: call 0x18007cd30
18003ebe9: imul r14d, dword ptr [rsp + 0x70]
18003ebef: imul r14d, dword ptr [rsp + 0x294]
18003ebf8: movsxd rax, r14d
18003ebfb: imul r12, rax, 0x51eb851f
18003ec02: mov rax, r12
18003ec05: shr rax, 0x3f
18003ec09: sar r12, 0x25
18003ec0d: add r12d, eax
18003ec10: cmp r12d, 2
18003ec14: cmovl r12d, r15d
18003ec18: mov dword ptr [rsi + 0x24c], r12d
18003ec1f: lea rcx, [rip + 0x5d411]
18003ec26: call 0x18005fca4
18003ec2b: test rax, rax
18003ec2e: je 0x18003ecaa
18003ec30: mov r13d, dword ptr [rsi + 0x248]
18003ec37: mov r14d, ebx
18003ec3a: mov ebx, dword ptr [rsi + 0x244]
18003ec40: mov r15d, ebp
18003ec43: mov ebp, dword ptr [rsi + 0x240]
18003ec49: mov dword ptr [rsp + 0x60], edi
18003ec4d: mov edi, dword ptr [rsi + 0x23c]
18003ec53: mov eax, dword ptr [rsi + 0x1d8]
18003ec59: mov dword ptr [rsp + 0x58], eax
18003ec5d: mov eax, dword ptr [rsi + 0x238]
18003ec63: mov dword ptr [rsp + 0x6c], eax
18003ec67: mov ecx, 2
18003ec6c: call 0x180055d10
18003ec71: mov dword ptr [rsp + 0x40], r12d
18003ec76: mov dword ptr [rsp + 0x38], r13d
18003ec7b: mov dword ptr [rsp + 0x30], ebx
18003ec7f: mov ebx, r14d
18003ec82: mov dword ptr [rsp + 0x28], ebp
18003ec86: mov ebp, r15d
18003ec89: mov dword ptr [rsp + 0x20], edi
18003ec8d: mov edi, dword ptr [rsp + 0x60]
18003ec91: lea rdx, [rip + 0x603f5]
18003ec98: mov rcx, rax
18003ec9b: mov r8d, dword ptr [rsp + 0x58]
18003eca0: mov r9d, dword ptr [rsp + 0x6c]
18003eca5: call 0x1800402d0
18003ecaa: lea rcx, [rip + 0x5d452]
18003ecb1: call 0x18005fca4
18003ecb6: test rax, rax
18003ecb9: je 0x18003eccc
18003ecbb: mov rcx, rax
18003ecbe: call 0x18005df88
18003ecc3: cdqe
18003ecc5: mov qword ptr [rsi + 0x440], rax
18003eccc: lea rcx, [rip + 0x5d43e]
18003ecd3: call 0x18005fca4
18003ecd8: test rax, rax
18003ecdb: je 0x18003ecee
18003ecdd: mov rcx, rax
18003ece0: call 0x18005df88
18003ece5: cdqe
18003ece7: mov qword ptr [rsi + 0x448], rax
18003ecee: mov r14d, dword ptr [rsp + 0x740]
18003ecf6: mov r15, qword ptr [rsi + 0x180]
18003ecfd: mov r12, qword ptr [rsi + 0x188]
18003ed04: cmp r15, r12
18003ed07: je 0x18003ed38
18003ed09: nop dword ptr [rax]
18003ed10: mov rcx, qword ptr [r15]
18003ed13: call 0x18007cc30
18003ed18: add r15, 8
18003ed1c: cmp r15, r12
18003ed1f: jne 0x18003ed10
18003ed21: mov rax, qword ptr [rsi + 0x180]
18003ed28: cmp rax, qword ptr [rsi + 0x188]
18003ed2f: je 0x18003ed38
18003ed31: mov qword ptr [rsi + 0x188], rax
18003ed38: mov dword ptr [rsi + 0x28], ebp
18003ed3b: mov dword ptr [rsi + 0x2c], ebx
18003ed3e: test edi, edi
18003ed40: cmovle edi, ebp
18003ed43: mov dword ptr [rsi + 0x4fc], edi
18003ed49: test r14d, r14d
18003ed4c: cmovle r14d, ebx
18003ed50: mov dword ptr [rsi + 0x500], r14d
18003ed57: mov eax, dword ptr [rsi + 0x4f4]
18003ed5d: movd xmm0, ebx
18003ed61: movd xmm1, ebp
18003ed65: punpckldq xmm1, xmm0
18003ed69: movdqa xmm0, xmm1
18003ed6d: psrld xmm0, 0x1f
18003ed72: paddd xmm0, xmm1
18003ed76: psrad xmm0, 1
18003ed7b: mov dword ptr [rsi + 0x260], 0x20
18003ed85: movq qword ptr [rsi + 0x264], xmm0
18003ed8d: cmp eax, 2
18003ed90: jne 0x18003edab
18003ed92: movdqa xmm0, xmm1
18003ed96: psrad xmm0, 0x1f
18003ed9b: psrld xmm0, 0x1e
18003eda0: paddd xmm0, xmm1
18003eda4: psrad xmm0, 2
18003eda9: jmp 0x18003edeb
18003edab: pcmpeqd xmm1, xmm1
18003edaf: movdqa xmm2, xmm0
18003edb3: psubd xmm2, xmm1
18003edb7: psrld xmm2, 0x1f
18003edbc: paddd xmm2, xmm0
18003edc0: psubd xmm2, xmm1
18003edc4: psrad xmm2, 1
18003edc9: paddd xmm2, xmmword ptr [rip + 0x4984f]
18003edd1: movdqa xmm0, xmm2
18003edd5: psrad xmm0, 0x1f
18003edda: psrld xmm0, 0x1e
18003eddf: paddd xmm0, xmm2
18003ede3: pand xmm0, xmmword ptr [rip + 0x49845]
18003edeb: mov dword ptr [rsi + 0x26c], 0x40
18003edf5: movq qword ptr [rsi + 0x270], xmm0
18003edfd: cmp eax, 2
18003ee00: jne 0x18003ee16
18003ee02: movdqa xmm1, xmm0
18003ee06: psrld xmm1, 0x1f
18003ee0b: paddd xmm1, xmm0
18003ee0f: psrad xmm1, 1
18003ee14: jmp 0x18003ee52
18003ee16: pcmpeqd xmm1, xmm1
18003ee1a: psubd xmm0, xmm1
18003ee1e: movdqa xmm2, xmm0
