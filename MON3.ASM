	 STTL 'MON3.ASM - Monitor BRK/Command Handler'
	 PAGE
*        06-23-1993
	 CODE

START    LDX TMPSP       reset the SP to what it was when we hit the BRK
         TXS
	 LDA #ECHOFF     TURN ON ECHO MODE
         TRB SFLAG
	 JSR CK_CONTC    CHECK & CLR CONTROL C
	 STZ WRAP        indicates we are past $FFFF
S000     JSR CRLF
	 LDA #'.'        TYPE PROMPTING '.'
         JSR OUTCH
         BCS START
S00      JSR GETCH
         BCS START

*        Raw character is in A.  May be wrong case, etc.  We will JSR to
*        alt. parsing if it exists at this point.  The alternate parser
*        will jump through the vector table to START if it completes the
*        command, and will do an RTS to the regular parser if it does not
*        have the command in its table.

S0       LDX $EFFD       This location has a JMP to an external parser
	 CPX #$4C        if an alternate parser exists
         BNE DFLTPRSR

	 JSR $EFFD       do the JSR to alternate parser
*                        and then continue to do our standard parsing

DFLTPRSR CMP #$0A
	 BEQ S00         IGNORE LF
	 JSR UPPER_CASE  IN ACC/ MAKE SURE
*                        UPPERCASE
	 LDX #ADRS-CMDS-1      LENGTH OF CMD TABLE
S1       CMP CMDS,X
         BNE S2
         TXA
	 ASL A           X2
         TAX
	 CPX #TWOSCMD-ADRS     IF :, M,<, >,SPACE
	 BCS IJMP         SPACE 2
         JSR SPAC2
IJMP     JMP (ADRS,X)

S2       DEX
	 BPL S1          LOOP FOR ALL CMDS

ERROPR   LDA #'?'        OPERATOR ERR, TYPE'?'
	 JSR OUTCH
	 BRA S000        send out a "." and try again

UCMD     JSR UCMD1
         BRA START

	 PAGE


* SINGLE LETTER COMMANDS USED ARE:
* A,B,C,D,E,F,G,H,J,K
* M,R,S,T,U,V,W,X
* <,>, ,?,/

CMDS     BYTE 'A'       ALTER REGISTERS
	 BYTE 'M'       CHANGE A MEMORY LOC
	 BYTE '<'       DEC TO NXT MEMORY LOC
	 BYTE '>'       INC TO NXT MEMORY LOC
	 BYTE ' '       REDISPLAY OLD LOCATION
	 BYTE 'R'       DISPLAY REGISTERS
	 BYTE 'G'       GO/JMP
	 BYTE 'J'       JSR
	 BYTE 'D'       DUMP MEMORY IN HEX
	 BYTE 'F'       FILL MEMORY
	 BYTE 'C'       CHECK SUM
	 BYTE 'V'       MOVE A BLOCK
	 BYTE '?'       HELP MENU
	 BYTE 'H'       HELP MENU
	 BYTE 'T'       DISPLAY TIME
	 BYTE 'X'       TOGGLE XON/XOFF MODE
	 BYTE 'S'       S28 LOADER FROM MONITOR
	 BYTE 'W'       S28 DUMPER
	 BYTE 'E'       PRINT ERRORS
	 BYTE 'U'       USER DEFINED COMMANDS
	 BYTE 'B'       BASIC COLD START
	 BYTE 'K'       BASIC WARM START & CONTINUE
	 BYTE '/'       QUICK ACCESS TO MEM FOR HOSTS

ADRS     WORD ALTER     CHANGE CURRENT REGS
	 WORD ALTERM    ALTER A MEMORY LOC
	 WORD DSPLYDEC  DEC ADDR & DISPLAY
	 WORD DSPLYINC  INC ADDR & DISPLAY
	 WORD DSPLYOLD  DISPLAY CURRENT ADDR

TWOSCMD  EQU *           END OF AREA NEEDING
*                        TWO (2) SPACES
	 WORD DSPLYR    DISPLAY REGS
	 WORD GO        GOTO/JMP
	 WORD GOJSR     JSR/JUMP TO SUBROUTINE
	 WORD WM        DUMP MEMORY IN HEX
	 WORD FILL      FILL MEMORY WITH A CONSTANT
	 WORD CHKSUM    CALC CHECK SUM
	 WORD MOVE      MOVE A BLOCK OF UP TO 256 BYTES
	 WORD HELP      HELP MENU
	 WORD HELP      HELP MENU
	 WORD DTIME     DISPLAY TIME OF DAY
	 WORD TGLXONXOFF  TOGGLE SERIAL XON/XOFF MODEF
	 WORD LSS       MOTOROLA S28 LOADER FROM MONITOR
	 WORD WO        MOTOROLA S28 DUMP
	 WORD PERR      PRINT ERRORS
	 WORD UCMD      USER DEFINED CMDS
	 WORD CBASIC    COLD START FOR BASIC
	 WORD KBASIC    WARM START BASIC & CONTINUE
	 WORD SLASH     HOST MEMORY ACCESS



UCMD1    JMP (|UCMDPTR)   GOTO USER COMMANDS


CBASIC   LDA $A000       CK TO SEE IF BASIC THERE
         CMP #$4C
         BEQ CBAS1
         JMP START

CBAS1    LDA #>$A000
         STA PCH
         LDA #<$A000
         BRA GBAS


KBASIC   LDA $A003       CK TO SEE IF BASIC THERE
         CMP #$4C
         BEQ KBAS1
         JMP START

KBAS1    LDA #>$A003
         STA PCH
         LDA #<$A003
GBAS     STA PCL
         JMP GO1

	 STTL 'MON3.ASM - Commands, Display Registers'
	 PAGE


 * Routine:  DSPLYR  DISPLAY REG CMD -PC,F,A,X,Y, and SP
 *
 * Reg Used: ACC,Y,X
 * Var Used: TMPC,TMP0
 * Routines Called: REGTTL,WRPC,SETR,SPAC,WROB
 * Returned Reg: NONE
 *

DSPLYR   JSR REGTTL
	 JSR WRPC        WRITE Program Counter
         JSR SETR
         STA TMPC
         LDY #0
R1       JSR SPAC
	 LDA (TMP0),Y    DISPLAY 5 REGS
         JSR WROB
         INY
         DEC TMPC
         BNE R1
M1       JMP START


REGTTL   LDA #>REGSTR
         LDX #<REGSTR
         LDY #REGSEND-REGSTR
         JMP PRTSTR


REGSTR   BYTE $0D,'ADDR F  A  X  Y  SP',$0D
REGSEND  

* Routine:  ALTERM
*
* Reg Used: ACC,Y,X
* Var Used: TMP0
* Routines Called: RDOA,SPAC,BYTE
* Returned Reg: NONE
*

ALTERM   JSR RDOA        READ MEM ADDR INTO TMP0
	 BCS M1          ERR IF NO ADDR

         LDA TMP0+1
	 PHA              push the starting address  we'll need it later
	 LDA TMP0        Display 16 bytes starting at given address
         PHA
         CLC
         ADC #15
         STA TMP2
         LDA #0
         ADC TMP0+1
         STA TMP2+1
	 JSR WRROUT      this routine messes up the starting address

         PLA
	 STA TMP0        bring back the starting address
         PLA
         STA TMP0+1
KKLLPP1  JSR CRLF
         JSR WROA
	 JSR SPAC2       2 spaces
	 JSR SPAC        and one more
         LDA #16
         STA TMPC

M0       EQU*
         JSR BYTE
	 BCC M001        branch if we read back what we wrote
	 PHP             save EQU flag status
*                        this is used because there are some periphals
*                        that we CANT read back, so we want to continue
	 LDA #'?'        indicate an error
	 JSR OUTCH       by replacing the space with a '?'
	 PLP             replace EQU flag from BYTE sub.
M001     BEQ KKLLPP1     branch if we have done 16
	 BCS M0          we had a write error - no space needed
	 JSR SPAC        output a space if we are on same line and no error
         BRA M0
         


DSPLYINC EQU*           INC DISPLAY MEM
         JSR INCTMP
         BRA DSPLYOLD


DSPLYDEC EQU*           DEC DISPLAY MEM
         LDA TMP0
         PHP
         DEC TMP0
         PLP
	 BNE DSPLYOLD    REDISPLAY MEM
         DEC TMP0+1
DSPLYOLD JSR WROA
         JSR SPAC
         LDA (TMP0)
         JSR WROB
         JSR SPAC2
         LDA (TMP0)
         AND #$7F
	 JSR IFASC       CK IF ASCII DATA
	 BCC OLD1        YES ,ASCII
	 LDA #'.'        NOT ASCII SO '.'
OLD1     JSR OUTCH       OUTPUT ASCII
         JMP START


DCMP     EQU*
	 SEC             TMP2-TMP0 DBL SUBTRACT
         LDA TMP2
         SBC TMP0
         STA DIFF
         LDA TMP2+1
         SBC TMP0+1
         TAY
	 ORA DIFF        OR LO FOR EQU TEST
         RTS


PUTP     EQU*
	 LDA TMP0        MOVE TMP0 TO PCH,PCL
         STA PCL
         LDA TMP0+1
         STA PCH
         RTS



* Routine:  BYTE
*  READ AND STORE BYTE.
*  NO STORE IF SPACE OR TMPC=0.
* Reg Used: ACC,Y,X
* Var Used: TMPC,TMP0
* Routines Called: RDOB,DADD,INCTMP
* Returned Reg: NONE
*

BYTE     EQU*
	 JSR RDOB        CHAR IN A, CY=0 IF
	 BCC BY3         SPACE,CR, OR COMMA
	 STA (TMP0)      STORE BYTE
	 CMP (TMP0)      TEST FOR VALID WRITE
         BEQ BY2
	 JSR INCTMP      increment the address
         DEC TMPC
         SEC
         RTS


BY2      JSR DADD        INCR CKSUM
BY3      JSR INCTMP      GO INCR TMP0 ADR
         DEC TMPC
         CLC
         RTS


SETR     EQU*
	 LDA #<FLGS      SET TO ACCESS REGS
         STA TMP0
	 STZ TMP0+1      WE KNOW ITS IN PAGE ZERO
         LDA #5
         RTS
	 STTL 'MON3.ASM - Commands, Alter registers/memory'
	 PAGE


* Routine:  ALTER
*   ALTER LAST DISPLAYED ITEM (ADDR IN TMP0)
*   TO END ENTERING DATA PRESS CR
* Reg Used: ACC,Y,X
* Var Used: TMPC,TMP0
* Routines Called: RDOB,DADD,INCTMP
* Returned Reg: NONE
*

ALTER    EQU*
	 JSR REGTTL      DISPLAY REGISTER HEADER
         JSR RDOA
	 BCS A2          GOT SPACE, CR OR COMMA SO SKIP MODIFYING PC
	 JSR PUTP        ALTER PC
A2       EQU*
*         CMP #CR         CHK IF CR IF SO END
*         BEQ A6
	 JSR SETR        POINT TO ALTER REGS &
	 STA TMPC        SAVE BYTE COUNT
A5       EQU*
	 JSR SPAC        PRESERVES Y
         JSR BYTE
	 BNE A5          NOT A CR YET, SO DO NEXT REGISTER
A6       JMP START


	 STTL 'MON3.ASM - Commands, JMP ---GO TO address'
	 PAGE

* Routine:  GO
*
* Reg Used: ACC,Y,X
* Var Used: TMP0,SININDX,SINEND,SOUTINDX,SOUTEND
* Routines Called: GOADDR,FLUSH_SERIAL_BUFF,SPAC,PUTP,RDOB
* Returned Reg: NONE
*

GO       EQU*
	 JSR GOADDR      GET ADDRESS
*                        if we got a BAD ADDR OR CR,so use OLD address
GO1      JSR FLUSH_SERIAL_BUFF   FLUSH SERIAL QUEUE
         LDX TMPSP
	 TXS             ORIG OR NEW SP VALUE TO SP
GO2      LDA PCH
	 PHA             SAVE ON STACK
         LDA PCL
         PHA
         LDA FLGS
         PHA
         LDA ACC
         LDX XR
         LDY YREG
         RTI


* Routine:  GOJSR
*
* Reg Used: ACC,Y,X
* Var Used: TMP0,SININDX,SINEND,SOUTINDX,SOUTEND
* Routines Called: GOADDR,FLUSH_SERIAL_BUFF,SPAC,PUTP,RDOB
* Returned Reg: NONE
*

GOJSR    EQU*           GO TO A JSR
	 JSR GOADDR      GET ADDRESS
*                        if we got a BAD ADDR OR CR,so use OLD address
	 JSR FLUSH_SERIAL_BUFF  FLUSH SERIAL QUEUE
         LDX TMPSP
	 TXS             ORIG OR NEW SP VALUE TO SP
	 LDA #>START-1   PLACE RETURN ADDRESS ON STACK
	 PHA             IE START OF MONITOR
         LDA #<START-1
         PHA
         BRA GO2

GOADDR   EQU*           GET GO/JMP/JSR ADDRESS
         JSR SPAC
	 JSR RDOA        GET ADDRESS
	 BCS GOAD        USE OLD ADDR, because probably a CR
*                        ( cy is SET on CR, SPACE, OR COMMA)
	 JSR PUTP        SET UP NEW ADDR
GOAD     RTS


	 STTL 'MON3.ASM - Commands, Display Memory'
	 PAGE

* HEX MEMORY DUMP ROUTINE
* Routine:  WM
*
* Reg Used: ACC,Y,X
* Var Used: TMPC,TMP0,TMP2,TMP4,TMP6,DIFF,
* Routines Called: RD_SAEA,PRTSTR,WROB,SPAC,
*                  SPAC2,BY3,IFASC,OUTCH,DCMP
* Returned Reg: NONE
*

WM       JSR RD_SAEA
         JSR WRROUT
         JMP START

WRROUT   LDA TMP0         This subroutine displays memory from
	 PHA              TMP0 to TMP2
         LDY TMP0+1
         PHY
         PHA
         LDA #>DUMPSTR
         LDX #<DUMPSTR
         LDY #DUMPEND-DUMPSTR
         JSR PRTSTR
         LDY #16
         PLA
         AND #LOWNIB
WRX1     PHA
         JSR WROB
         JSR SPAC
         PLA
         INC A
         DEY
         BNE WRX1
         PLA
         STA TMP0+1
         PLA
         STA TMP0

WM0      LDX WRAP
         BNE WMX
	 JSR CRLF        NEW LINE
         BCS MD1
	 JSR WROA        PRINT ADDR
         BCS MD1
	 LDX #16         BYTES PER LINE
         STX TMPC
	 JSR DCMP        EA-SA  DIFF IN DIFF & Y

	 TYA             Y REG = MSD
         BNE WM1
	 LDA DIFF        LSB of difference
	 CMP #15         full line of display
         BCS WM1
	 STA TMPC        SHORT LINE
         INC TMPC
WM1      JSR SPAC2
         CLC
MD1      LDA TMP0        SAVE POINTERS TO
	 STA TMP6        DO ASCII
         LDA TMP0+1
         STA TMP6+1
         LDA TMPC
         STA TMP4

WM2      JSR SPAC
	 LDA (TMP0)      DATA
	 JSR WROB        TWO HEX BYTES
         BCS WMX
	 JSR BY3         UP ADDR
         BNE WM2

         JSR SPAC2
         BCS WMX
         JSR SPAC2
         BCS WMX
	 LDA TMP6        RESTORE POINTERS
         STA TMP0
         LDA TMP6+1
         STA TMP0+1
         LDA TMP4
         STA TMPC
LISTS2   LDA (TMP0)      DATA
	 AND #$7F        MASK
	 JSR IFASC       CK IF ASCII DATA
	 BCC LISTS3      YES ,ASCII
	 LDA #'.'        NOT ASCII SO '.'
LISTS3   JSR OUTCH       OUTPUT ASCII
	 BCS WMX         GOT A CNTRL C
	 JSR BY3         UP ADDR
         BNE LISTS2
         JSR DCMP
	 BCS WM0         AGAIN
WMX      RTS


DUMPSTR  EQU*
	 BYTE $0D,'ADDR   '
DUMPEND  EQU*

	 STTL 'MON3.ASM - Commands, Fill memory'
	 PAGE

* Routine:  FILL
*
* Reg Used: ACC,Y,X
* Var Used: TMPC,TMP0,TMP6,DIFF
* Routines Called: RD_SAEA,SPAC,RDOB,BY3,DCMP
* Returned Reg: NONE
*

FILL     JSR RD_SAEA     READ SA & EA
         BCS FILLSX
         JSR SPAC
         BCS FILLSX
	 JSR RDOB        READ FILL CHAR
         BCC FILLSX
         STA TMP6
FILLS0   JSR DCMP        EA - SA
	 LDA DIFF        LSB of difference
         STA TMPC
         INC TMPC
FILLS1   LDA TMP6
	 STA (TMP0)      DATA
	 CMP (TMP0)      CK IF WRITTEN
         BNE FILLERR
	 JSR BY3         UP ADDR
         BNE FILLS1
         JSR DCMP
         BEQ FILLSX
	 BCS FILLS0      AGAIN
FILLSX   JMP START

FILLERR  JMP ERROPR      BAD FILL, MEMORY MISSING

	 STTL 'MON3.ASM - Commands, Help'
	 PAGE


HELP     EQU*           DISPLAY HELP MENU
         LDA #>HELPMENU
         LDX #<HELPMENU
         LDY #HELPEND1-HELPMENU
         JSR PRTSTR
	 BCS HELPX       BAD RETURN FROM SERIAL
         LDA #>HELPEND1
         LDX #<HELPEND1
         LDY #HELPEND-HELPEND1
         JSR PRTSTR
HELPX    JMP START


* Routine:  PRTSTR
*
* Reg Used: ACC & Y
* Var Used: TMP0,TMP2,TMP6
* Routines Called: OUTCH
* Returned Reg: NONE
*

PRTSTR   STA TMP0+1      MSB OF ADDRESS
	 STX TMP0        LSB OF ADDRESS
	 STY TMP6        # OF CHAR TO PRINT/SEND OUT TO SERIAL
         LDY #0
HELP1    LDA (TMP0),Y
         JSR OUTCH
	 BCS HELP2       GOT A CNTRL C
         INY
         CPY TMP6
         BNE HELP1
         CLC
HELP2    RTS


HELPMENU BYTE $0D
	 BYTE 'D      Display memory',$0D
	 BYTE 'SPACE  Display current memory address',$0D
	 BYTE '<,>    Decrement, Increment memory address',$0D
	 BYTE 'M      Alter memory',$0D
	 BYTE '/      Host memory access',$0D,$0D

	 BYTE 'R,A    Display, Alter registers',$0D
	 BYTE 'G,J    JMP, JSR to PC [location]',$0D
HELPEND1 BYTE 'F,V,C  Block Fill, Move, Checksum',$0D
	 BYTE 'S,W,E  S28 Input, Output, Errors',$0D,$0D

	 BYTE '?,H    Help',$0D
	 BYTE 'B,K    BASIC Start, Continue',$0D
	 BYTE 'T      Display time',$0D
	 BYTE 'X      Toggle handshake mode',$0D
	 BYTE 'U      User installed commands'
HELPEND  EQU*


* Routine:  VERSION
*
* Reg Used: Acc,Y,X
* Var Used: NONE
* Routines Called: NONE
* Returned Reg: Acc,X,Y
*

VERSION  EQU*           RETURN VERSION IN A,X,Y
	 LDA MONVER_
	 LDX MONVER_+1
	 LDY MONVER_+2
         RTS

	 STTL 'MON3.ASM - Commands, S28/S19 HEX loader'
	 PAGE


* Routine:  MS28IN
*
* Reg Used: ACC,Y,X
* Var Used: TMP0,TMP2,TMP4,TMP6,TMPC,ERRORS,SFLAG,
* Routines Called: GETCH,DADD,RDOB,OUTCH,PERR1,CRLF,SPAC,
*                   WROA,SPAC2,BYTE,BY2
* Returned Reg: NONE
*

MS28IN   EQU*
         JSR GETCH
	 CMP #'S'        FIND NEXT RCD MARK (S)
         BNE MS28IN


LSS      EQU*           LOAD SINGLE S28 RECORD
*                       CHECKSUM USED, BUT
*                       REQUIRED SO THAT IT
*                       IS COMPATABLE
         INC ERRORS
         SEI
         LDA SFLAG
         AND #ECHOFF
	 STA TMP6+1      SAVE CURRENT STATE OF ECHO OFF
	 LDA #ECHOFF     SET ECHO OFF
         TSB SFLAG

         CLI
	 JSR GETCH       GET S RECORD TYPE
	 BCS LSS0        CHK FOR CNTRL 'C'
	 PHA             SAVE S RECORD TYPE
         STZ TMP4
	 STZ TMP4+1      CLR CKSUM REG
	 JSR RDOB        GET BYTE COUNT
	 STA TMPC        SAVE BYTE COUNT
         JSR DADD
	 DEC TMPC        GET S28 ADDR
         DEC TMPC
         DEC TMPC
	 PLA             GET RECORD TYPE
         CMP #'1'
	 BEQ SHORTADDR   SHORT RECORD
         CMP #'9'
         BEQ SHORTADDR
         CMP #'2'
         BEQ S28LA1
         CMP #'8'
         BNE LSS0
S28LA1   DEC TMPC
	 JSR RDOB        GET BANK ADDR, But ignore it
	 JSR DADD        ADD TO CKSM
SHORTADDR JSR RDOB       SA HO TO TMP0+1
         STA TMP0+1
	 JSR DADD        ADD TO CKSM
	 JSR RDOB        SA LO TO TMP0
         STA TMP0
	 JSR DADD        ADD TO CHKSM

	 LDA TMPC        CK IF # OF BYTES ZERO
         BEQ S28G2
S28GD1   JSR BYTE        BYTE SUB/R DECRS LCNT
         BCC S28G3
	 INC ERRORS      DEC COUNTER & INC ADDR
	 INC TMP4        MESS UP CKSUM SO WILL PRINT ERR
	 JSR BY2         SO CNT WILL BE RIGHT FROM
*                        BYTE ENDING TOO SOON
S28G3    BNE S28GD1      ON EXIT
S28G2    JSR RDOB        CKSUM FROM HEX RCD>TMP0
         JSR DADD
	 LDA TMP4        GET CHKSUM

         CMP #$FF
         BEQ LSS0
	 LDA #$07        BEEP
         JSR OUTCH
         JSR PERR1
         BRA LSFIN

LSS0     DEC ERRORS      A GOOD LOAD
LSFIN    JSR GETCH       GET CR OR LF
         SEI
         LDA SFLAG
         AND #$FF-ECHOFF
	 ORA TMP6+1      RESTORE STATE OF ECHO OFF
         STA SFLAG
         CLI
LHDONE   JMP START       GOTO START


PERR     JSR PERR1
	 STZ ERRORS      RESET ERROR COUNT
	 STZ TMP0        RESET ADDR ALSO
         STZ TMP0+1
         JMP START


PERR1    JSR CRLF        PRINT # OF ERRORS
         LDA #'E'
         JSR OUTCH
         JSR SPAC
	 JSR WROA        OUTPUT ADDR CLOSE TO
	 JSR SPAC2       ERROR,MAYBE OFF BY 16
         LDA ERRORS
	 JMP SNDT1       WRITE # OF ERRORS

	 STTL 'MON3.ASM - Commands, S19 HEX output'
	 PAGE


* Routine:  MS19OUT
*
* Reg Used: ACC,Y,X
* Var Used: TMP0,TMP2,TMP4,TMP6,SFLAG,TMPC,DIFF
* Routines Called: CRLF,GETCH,RD_SAEA,WRTWO,DCMP,DADD
*                   CKNOUT,WROB
* Returned Reg: NONE
*

SLASTLINE BYTE  'S9030000FC'
SLASTEND EQU*

WO       EQU*
	 STZ TMP6        TMP6 is the Offset added as the address goes out
	 STZ TMP6+1      We use TMP6 to 'relocate' as we write the output

	 JSR RD_SAEA     RD START ADDR & END ADDR

WO1      JSR GETCH       DELAY FOR FINAL CR
         JSR CRLF
	 LDA #$FF        indicates need to send end record
         JSR MS19OUT
         JMP START

MS19OUT  EQU*
         STZ WRAP
         PHA
         JSR MS19OUTA
         PLA
         BEQ NOFINAL

	 JSR CRLF        WRITE LAST LINE
         LDX #<SLASTLINE
         LDA #>SLASTLINE
         LDY #SLASTEND-SLASTLINE
         JSR PRTSTR      
NOFINAL  RTS


MS19OUTA LDX WRAP
         BNE BCCST2

         JSR CRLF
         STZ TMP4
	 STZ TMP4+1      CLEAR CKSUM
         LDA #S28BN
	 STA TMPC        TMPC = 16+3 FOR SHORT

	 LDA #'1'        OUTPUT S1
	 LDX #'S'
         JSR WRTWO
	 JSR DCMP        EA-SA (TMP0+2-TMP0) DIFFERENCE
	 TYA             IN LOC DIFF,Y REG HAS MSD
	 BNE WH10        OF DIFFERENCE
         LDA DIFF
         CMP #15
	 BCS WH10        DIFF GT 15
	 CLC             ADD 2 FOR ADDR
	 ADC #$04        ADD 1 FOR CKSUM
	 STA TMPC        ADD 1 FOR BYTE CNT
WH10     LDA TMPC        OUTPUT BYTE COUNT
	 JSR CKNOUT      RCC CNT IN A

         DEC TMPC
         DEC TMPC 
         DEC TMPC 

WH1A     CLC             output the address plus the offset
         LDA TMP0
         ADC TMP6
         PHA
         LDA TMP0+1
         ADC TMP6+1
	 JSR CKNOUT      ADD TO CKSM
         PLA
	 JSR CKNOUT      ADD TO CKSM

WH2      LDA (TMP0)      WRITE OUT DATA BYTES
	 JSR CKNOUT      INC CKSUM
	 JSR BY3         INC SA
	 BNE WH2         LOOP FOR 16 BYTES
         LDA TMP4
	 EOR #$FF        we want 1's complement
	 JSR WROB        WRITE CKSUM
         JSR DCMP
	 BCS MS19OUTA    LOOP WHILE EA GT OR = SA

BCCST2   RTS

CKNOUT   JSR DADD
         JMP WROB


	 STTL 'MON3.ASM - Commands, General Purpose Routines'
	 PAGE

* Routine:  RD_SAEA
*
* Reg Used: ACC,Y,X
* Var Used: TMP0,TMP2
* Routines Called: RDOA,SPAC,T2T2,T3T3
* Returned Reg: NONE
*

RD_SAEA  JSR SPAC        READ 16 BIT ADDR FORM
         JSR RDOA

	 LDA TMP0        save SA
         PHA
         CLC
         ADC #15
         STA TMP2
         LDA TMP0+1
         PHA
         ADC #0
	 STA TMP2+1      EA will be SA+15 if left off

	 JSR SPAC        put a space between the addresses
	 JSR RDOA        get ending address
         BCS ENDOK

	 LDA TMP0        put EA in TMP2
         STA TMP2
         LDA TMP0+1
         STA TMP2+1

ENDOK    PLA             put SA back in TMP0
         STA TMP0+1
         PLA
         STA TMP0
         RTS




* Routine:  DADD
*
* Reg Used: NONE
* Var Used: TMP4
* Routines Called: NONE
* Returned Reg: NONE
*
*                        CALCULATE CHECKSUM
DADD     PHA             SAVE A
         CLC
         ADC TMP4
         STA TMP4
         LDA TMP4+1
         ADC #0
         STA TMP4+1
	 PLA             RESTORE A
         RTS




* Routine:  INCTMP
*
* Reg Used: NONE
* Var Used: TMP0
* Routines Called: NONE
* Returned Reg: NONE
*

*                        INC STRING POINTER
INCTMP   INC TMP0        LO BYTE
         BNE INCT2
         INC TMP0+1
         BNE INCT2
         INC WRAP
INCT2    RTS

	 STTL 'MON3.ASM - Commands, calculate checksum'
	 PAGE


* Routine:  CHKSUM
*           TMP4 & TMP4+1 contains the sum of the digits to
*           facilitate either TWO's compliment or ONE's compliment checksum
*           Difference between TMP0 & TMP2 should not be GT 255
*
* Reg Used: ACC,Y,X
* Var Used: TMP0,TMP2,TMP4
* Routines Called: SPAC2,WROA4,RD_SAEA,CHK_SUM
* Returned Reg: NONE
*

CHKSUM   EQU*           CALCULATE CHECK SUM
         JSR RD_SAEA
;        BCS CKS_RSTART  ERROR IN GETTING SA & EA
         JSR CHK_SUM
         JSR SPAC2
	 JSR WROA4       PRINT CHECK SUM
CKS_RSTART EQU*
         JMP START


CHK_SUM  EQU*           CALCULATE CHECK SUM
         STZ TMP4
	 STZ TMP4+1      clear checksum register
	 JSR DCMP        EA-SA in A & Y
	 BEQ CKSX        A & Y or'd on return
CKS1     LDA (TMP0),Y
	 JSR DADD        add to TMP4
	 JSR INCTMP      TMP0+1 to TMP0
	 JSR DCMP        EA-SA  returns 0 if =
         BNE CKS1
CKSX     RTS


	 STTL 'MON3.ASM - Commands, block move'
	 PAGE

* Routine:  MOVE
*
* Reg Used: ACC,Y,X
* Var Used: TMP0,TMP2
* Routines Called: SPAC,RD_SAEA,RDOB,MVDATA
* Returned Reg: NONE
*


MOVE     JSR RD_SAEA     MOVE A BLOCK UPTO 256 BYTES
*        BCS CKS_RSTART  ERROR IN GETTING SA & EA
         JSR SPAC
	 JSR RDOB        GET # OF BYTES
         TAY
         JSR MVDATA
         BCS MOVEBAD
         BRA CKS_RSTART

MOVEBAD  JMP ERROPR      DID NOT MOVE MEMORY
*                        NOT THERE
	 PAGE


TGLXONXOFF EQU*         TOGGLE SERIAL XON/XOFF MODE
         JSR SPAC
         SEI
         LDA SFLAG
         EOR #XONOFLG
         STA SFLAG
         CLI
         AND #XONOFLG
         BEQ TGLX1
         LDA #1
TGLX1    JSR WROB        OUTPUT STATUS OF BIT
         JMP START


	 STTL 'MON3.ASM - Commands, display ToD clock'
	 PAGE
DTIME    JSR CRLF
         JSR SNDTOD
         BRA CKS_RSTART

*        The Slash (/) command is to allow host computers quick access
*        to memory locations.  It has many forms:

*        /<SPACE> returns curr. mem location & increments pointer
*        /XX<SPACE> writes curr. to mem pointer, re-reads and returns
*                   the data at the pointer (as a check for writable mem)
*                   then increments pointer.
*        /XXXX<SPACE> changes the pointer, returns data, inc's pointer.
*        /XXXXYY<SPACE>  changes pointer, writes data, reads & returns data,
*                        and increments the pointer.

SLASH    SEI             kill the echo
         LDA SFLAG
         AND #ECHOFF
	 STA TMP6+1      SAVE CURRENT STATE OF ECHO OFF
	 LDA #ECHOFF     SET ECHO OFF
         TSB SFLAG

         CLI

	 JSR RDOB        get the first byte
	 BCC RETBYTE     branch if it was a SPACE
	 PHA             save the data
	 JSR RDOB        get the next byte
	 BCC WRTBYTE     no next byte - write one byte, read, return
	 STA TMP0        two bytes in succession - an address
         PLA
         STA TMP0+1
	 BRA SLASH       we had an address and set it - back to beginning.

WRTBYTE  PLA
         STA (TMP0)

RETBYTE  LDA (TMP0)
	 JSR WROB        write the byte to the serial port
	 INC TMP0        increment the address
         BNE OUTSLASH
         INC TMP0+1

OUTSLASH SEI             put the echo back
         LDA SFLAG
         AND #$FF-ECHOFF
	 ORA TMP6+1      RESTORE STATE OF ECHO OFF
         STA SFLAG
         CLI

         JMP START                  

	 ENDS

	 APPEND MON4.ASM
