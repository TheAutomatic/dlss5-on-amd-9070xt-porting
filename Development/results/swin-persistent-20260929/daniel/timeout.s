180037b04: mov rax, qword ptr [rsi + 0x250]
180037b0b: test rax, rax
180037b0e: je 0x180037bbc
180037b14: cmp dword ptr [rax], 0
180037b17: je 0x180037bbc
180037b1d: mov r9d, dword ptr [rax]
180037b20: mov dword ptr [rax], 0
180037b26: add dword ptr [rsi + 0x450], r9d
180037b2d: lea r8, [rip + 0x67240]
180037b34: lea rbx, [rsp + 0x210]
180037b3c: mov edx, 0x78
180037b41: mov rcx, rbx
180037b44: call 0x180028af0
180037b49: lea rdi, [rsi + 0x88]
180037b50: mov rcx, rbx
180037b53: call 0x18007c040
180037b58: mov rcx, qword ptr [rsi + 0x98]
180037b5f: mov rdx, qword ptr [rsi + 0xa0]
180037b66: mov r8, rdx
180037b69: sub r8, rcx
180037b6c: cmp rax, r8
180037b6f: jbe 0x180037b8b
180037b71: mov qword ptr [rsp + 0x20], rax
180037b76: lea r9, [rsp + 0x210]
180037b7e: mov rcx, rdi
180037b81: mov rdx, rax
180037b84: call 0x180029890
180037b89: jmp 0x180037bbc
180037b8b: mov rbx, rax
180037b8e: add rbx, rcx
180037b91: mov qword ptr [rsi + 0x98], rbx
180037b98: cmp rdx, 0x10
180037b9c: jb 0x180037ba5
180037b9e: mov rdi, qword ptr [rsi + 0x88]
180037ba5: add rcx, rdi
180037ba8: lea rdx, [rsp + 0x210]
180037bb0: mov r8, rax
180037bb3: call 0x18007b570
180037bb8: mov byte ptr [rdi + rbx], 0
180037bbc: movaps xmm6, xmmword ptr [rsp + 0x610]
180037bc4: movaps xmm7, xmmword ptr [rsp + 0x620]
180037bcc: movaps xmm8, xmmword ptr [rsp + 0x630]
