180040110: add r8, 4
180040114: cmp r10, rbx
180040117: cmova rbx, r10
18004011b: jmp 0x180040080
180040120: mov qword ptr [rsi + 0x230], r8
180040127: add rbx, r8
18004012a: shl rbx, 2
18004012e: mov qword ptr [rsi + 0x1e8], rbx
180040135: lea rcx, [rsp + 0x110]
18004013d: mov rdx, rbx
180040140: call 0x18007ccd0
180040145: mov rcx, qword ptr [rsp + 0x110]
18004014d: xor edx, edx
18004014f: mov r8, rbx
180040152: call 0x18007cd10
180040157: mov rdx, qword ptr [rsi + 0x188]
18004015e: cmp rdx, qword ptr [rsi + 0x190]
180040165: je 0x18004017c
180040167: mov rax, qword ptr [rsp + 0x110]
18004016f: mov qword ptr [rdx], rax
180040172: add qword ptr [rsi + 0x188], 8
18004017a: jmp 0x180040194
18004017c: lea r8, [rsp + 0x110]
180040184: mov rcx, rdi
180040187: call 0x180029c00
18004018c: mov rax, qword ptr [rsp + 0x110]
180040194: mov qword ptr [rsi + 0x1e0], rax
