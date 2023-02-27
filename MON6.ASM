	 STTL 'MON6.ASM - Library Subroutines'
	 PAGE
*        06-21-1993
	 CODE

DVDN     EQU TMP0
DVSR     EQU TMP2
RMNDR    EQU TMP4
*
* MOVE A BLOCK OF DATA'
*
* 08-21-1988



* SRCE--ADDRESS OF SOURCE BLOCK
* DEST--ADDRESS OF DESTINATION BLOCK
* Y--# OF BYTES TO BE MOVED
*  Y=0 IS TO MOVE 256 BYTES
* WARNING: TWO MEMORY AREAS MUST NOT OVER LAP
*  CY = 1 IF MEMORY NOT THERE

MVDATA   DEY             DEC INDEX
	 LDA (SRCE),Y    GET SOURCE BYTE
	 STA (DEST),Y    STORE DATA
	 CMP (DEST),Y    CK IF WRITTEN
         BNE MVBAD
	 CPY #$00        ARE WE DONE
	 BNE MVDATA      NOT DONE
	 CLC             GOOD MOVE
	 RTS             RETURN

MVBAD    SEC
         RTS



*
*     CONVERTS ASCII HEX TO HEX
*

* 01-19-1989


*  Routine:  HEXIN
*    IF CARRY SET THEN NOT ASCII HEX
*    ACC IN AND OUTPUT
*  Reg Used: Acc
*  Var Used: NONE
*  Routines Called: ISHEX
*  Returned Reg: Acc
*


HEXIN    JSR ISHEX       IS IT HEX
         BCS HEXXX
         CMP #$3A
	 PHP             SAVE STATUS
	 AND #$0F        STRIP OF LS NIBBLE
	 PLP             GET STAT
	 BCC HEXXX       WAS NUMBER
	 ADC #$08        WAS ALPHA ADD 8+CY=9
HEXXX    RTS


*  Routine:  ISHEX
*    TESTS FOR VALID ASCII HEX DIGIT
*    C=SET IF NOT HEX
*  Reg Used: Acc
*  Var Used: NONE
*  Routines Called: UPPER_CASE
*  Returned Reg: Acc

ISHEX    JSR UPPER_CASE  IF NOT MAKE UPPER CASE
	 CMP #'A'        LESS THAN 'A'
	 BCC ISDECIMAL   YES,TRY NUMBER CHECK
	 CMP #'G'        F+1
*                        IF CY SET THEN GREATER THAN F
	 RTS             IF CY CLR THEN OK


*  Routine:  ISDECIMAL
*    CHECK FOR VALID ASCII #
*  Reg Used: Acc
*  Var Used: NONE
*  Routines Called: NONE
*  Returned Reg: Acc

ISDECIMAL CMP #'0'       IS LESS THAN '0'
	 BCC ISN1        YES,NG
	 CMP #'9'+1      IE >9
*                        IF CY SET THEN NG
	 RTS             IF CY CLR THEN OK

ISN1     SEC             BAD GUYS EXIT
         RTS


*  Routine:  IFASC
*    CHECK FOR VALID ASCII
*  Reg Used: Acc
*  Var Used: NONE
*  Routines Called: ISHEX
*  Returned Reg: Acc

IFASC    CMP #' '        IS LESS THAN SPACE
	 BCC ISN1        YES SO NOT ASCII
	 CMP #$7F        GT TILDA
*                        IF CY SET THEN SO NOT ASCII
	 RTS             IF CY CLR THEN OK



*  Routine:  UPPER_CASE
*  Reg Used: Acc
*  Var Used: NONE
*  Routines Called: NONE
*  Returned Reg: Acc


UPPER_CASE CMP #'a'      CONVERT TO UPPER CASE
	 BCC NIBBIN1     NOT an upper case char
	 CMP #'z'+1      IS IT GT A 'z'
	 BCS NIBBIN1     NOT an upper case char
         SEC
	 SBC #$20        MAKE IT UPPER CASE
NIBBIN1  RTS



*  Routine:  BIN2DEC
*  Reg Used: Acc
*  Var Used: NONE
*  Routines Called: NONE
*  Returned Reg: Acc


BIN2DEC  PHX              convert Acc to packed decimal (MAX 99)
         PHA
         LSR A
         LSR A
         LSR A
         LSR A
         TAX
         SED
         PLA
         AND #$0F
         PHA
         LDA BINDECH,X
         CLC
         PLX
         ADC BINDECL,X
         CLD
         PLX
         RTS

	 ENDS

	 APPEND MON7.ASM
