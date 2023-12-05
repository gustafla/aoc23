.data

line_buffer:
    .fill 1024, 1, 0

.text

.globl _start
_start:
    // syscall read(int fd, const void *buf, size_t count)
    mov     x0, #0      // STDIN_FILENO
    mov     x3, #0      // index 0
    mov     x2, #1      // count 1
    mov     w8, #63     // read is syscall 63
read_byte:
    ldr     x1, =line_buffer
    add     x1, x1, x3
    svc     #0          // return value is passed in register x0
    add     x3,x3,#1    // increment x3 index

    //.inst 0xd4200000    // breakpoint
check_newline:
    ldrb    w4, [x1]    // Load 1 byte from address pointed by x1
    cmp     w4, '\n'    // if character == '\n'
    b.eq    print_echo  // jump to print_echo
    
    cmp     x0, #0      // if read > 0
    b.gt    read_byte   // loop back to read_byte

print_echo:
    // syscall write(int fd, const void *buf, size_t count)
    mov     x0, #1      // fd := STDOUT_FILENO
    ldr     x1, =line_buffer
    mov     x2, x3      // use index as count-parameter
    mov     w8, #64     // write is syscall 64
    svc     #0

    // syscall exit(int status)
    mov     x0, #0      // status := 0
    mov     w8, #93     // exit is syscall 93
    svc     #0          // invoke syscall
