1800380e3: xor r13d, r13d
1800380e6: lea rcx, [rip + 0x81f17]
1800380ed: movdqa xmm6, xmmword ptr [rip + 0x504fb]
1800380f5: xor eax, eax
1800380f7: jmp 0x180038119
1800380f9: test r12, r12
1800380fc: je 0x18003825d
180038102: inc r15
180038105: xor edi, edi
180038107: nop word ptr [rax + rax]
180038110: dec r12
180038113: add r14, 0xc
180038117: mov eax, edi
180038119: mov dil, 1
18003811c: test al, 1
18003811e: jne 0x1800381d0
180038124: movq xmm7, qword ptr [r14]
180038129: mov ebx, dword ptr [r14 - 4]
18003812d: mov eax, dword ptr [rip + 0x81ed1]
180038133: mov r8d, dword ptr [rip + 0x8263e]
18003813a: mov rdx, qword ptr gs:[0x58]
180038143: mov rdx, qword ptr [rdx + r8*8]
180038147: cmp eax, dword ptr [rdx + 0xc]
18003814d: jg 0x1800381dd
180038153: lea eax, [rbx + 0x3f]
180038156: test ebx, ebx
180038158: cmovns eax, ebx
18003815b: sar eax, 6
18003815e: test dword ptr [r10 + 0x1d8], eax
180038165: je 0x1800380f9
180038167: cmp byte ptr [rip + 0x81e92], 0
18003816e: jne 0x1800381d0
180038170: xor eax, eax
180038172: cmp ebx, 0x80
180038178: setne al
18003817b: inc eax
18003817d: paddd xmm7, xmm6
180038181: movdqa xmm0, xmm7
180038185: psrad xmm0, 0x1f
18003818a: psrld xmm0, 0x1d
18003818f: paddd xmm0, xmm7
180038193: psrad xmm0, 3
180038198: movd r8d, xmm0
18003819d: pshufd xmm0, xmm0, 0x55
1800381a2: movd edx, xmm0
1800381a6: imul edx, r8d
1800381aa: cmp ebx, 0x40
1800381ad: movzx r8d, byte ptr [rip + 0x81d67]
1800381b5: cmove eax, r13d
1800381b9: lea rax, [rsi + rax*8]
1800381bd: cmp edx, dword ptr [rax + r8*4]
1800381c1: setg dil
1800381c5: nop word ptr cs:[rax + rax]
1800381d0: test r12, r12
1800381d3: je 0x180038235
1800381d5: inc r15
1800381d8: jmp 0x180038110
1800381dd: call 0x1800528e4
