180037bd5: movaps xmm9, xmmword ptr [rsp + 0x640]
180037bde: movaps xmm10, xmmword ptr [rsp + 0x650]
180037be7: add rsp, 0x668
180037bee: pop rbx
180037bef: pop rbp
180037bf0: pop rdi
180037bf1: pop rsi
180037bf2: pop r12
180037bf4: pop r13
180037bf6: pop r14
180037bf8: pop r15
180037bfa: ret
180037bfb: int3
180037bfc: int3
180037bfd: int3
180037bfe: int3
180037bff: int3
180037c00: push r15
180037c02: push r14
180037c04: push rsi
180037c05: push rdi
180037c06: push rbx
180037c07: sub rsp, 0x170
180037c0e: mov r14, r9
180037c11: mov ebx, r8d
180037c14: mov esi, edx
180037c16: mov rdi, rcx
180037c19: mov ecx, dword ptr [rcx + 0x4f4]
180037c1f: mov qword ptr [rsp + 0x20], 0x140
180037c28: lea r9, [rsp + 0x30]
180037c2d: call 0x18003e220
180037c32: test al, al
180037c34: je 0x180037cb1
180037c36: mov r15, qword ptr [rsp + 0x1c0]
180037c3e: mov ecx, dword ptr [rdi + 0x4f4]
180037c44: mov qword ptr [rsp + 0x20], r15
180037c49: mov edx, esi
180037c4b: mov r8d, ebx
180037c4e: mov r9, r14
180037c51: call 0x18003e620
180037c56: mov edx, dword ptr [r14]
180037c59: cmp byte ptr [rdi + 0x408], 1
180037c60: jne 0x180037c8f
180037c62: cmp edx, dword ptr [rdi + 0x28]
