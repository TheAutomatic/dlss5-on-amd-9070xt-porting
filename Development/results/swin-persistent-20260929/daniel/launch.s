1800423c0: push r15
1800423c2: push r14
1800423c4: push r13
1800423c6: push r12
1800423c8: push rsi
1800423c9: push rdi
1800423ca: push rbp
1800423cb: push rbx
1800423cc: sub rsp, 0x3b8
1800423d3: mov qword ptr [rsp + 0x90], r9
1800423db: mov r14, r8
1800423de: mov dword ptr [rsp + 0x88], edx
1800423e5: mov rbx, rcx
1800423e8: mov ebp, dword ptr [rsp + 0x440]
1800423ef: mov r12d, dword ptr [rsp + 0x438]
1800423f7: mov esi, dword ptr [rsp + 0x420]
1800423fe: mov edi, dword ptr [rsp + 0x428]
180042405: lea rcx, [rsp + 0xa8]
18004240d: mov r8d, 0x188
180042413: xor edx, edx
180042415: call 0x18007bc20
18004241a: sub edi, esi
18004241c: lea r15d, [rdi + 1]
180042420: mov dword ptr [rsp + 0x1a8], r15d
180042428: mov dword ptr [rsp + 0x60], r12d
18004242d: mov dword ptr [rsp + 0x1ac], r12d
180042435: mov dword ptr [rsp + 0x64], ebp
180042439: mov dword ptr [rsp + 0x1b0], ebp
180042440: cmp edi, 0x7fffffff
180042446: mov qword ptr [rsp + 0x98], rbx
18004244e: jae 0x18004255d
180042454: add dword ptr [rsp + 0x64], 7
180042459: add dword ptr [rsp + 0x60], 7
18004245e: mov rax, qword ptr [rsp + 0x90]
180042466: mov r13, qword ptr [rax]
180042469: mov eax, esi
18004246b: mov qword ptr [rsp + 0xa0], rax
180042473: mov ebp, 0x1c
180042478: xor esi, esi
18004247a: nop word ptr [rax + rax]
180042480: mov rax, qword ptr [rsp + 0x430]
180042488: movsxd rax, dword ptr [rax + rsi*4]
18004248c: lea rdx, [rip + 0x3c02d]
180042493: mov r8d, dword ptr [rdx + rax*8]
180042497: mov dword ptr [rsp + 0x8c], r8d
18004249f: mov ecx, dword ptr [rsp + 0x64]
1800424a3: sub ecx, r8d
1800424a6: lea edi, [rcx + 7]
1800424a9: test ecx, ecx
1800424ab: cmovns edi, ecx
1800424ae: mov r12d, dword ptr [rdx + rax*8 + 4]
1800424b3: sar edi, 3
1800424b6: mov eax, dword ptr [rsp + 0x60]
1800424ba: sub eax, r12d
1800424bd: lea ebx, [rax + 7]
1800424c0: test eax, eax
1800424c2: cmovns ebx, eax
1800424c5: sar ebx, 3
1800424c8: mov r15, qword ptr [r14]
1800424cb: mov rax, qword ptr [rsp + 0xa0]
1800424d3: lea edx, [rax + rsi]
1800424d6: mov rcx, qword ptr [rsp + 0x98]
1800424de: xor r8d, r8d
1800424e1: call 0x1800409c0
1800424e6: mov qword ptr [rsp + rbp + 0x8c], r15
1800424ee: mov qword ptr [rsp + rbp + 0x94], r13
1800424f6: mov qword ptr [rsp + rbp + 0x9c], rax
1800424fe: mov eax, dword ptr [rsp + 0x8c]
180042505: mov dword ptr [rsp + rbp + 0xa4], eax
18004250c: mov dword ptr [rsp + rbp + 0xa8], r12d
180042514: mov dword ptr [rsp + rsi*4 + 0x1b4], edi
18004251b: imul ebx, edi
18004251e: add ebx, dword ptr [rsp + rsi*4 + 0x1d4]
180042525: mov dword ptr [rsp + rsi*4 + 0x1d8], ebx
18004252c: inc rsi
18004252f: mov r13, qword ptr [r14]
