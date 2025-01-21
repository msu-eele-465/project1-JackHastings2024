; Jack Glutting-Gilsdorf
; 1/17/2025
; Project 1 - Toggle P1.0 using delay loop subroutine
;

            .cdecls C,LIST,"msp430.h"  ; Include device header file
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.

            .global __STACK_END
            .sect   .stack                  ; Define stack linker segment

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs

RESET       mov.w   #__STACK_END,SP         ; Initialize stack pointer

StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT

init:
            ; Set P1.0 and P6.1 as outputs
            bis.b   #BIT0, &P1DIR
            bic.b   #BIT0, &P1OUT          ; Ensure P1.0 is off
            bis.b   #BIT6, &P6DIR
            bic.b   #BIT6, &P6OUT          ; Ensure P6.1 is off

            ; Disable low-power mode
            bic.w   #LOCKLPM5, &PM5CTL0

            ;-----Setup Timer B0
			bis.w	#TBCLR, &TB0CTL				; Clear timer and dividers
			bis.w	#TBSSEL__ACLK, &TB0CTL		; Select ACLK as timer source
			bis.w 	#MC__CONTINUOUS, &TB0CTL 	; Choose continuous counting
			bis.w	#CNTL_1, &TB0CTL			; Using N = 2^12
			bis.w	#ID__8, &TB0CTL				; Setting d1 = 8 (d2 is Default 1) d1*d2 = D = 8
			bis.w	#TBIE, &TB0CTL				; Enable Overflow Interupt
			bic.w	#TBIFG, &TB0CTL				; Clear interupt flag
			bis.w	#GIE, SR					; Enable global interupts

main:
            mov.w   #1045, R14                ; Set delay_ms to delay for 1000 ms (1 s)
            call    #delay_loop

            xor.b   #BIT0, &P1OUT            ; Toggle P1.0 every 1 s

            jmp     main
            nop

; delay_loop
; Delay for a desired number of milliseconds
;
; Inputs:
;   R14: Number of milliseconds to delay
;
delay_loop:

; Inner loop timing calculation:
;   3 cycles per iteration * 332 iterations = 996 cycles
;   mov.w to setup loop counter: 2 cycles
;   996 + 2 = 998 --> need two extra nop cycles

                ; Setup outer loop counter
                mov.w   #332, R15             ; 2 cycles

                ; Delay a couple of cycles to get timing exact
                nop                          ; 1 cycle
                nop                          ; 1 cycle

                ; Decrement inner loop variable
loop_inner:     dec.w   R15                   ; 3 cycles per iteration
                jnz     loop_inner

                ; Decrement outer loop variable
                dec.w   R14
                jnz     delay_loop

                ret
;------------------------------------------------------------------------------
; Interrupt Service Routines
;------------------------------------------------------------------------------

TimerB0_1s:		;Flips red LED1 on and off at a 1 sec interval
		xor.b	#BIT6, &P6OUT
		bic.w	#TBIFG, &TB0CTL	; TB0 Flag Reset
		reti
;-------------------- End TimerB0_1s -------------------------------------------

;------------------------------------------------------------------------------
; Stack Pointer definition
;------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack

;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET

            .sect	".int42"
            .short	TimerB0_1s
