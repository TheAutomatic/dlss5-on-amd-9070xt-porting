   140027af8:	48 8b 83 20 06 00 00 	mov    rax,QWORD PTR [rbx+0x620]
   140027aff:	48 3b 83 28 06 00 00 	cmp    rax,QWORD PTR [rbx+0x628]
   140027b06:	74 07                	je     140027b0f <_ZN9NrSession5buildEiPPcPKSt6vectorIN12_GLOBAL__N_14StepESaIS4_EE+0x12adf>
   140027b08:	48 89 83 28 06 00 00 	mov    QWORD PTR [rbx+0x628],rax
   140027b0f:	45 31 ed             	xor    r13d,r13d
   140027b12:	48 8b 94 24 70 13 00 	mov    rdx,QWORD PTR [rsp+0x1370]
   140027b19:	00 
   140027b1a:	8b 8c 24 68 13 00 00 	mov    ecx,DWORD PTR [rsp+0x1368]
   140027b21:	4c 8d 0d 65 0a 10 00 	lea    r9,[rip+0x100a65]        # 14012858d <.rdata+0x158d>
   140027b28:	4c 89 ab 10 06 00 00 	mov    QWORD PTR [rbx+0x610],r13
   140027b2f:	4c 8d 05 03 2a 10 00 	lea    r8,[rip+0x102a03]        # 14012a539 <.rdata+0x3539>
   140027b36:	4c 89 ab 40 06 00 00 	mov    QWORD PTR [rbx+0x640],r13
   140027b3d:	e8 0e 9b fd ff       	call   140001650 <_ZN12_GLOBAL__N_13argEiPPcPKcS3_>
   140027b42:	48 89 c1             	mov    rcx,rax
   140027b45:	e8 ee ac 01 00       	call   140042838 <atoi>
   140027b4a:	48 8b b4 24 70 13 00 	mov    rsi,QWORD PTR [rsp+0x1370]
   140027b51:	00 
   140027b52:	8b bc 24 68 13 00 00 	mov    edi,DWORD PTR [rsp+0x1368]
   140027b59:	4c 8d 05 8e 14 10 00 	lea    r8,[rip+0x10148e]        # 140128fee <.rdata+0x1fee>
   140027b60:	89 83 08 06 00 00    	mov    DWORD PTR [rbx+0x608],eax
   140027b66:	48 89 f2             	mov    rdx,rsi
   140027b69:	89 f9                	mov    ecx,edi
   140027b6b:	e8 50 9b fd ff       	call   1400016c0 <_ZN12_GLOBAL__N_14flagEiPPcPKc>
   140027b70:	48 89 f2             	mov    rdx,rsi
   140027b73:	4c 8d 05 c7 29 10 00 	lea    r8,[rip+0x1029c7]        # 14012a541 <.rdata+0x3541>
   140027b7a:	89 f9                	mov    ecx,edi
   140027b7c:	88 83 e1 05 00 00    	mov    BYTE PTR [rbx+0x5e1],al
   140027b82:	e8 39 9b fd ff       	call   1400016c0 <_ZN12_GLOBAL__N_14flagEiPPcPKc>
   140027b87:	4c 8d 0d ff 09 10 00 	lea    r9,[rip+0x1009ff]        # 14012858d <.rdata+0x158d>
   140027b8e:	48 89 f2             	mov    rdx,rsi
   140027b91:	89 f9                	mov    ecx,edi
   140027b93:	88 83 e2 05 00 00    	mov    BYTE PTR [rbx+0x5e2],al

.rdata VMA 0x140127000, file_offset0x125600; r9 fallback0x14012858d is file[0x126b8d:]=31 00 (ASCII "1").
