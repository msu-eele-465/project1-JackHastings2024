; Jack Glutting-Gilsdorf
; 1/17/2025
; Project 1
;  MSP430FR235x Demo - Toggle P1.0 using software
;
;  Description: Toggle P1.0 every 0.1s using software.
;  By default, FR235x select XT1 as FLL reference.
;  If XT1 is present, the PxSEL(XIN & XOUT) needs to configure.
;  If XT1 is absent, switch to select REFO as FLL reference automatically.
;  XT1 is considered to be absent in this example.
;  ACLK = default REFO ~32768Hz, MCLK = SMCLK = default DCODIV ~1MHz.
;
;           MSP430FR2355
;         ---------------
;     /|\|               |
;      | |               |
;      --|RST            |
;        |           P1.0|-->LED
;
;   Cash Hao
;   Texas Instruments Inc.
;   November 2016
;   Built with Code Composer Studio v6.2.0
;******************************************************************************
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
            call #delay_ms

            xor.b   #BIT0,&P1OUT            ; Toggle P1.0 every 0.1s

            jmp main
            nop

; delay_ms
; Delay for a desired number of ms
;
; Inputs:
;   
delay_ms: 

; inner loop timing calculation:
;   3 cycles per iteration * 332 iterations = 996 cycles
;   mov.w to setup loop counter: 2 cycles
;   996 + 2 = 998 --> need two extra nop cycles

                ; setup inner loop counter
delay_ms_outer  mov.w #332, R15             ; 2 cycles

                ; delay a couple cycles to get timing exact
                ; TODO: need to verify timing with a scope
                nop                         ; 1 cycle
                nop                         ; 1 cycle

                ; decrement inner loop variable
delay_ms_inner  dec.w R15                   ; 3 cycles per iteration
                jnz delay_ms_inner

                ; decrement outer loop variable
                dec.w R14
                jnz delay_ms_outer

                ret

;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;
            .end
