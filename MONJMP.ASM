	 STTL 'MONJMP.ASM - Monitor JMP Table'
	 PAGE
*        06-21-1993
	 CODE

	 ORG $F000


	 JMP VERSION    GET MONITOR VERSION
*             Returns monitor version in A, month in X, day in Y.

	 JMP ACI_INIT   INITIALIZES ACIA
*             Initializes ACI to baud rate in A, data length in X,
*             and parity in Y.
*             Anything in the current buffers is flushed.
*             Baud rate values are:
*
*             A   Baud rate       A        Baud rate
*            ---  ---------      ---       ---------
*             0        75          6           1800
*             1       110          7           2400
*             2       150          8           4800
*             3       300          9           9600
*             4       600          A          19200
*             5      1200          B          38400

*             X has data length 7 = 7 bits, 8 = 8 bits
*             Y has parity.  B0 = 1 enables, B1 = 1 sets even parity.
*             B1=0 sets odd parity.

	 JMP RD_CHAR    RETURNS A CHARACTER
*             from ACIA if one was present.  Otherwise it will return
*             a 00 (null). CY = 1 if ^C is encountered and control C
*             flag reset (see CK_CONTC)

	 JMP CK_CONTC   RETURNS WITH C BIT SET if a control "C" has been
*            detected on input else -C = 0

	 JMP GETCH      READ ACIA
*             Wait until we get a character CY = 1 if ^C and
*             acc = null ($00).
*             C flag reset (see CK_CONTC) This routine also echos the
*             character, this feature can be switched off. Echo is bit 5
*             of SFLAG (addr 0072)

	 JMP OUTCH      WRITE ACIA
*            ACC has the character (7-bit ASCII) to send CY = 1 if ^C

	 JMP CRLF       PRINT CARRIAGE RETURN.
*             ACC used

	 JMP SPAC       PRINTS A SPACE
*             ALL REG preserved

	 JMP ASCBIN     ASCII TO BINARY

	 JMP BINASC     BINARY TO ASCII HEX
*             ACC has lower nibble in ASCII, X has upper nibble in ASCII

	 JMP PRTSTR     PRINTS A STRING
*             Useful for concatenating strings, and can embed CRLF
*             Y = # of bytes to send X = LO & ACC = HI point to text
*             CY = 1 if ^C
 
	 JMP RDOA       READS AN ADDRESS $XXXX
*             TMP0 =   starting address low TMP0+1 = starting address high
*             This routine also echos the character, this feature can be
*             switched off. Echo is bit 5 of SFLAG (addr 0072) and CY = 1
*             CY = 0 if SPACE. X reg not used, Y reg restored.
 
	 JMP RDOB       READS A BYTE $ZZ
*             hex byte = ACC, and CY = 1 CY = 0 if SPACE
*             X reg not used, Y reg restored.  This routine also echos
*             the character this feature can be switched off.
*             Echo is bit 5 of SFLAG (addr 0072)
 
	 JMP WR_ADDR    WRITE AN ADDRESS $XXXX
*             CY = 1 if ^C
 
	 JMP WROB       WRITE A BYTE $XX
*             CY = 1 if ^C
 
	 JMP ISDECIMAL  CHECKS IF ASCII DECIMAL DIGIT
*            CY = 1 if not decimal digit
 
	 JMP IFASC      CHECKS IF ITS ASCII
*            CY = 1 if not ASCII
 
	 JMP UPPER_CASE CONVERT LOWER CASE ASCII TO UPPER CASE
*            ASCII character in ACC is converted to upper case ASCII.

 
	 JMP MVDATA     MOVE DATA
*            TMP0,+1 =   Source address (Low, Hi)
*            TMP2,+1 =   Destination address low,hi
*            Y = # of bytes to be moved.
*            Y = 0 moves 256 bytes.
*            WARNING: TWO MEMORY AREAS MUST NOT OVER LAP
*             CY = 1 IF NO RAM AT DEST LOCATION
                      
	 JMP START      This is used to get back to the command prompt
*            for the monitor.  It resets the stack from the memory location
*            that gets updated on the BRK command.
 
	 JMP HEXIN      CONVERTS ASCII HEX TO
*            HEX/BINARY
*            returns hex/nibble binary in ACC
*            IF CARRY SET THEN NOT ASCII HEX
 
	 JMP BIN2DEC    Converts value in A from hex to packed decimal.
*            Do not exceed 99.
 
	 JMP MS19OUT    MOTOROLA S19 OUTPUT
*            TMP0 =   starting address low
*            TMP0+1 = starting address high
*            TMP2 =   ending address low
*            TMP2+1 = ending address high
*            TMP6 =   Offset address low       Address field of S-Record
*            TMP6+1 = Offset address high      is data address + offset)
 
	 JMP MS28IN     MOTOROLA S28 INPUT (Also S19)

 
	 JMP CHK_SUM    CALCULATE CHECK SUM
*            TMP0 & TMP0+1 contain starting address
*            TMP2 & TMP2+1 contain ending address
*            TMP4 & TMP4+1 contains the sum of the digits to
*            facilitate either TWO's compliment or ONE's compliment checksum
*            Difference between TMP0 & TMP2 should not be GT 255
 
	 JMP RD_CLOCK   You give this routine a pointer in A,X (A is low).
*             This routine puts the real time data in that location in the
*             following format:

*             Byte        Contents

*              0          Seconds, in 2's complement.
*              1          Minutes,       ""
*              2          Hours (0-23)   ""
*              3          Day of Month   ""
*              4          Month (1-12)   ""
*              5          Year           ""
*              6          Weekday (1-7)  ""

	 JMP WR_CLOCK   You write a buffer with the time, in the format shown
*             above.  Put a pointer to the buffer in A,X and call this routine
*             to change the TOD clock.
 
	 JMP RTC_MODE   DAYLIGHT SAVINGS FLAG
*             Call this routine with ACC=1 and the RTC will make daylight
*             savings shifts when required. If called with ACC=0, no shifts will
*             be made. CY = 1 on error
 
	 JMP WR_ACLOCK  You write a buffer with the time, in the format
*             shown above.  Put a pointer to the buffer in A,X and call this
*             routine to change the alarm clock.
*             There is a WILD CARD of $FF for a match.

	 JMP NOEXTROM   Entry point written at $8000

	 BYTE $CB,$EA,$60   WAIT RTS INTERNAL ROM


	 JMP ISHEX      TESTS FOR VALID ASCII HEX DIGIT
*            CY = 1 if not ASCII HEX and returns char in UPPER case.


	 JMP FLUSH_SERIAL_BUFF SETUP QUEUE COUNTERS TO ZERO
*            IE FLUSH ALL SERIAL QUEUES

	 ENDS

	 APPEND MON1.ASM
