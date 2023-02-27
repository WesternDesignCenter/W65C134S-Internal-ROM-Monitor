	 STTL 'MONZPEQU.ASM - ZP Equates for the $F000 Monitor'
	 PAGE
*        06-21-1993
	 PAGE0

LOWNIB   EQU $0F
HINIB    EQU $F0
S28BN    EQU 19         16 + 2 FOR ADDR
*                        + 1 FOR CKSUM
XON      EQU $11        DC1/^Q
XOFF     EQU $13        DC3/^S
CNTRLC   EQU $03
CNTRLX   EQU $18


* 65C134 INPUT/OUTPUT ADDRESSES

PD0      EQU $0030
PD1      EQU $0031
PD2      EQU $0032
PDD0     EQU $0034
PDD1     EQU $0035
PDD2     EQU $0036


PD3      EQU $0003


PCS3     EQU $0007      Output pin or Memory SEL


IFR2     EQU $0008
IER2     EQU $0009      IFR2 INTERRUPT ENABLE
T1FLG    EQU $10
T2FLG    EQU $20
IRQ1FLG  EQU $40
IRQ2FLG  EQU $80

TCR1     EQU $000A
TCR2     EQU $000B

T1LL     EQU $000C      TIMER 1 LATCH LOW
T1LH     EQU $000D      TIMER 1 LATCH HIGH
T2LL     EQU $000E      TIMER 2 LATCH LOW
T2LH     EQU $000F      TIMER 2 LATCH HIGH

T1CL     EQU $0010      TIMER 1 COUNTER LOW
T1CH     EQU $0011      TIMER 1 COUNTER HIGH
T2CL     EQU $0012      TIMER 2 COUNTER LOW
T2CH     EQU $0013      TIMER 2 COUNTER HIGH

* RESERVED

BCR      EQU $001B      BUS CNTRL REG
*                       BIT 0-EXTERNAL MEM BUS ENABLE
*                       BIT 1-PORT 44-47 EDGE SENS IRQ
*                       BIT 2-ALWAYS 0
*                       BIT 3-ICE ENABLE=1
*                       BIT 4-PORT 50-53 EDGE SENS IRQ
*                       BIT 5-PORT 54-57 EDGE SENS IRQ
*                       BIT 6-NMI,IRQ1,IRQ2 ENABLE = 1
*                       BIT 7-EXTERNAL $F000-$FFFF = 1
*
PD4      EQU $001C
*                       BIT 7-DATA SET READY NE47 IRQ (INPUT)

PD5      EQU $001D

PD6      EQU $0020
*                       BIT 0-RXD (INPUT)
*                       BIT 1-TXD (OUTPUT)
*                       BIT 2-DATA TERMINAL READY (OUTPUT)
DTR      EQU $04

PDD4     EQU $001E
PDD5     EQU $001F
PDD6     EQU $0021

ACSR     EQU $0022      ACI CONTROL
*                       BIT 0-XMIT PORT ENABLE
*                       BIT 1-XMIT IRQ SOURCE
*                       BIT 2-7/8 BIT DATA
*                       BIT 3-PARITY ENABLE
*                       BIT 4-ODD/EVEN PARITY
*                       BIT 5-RECV ENABLE
*                       BIT 6-SOFTWARE SEMIPHORE
*                       BIT 7-RECV ERROR FLG
SON      EQU $01


ARTD     EQU $0023      ACI XMIT/RECV DATA REG


TALL     EQU $0024      TIMER A LATCH LOW
TALH     EQU $0025
TACL     EQU $0026      TIMER A COUNTER LOW
TACH     EQU $0027

TMLL     EQU $0028      TIMER M LATCH LOW
TMLH     EQU $0029      TIMER M LATCH HIGH
TMCL     EQU $002A      TIMER M COUNTER LOW
TMCH     EQU $002B      TIMER M COUNTER HIGH

IFR1     EQU $002C      INTERRUPT FLG REG 1
IER1     EQU $002D      INTERRUPT ENABLE REG 1

	 PAGE
	 ORG $40

UBRK     DS 2          USER BREAK
UNMI     DS 2          USER NMI VECTOR
UIRQ2    DS 2          USER IRQ VECTOR
UIRQ1    DS 2          USER IRQ VECTOR
UIRQT2   DS 2          USER IRQ TIMER VECTOR
UIRQT1   DS 2          USER IRQ TIMER VECTOR
UNE46    DS 2          USER NE46 VECTOR
UGENIRQ  DS 2          USER GENERAL IRQ VECTORS
UIRQEND  EQU *

UCMDPTR  DS 2          USER COMMAND PROCESSOR
*                       IE 'U'X COMMANDS DEFINED
*                       BY THE USER AND HIS CODE

SINPTR   DS 2          SERIAL INPUT BUFFER START ADDR PTR
SOUTPTR  DS 2          SERIAL OUTPUT BUFFER START ADDR PTR
SINCNT   DS 1          SERIAL INPUT BUFFER SIZE COUNT 3-255
SOUTCNT  DS 1          SERIAL OUTPUT BUFFER SIZE COUNT 3-255

PCL      DS 1          PROGRAM COUNTER LOW
PCH      DS 1          PROGRAM COUNTER HIGH
FLGS     DS 1          CONDITIONAL CODE REG
*                       BIT 0--CARRY BIT
*                       BIT 1--ZERO BIT
*                       BIT 2--INTERRUPT ENABLE BIT
*                       BIT 3--BINARY CODED DECIMAL
*                       BIT 4--BREAK
*                       BIT 5--NU
*                       BIT 6--OVERFLOW
*                       BIT 7--MINUS
ACC      DS 1          TEMP ACC REG
XR       DS 1          TEMP X REG
YREG     DS 1          TEMP Y REG
TMPSP    DS 1          TEMP STACK POINTER
TMPC     DS 1          COUNT DOWN CTR FOR S28
TODCKS   DS 1          IRQ TEMP REG FOR ACC
*                       BEFORE CKING BRK CMD



H100HZ   DS 1          1000HZ NMI

TENTHSEC DS 1          0.1 SEC
SEC      DS 1          SECONDS   0 TO 59
MIN      DS 1          MINUTES   0 TO 59
HR       DS 1          HOURS     0 TO 23
DAY      DS 1          DAY       1 TO 28,29,30,31
MONTH    DS 1          MONTH 1= JAN 12= DEC
YR       DS 1          88
DAYWK    DS 1          DAY OF WEEK 1 = SUNDAY
*                       7 = SATURDAY
DAYLIT   DS 1          DAY LIGHT SAVINGS TIME
*                       BIT 0--ENABLED =1
*                       BIT 1-6 NU
*                       BIT 7--IN PROCESS OF
*                              MODIFYING TOD
DAYLITFLG EQU $01 
DAYLPROG  EQU $80

*                       ALARM VARIABLES
ASEC     DS 1          SECONDS   0 TO 59
AMIN     DS 1          MINUTES   0 TO 59
AHR      DS 1          HOURS     0 TO 23
ADAY     DS 1          DAY       1 TO 28,29,30,31
AMONTH   DS 1          MONTH 1= JAN 12= DEC
AYR      DS 1          88
ADAYWK   DS 1          DAY OF WEEK 1 = SUNDAY
*                       7 = SATURDAY
SFLAG    DS 1          SERIAL RS-232 FLAGS
*                       BIT 0-SERIAL INPUT QUEUE DATA
*                       BIT 1-CONTROL 'C' RECEIVED, FLUSH QUEUE
*                       BIT 2-XON/XOFF CONTROL USED=1
*                       BIT 3-XON/XOFF OR HDW HS SEND OVERFLOW
*                       BIT 4-LAST CNTRL CHAR WAS XON=1 XOFF=0
*                       BIT 5-ECHO ON/OFF FLAG OFF=1
*                       BIT 6-OUTPUT XOFF
*                       BIT 7-OUTPUT XON
SFLG      EQU $01
CFLG      EQU $02
XONOFLG   EQU $04
SNDOVF    EQU $08
LASTXONOF EQU $10
ECHOFF    EQU $20
SXOFFLG   EQU $40
SXONFLG   EQU $80

SOUTINDX  DS 1         INDEX TO OUTPUT SERIAL RS-232C QUEUE
SOUTEND   DS 1         end of output queue
SININDX   DS 1         INDEX TO INPUT SERIAL RS-232C QUEUE
SINEND    DS 1         end of input queue

DISPTYP   DS 1         DISPLAY TYPE AND IF
*                       TOD DISPLAY IS ON
*                       BIT 0-2 TYPE OF DISPLAY
*                       BIT 3-ALARM ENABLE BIT
*                       BIT 4-ALARM INTERRUPT HAPPENED
*                       BIT 5-POWER UP IN PROGRESS FLG
*                       BIT 6-DISPLAY NOT WORKING
*                       BIT 7-TOD ON DISPLAY FLG

ALRMENAB EQU $08        Enable the ALARM function
ALRMIRQ  EQU $10        ALARM INTERRUPT
PUFLG    EQU $20        POWER UP


WRAP     DS 1          $FFFF WRAP AROUND

DIFF     DS 2          EA-SA = DIFF & Y REG HAS HIGH MSB
TMP0     DS 3          START ADDR
TMP2     DS 3
TMP4     DS 2
TMP6     DS 2
ERRORS   DS 1          S28 DOWNLOAD ERROR COUNT
SPEED    DS 1          MAIN XTAL SPEED
*                       0 = 2.000000MHZ
*                       1 = 4.000000MHZ
*                       2 = 2.457600MHZ
*                       3 = 3.686400MHZ
*                       4 = 1.843200MHZ
*                       5 = 4.914   MHZ
 
DEST     EQU TMP2       DESTINATION ADDR
SRCE     EQU TMP0       SOURCE ADDR
TEMP     EQU TMP6

	 ENDS          Ends page 0 declarations
	 APPEND JMP.ASM
