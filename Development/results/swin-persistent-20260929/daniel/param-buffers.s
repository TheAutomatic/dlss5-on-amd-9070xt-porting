180042532: mov rcx, qword ptr [rsp + 0x90]
18004253a: mov rax, qword ptr [rcx]
18004253d: mov qword ptr [r14], rax
180042540: mov qword ptr [rcx], r13
180042543: mov r15d, dword ptr [rsp + 0x1a8]
18004254b: movsxd rax, r15d
18004254e: add rbp, 0x20
180042552: cmp rsi, rax
180042555: jl 0x180042480
18004255b: jmp 0x180042560
18004255d: movsxd rax, r15d
180042560: movsxd rax, dword ptr [rsp + rax*4 + 0x1d4]
180042568: mov r10, qword ptr [rsp + 0x98]
180042570: mov rcx, qword ptr [r10 + 0x1e0]
180042577: movsxd rdx, dword ptr [rsp + 0x448]
18004257f: mov rdx, qword ptr [r10 + rdx*8 + 0x1f0]
180042587: lea r8, [rcx + rdx*4]
18004258b: mov qword ptr [rsp + 0x1f8], r8
180042593: lea r9, [rcx + rdx*4 + 4]
180042598: mov qword ptr [rsp + 0x200], r9
1800425a0: mov r9, qword ptr [r10 + 0x258]
1800425a7: mov qword ptr [rsp + 0x218], r9
1800425af: lea rdx, [rcx + rdx*4 + 0x10]
1800425b4: mov qword ptr [rsp + 0x208], rdx
1800425bc: lea rax, [r8 + rax*4 + 0x10]
1800425c1: mov qword ptr [rsp + 0x210], rax
1800425c9: mov rax, qword ptr [r10 + 0x230]
1800425d0: lea rax, [rcx + rax*4]
1800425d4: mov qword ptr [rsp + 0x228], rax
1800425dc: mov dword ptr [rsp + 0x220], 0x989680
1800425e7: mov esi, dword ptr [rsp + 0x88]
1800425ee: cmp esi, 0x40
1800425f1: mov rcx, r10
1800425f4: je 0x1800427ca
1800425fa: cmp esi, 0x80
180042600: je 0x1800426ee
180042606: cmp esi, 0x100
18004260c: jne 0x180042ab4
180042612: lea eax, [r15 - 9]
180042616: cmp eax, -9
180042619: jbe 0x180042ad5
18004261f: mov r9, qword ptr [rcx + 0x410]
180042626: mov eax, r15d
180042629: mov ecx, dword ptr [rsp + rax*4 + 0x1d4]
180042630: cmp ecx, 2
180042633: mov eax, 1
180042638: cmovge eax, ecx
18004263b: cmp byte ptr [rip + 0x778da], 0
180042642: je 0x1800429f2
180042648: movabs rcx, 0x100000100
180042652: mov qword ptr [rsp + 0x54], rcx
180042657: mov dword ptr [rsp + 0x5c], 1
18004265f: mov dword ptr [rsp + 0x48], eax
180042663: movabs rax, 0x100000001
18004266d: mov qword ptr [rsp + 0x4c], rax
180042672: lea rcx, [rsp + 0x48]
180042677: lea rdx, [rsp + 0x54]
18004267c: xor r8d, r8d
18004267f: call 0x18007cb30
180042684: test eax, eax
180042686: jne 0x180042a9f
18004268c: lea rsi, [rsp + 0x230]
180042694: lea rdx, [rsp + 0xa8]
18004269c: mov r8d, 0x188
