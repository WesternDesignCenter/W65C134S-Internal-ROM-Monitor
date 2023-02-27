	 STTL 'MON7.ASM - Special interrupts - Power Down'
	 PAGE
*        06-23-1993
	 CODE

NE46 EQU *               POWER FAIL PENDING
	 JMP (|UNE46)


*  POWER DOWN:

*  When we get a power down interrupt, we come here.  We shut down all
*  interrupts (except TOD clock), and clear any that were pending.
*  we reset the stack to FF, we write a semiphore into RAM to indicate that
*  we are powered down, and we run the power down routine. We slow down then
*  shut off the fast clock.  We turn all i/o ports to inputs.

*  The power down routine executes the time of day interrupt, then checks RAM
*  for a semiphore indicating that there is a low power routine in RAM.
*  If there is we JSR to $0088.  The RAM routine can do anything it likes and
*  returns with a RTS.

*  After the RTS (or after deciding there is no RAM routine) we check for
*  power back up.  If power has returned to the system, we bring up a few
*  key registers then jump to RESET.

*  If a physical reset occurs while we are powered down, we must return to
*  the power down code w/out restarting anything on the bus.  We use the first
*  semiphore above to flag this condition.
         
*  IMPORTANT SEMIPHORES:

*  If we are in low power mode, locations $7B = $55, $7C = $AA, $7D = $88.
*  This is checked by RESET.

*  If there is a valid routine in RAM, it starts at $0088, and locations
*  $7E = $55, $7F = $AA. If that is the case, the low power
*  routine will jsr to $0088 once per second.

*  RAM LOCATIONS:

*  RAM locations F8-FF are used for the stack to do the TOD interrupt.

*  $40 - $87  remain through power down  don't mess with them.



PDOWN    EQU *           GOTO LOW POWER MODE

	 LDA #$55        set the LP semiphore
	 STA <$7B
         LDA #$AA
	 STA <$7C
         LDA #$88
	 STA <$7D

	 LDA #%01111010  DISABLE EDGE IRQ'S
	 TRB BCR         DISABLE NMI & IRQ'S

	 STZ IER1        DISABLE INTERRUPTS
         LDA #$FF
	 STA IFR1        RESET ANY INTERRUPTS

	 LDA #$20        ENABLE ONLY T2
         STA IER2

         LDA #$DF
	 TSB IFR2        RESET ANY EXCEPT T2

	 LDA #<TODIRQ    MAKE TOD CLK INTERNAL
         STA UIRQT2
         LDA #>TODIRQ
         STA UIRQT2+1

	 STZ ACSR        DISABLE REC & XMIT SERIAL

	 LDA ARTD        RESET ANY SERIAL READS
	 STZ ARTD        RESET ANY SERIAL WRITES

	 STZ PD4         PUT ALL PORTS LOW
         STZ PD5
         STZ PD6
	 STZ PDD4        RESET PORTS TO INPUTS
         STZ PDD5
         STZ PDD6

	 LDA #$18        T1 DISABLE, LEAVE T2 (TOD)
         STA TCR2

	 LDA #%00000100  shift to slow clock
         STA TCR1

	 LDA #$00        WAIT UNTIL SLOW CLOCK
PDLP1    DEC A           CAN TAKE EFFECT
         BNE PDLP1            

	 STZ TCR1        fast clock is now OFF

	 IFDEF IROM
	 STZ BCR         GO TO ALL INTERNAL
	 ELSE
	 LDA #$81
	 STA BCR         for test
	 ENDIF

	 STZ PCS3        kill CS outputs
	 IFDEF IROM
	 STZ PD3         internal ROM, set all output to 0
	 ELSE
	 LDA #$FF
	 STA PD3         external ROM, set all high CS outs
	 ENDIF

	 LDX #$FF        RESET STACK TO INTERNAL
         TXS

	 STZ PD0         PUT ALL PORTS LOW
         STZ PD1
         STZ PD2
	 STZ PDD0        RESET PORTS TO INPUTS
         STZ PDD1
         STZ PDD2

NE46LP1  LDA #PUFLG      set flag to indicate
	 TRB DISPTYP     we haven't seen any
*                        power up yet.

         CLI

NE46LP   BYTE $DB       STOP until Interrupt
         NOP

* We get here after doing a TOD Interrupt



	 LDA <$7E
         CMP #$55
         BNE NORAMRT
	 LDA <$7F
         CMP #$AA
         BNE NORAMRT
	 JSR $0088       JSR to RAM routine

NORAMRT  LDA PD4         CK PD46 FOR POWER UP
         BIT #$40             
	 BEQ NE46LP1     reset PUP flag if Necss.

	 LDA #PUFLG      SET 1ST TIME FLG
	 TSB DISPTYP     NOTICED PU FLG
	 BEQ NE46LP      a debounce of 2
         

* POWER BACK UP - Restart system



	 STZ <$7B         CLEAR ALL SEMIPHORES
	 STZ <$7C
	 STZ <$7D
	 STZ <$7E
	 STZ <$7F

         JMP ($FFFC)



PE44     EQU *
PE45     EQU *
PE50     EQU *
PE51     EQU *
NE52     EQU *
NE53     EQU *
IRQRESERVED EQU *
PE54     EQU *
PE55     EQU *
PE56     EQU *
NE57     EQU *
GENIRQ   EQU *
	 JMP (|UGENIRQ)



IRQT1    JMP (|UIRQT1)


IRQT2    JMP (|UIRQT2)


IRQ1     JMP (|UIRQ1)


IRQ2     JMP (|UIRQ2)


NMIRQ    JMP (|UNMI)



IRQBRK   JMP (|UBRK)



TABLE_START EQU $FEF3


ZZZSPACE EQU TABLE_START-*      gives space left in the ROM

LASTBYTE EQU *+1
	 ENDS
	 STTL 'MON7.ASM - GENERAL LOOKUP TABLES'
	 PAGE
	 DATA
	 ORG TABLE_START

BAUDOFFSET EQU *
	 BYTE 00        2.0000MHZ
	 BYTE 24        4.0000MHZ
	 BYTE 48        2.4576MHZ
	 BYTE 72        3.6864MHZ
	 BYTE 96        1.8432MHZ
	 BYTE 120       4.9125 MHZ




ACIBAUD  EQU *
*                         2MHZ
	 WORD $0682        75 BAUD
	 WORD $046F       110 BAUD
	 WORD $0340       150 BAUD
	 WORD $01A0       300 BAUD
	 WORD $00CF       600 BAUD
	 WORD $0067      1200 BAUD
	 WORD $0044      1800 BAUD
	 WORD $0033      2400 BAUD
	 WORD $0019      4800 BAUD
	 WORD $000C      9600 BAUD DOES NOT WORK RELIABLY
	 WORD $0006     19200 BAUD BAD WONT WORK AT 2MHZ
	 WORD $0002     38400 BAUD BAD WONT WORK AT 2MHZ

*                        4MHZ
	 WORD $0D04        75 BAUD
	 WORD $08E0       110 BAUD
	 WORD $0682       150 BAUD
	 WORD $0340       300 BAUD
	 WORD $01A0       600 BAUD
	 WORD $00CF      1200 BAUD
	 WORD $008A      1800 BAUD
	 WORD $0067      2400 BAUD
	 WORD $0033      4800 BAUD
	 WORD $0019      9600 BAUD
	 WORD $000C     19200 BAUD
	 WORD $0006     38400 BAUD BAD WONT WORK AT 2MHZ

*                        2.4576MHZ
	 WORD $07FF        75 BAUD
	 WORD $0573       110 BAUD
	 WORD $03FF       150 BAUD
	 WORD $01FF       300 BAUD
	 WORD $00FF       600 BAUD
	 WORD $007F      1200 BAUD
	 WORD $0054      1800 BAUD
	 WORD $003F      2400 BAUD
	 WORD $001F      4800 BAUD
	 WORD $000F      9600 BAUD
	 WORD $0007     19200 BAUD
	 WORD $0003     38400 BAUD

*                 3.6864MHZ
	 WORD $0BFF        75 BAUD
	 WORD $082E       110 BAUD
	 WORD $05FF       150 BAUD
	 WORD $02FF       300 BAUD
	 WORD $017F       600 BAUD
	 WORD $00BF      1200 BAUD
	 WORD $007F      1800 BAUD
	 WORD $005F      2400 BAUD
	 WORD $002F      4800 BAUD
	 WORD $0017      9600 BAUD
	 WORD $000B     19200 BAUD
	 WORD $0005     38400 BAUD

*                        1.8432MHZ
	 WORD $05FF        75 BAUD
	 WORD $0416       110 BAUD
	 WORD $02FF       150 BAUD
	 WORD $017F       300 BAUD
	 WORD $00BF       600 BAUD
	 WORD $005F      1200 BAUD
	 WORD $003F      1800 BAUD
	 WORD $002F      2400 BAUD
	 WORD $0017      4800 BAUD
	 WORD $000B      9600 BAUD
	 WORD $0005     19200 BAUD
	 WORD $0002     38400 BAUD


*                        4.9152MHZ
	 WORD $0FFF        75 BAUD
	 WORD $0AE8       110 BAUD
	 WORD $07FF       150 BAUD
	 WORD $03FF       300 BAUD
	 WORD $01FF       600 BAUD
	 WORD $00FF      1200 BAUD
	 WORD $00AA      1800 BAUD
	 WORD $007F      2400 BAUD
	 WORD $003F      4800 BAUD
	 WORD $001F      9600 BAUD
	 WORD $000F     19200 BAUD
	 WORD $0007     38400 BAUD





* TIME OF DAY MAX MIN TABLES


MAXTTBL  EQU *
	 BYTE 60        MIN
	 BYTE 24        HR
	 BYTE 32        DAY
	 BYTE 13        MONTH
	 BYTE 100       YR
	 BYTE 8         DAY OF WEEK

MINTTBL  EQU *
	 BYTE 0         MIN
	 BYTE 0         HR
	 BYTE 1         DAY
	 BYTE 1         MONTH
	 BYTE 0         YR
	 BYTE 1         DAY OF WEEK


LASTDY   BYTE 31        JANUARY
	 BYTE 28        FEBRUARY-EXCEPT LEAP YR
	 BYTE 31        MARCH
	 BYTE 30        APRIL
	 BYTE 31        MAY
	 BYTE 30        JUNE
	 BYTE 31        JULY
	 BYTE 31        AUGUST
	 BYTE 30        SEPTEMBER
	 BYTE 31        OCTOBER
	 BYTE 30        NOVEMBER
	 BYTE 31        DECEMBER

DFLTS    BYTE 0         SEC
	 BYTE 00        MINUTES
	 BYTE 12        HOUR
	 BYTE 04        DAY
	 BYTE 07        MONTH
	 BYTE 93        YEAR
	 BYTE 1         DAY OF WEEK
	 BYTE 0         DAYLIGHT SAVING OFF
DFLTSEND EQU *


   STTL 'CONVERSION TABLES

HEXTOPOS EQU *
	 BYTE $01,$02,$04,$08
	 BYTE $10,$20,$40,$80


BINDECL  EQU *
	 BYTE $00,$01,$02,$03,$04,$05,$06,$07,$08,$09
	 BYTE $10,$11,$12,$13,$14,$15

BINDECH  BYTE $00,$16,$32,$48,$64,$80,$96
	 PAGE

	 WORD TODIRQ    MONITOR TOD IRQ PTR
	 WORD MONBRK    MONITOR BREAK IRQ PTR
	 WORD PDOWN     POWER DOWN IRQ PTR
	 WORD S0        JMP INTO MONITOR CMD PARSER
	 WORD PE44

	 WORD PE45
	 WORD NE46
	 WORD NE47
	 WORD PE50
	 WORD PE51
	 WORD NE52
	 WORD NE53
	 WORD IRQRESERVED
	 WORD IRQRESERVED
	 WORD IRQAT
	 WORD IRQAR
	 WORD IRQRESERVED
	 WORD PE54
	 WORD PE55
	 WORD PE56
	 WORD NE57

	 WORD IRQT1
	 WORD IRQT2
	 WORD IRQ1
	 WORD IRQ2
	 WORD NMIRQ
	 WORD RESET
	 WORD IRQBRK

	 IFTRUE LASTBYTE.UGT.BAUDOFFSET
	 EXIT
	 ENDIF

	 ENDS
