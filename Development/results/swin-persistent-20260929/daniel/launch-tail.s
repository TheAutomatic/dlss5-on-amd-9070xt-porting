1800429f2: movabs rcx, 0x100000100
1800429fc: mov qword ptr [rsp + 0x54], rcx
180042a01: mov dword ptr [rsp + 0x5c], 1
180042a09: mov dword ptr [rsp + 0x48], eax
180042a0d: movabs rax, 0x100000001
180042a17: mov qword ptr [rsp + 0x4c], rax
180042a1c: lea rcx, [rsp + 0x48]
180042a21: lea rdx, [rsp + 0x54]
180042a26: xor r8d, r8d
180042a29: call 0x18007cb30
180042a2e: test eax, eax
180042a30: jne 0x180042a9f
180042a32: lea rsi, [rsp + 0x230]
180042a3a: lea rdx, [rsp + 0xa8]
180042a42: mov r8d, 0x188
180042a48: mov rcx, rsi
180042a4b: call 0x18007b570
180042a50: mov qword ptr [rsp + 0x30], rsi
180042a55: lea rsi, [rsp + 0x78]
180042a5a: lea rdi, [rsp + 0x68]
180042a5f: lea r8, [rsp + 0x40]
180042a64: lea r9, [rsp + 0x38]
180042a69: mov rcx, rsi
180042a6c: mov rdx, rdi
180042a6f: call 0x18007cb20
180042a74: mov rax, qword ptr [rsp + 0x40]
180042a79: mov rcx, qword ptr [rsp + 0x38]
180042a7e: mov qword ptr [rsp + 0x28], rcx
180042a83: mov qword ptr [rsp + 0x20], rax
180042a88: lea rcx, [rip + 0x46a41]
180042a8f: lea r9, [rsp + 0x30]
180042a94: mov rdx, rsi
180042a97: mov r8, rdi
180042a9a: call 0x18007ccc0
180042a9f: nop
180042aa0: add rsp, 0x3b8
180042aa7: pop rbx
180042aa8: pop rbp
180042aa9: pop rdi
180042aaa: pop rsi
180042aab: pop r12
180042aad: pop r13
180042aaf: pop r14
180042ab1: pop r15
180042ab3: ret
180042ab4: mov ecx, 2
180042ab9: call 0x180055d10
180042abe: lea rdx, [rip + 0x5c5b8]
180042ac5: mov rcx, rax
180042ac8: mov r8d, esi
180042acb: call 0x1800402d0
180042ad0: call 0x18005aa40
180042ad5: mov ecx, 2
180042ada: call 0x180055d10
180042adf: lea rdx, [rip + 0x5c3e2]
180042ae6: mov rcx, rax
180042ae9: mov r8d, 0x100
180042aef: jmp 0x180042b27
180042af1: mov ecx, 2
180042af6: call 0x180055d10
180042afb: lea rdx, [rip + 0x5c3c6]
180042b02: mov rcx, rax
180042b05: mov r8d, 0x80
180042b0b: jmp 0x180042b27
180042b0d: mov ecx, 2
180042b12: call 0x180055d10
180042b17: lea rdx, [rip + 0x5c3aa]
180042b1e: mov rcx, rax
180042b21: mov r8d, 0x40
180042b27: mov r9d, r15d
180042b2a: call 0x1800402d0
180042b2f: call 0x18005aa40
180042b34: int3
