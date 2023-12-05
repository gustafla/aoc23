.data

/* Data segment: define our message string and calculate its length. */
msg:
    .ascii        "Hello, ARM64!\n"
len = . - msg

line_buffer:
    .fill 1024, 1, 0

.text

/* Our application's entry point. */
.globl _start
_start:
    /* syscall write(int fd, const void *buf, size_t count) */
    mov     x0, #1      /* fd := STDOUT_FILENO */
    ldr     x1, =msg    /* buf := msg */
    ldr     x2, =len    /* count := len */
    mov     w8, #64     /* write is syscall #64 */
    svc     #0          /* invoke syscall */

    /* syscall read(int fd, const void *buf, size_t count) */
    mov     x0, #0      /* fd := STDIN_FILENO */
    ldr     x1, =line_buffer    /* buf := line_buffer */
    mov     x2, #1      /* count := 1 */
    mov     w8, #63     /* read is syscall #63 */
    svc     #0          /* invoke syscall */

    .inst 0xd4200000    /* breakpoint */

    /* syscall exit(int status) */
    mov     x0, #0      /* status := 0 */
    mov     w8, #93     /* exit is syscall #93 */
    svc     #0          /* invoke syscall */
