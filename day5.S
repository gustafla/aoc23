.data

line_buffer:
    .fill 1024, 1, 0

.text

.globl _start
_start:
    // syscall read(int fd, const void *buf, size_t count)
    mov     x0, #0      // STDIN_FILENO
    ldr     x1, =line_buffer
    mov     x2, #1      // count 1
    mov     x3, #0      // index 0
read_byte:
    mov     w8, #63     // read is syscall 63
    svc     #0          // return value is passed in register x0
    add     x3,x3,1     // increment x3 index
    add     x1,x1,x3    // set x1 = x1 + x3

    //.inst 0xd4200000    // breakpoint
    cmp     x0, #0
    b.gt    read_byte

print_echo:
    // syscall write(int fd, const void *buf, size_t count)
    mov     x0, #1      // fd := STDOUT_FILENO
    ldr     x1, =line_buffer
    mov     x2, x3      // use index as count-parameter
    mov     w8, #64     // write is syscall
    svc     #0

    // syscall exit(int status)
    mov     x0, #0      // status := 0
    mov     w8, #93     // exit is syscall #93
    svc     #0          // invoke syscall
