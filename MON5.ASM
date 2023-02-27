	 STTL 'MON5.ASM - Serial Routines'
	 PAGE
*        06-23-1993
	 CODE

* Routine:  IRQAR
*
* Reg Used: ACC & Y
* Var Used: SFLAG,SINEND
* Routines Called: FLUSH_SERIAL_BUFF
* Returned Reg: NONE
*

*                        CALLED BY IRQ ROUTINE
IRQAR    EQU*           QUEUE UP SERIAL BYTE
         PHA
         PHY
	 LDA ARTD        GET DATA
	 AND #$7F        MAKE ASCII
         BNE RQ5
	 JMP RECDONE     CHK FOR NULL


RQ5      CMP #$19        QUICK CHK FOR CNTRL CHAR
         BCS RQ8
	 CMP #CNTRLC     CHK IF CONTROL 'C'
         BNE RQ6
RECSC0   JSR FLUSH_SERIAL_BUFF  GOT A CONTROL 'C'
         LDA SFLAG
	 AND #$FF-SFLG   CLR CHAR PENDING FLG
	 ORA #CFLG       SO FLUSH QUEUE
         BIT #XONOFLG
         BEQ RECSC1
         ORA #SXONFLG+LASTXONOF
RECSC1   STA SFLAG
         JMP RECDONE



RQ6      CMP #CNTRLX     CHK IF CONTROL 'X'
         BEQ RECSC0
         PHA
         LDA SFLAG
         BIT #XONOFLG
         BEQ RQ7A
         PLA
	 CMP #XOFF       CHK XON/XOFF PROTOC
         BEQ RECSXOFF
         CMP #XON
         BEQ RECSXON
         BRA RQ8

RQ7A     PLA
RQ8      LDY SININDX     GET CURRENT PTR
         INY
	 CPY SINEND      IS BUFF FULL
         BNE RQ9
         PHA
         LDA SINEND
	 INC A           REMOVE OLDEST CHAR
         CMP SINCNT
         BNE RQ8A
         LDA #$00
RQ8A     STA SINEND
         PLA
RQ9      CPY SINCNT      GET SIZE OF QUEUE
	 BCC RECS11      CK FOR WRAP AROUND
	 LDY #0          WRAP AROUND
RECS11   STY SININDX
	 STA (SINPTR),Y  SAVE DATA IN QUE
         LDA #SFLG
         TSB SFLAG
	 INY             IS BUFF ALMOST FULL?
         INY
         INY
         INY
         INY

	 CPY SINCNT      GET SIZE OF QUEUE
         BCC RQ0
         TYA
         SEC
         SBC SINCNT
         TAY
RQ0      CPY SINEND      We'll kill buffer control if IN+5 = END
	 BNE RECDONE     branch if we haven't hit the stop point
      
RQ1      EQU*
	 LDA SFLAG       XON/XOFF OR DTR?
         BIT #XONOFLG
         BEQ SNDXOFFHW
         BIT #LASTXONOF
	 BEQ RECDONE     ALREADY SENT XOFF
	 AND #$FF-LASTXONOF    SEND XOFF NXT XMIT IRQ
	 ORA #SXOFFLG    XON/XOFF HS
         STA SFLAG
         BRA RECDONET

SNDXOFFHW EQU*
	 LDA #DTR        SETUP HW HS
	 TSB PD6         DTR HIGH
	 BRA RECDONE     HOLD OFF FURTHER XMISSION


RECSXOFF LDA #SNDOVF     OVERRUNNING OTHER GUYS
	 TSB SFLAG       SERIAL INPUT BUFFER SO
         BRA RECDONE


RECSXON  LDA #SNDOVF     OVERFLOW ON XMIT OVER
         TRB SFLAG

RECDONET LDA ACSR        TURN ON SERIAL XMIT
         ORA #$03
         STA ACSR

RECDONE  PLY             RECEIVE IRQ DONE
         PLA
         RTI
	 PAGE

* Routine:  IRQAT
*
* Reg Used: ACC & Y
* Var Used: SFLAG,SOUTINDX
* Routines Called: NONE
* Returned Reg: NONE
*
*                        CALLED BY IRQ ROUTINE
IRQAT    EQU*           DEQUEUE SERIAL BYTE
	 PHA             FROM OUTPUT BUFFER
	 PHY             SEE OUTCH ROUTINE
	 LDA SFLAG       CK IF WE ARE OVERFLOWING
         AND #SXOFFLG+SXONFLG
	 BEQ SQ0A        QUICK CK FOR CNTRL FLGS
         CMP #SXOFFLG+SXONFLG
         BEQ IRQATERR
         BIT #SXOFFLG
	 BNE SNDXOFF     SEND XOFF
SNDXON   LDA #SXONFLG
         TRB SFLAG
         LDA #XON
         BRA SQ1


SNDXOFF  EQU*
         LDA #SXOFFLG+LASTXONOF
         TRB SFLAG
         LDA #XOFF
         BRA SQ1

IRQATERR LDA #SXONFLG+SXOFFLG
         TRB SFLAG
SQ0A     LDA ACSR
	 AND #$02              XMIT IRQ ON
         BNE XIRQ1
XIRQ2    LDY SOUTINDX    IS BUFFER NOW EMPTY
         CPY SOUTEND
         BNE XIRQ3
	 LDA ACSR        DISABLE SERIAL XMIT
	 AND #$02        EVERYTHING IS OUT OF
         BNE SQ3A
         LDA #00
         BRA SQ1

XIRQ1    LDA SFLAG
         BIT #XONOFLG
         BNE XIRQ1A
	 LDA PD4          DSR = P47
         BMI SQ3A
         BRA XIRQ2

XIRQ1A   BIT #SNDOVF
         BEQ XIRQ2
         BRA SQ3A

XIRQ3    INY
	 CPY SOUTCNT     GET SIZE OF QUEUE
         BCC SQ0
         LDY #0
SQ0      STY SOUTINDX
	 LDA (SOUTPTR),Y  GET DATA FROM QUEUE
SQ1      STA ARTD        SEND DATA
         LDA SFLAG
         BIT #XONOFLG
         BNE SQ2
         LDA PD4
	 BMI SQ3         P47 HI     DSR TEST
SQ2      LDA SFLAG
         BIT #SNDOVF
         BNE SQ3
         LDY SOUTINDX
	 CPY SOUTEND     IS BUFF EMPTY
         BEQ SQ3
         LDA ACSR
         AND #$FC
         ORA #SON
         STA ACSR
         BRA RECDONE

SQ3A     LDA #$02        set the output high to prevent falsing
	 TSB PD6         when we shut it off.
	 LDA #$03        NO MORE CHAR
	 TRB ACSR        turn ACSR off
         JMP RECDONE

SQ3      LDA #$03        TURN ON XMIT & RECV
         TSB ACSR
         JMP RECDONE

	 PAGE 'HARDWARE HANDSHAKE'


NE47     PHA             HARDWARE HS INPUT
	 LDA #$08        DSR
	 TSB IFR1        RESET IRQ
         LDA SFLAG
         BIT #XONOFLG
	 BNE NE47A       XON/XOFF MODE
         LDA ACSR
         ORA #SON+$02
         STA ACSR
         BRA NE47B

NE47A    LDA #$08        DISABLE NE47 IRQS
	 TRB IER1        SHOULD BE IN XON/XOFF MODE
NE47B    PLA
         RTI



* SERIAL WRITES


* Routine:  WR_ADDR
*
* Reg Used: ACC & X
* Var Used: TMPC,TMP0
* Routines Called: WROB,BINASC,WRTWO
* Returned Reg: NONE                  X & Y REG are PRESERVED
*

WR_ADDR  STA TMP0        WRITE ADDRESS IN TMP0
         STX TMP0+1
*                        WRITE ADDR FROM TMP0
WROA     LDX #1          DISPLAY TMP0
         BRA WROA1

WROA4    LDX #TMP4-TMP0+1 
	 BRA WROA1       USUALLY CHKSUM

WRPC     LDX #PCL-TMP0+1  DISPLAY PROGRAM CTR
WROA1    LDA TMP0-1,X
         PHA
         LDA TMP0,X
         JSR WROB
	 BCS WRTWORTS    GOT A CNTRL 'C'
         PLA

WROB     PHX             WRITE BYTE AS 2 HEX CHAR
	 JSR BINASC      UNPACK BYTE DATA INTO
*                        TWO ASCII CHARS.
	 JSR WRTWO       X,A=CHARS
         PLX
         RTS


CRLF     LDA #$0D        OUTPUT CR WITH AUTO LF
         BRA OUTCH

WRTWO    PHA             WRITE 2 CHARS-X,A=CHARS
	 TXA             WRITE X FIRST
         JSR OUTCH
         BCS WRTWORTS
         PLA
         BRA OUTCH

WRTWORTS PLA             GOT A CNTRL 'C'
SPACRTS  RTS


* Routine:  SPAC2
*
* Reg Used: ACC
* Var Used: NONE
* Routines Called: SPAC
* Returned Reg: Acc X & Y REG are PRESERVED
*


SPAC2    JSR SPAC
	 BCS SPACRTS     GOT ^C
SPAC     PHA
         LDA #' '
         JSR OUTCH
         PLA
         RTS


* Routine:  OUTCH
*
* Reg Used: Acc & Y
* Var Used: SOUTEND
* Routines Called: NONE
* Returned Reg: Acc                     X & Y REG are PRESERVED
*


OUTCH    EQU*           PLACE CHAR IN OUTPUT
	 PHA             QUEUE
	 PHY             SAVE YREG
         PHA
OUTCH1   LDY SOUTEND     CK IF CURRENT QUEUE POS
	 INY             POINT TO NXT DATA
	 CPY SOUTCNT     DO WE WRAP
	 BCC SNDSD2      NO
	 LDY #0          WE WRAPPED
SNDSD2   CPY SOUTINDX    DID WE OVERRUN QUEUE
	 BEQ OUTCH1      YES, SO WAIT

	 LDA SFLAG       CK FOR CNTRL 'C'
         BIT #CFLG
	 BNE OUTCH3      GOT CNTRL 'C'
         SEI

         STY SOUTEND
	 PLA             GET DATA
	 STA (SOUTPTR),Y  PUT DATA IN QUEUE
	 LDA SFLAG       CK IF HWHS OR SOFTWARE HS
         BIT #XONOFLG
	 BNE SNDOUT1     SW HS ON
	 LDA PD4         CK IF WE ARE TO HOLD OFF
	 BMI OUTCH2      DONT TURN ON SERIAL IRQS
         BRA SNDOUT2

SNDOUT1  BIT #SNDOVF     CHK FOR SW HS
	 BNE OUTCH2      HAVE A XOFF SO DONT XMIT

SNDOUT2  LDA ACSR
	 BIT #SON        IS SERIAL IRQ ON
	 BEQ OUTCH1A     NO
	 BIT #$02        ARE WE IN FAST SERIAL
	 BEQ OUTCH2      MODE--YES
	 AND #$FF-$02    GOTO FAST SERIAL MODE
         BRA OUTCH1B

OUTCH1A  ORA #SON+$02    SERIAL IRQ SINGLE CHR MODE
OUTCH1B  STA ACSR
OUTCH2   CLI
         PLY
         PLA
         CLC
         RTS

OUTCH3   PLA             RESTORE STK ON CNTRL 'C'
         PLY
         PLA
         SEC
         RTS


* Routine:  BINASC
*
* Reg Used: Acc & X
* Var Used: NONE
* Routines Called: ASCII
* Returned Reg: Acc & X           Y REG is PRESERVED
*

BINASC   PHA             CONVERT BYTE TO 2
	 LSR A           ASCII CHAR
         LSR A
         LSR A
         LSR A
	 JSR ASCII       CONVERT TO ASCII
         TAX
         PLA
         AND #LOWNIB
*                        FALL THRU TO ASCII
ASCII    CLC
         ADC #6
         ADC #HINIB
         BCC ASC1
         ADC #$06
ASC1     ADC #'9'+1      GT '9'
         RTS

	 PAGE

* Routine:  GETCH
*
* Reg Used: Acc
* Var Used: NONE
* Routines Called: RD_CHAR,OUTCH
* Returned Reg: Acc               X & Y REG are PRESERVED
*

GETCH    JSR RD_CHAR     WAIT UNTIL WE GET A CHAR
	 BCS GETC4       HAD ^C,SO ERROR
         CMP #$00
	 BEQ GETCH       WAIT FOR INPUT
	 PHA             SAVE DATA
	 LDA SFLAG       CHK IF ECHO
         AND #ECHOFF
         BNE GETC3
         PLA
	 CMP #$0A        LINE FEED
         BEQ GETC3A
	 JMP OUTCH       ECHO BACK INPUT
*                        CY SET SO ERROR

GETC3    PLA
GETC3A   CLC
         RTS

GETC4    LDA #3          %rev  SEND ^C TO CALLER
         RTS




* Routine:  RD_CHAR
*
* Reg Used: ACC & Y
* Var Used: SINEND,SFLAG
* Routines Called: CK_CONTC
* Returned Reg: Acc             X & Y REG are PRESERVED
*


RD_CHAR  EQU*           CHK FOR CHARACTER
	 LDA SFLAG       GET SERIAL BYTE
	 AND #SFLG+CFLG  FROM INPUT QUEUE
         BEQ RD_CH0
         PHY
	 SEI             PUT THERE BY RECSBYTE
	 LDY SINEND      CK IF CURRENT QUEUE POS
	 INY             POINT TO NXT DATA
	 CPY SINCNT      DO WE WRAP
         BCC GETSD4
	 LDY #0          WE WRAPPED
GETSD4   JSR CK_CONTC    RESET ^C FLAG
	 BCS RD_CH2      HAD ^C
         STY SINEND
	 LDA (SINPTR),Y  GET DATA
         PHA
	 CPY SININDX     IS SAME AS END OF QUEUE
         BNE GETSD3

	 LDA SFLAG       CK IF XON/XOFF
	 BIT #XONOFLG    OR HARDWARE HS
         BEQ GETSD1
	 BIT #LASTXONOF  HAS XON ALREADY BEEN SENT?
         BNE GETSD2
         LDA #SXONFLG+LASTXONOF 
         TSB SFLAG
         LDA ACSR
         BIT #SON
         BNE GETSD2
         ORA #SON+$02
         STA ACSR
         BRA GETSD2

GETSD1   EQU*           HANDLE HARDWARE HS
	 LDA #DTR        DTR LOW, OK FOR
	 TRB PD6         OTHER GUY TO SEND
GETSD2   LDA #SFLG       NO MORE SERIAL CHARS
         TRB SFLAG
GETSD3   PLA             GET DATA
         CLI
         PLY
RD_CH0   CLC             NO DATA RETURN NULL
         RTS

RD_CH2   CLI             NG ^C, RETURN NULL
	 PLY             AND CY = 1
         RTS


* Routine:  CK_CONTC
*
* Reg Used: Acc
* Var Used: SFLAG
* Routines Called: NONE
* Returned Reg: Acc
*

CK_CONTC EQU*           CHK  FOR CONTROL "C"
         LDA #CFLG
         TRB SFLAG
	 BEQ RD_CH0      CLR CY NOT ^C
	 SEC             FOUND CNTRL 'C'
         RTS


*  READ HEX ADR, RETURN HO IN TMP0,
*  LO IN TMP0+1 AND CY=1
*  IF SPACE,CR, OR COMMA CY=0


* Routine:  RDOA
*
* Reg Used: Acc
* Var Used: TMP0
* Routines Called: RDOB
* Returned Reg: Acc
*

RDOA     STZ TMP0        CLR ADDRESS SO ALL ZEROS
         STZ TMP0+1
	 JSR RDOB        READ 2 CHAR BYTE
	 BCC RDOA2A      SPACE,CR OR COMMA

         STA TMP0+1
	 JSR RDOB        NO NEED TO CK FOR
         BCC RDOA2
	 STA TMP0        DELIMETER JUST SAVE
	 CLC             C is clear if addr is OK
         RTS

RDOA2A   JSR SPAC2
RDOA2    STA TMP0
         STZ TMP0+1
	 SEC             carry set if Addr = 0
         RTS


*  READ HEX BYTE AND RETURN IN A, AND CY=1
*  IF SPACE,CR OR COMMA CY=0

* Routine:  RDOB
*
* Reg Used: ACC & X
* Var Used: TMP0
* Routines Called: GETCH,ASCBIN
* Returned Reg: Acc             X & Y REGS are PRESERVED
*

RDOB     PHX             SAVE X
         JSR GETCH
	 BCS RDOB4       CNTRL 'C'
	 CMP #$0D        CR?
         BNE RDOB1

RDCR     JMP START       start resets stack to last BRK position

RDOB1    CMP #' '        CHK FOR SPACE
         BEQ RDOB1A
	 CMP #','        CHK FOR COMMA
         BNE RDOB2
RDOB1A   JSR SPAC        keep command line spacing constant
	 LDX #'0'        FILL WITH ZEREOS
*                        BOTH Acc & X REG NEED DATA IE '00'
	 BRA RDOB2A      PROCESS ALL ZEROS


RDOB2    TAX             SAVE 1ST CHAR IN X REG
	 JSR GETCH       READ NEXT CHAR
	 BCS RDOB4       ctrl-C OR ctrl-X
	 CMP #$0D        CR?
         BEQ RDCR
	 CMP #','        CK FOR COMMA DELIMITER
         BEQ RDOB2A
	 CMP #' '        SPACE DELIMETER
         BNE RDOB3
RDOB2A   LDA #'0'
	 JSR ASCBIN      PROCESS ALL ZEROS
         CLC
         BRA RDOB4

RDOB3    JSR ASCBIN
	 SEC             CY=1
RDOB4    PLX             RESTORE X
         RTS


* Routine:  ASCBIN  ASCII TO BINARY
*
* Reg Used: ACC,X, and Y
* Var Used: TMP6
* Routines Called: HEXIN
* Returned Reg: Acc & X
*
ASCBIN   JSR HEXIN       ACC & X REG HAVE DATA
*                        1ST CHAR IN X REG
         PHP
         PHY
	 SEI             DISABLE INTR SO WE CAN
	 LDY TMP6        save TMP6 in Y
	 STA TMP6        USE VAR TMP6 AS TMP STORAGE
         TXA
         JSR HEXIN
         ASL A
         ASL A
         ASL A
         ASL A
         ORA TMP6
	 STY TMP6        restore TMP6
         PLY
         PLP
         RTS


	 PAGE

* Routine:  ACI_INIT
*
* Reg Used: ACC,Y,X
* Var Used: SOUTINDX,SOUTEND,SININDX,SINEND,ERRORS,SFLAG,TMP6,
* Routines Called: FLUSH_SERIAL_BUFF
* Returned Reg: NONE
*
*       Baud Rates          | For even parity, Y = 03
*                           | For Odd parity,  Y = 01
* 0     75 BAUD             | No parity, Y = 00 or 02
* 1    110 BAUD             |
* 2    150 BAUD             |
* 3    300 BAUD             | Data length in X is either
* 4    600 BAUD             | 8 for 8 bits, or anything
* 5   1200 BAUD             | else for 7 bits.
* 6   1800 BAUD             |
* 7   2400 BAUD             |
* 8   4800 BAUD             |
* 9   9600 BAUD             |
* A  19200 BAUD             |
* B  38400 BAUD             |



ACI_INIT EQU*           A=BAUD,X=DATA LENGTH,
*                        SETUP POINTERS
	 PHP             SAVE INTERUPT STATUS
	 SEI             DISABLE ANY IRQ'S
         JSR FLUSH_SERIAL_BUFF
         STZ SFLAG
	 STZ ERRORS      CLR SERIAL ERROR COUNT
	 PHY             Y=PARITY
	 PHX             DATA LENGTH
	 CMP #$0C        IS ACC VALID 75-38400
         BCS ACI_ERR
	 ASL A           X2
         STA TMP6
	 LDY SPEED       MULT BY 11 FOR MAIN XTAL
         LDA BAUDOFFSET,Y
         CLC
         ADC TMP6
         TAX
	 LDA ACIBAUD,X   SETUP COUNTERS
         STA TALL
         LDA ACIBAUD+1,X
         STA TALH
	 LDA #$20        rev 2  Enable Receive - 7 Bit
         PLX
	 CPX #$08        8 BIT?
         BNE ACI_I1
	 ORA #$04        SWITCH TO 8 BIT
ACI_I1   STA TMP6
	 PLA             GET PARITY WAS IN Y REG
         ROL A
         ROL A
         ROL A
         ORA TMP6
         STA ACSR
         JSR SIOPORTS
         PLP
         LDA #$00
         RTS



SIOPORTS LDA #$06        SET P62 RXD AS OUTPUT
	 TSB PDD6        AND TXD
         LDA #$01
	 TRB PDD6        SET RXD AS INPUT
	 LDA #$02        SET TXD TO DEFAULT MARK
	 TSB PD6         TELL OTHER GUY TO XMIT
	 LDA #$04        SERIAL DATA TO ME
         TRB PD6
	 LDA #$80        P47 AS INPUT
	 TRB PDD4        SETUP PORTS
	 LDA #$08        ENABLE NE47
         TSB IER1
	 LDA #$02        SET PORT 44-47
	 TSB BCR         ENABLED
	 LDA #$0E        SETUP SERIAL IRQS
         STA TCR1
	 STZ ARTD        SET DATA TO NULL
         RTS


FLUSH_SERIAL_BUFF EQU*  ARTD ERROR
	 STZ SOUTINDX    SETUP QUEUE COUNTERS TO ZERO
	 STZ SOUTEND     IE FLUSH ALL SERIAL QUEUES
         STZ SININDX
         STZ SINEND
         RTS



ACI_ERR  EQU*
         PLX
         PLY
	 LDA #DTR        TELL OTHER GUY TO XMIT
	 TRB PD6         SERIAL DATA TO ME
         PLP
         LDA #$FF
         RTS


	 PAGE

* Routine:  TGLXONMODE
*
* Reg Used: ACC,Y,X
* Var Used: TMPC,TMP0
* Routines Called: REGTTL,WRPC,SETR,SPAC,WROB
* Returned Reg: NONE
*


TGLXONMODE EQU*         TOGGLE SERIAL XON/XOFF MODE
         SEI
         LDA SFLAG
         EOR #XONOFLG
         BIT #XONOFLG
         BEQ TGLXONA
         AND #$FF-SXOFFLG-SNDOVF
         ORA #SXONFLG+LASTXONOF
         STA SFLAG
	 LDA #$08        DISABLE NE47
         TRB IER1
         BRA TGLXONB

TGLXONA  AND #$FF-SXONFLG-SXOFFLG-SNDOVF-LASTXONOF
         STA SFLAG
	 LDA #$08        ENABLE NE47
         TSB IER1
TGLXONB  LDA #$04        DTR LOW
         TRB PD6
         CLI
         RTS

	 ENDS

	 APPEND MON6.ASM
