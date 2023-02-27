	 STTL 'MON4.ASM - Time of Day Clock Routines'
	 PAGE
*        06-22-1993
	 CODE


* TIME OF DAY CLOCK
* Routine:  INITCLK
*
* Reg Used: ACC & X
* Var Used: SEC,MIN,HR,DAY,MONTH,YR,ASEC, ....
* Routines Called: NONE
* Returned Reg: NONE
*


INITCLK  EQU*
	 LDX #DFLTSEND-DFLTS-1  LOAD TOD DEFAULT
ICLK1    LDA DFLTS-1,X
         STA SEC-1,X
         DEX
         BNE ICLK1
	 LDX #DFLTSEND-DFLTS-1  RESET ALARM CLOCK ALSO
ICLK2    STZ ASEC-1,X
         DEX
         BNE ICLK2
	 LDX #DFLTSEND-DFLTS-1  LOAD TOD CHECKSUM
         LDA #00
         CLC
ICLK3    ADC SEC-1,X
         DEX
         BNE ICLK3
         EOR #$FF
         STA TODCKS
         RTS

         STTL 'MON4.ASM - Time of day clock IRQ routine'
         PAGE


* Routine:  TODIRQ
*
* Reg Used: ACC,Y,X
* Var Used: SEC,MIN,HR,DAY,MONTH,YR,DAYWK,DAYLIT
*           ASEC,AMIN,AHR,ADAY,AMONTH,AYR,ADAYWK
* Routines Called: NONE
* Returned Reg: NONE
*

TODIRQ   EQU*           MONITOR TIME OF DAY IRQ
         PHA
	 LDA #T2FLG      RESET TIMER 2 IRQ
         TSB IFR2
         PHY
         PHX
	 LDA #$FF        RESET WATCHDOG TIMER 'M'
         STA TMLL
         STA TMCL
         STA TMLH
         STA TMCH
	 INC SEC         INCREMENT SECONDS
         LDA #59
         CMP SEC
         BCS EXITOCT
	 STZ SEC         ROLLED OVER

	 INC MIN         INCREMENT MINUTES
         CMP MIN
         BCS EXITOCT
	 STZ MIN         ROLLED OVER

	 INC HR          INCREMENT HOUR
         LDA HR
         CMP #1
         BNE TODINT8
OCTOBER  LDA #DAYLITFLG  IS DAYLIGHT SAVINGS ON
         BIT DAYLIT
         BEQ EXITOCT
         LDA MONTH
	 CMP #10         IS IT OCTOBER
         BNE EXITOCT
	 LDA DAYWK       IS IT SUNDAY
         CMP #$01
	 BNE EXITOCT     NO
	 LDA DAY         IS IT LAST SUNDAY
         CMP #25
         BCC EXITOCT
	 LDA #DAYLPROG   CK IF ALREADY SET BACK
         TRB DAYLIT
         BNE EXITOCT
         TSB DAYLIT
         STZ HR
EXITOCT  BRA T2EXIT


TODINT8  EQU*
         CMP #24
         BCC EXITA6
	 STZ HR          ROLLED OVER
EXITA6   LDA HR
         BEQ TODINT9
         BRA T2EXIT

TODINT9  INC DAYWK
         LDA DAYWK
         CMP #7
         BCC INCDAY
         LDA #1
	 STA DAYWK       ROLLED OVER

INCDAY   INC DAY
	 LDA #DAYLITFLG  IS DAY LIGHT SAVINGS ON
         BIT DAYLIT
	 BEQ INCADAY     NO
         LDA MONTH
	 CMP #4          IS IT APRIL
         BEQ APRIL
INCADAY  LDA DAY         INCREMENT DAYS
         LDX MONTH
         CMP LASTDY-1,X
         BCC T2EXIT

	 CPX #2          INCREMENT MONTH
	 BNE INCMTH      NOT FEBRUARY
         LDA YR
	 AND <%00000011   IS IT LEAP YR
         BNE INCMTH

	 LDA DAY         ITS FEB AND LEAP YR
         CMP #29
         BEQ T2EXIT

INCMTH   LDY #1          ROLLED OVER
         STY DAY
         INC MONTH
         LDA MONTH
         CMP #13
         BCC T2EXIT
	 STY MONTH       MONTH 1= JAN

         INC YR


T2EXIT   EQU*
	 LDA DISPTYP     CK IF ALARM ENABLED
         BIT #ALRMENAB
         BEQ EXITA
	 LDA ASEC        CHK IF ALARM CLOCK IS
	 ORA AMIN        RUNNING
         ORA AHR
         ORA ADAY
         ORA ADAYWK
         ORA AMONTH
         ORA AYR
         BEQ EXITA
*                        CHK IF WE HAVE AN ALARM
         LDX #DFLTSEND-DFLTS-1
CKALARM  LDA ASEC-1,X
         CMP #$FF
         BEQ CKAL1
         CMP SEC-1,X
         BNE EXITA

CKAL1    DEX
         BNE CKALARM
	 LDA #ALRMIRQ    SET ALARM FLAG
         TSB DISPTYP
EXITA    EQU*
	 LDX #DFLTSEND-DFLTS-1  LOAD TOD CHECKSUM
         LDA #00
         CLC
CLKSUM   ADC SEC-1,X
         DEX
         BNE CLKSUM
         EOR #$FF
         STA TODCKS
         PLX
         PLY
         PLA
         RTI

APRIL    LDA DAYWK       IS IT SUNDAY
         CMP #$01
	 BNE INCADAY     NO
	 LDA DAY         IS IT 1ST SUNDAY
         CMP #8
         BCC APR1
         JMP INCADAY


APR1     LDA #1
         STA HR
         BRA T2EXIT

         STTL 'MON4.ASM - General ToD subroutines'
         PAGE

* Routine:  RTC_MODE
*
* Reg Used: ACC
* Var Used: DAYLIT
* Routines Called: NONE
* Returned Reg: NONE
*

RTC_MODE EQU*           ENABLE/DISABLE DAYLIGHT
	 BMI RTC_ERR     VALUE EITHER 0 OR 1 ONLY
         CMP #$02
         BCS RTC_ERR
         BEQ RTC0
         LDA #DAYLITFLG
	 TSB DAYLIT      SAVINGS TIME
         BRA RTC1

RTC0 LDA #DAYLITFLG
         TRB DAYLIT
RTC1     CLC
         RTS

RTC_ERR  SEC             ERROR IN PARAMETERS
         RTS

* Routine:  RD_CLOCK
*
* Reg Used: ACC,Y,X
* Var Used: TMP0
* Routines Called: NONE
* Returned Reg: NONE             Y REG is RESTORED
*

RD_CLOCK EQU*           READS CLOCK HR,MIN,SEC
	 PHY             MONTH,DAY,YR
         STA TMP0
         STX TMP0+1
         PHP
         SEI
         LDY #0

RD_CLP   LDA |SEC,Y
         STA (TMP0),Y
         INY
         CPY #7
         BNE RD_CLP
         PLP
         PLY
         RTS



* Routine:  WR_CLOCK
*
* Reg Used: ACC,X,Y
* Var Used: TMP0
* Routines Called: NONE
* Returned Reg: NONE             Y REG is RESTORED
*

WR_CLOCK EQU*           WRITES CLOCK SEC,MIN,HR
	 PHY             MONTH,DAY,YR,DofW
         STA TMP0
         STX TMP0+1
         LDY #0
         PHP
         SEI
WR_CLP   LDA (TMP0),Y
	 STA |SEC,Y
         INY
         CPY #7
         BNE WR_CLP
         PLP
         PLY
         RTS




*        Alarm Clock:  To use the alarm clock, you set it using the routine
*                      below.  You must set all 7 parameters, but if you set
*                      any of them to $FF, it will be ignored.  For example,
*                      if you want the alarm clock to go off at 1:00 pm on
*                      Saturdays, you would set it to:

*                      00 00 0D FF FF FF 07

*                      This is zero seconds, zero minutes, 13 hours,
*                      any day, any month, any year, and the 7th day of the
*                      week (Sun = 1, Sat = 7).

*                      Once set, you must enable the alarm clock.  This is
*                      by setting bit 3 of location $77 to a '1'.  If you
*                      want to turn it off (which saves a bit of interrupt
*                      time), set the enable bit to a 0.

*                      When the appropriate time hits, the clock interrupt
*                      will set a flag.  The flag is bit 4 of location $77.
*                      A '1' in that bit indicates the alarm went off.  The
*                      flag stays set until you reset it.

*                      Remember that 'ANY' is just that  if you set the alarm
*                      for Jan 3, 1990 by using: FF FF FF 03 01 5A FF,
*                      you'll get an alarm set every second all day long on
*                      Jan 3, 1990.  Note also that if you want a specific
*                      time and date, you should set the day of the week to
*                      'ANY' to avoid a mis-match.

*                      If you want every other day, then you'll have to set
*                      the alarm for every day and check for every other day
*                      by yourself.







* Routine:  WR_ACLOCK
*
* Reg Used: ACC,X
* Var Used: TMP0
* Routines Called: NONE
* Returned Reg: NONE           Y REG is RESTORED
*

WR_ACLOCK EQU*          WRITES ALARM CLOCK DATA
	 PHY             MONTH,DAY,YR
	 STA TMP0        A has low address of alarm time
	 STX TMP0+1      X has high address of alarm time
         PHP
	 SEI             no alarms in the middle of setting it, please.
         LDY #0
WR_ACLP  LDA (TMP0),Y
	 STA |ASEC,Y
         INY
         CPY #7
         BNE WR_ACLP
         PLP
         PLY
         RTS



* Routine:  SNDTOD
*
* Reg Used: ACC,X
* Var Used:
* Routines Called: SNDT1,SPAC,OUTCH,SNDTIME,CRLF
* Returned Reg: NONE
*
* WARNING: if the time rolls in the middle of this, the result is wrong.
*

SNDTOD   LDA DAYWK       SEND OUT TOD CLOCK
         JSR SNDT1
         JSR SPAC
         LDA MONTH
         JSR SNDT1
         LDA #'/'
         JSR OUTCH
         LDA DAY
         JSR SNDT1
         LDA #'/'
         JSR OUTCH
         LDA #19
         JSR SNDT1
         LDA YR
         JSR SNDT1
         JSR SPAC2
	 JSR SNDTIME     DISPLAY TIME
         JMP CRLF


* Routine:  SNDTIME
*
* Reg Used: ACC,X
* Var Used:
* Routines Called: SNDT1,OUTCH,BINASC,WRTWO
* Returned Reg: NONE
*
* WARNING: if the time rolls in the middle, output will be wrong
*

SNDTIME  LDA HR
         JSR SNDT1
         LDA #':'
         JSR OUTCH
         BCS SNDTDONE
         LDA MIN
         JSR SNDT1
         LDA #':'
         JSR OUTCH
         BCS SNDTDONE
         LDA SEC

SNDT1    JSR BIN2DEC
         JSR BINASC
         JSR WRTWO
SNDTDONE RTS



	 ENDS

	 APPEND MON5.ASM
