	 STTL 'MON1.ASM - Initial Code'
	 PAGE
*        01-13-1995
	 CODE


MONVER_  EQU *
	 BYTE $17,$01,$13,$95  Must also be altered in MON2.ASM
*                               The log-on message has ASCII version
WDC      EQU *
	 BYTE 'WDC'

MONIRQTBL EQU *          USER INTERRUPTS
	 WORD MONBRK    UBRK
	 WORD RESET     UNMI
	 WORD RESET     UIRQ2
	 WORD RESCN     UIRQ1
	 WORD TODIRQ    UIRQT2
	 WORD RESET     UIRQT1
	 WORD PDOWN     UNE46
	 WORD RESET     UGENIRQ
	 WORD START     UCMDPTR
MONIRQEND EQU *

MXTALCALC EQU *          MAX
	 BYTE $C1       2MHZ
	 BYTE $E1       4MHZ
	 BYTE $CD       2.4576MHZ
	 BYTE $DF       3.6864MHZ
	 BYTE $BD       1.8432MHZ
	 BYTE $E7       4.9125 MHZ
MXTLEND  EQU *

MNTALCALC EQU *          MIN
	 BYTE $C2       2MHZ
	 BYTE $E2       4MHZ
	 BYTE $CE       2.4576MHZ
	 BYTE $E0       3.6864MHZ
	 BYTE $BE       1.8432MHZ
	 BYTE $E8       4.9125 MHZ
MNTLEND  EQU *


RESCN     PHA
	  LDA #$40       RESET IRQ1
          TSB IFR2
          PLA
          RTI



RESET    EQU *
         SEI
	 CLD             CLEAR DECIMAL MODE
         LDX #$FF
         TXS
	 IFDEF IROM
         STZ PCS3
	 LDA #$01        EXT BUSS BUT NO ICE MODE
	 ELSE
	 LDA #$80        CS7  EPROM
	 STA PCS3
	 LDA #$89        EXT BUSS, ICE & EXT ROM
	 ENDIF
         STA BCR

*        Reset all regs to reset values (in case we had a JMP reset rather
*        than a hard reset.  Exception is TCR1 because the chip will die if
*        we switch to slow clock and shut off fast clock simultaniously,

         STZ IFR2
         STZ IER2
         STZ TCR2
         STZ PD4
         STZ PD5
         STZ PDD4
         STZ PDD5
         STZ PD6
         STZ PDD6
         STZ IFR1
         STZ IER1
         LDA #$FF
         STA PD3
         LDA #$F9
         TRB TCR1

	 IFDEF IROM
	 LDA <$7B        see if we are in low power mode.
         CMP #$55
         BNE NOLPWR
	 LDA <$7C
         CMP #$AA
         BNE NOLPWR
	 LDA <$7D
         CMP #$88
         BNE NOLPWR

	 JMP (|UNE46)    if we were, the vector is there.

NOLPWR   EQU *
	 ENDIF

	 LDA #$C0        ENABLE $8000 & $0200
	 TSB PCS3        SO WE CAN CK THE 'WDC'

         LDX #$00
CKHIROM  LDA $8000,X      CHK FOR EXTERNAL ROM
         CMP WDC,X
         BNE CKLOWRAM
         INX
         CPX #3
         BNE CKHIROM
	 JMP $8004       JMP TO EXTERNAL ROM

CKLOWRAM EQU *           CHK FOR LOW MEM ROM
         LDX #$00
LORAMLP  LDA $200,X
         CMP WDC,X
         BNE NOEXTROM
         INX
         CPX #3
         BNE LORAMLP
	 JMP $204        JMP TO EXTERNAL ROM
     

NOEXTROM:

	 LDA $200        CHECK FOR RAM AT $200
         EOR #$FF
         STA $200
         CMP $200
         BNE NOEXTRAM
         EOR #$FF
         STA $200
         CMP $200
         BEQ EXTRAM

NOEXTRAM:
	 LDA #$40        TURN OFF SRAM to keep stack
	 TRB PCS3        INSIDE 65C134

EXTRAM:
	 IFNDEF IROM
	 LDA $7B         see if we are in low power mode.
	 CMP #$55
	 BNE NOLPWR

	 LDA $7C
	 CMP #$AA
	 BNE NOLPWR

	 LDA $7D
	 CMP #$88
	 BNE NOLPWR

	 JMP (UNE46)     if we were, the vector is there.

NOLPWR   EQU *
	 ENDIF


*  START FAST CLOCK BUT NOT USING YET
         LDA #$04
         TSB TCR1

	 LDX #MONIRQEND-MONIRQTBL  SETUP ALL USER INTERRUPTS
FUIRQS   LDA MONIRQTBL-1,X
         STA UBRK-1,X
         DEX
         BNE FUIRQS

         LDX #$00
DLY0     DEX
         BNE DLY0
	 LDA #$02        ENABLE FAST CLOCK
         TSB TCR1
	 LDA #$04        ENABLE NE46
	 TSB IER1        FOR POWER DOWN SENSE
     

*                        these are placed here to facilitate
*                        quickly changing for other projects
*                        near where they are used.
XMITSIZ  EQU 4
RECSIZ   EQU $10
RECLOC   EQU $90

	 LDA #<32768     SET TIMER 2 FOR
	 STA T2LL        1 SECOND IRQ
         LDA #>32768
         STA T2LH
	 LDA #$20        ENABLE TIMER 2 IRQS
         STA IER2
	 LDA #$18        TIMER 2 ENABLED
         STA TCR2

	 LDA #<RECLOC    SETUP SERIAL BUFFERS
	 STA SINPTR      IN PAGE ZERO
         STZ SINPTR+1
         LDA #<RECLOC+RECSIZ
         STA SOUTPTR
         STZ SOUTPTR+1
	 LDA #RECSIZ     SIZE OF BUFFERS
         STA SINCNT
	 LDA #XMITSIZ    SIZE OF XMIT
         STA SOUTCNT



*  PATCH THIS BY STARTING HERE AND ENTERING

*   LDX #3
*   JMP MXTALFND

*   This deletes auto clock selection







*        CK MAIN XTAL Frequency
     
T2ZERO   LDA T2CH
	 ORA T2CL        WAIT UNTIL TOD CLOCK
	 BNE T2ZERO      READY TO LOAD
     
         LDX #3
T2DELAY  DEC A           NOW WAIT A PREDETERMINED
	 BNE T2DELAY     AMT OF TIME TO CALC XTAL
         DEX
         BNE T2DELAY

	 LDA T2CL        CK A RANGE OF #'S

         LDX #MXTLEND-MXTALCALC
TRYMXTAL CMP MXTALCALC-1,X
         BEQ MXTALFND
         DEX
         BNE TRYMXTAL

         LDX #MNTLEND-MNTALCALC
TRYMNTAL CMP MNTALCALC-1,X
         BEQ MXTALFND
         DEX
         BNE TRYMNTAL


	 LDX #3          DEFAULT 2.4576MHZ
     


MXTALFND EQU *
         DEX
	 STX SPEED       SAVE MAIN XTAL SPEED

	 LDA #$09        9600 BAUD
	 LDX #8          8 BITS
	 LDY #%00000010  EVEN PARITY / BUT NO PARITY
	 JSR ACI_INIT    INITIALIZE ACIA.
*                        hardware handshake is ON

         LDX #DFLTSEND-DFLTS-1 
         LDA #00
         CLC
CKTODLP  ADC SEC-1,X     CK IF VALID TOD CLOCK
         DEX
         BNE CKTODLP
     

         EOR #$FF
         CMP TODCKS
         BEQ GDTOD
TODERR   JSR INITCLK     NOT VALID TOD CLOCK SO FILL

         BRA GDTOD1     

GDTOD    EQU *
         JSR FLUSH_SERIAL_BUFF
         STZ ERRORS
         LDA #$FF-XONOFLG
	 TRB SFLAG       reset all of SFLAG except XON/XOFF,
*                        leave it in old state.

         JSR SIOPORTS

GDTOD1   LDA $E000       CHK IF WE HAVE E000 ROM
         CMP #$4C
         BNE SKPE000
         JSR $E000
SKPE000  EQU *
	 LDA ARTD        CLEAR SIO RECEIVE IRQS
     
         

	 ENDS

	 APPEND MON2.ASM
