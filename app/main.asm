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
            ; set P1.0  and P6.1 as an output
            bis.b   #BIT0, &P1DIR
            bic.b	#BIT0, &P1OUT			;Set off
            bis.b 	#BIT6, &P6DIR
			bic.b	#BIT6, &P6OUT			;Set off

            ; Disable low-power mode
            bic.w   #LOCKLPM5,&PM5CTL0

            ;-----Setup Timer B0
			bis.w	#TBCLR, &TB0CTL				; Clear timer and dividers
			bis.w	#TBSSEL__ACLK, &TB0CTL		; Select ACLK as timer source
			bis.w 	#MC__CONTINUOUS, &TB0CTL 	; Choose continuous counting
			bis.w	#CNTL_1, &TB0CTL			; Using N = 2^12
			bis.w	#ID__8, &TB0CTL				; Setting d1 = 8 (d2 is Default 1) d1*d2 = D = 8
			bis.w	#TBIE, &TB0CTL				; Enable Overflow Interupt
			bic.w	#TBIFG, &TB0CTL				; Clear interupt flag


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
;Interupt Service Routines
;------------------------------------------------------------------------------

TimerB0_1s:		;Flips red LED1 on and off at a 1 sec interval
		xor.b	#BIT6, &P6OUT
		bic.w	#TBIFG, &TB0CTL	; TB0 Flag Reset
		reti
;--------------------End TimerB0_1s -------------------------------------------

;------------------------------------------------------------------------------
; Stack Pointer definition
;------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack


;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;
            .end

            .sect	".int42"				;Timer Interrupt for 1 Second Timer
            .short	TimerB0_1s
