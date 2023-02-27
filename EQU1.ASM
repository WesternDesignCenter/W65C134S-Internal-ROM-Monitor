	 STTL 'EQU1.ASM - PVI I/O RAM REG/FLAGS'
	 PAGE
*        12-05-1989
	 DATA

BTMP0    EQU $7B  
BTMP2    EQU $7E  
BTMP4    EQU $81  
GENREVCT EQU $87        revectoring of general interrupt in BASIC
*                       uses $87 and $88

MONFLGS  EQU $77        DISPLAY TYPE AND IF
*                       TOD DISPLAY IS ON
*                       BIT 0-2 TYPE OF DISPLAY
*                       BIT 3-ALARM ENABLE BIT
*                       BIT 4-ALARM INTERRUPT HAPPENED
*                       BIT 5-POWER UP IN PROGRESS FLG
*                       BIT 6-DISPLAY NOT WORKING
*                       BIT 7-TOD ON DISPLAY FLG
DTYPMSK  EQU $0F        UP TO 8 TYPES OF DISPLAYS    >7=Default

NO_DISPLAY   EQU $40    DISPLAY NOT WORKING
DISP_TOD_FLG EQU $80    DISPLAY TOD


	 PAGE
*         Page 1  Definitions of Variables

*         Locations $100 to $11F are reserved for Aux I/O PWB
         
PAUX7    EQU $100       7 & 8 are Output ONLY Ports
PAUX8    EQU $104
PAUX9    EQU $108       9 & 10 are Input ONLY Ports
PAUX10   EQU $10C       
PAUX11   EQU $111       ACIA Status Port
PAUX12   EQU $114       Centronix Status Reg
*                        Bit 0 = PTRSEL*
*                        Bit 1 = ERROR*
*                        Bit 2 = unused
*                        Bit 3 = PWB Test

*                        Bit 4 = PAPER ALARM
*                        Bit 5 = PTR POWER
*                        Bit 6 = BUSY
*                        Bit 7 = ACK*

PAUXD7   EQU $101       Data Direction Reg
PAUXD8   EQU $105       Data Direction Reg


ACIADATA EQU $110       ACIA Data (in\out) Regs
ACIASTAT EQU $111       ACIA Status Reg
*                        Bit 0 = Parity Error
*                        Bit 1 = Framming Error
*                        Bit 2 = Overrun
*                        Bit 3 = Receive Data Reg Full

*                        Bit 4 = Xmit Data Reg Empty
*                        Bit 5 = DCD = 0
*                        Bit 6 = DSR = 0
*                        Bit 7 = IRQ = 1

ACIACMD  EQU $112       ACIA Command Reg
*                        Bit 0 = DTR = 1
*                        Bit 1 = Receive IRQ = 0
*                        Bit 2&3 = RTS & Xmit Enable
*                         B3 B2   RTS   XMIT   Xmit-IRQ
*                         0  0   off    off     Disabled
*                         0  1    on     on     Enabled
*                         1  0    on     on     Disabled
*                         1  1    on    BRK     Disabled
*                         Bit 4 = Echo = 1 (B2 & B3 must be 0)
*                        Bit 5,6,7
*                         B7 B6 B5   Parity
*                         -  -  0    No Parity
*                         0  0  1    Odd Parity
*                         0  1  1    Even Parity
*                         1  0  1    Mark Parity (no check)
*                         1  1  1    Space Parity (no Check)
ACIAXTRL EQU $113       ACIA Control Reg
*                        Bits 0,1,2,3   Baud Rate Gen
*                         B3 B2 B1 B0
*                         0  0  0  0   16 x External Clock
*                         0  0  0  1     50
*                         0  0  1  0     75
*                         0  0  1  1    110
*                         0  1  0  0    134.5
*                         0  1  0  1    150
*                         0  1  1  0    300
*                         0  1  1  1    600
*                         1  0  0  0   1200
*                         1  0  0  1   1800
*                         1  0  1  0   2400
*                         1  0  1  1   3600
*                         1  1  0  0   4800
*                         1  1  0  1   7200
*                         1  1  1  0   9600
*                         1  1  1  1  19200
*                         Bit 4 = Use Int Baude Rate Gen = 1
*                         Bits 5,6    Word Length
*                         B6 B5
*                         0  0        8
*                         0  1        7
*                         1  0        6
*                         1  1        5
*                         Bit 7 = (1 Stop Bit) = 0
*          $130 to 16F Auxillary F.P. Buffers
	  PAGE
*        Page 2  $200-$2FF



DTMFTMR  EQU $200       DTMF DURATION COUNTER
LOWFCNT  EQU DTMFTMR+1  DTMF DURATION COUNTER

FLAGREG  EQU LOWFCNT+1  MONITOR SET FLAGS
*                       BIT 0--INTERRUPT TIMED OUT
*                       BIT 1--AUX PWB Installed
*                       BIT 2--COR RECEIVED
*                       BIT 3--RING RECEIVED

*                       BIT 4--LOCAL RECEIVED
*                       BIT 5--EXTERNAL IRQ RECEIVED
*                       BIT 6--ON ERROR RECEIVED
*                       BIT 7--NU
INTRFLG  EQU $01
AUXPWB   EQU $02
CORFLG   EQU $04 
RNGFLG   EQU $08 
LCLFLG   EQU $10 
EXTFLG   EQU $20 
ONERRFLG EQU $40 

ENABREG  EQU FLAGREG+1  ENABLE FROM BASIC SOFTWARE
*                       BIT 0--INTERRUPT TIMER ENABLED
*                       BIT 1--NU
*                       BIT 2--COR ENABLE
*                       BIT 3--RING ENABLE
*                        BIT 4--LOCAL ENABLE
*                       BIT 5--EXTERNAL IRQ ENABLE
*                       BIT 6--ON ERROR ENABLE
*                       BIT 7--NU
*
INTREG   EQU ENABREG+1  INTERRUPT IN PROCESS
*                       BIT 0--INTERRUPT TIME PGM IN PROCESS
*                       BIT 1--NU
*                       BIT 2--COR PGM IN PROCESS
*                       BIT 3--RING PGM IN PROCESS
*                        BIT 4--LOCAL PGM IN PROCESS
*                       BIT 5--EXTERNAL IRQ PGM IN PROCESS
*                       BIT 6--ALARM PGM IN PROCESS
*                       BIT 7--NU
ALRMFLG  EQU $40

BASIRQ   EQU INTREG+1   BASIC TIMED INTERRUPT
TBASIRQ  EQU BASIRQ+2   INIT STORAGE FOR BASIRQ

	 ENDS

	 APPEND JMP.ASM
