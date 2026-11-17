format PE64 EFI
entry main

section ".text" code readable executable

OFFSET_SYSTEM_TABLE_CON_IN  = 48
OFFSET_CON_IN_READ_KEY_STROKE = 8
OFFSET_CON_IN_WAIT_FOR_KEY = 16
OFFSET_SYSTEM_TABLE_CON_OUT = 64
OFFSET_CON_OUT_OUTPUT_STRING = 8
OFFSET_SYSTEM_TABLE_BOOT_SERVICES = 96
OFFSET_BOOT_SERVICES_WAIT_FOR_EVENT = 96
OFFSET_BOOT_SERVICES_LOCATE_HANDLE_BUFFER = 312
OFFSET_BOOT_SERVICES_HANDLE_PROTOCOL = 152

; rdi - null terminated string pointer
debug_print:
    mov     rcx, [r12 + OFFSET_SYSTEM_TABLE_CON_OUT]
    mov     rax, [rcx + OFFSET_CON_OUT_OUTPUT_STRING]
    mov     rdx, rdi

    sub     rsp, 40
    call    rax
    add     rsp, 40

    ret

debug_wait_for_key:
    lea     rdi, [string_waiting_for_key]
    call    debug_print

    mov     rax, [r12 + OFFSET_SYSTEM_TABLE_CON_IN]
    mov     rax, [rax + OFFSET_CON_IN_WAIT_FOR_KEY]
    mov     [wait_event], rax

    mov     rax, [r12 + OFFSET_SYSTEM_TABLE_BOOT_SERVICES]
    mov     rcx, 1
    lea     rdx, [wait_event]
    lea     r8, [event_index]

    sub     rsp, 40
    call    qword [rax + OFFSET_BOOT_SERVICES_WAIT_FOR_EVENT]
    add     rsp, 40

    mov     rcx, [r12 + OFFSET_SYSTEM_TABLE_CON_IN]
    lea     rdx, [key]

    sub     rsp, 40
    call    qword [rcx + OFFSET_CON_IN_READ_KEY_STROKE]
    add     rsp, 40
    
    ret

disk_read:
    lea     rdi, [string_blockio_search]
    call    debug_print
    mov     rax, [r12 + OFFSET_SYSTEM_TABLE_BOOT_SERVICES]
    mov     rax, [rax + OFFSET_BOOT_SERVICES_LOCATE_HANDLE_BUFFER]

    mov     rcx, 2               ; ByProtocol
    lea     rdx, [block_io_guid]
    xor     r8, r8               ; SearchKey = NULL
    lea     r9, [num_handles]

    lea     r10, [handle_buffer]
    mov     [rsp + 32], r10

    sub     rsp, 40
    call    rax
    add     rsp, 40
    ; TODO handle errors
    
    lea     rdi, [print_buffer]
    mov     byte [print_buffer], "0"
    mov     byte [print_buffer+1], 0
    mov     rcx, [num_handles]
    add     byte [print_buffer], cl
    call    debug_print
    lea     rdi, [string_blockio_search_success]
    call    debug_print

    xor     r13, r13
.loop:
    cmp     r13, [num_handles]
    jae     .done

    mov     rax, [handle_buffer]
    mov     rcx, [rax + r13*8]

    mov     rax, [r12 + OFFSET_SYSTEM_TABLE_BOOT_SERVICES]
    mov     rax, [rax + OFFSET_BOOT_SERVICES_HANDLE_PROTOCOL]

    lea     rdx, [block_io_guid]
    lea     r8, [block_io]

    sub     rsp, 40
    call    rax
    add     rsp, 40

    lea     rdi, [print_buffer]
    mov     byte [print_buffer], "0"
    mov     byte [print_buffer+1], 0
    mov     rcx, [block_io]
    mov     rcx, [rcx]
    mov     cl, [rcx+6]
    add     byte [print_buffer], cl
    call    debug_print
    lea     rdi, [string_blockio_device_logical]
    call    debug_print

    test    rax, rax
    jnz     .next
.next:
    inc     r13
    jmp     .loop
.done:
    ret

main:
    push    r12
    mov     r12, rdx 
    
    sub     rsp, 32
    lea     rdi, [string_starting]
    call    debug_print
    call    disk_read
    call    debug_wait_for_key
    add     rsp, 32
   
    pop     r12
    xor     eax, eax;  EFI_SUCCESS

    ret

section ".rodata" data readable

string_starting du "starting bootloader", 13, 10, 0
string_blockio_search du "searching blocking I/O devices... ", 13, 10, 0
string_blockio_search_success du " devices found", 13, 10, 0
string_blockio_device_logical du " <- is a logical partition?", 13, 10, 0
string_waiting_for_key du "press any key to continue", 13, 10, 0

block_io_guid:
    dd 0x964E5B21
    dw 0x6459
    dw 0x11D2
    db 0x8E, 0x39, 0x00, 0xA0, 0xC9, 0x69, 0x72, 0x3B

partition_info_guid:
    dd 0x8CF2F62C
    dw 0xBC9B
    dw 0x4821
    db 0x80, 0x8D, 0xEC, 0x9E
    db 0xEB, 0x6A, 0xB5, 0xA5

section ".bss" data readable writeable

wait_event  dq 0
event_index dq 0
key         rb 4
num_handles   rq 1
handle_buffer rq 1
block_io      rq 1
partition_info rq 1
print_buffer    rq 1
