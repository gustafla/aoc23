.arch armv8-a

.data
    // Nothing for now

.bss
    .type   line_buffer, %object
    .size   line_buffer, 1024
line_buffer:
    .zero   1024

.text

read_line:
    sub     sp, sp, 32          // create a new stack frame
    str     x30, [sp]           // push return location
    str     x19, [sp, 8]        // push r19 value (callee saves)
    str     x20, [sp, 16]       // push r20 value (callee saves)

    mov     x19, 0              // set index at 0

    mov     x0, 0               // STDIN_FILENO
    mov     x2, 1               // count 1
    mov     w8, 63              // read is syscall 63
read_byte:
    ldr     x1, =line_buffer    // set write buf address to line_buffer + index
    add     x1, x1, x19
                                // syscall read(int fd, const void *buf, size_t count)
    svc     0                   // return value is passed back in register x0
    add     x19, x19, 1         // increment index
check_newline:
    ldrb    w20, [x1]           // Load 1 byte from address pointed by x1
    cmp     w20, '\n'           // if character == '\n'
    b.eq    read_line_ret       // then return from func
    cmp     x0, 0               // if read > 0
    b.gt    read_byte           // loop back to read_byte
read_line_ret:
    mov     x0, x19             // set return value (len)
    ldr     x30, [sp]           // pop return location
    ldr     x19, [sp, 8]        // pop r19 value (callee saves)
    ldr     x20, [sp, 16]       // pop r20 value (callee saves)
    add     sp, sp, 32
    ret

.globl _start
_start:
    bl      read_line
    mov     x19, x0
                                // syscall write(int fd, const void *buf, size_t count)
    mov     x0, 1               // fd := STDOUT_FILENO
    ldr     x1, =line_buffer
    mov     x2, x19             // use index as count-parameter
    mov     w8, 64              // write is syscall 64
    svc     0
                                // syscall exit(int status)
    mov     x0, 0               // status := 0
    mov     w8, 93              // exit is syscall 93
    svc     0                   // invoke syscall
