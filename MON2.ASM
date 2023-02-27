	 STTL 'MON2.ASM - As we enable interrupts after RESET'
	 PAGE
*        01-13-1995
	 CODE

	 CLI             ENABLE INTERUPTS
*                        WRITE MONITOR VERSION

         LDA #>MONVER
         LDX #<MONVER
         LDY #MONVEND-MONVER
         JSR PRTSTR
	 JSR SNDTOD      DISPLAY TOD
	 BRK $00         ENTER COM BY BREAK


MONVER   EQU *
	 BYTE $0D,'134 ROM Version 1.07'   SEE MON1.ASM & MONTXT.ASM
	 BYTE $0D,'(C) Copyright 1995'
	 BYTE $0D,'Western Design Center',$0D
MONVEND  EQU *

	 STTL 'MON2.ASM - BRK handler'
	 PAGE


MONBRK   EQU *           MONITOR BREAK
         STA ACC
	 STX XR          SAVE X
	 STY YREG        Y
         PLA
	 STA FLGS        FLAGS
	 CLC             for the add below
         PLA
	 ADC #$FF        CY SET TO PC-1 FOR BR
         STA PCL
         PLA
         ADC #$FF
         STA PCH
         TSX
	 STX TMPSP       SAVE ORIG SP
	 CLI             ENABLE SERIAL OUTPUT
	 LDA #'R'        SET FOR R DISPLAY TO
*                        PERMIT IMMEDIATE ALTER
	 BRA S0          FOLLOWING BREAKPOINT.
	 ENDS


	 APPEND MON3.ASM
