title   rash64.x64.asm: rash64 for x64.

; 2017-07-21
; Public Domain

; No warranty expressed or implied. Use at your own risk. You have been warned.

; rash64 is a fast insecure random number generator function.

public rash64_seed;(seed: uint64)

public rash64;()

; The key to rash64 is multiplication by a big prime number yielding a 128 bit
; product. CPUs know how to do a 128:=64*64 bit unsigned multiply, but most
; programming languages do not, which is why this is written in assembly
; language.

; rash64 requires 64 bits of seed.

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

; Repair the register names. Over the long and twisted evolution of x86, the
; register names have picked up some weird, inconsistent conventions. We can
; simplify, naming them r0 thru r15. (We don't use rsp or rbp.)

r0      equ rax
r1      equ rcx
r2      equ rdx
r3      equ rbx
r6      equ rsi
r7      equ rdi

; There is painfully inadequate standardization around x64 calling conventions.
; On Win64, the first three arguments are passed in r1, r2, and r8. On Unix,
; the first three arguments are passed in r7, r6, and r2. We try to hide that
; weirdness behind these macros. The two systems also have different
; conventions about which registers may be clobbered and which must be
; preserved. This code lives in the intersection.

; Registers r1, r2, r8, r9, r10, and r11 are clobbered. Register r0 is the
; return value. The other registers are not disturbed.

; This has not yet been tested on Unix.

UNIX    equ 0                   ; calling convention: 0 for Windows, 1 for Unix

function_with_one_parameter macro
    if UNIX
    mov     r1,r7               ;; UNIX
    endif
    endm


; There may be a performance benefit in padding programs so that most jump
; destinations are aligned on 16 byte boundaries.

pad macro
    align   16
    endm

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

; Constant:

prime     equ     08AC7230489E7FFD9h ;  9999999999999999961
prime_3   equ     02E426101834D5517h ;  3333333333333333271

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

rash64_state segment page write

result    qword   0
sum       qword   0
counter   qword   0

rash64_state ends

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

rash64_code segment para execute

rash64_seed: function_with_one_parameter;(seed: uint64)

    mov     r0,prime_3
    mov     r2,1
    mov     result,r1
    mov     sum,r0
    mov     counter,r2
    ret

    pad; -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

rash64:

;   r0  low
;   r1  sum
;   r2  high
;   r8  counter

    mov     r0,result   ; high ; low := (result xor counter) * prime
    mov     r8,counter
    mov     r2,prime
    xor     r0,r8
    mov     r1,sum
    mul     r2
    add     r8,1        ; counter += 1
    mov     counter,r8
    add     r1,r2       ; sum += high
    mov     sum,r1
    xor     r0,r1       ; result := low xor sum
    mov     result,r0   ; return result
    ret

rash64_code ends
    end
