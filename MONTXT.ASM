	 STTL 'MONTXT.ASM - Monitor Commands Defined'
	 PAGE
*        01-13-1995
	 DATA



* WRITTEN BY L. A. HITTEL and RALPH GREENTHAL
*
* ORIGIONAL  DATE:  JUNE 02,1988
*  REVISION 1.01 DATE:  DEC  05,1989
*  REVISION 1.02 DATE:  OCT 08,1991
*       7 BIT SERIAL UART CODE FIXED
*       ^C RETURNS 03h NOW - C still set!
*
* REV:  01.03   never issued
*
* REV:  01.04   June 21, 1993
*     MODIFIED:
*      1) SOME BRANCHES REMOVED TO SAVE SPACE
*      2) UPPER CASE NOT WORKING FOR 'z'
*      3) 4.9152 MHZ ADDED TO TABLES
*      4) ASCI INIT STACK PROBLEM
*      5) RESTORED Acc FOR ROUTINE 'SPAC'
*      6) CHECKSUM fixed
*
* REV:  01.05   JUNE 13, 1994
*      FIXED START-UP SEQUENCE
*
* REV:  01.06   DEC 09, 1994
*      REMOVED ICE BIT IN BCR FOR ROM USE
*
* REV:  01.07   JAN 13, 1995
*      ADDED TEST FOR SRAM AT $200
*
* COM LOG CO. INC. W65C134 Controller Interface Monitor
*
*
*                                  MONITOR PREREQUISITES:
*
*
*  This monitor expects a terminal to be connected to the serial port
*  The terminal must be configured as follows:
*
*  Hardware handshaking.
*  8 bit data.
*  No parity.
*  9600 Baud (Unless otherwise noted).
*
*
*
*  On reset, the monitor sends copyright and version notices, as well as
*  a register display to the terminal.  (There are semiphores which can
*  be placed in EPROM to prevent this)
*
*  When the monitor is ready for a command, a '.' (period) is sent.
*
*  Commands are entered after the period.  No backsapces are allowed*
*  this is due to the small initial buffer space.  If a character is
*  entered incorrectly, usually a return (CR) will cancel the command.
*
*  In most cases, a control C  (^C) will cancel a command in progress.

	 PAGE
*
*                                  MONITOR COMMANDS
*
*  ? or H     Lists the commands available
*
*
*  R          Display processor registers (PC,F,A,X,Y,SP)

*  M          Alter Memory address and locations
*              The first 4 characters entered after the 'M' set the
*              current address pointer.  Each pair of characters entered
*              after the address changes the byte at the current address.
*              A space entered after a byte change increments the current
*              address pointer.  A CR will end the command, and
*              can be entered after the initial address or any number of
*              byte changes.

*  >          Increment the current address and display the contents.
*              (The M command, above, can set the current address pointer.)

*  <          Decrement the current address and display the contents.
*              (The M command, above, can set the current address pointer.)

*  SPACE      Uses the current addres spointer and displays the contents.

*  C          Displays a checksum of memory from start address to end address.
*              Format is C SSSS EEEE, where SSSS is start address and EEEE
*              is the end address.

*  D          Displays memory from start address to end address.
*              Format is D SSSS EEEE, where SSSS is the start address...

*  T          Reads current time of day clock and displays the results.

*  X          Switches the system from hardware handshake to XON-XOFF.  This
*              is a toggle command, each time X is entered, the system
*              switches.  The flag is displayed after each toggle.  The
*              flag is zero for hardware handshake.
*
*
*  A          Alter registers in the order PC F A X Y SP.  A space skips
*              to the next register.  A CR ends the command.
*
*  F          Fill memory from start address to end address with value.
*              The format is F SSSS EEEE VV.

*  V          Move a block of memory from start address to end address.
*              The format is V SSSS EEEE XX.  SSSS is the start address,
*              EEEE is the end address, and XX is the number of bytes.
*              if XX = 0, 256 bytes are moved.
	 PAGE
*                                  Monitor Commands, cont.

*  G (CR)     Begin execution from the current address in the PC.

*  G ADDR     Set PC to ADDR and begin execution.

*  J (CR)     Do a JSR to the current PC address

*  J ADDR     Do a JSR to ADDR.
*
*  U          Jump through the USR command vector.  (This is a hook to allow
*              additional commands to be added to the monitor.

*  B          Jumps to BASIC cold start.

*  K          Jumps to BASIC warm start.

*
*  I/O COMMANDS
*  ------------------------
*
*  S          Start of a data record in Motorola S28 or S19 format.  When
*              this command is received, data is not echoed until a CR is
*              received.  This command is used to load programs, etc and
*              the Error (E) command should be used after loading a number
*              of S28 records to check for data errors.

*  W          Output data in Motorola S28 format.  This command outputs 16
*              byte records (the last record may be less) from start address
*              to end address.  The format is W SSSS EEEE
*
*  E          Display the number of S28 receive errors noticed.  While 'S'
*              records are received, an accumulation of checksum errors is
*              kept.  This command displays that accumulation.  Once
*              displayed, the error number is cleared to 0.
*
	 PAGE
*                                  Monitor Operation:
*
*             The monitor is entered on power up and on a BRK instruction.
*              Generally, if code goes wild, it will eventually hit a BRK'
*              and return to the monitor.  At that time, the registers are
*              displayed and the monitor commands are available to the user.
*
*             Interrupts are still running, though, and a bad interrupt can
*              disable the monitor functions.
*
*             Code debugging can be accomplished by placing BRK (00)
*              instructions in the code, entering the monitor, and examining
*              memory and registers.  Be careful with the BRK instructions*
*              if you replace a normal instruction with a BRK you cannot
*              continue until you return the original instruction to that
*              location and fix the PC accordingly.
*
*             When a BRK instruction has occurred, the PC in the monitor will
*              be pointing at the location AFTER the BRK instruction.  This
*              means that if the BRK is placed in the code by an assembler,
*              and the next instruction follows the BRK, then you can
*              continue execution simply by hitting 'G' followed be a CR.

*
*
*                                  INTERRUPTS
*
*             The monitor handles all interrupts.  In many cases, this is
*              done by having a second vector in RAM.  When the monitor
*              is started, it writes the RAM locations with pointers to its
*              own interrupt routines.  Unused interrupts simply jump to
*              RESET.  The user can revector his interrupts by changing
*              the RAM vector.
*
*             To save memory, most of the edge interrupts jump through the
*              same vector.  This defeats the purpose of having all those
*              individual vectors in the first place, but then we only have
*              a limited amount of on chip RAM.
*
*             The result is that for the interrupts sharing the common vector,
*              the interrupt routine must be able to identify which interrupt
*              was received. See the code for more details.
	 ENDS

	 APPEND MONZPEQU.ASM
