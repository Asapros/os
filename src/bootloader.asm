format PE64 EFI
entry main

section ".text" code readable executable

main:
    ; Preserve SystemTable (RDX)
    push    r12
    mov     r12, rdx

   ; OutputString
    mov     rax, [r12 + 64]       ; SystemTable->ConOut
    lea     rdx, [hello]
    mov     rcx, rax
    sub     rsp, 32
    call    qword [rax + 8]             ; OutputString
    add     rsp, 32

    ; Get ConIn->WaitForKey event
    mov     rax, [r12 + 48]       ; SystemTable->ConIn
    mov     rax, [rax + 16]      ; WaitForKey
    mov     [wait_event], rax

    ; WaitForEvent(1, &WaitForKey, &Index)
    mov     rax, [r12 + 96]      ; BootServices
    mov     rcx, 1
    lea     rdx, [wait_event]
    lea     r8, [event_index]

    sub     rsp, 32
    call    qword [rax + 96]           ; WaitForEvent
    add     rsp, 32

    ; ReadKeyStroke()
    mov     rcx, [r12 + 48]      ; ConIn
    lea     rdx, [key]

    sub     rsp, 32
    call    qword [rcx + 8]            ; ReadKeyStroke
    add     rsp, 32

    ; Return EFI_SUCCESS
    xor     eax, eax
    pop     r12
    ret

section ".data" data readable writeable

hello       du "hello pszemo", 13, 10, 0
wait_event  dq 0
event_index dq 0
key         rb 4
