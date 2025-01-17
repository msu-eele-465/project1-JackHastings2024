; Jack Glutting-Gilsdorf
; 1/17/2025
; Project 1 - Toggle P1.0 using delay loop subroutine
;

            .cdecls C,LIST,"msp430.h"  ; Include device header file
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.

            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs

RESET       mov.w   #__STACK_END,SP         ; Initialize stack pointer

StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT

init:
            ; set P1.0 as an output
            bis.b   #BIT0, &P1DIR

            ; Disable low-power mode
            bic.w   #LOCKLPM5,&PM5CTL0


main:

            mov.w #1000, R14                ; set delay_ms to delay for 1000 ms (1 s)
            call #delay_loop

            xor.b   #BIT0,&P1OUT            ; Toggle P1.0 every 0.1s

            jmp main
            nop

; delay_ms
; Delay for a desired number of ms
;
; Inputs:
;   
delay_loop:

; inner loop timing calculation:
;   3 cycles per iteration * 332 iterations = 996 cycles
;   mov.w to setup loop counter: 2 cycles
;   996 + 2 = 998 --> need two extra nop cycles

                ; setup inner loop counter
delayloop_outer  mov.w #332, R15             ; 2 cycles

                ; delay a couple cycles to get timing exact
                ; TODO: need to verify timing with a scope
                nop                         ; 1 cycle
                nop                         ; 1 cycle

                ; decrement inner loop variable
delayloop_inner  dec.w R15                   ; 3 cycles per iteration
                jnz delayloop_inner

                ; decrement outer loop variable
                dec.w R14
                jnz delayloop_outer

                ret

;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;
            .end
