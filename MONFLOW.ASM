	 STTL 'Monitor / Program Flow'
	 PAGE
	 DATA
*                                  PROGRAM FLOW
*
*        The 134 monitor (called the F-thousand monitor) is screened into the
*   ROM of the 134.  This section of text describes the steps taken by the
*   monitor from power up to a command prompt.  It is intended as an overview
*   only; not a specific, line by line analysis of the code.
*
*
*                                  GOALS
*
*        The monitor must be able to be 'shut off' that is it must exit to
*   another program immediately after reset if necessary.
*
*        The monitor must handle the serial port on the 134, and must provide
*   routines such that another program can easily use the serial port via
*   the monitor.
*
*        The monitor must be able to load other programs into RAM, and
*   provide some debugging capabilities.
*
*        The monitor must maintain a time of day clock, and be capable of
*   maintaining that clock on minimum power.
*
*        The monitor must fit in the $F000 to $FFFF memory space.
*
*
*        These are the main goals of the monitor.
*
*
*
*                                  RESET SEQUENCE
*
*        This monitor is intended for the internal ROM of the 134.  As such,
*   the assumption is that the reset vector is entered from an internal ROM
*   reset.  In reality, this means that the code is started with the BCR=00.
*
*        Reset can be either a pushbutton reset or a power up reset.  There
*   is no simple way to differentiate.  However, we will set some semiphores
*   (flags) in memory to tell us that certain aspects of the machine are
*   already initialized and should not be changed by the reset routine.
*
*        There is a checksum to tell us that the time of day clock is running
*   and is correct.  If this is the case, the clock value is not reset on
*   reset.  The same semiphore is used for baud rate.  Therefore, the only
*   way to get the ToD (Time of Day) clock or the baud rate to completely
*   reset is to completely remove power from the processor long enough for
*   the memory to scramble (one minute usually does it).
*
*        The second reset semiphore used is a three byte sequence in RAM to
*   indicate that the system is in 'power down'.  If  this is set the system
*   will jump to the low power vector (NE46) immediately after reset.
	 PAGE
*  RESET OCCURS
*
*        Interrupts disabled, stack reset, decimal mode cleared.
*
*        Check for low power semiphore; JMP (UNE46) if semiphore set.
*
*        Set BCR to 01 - this turns on external address and data lines.
*
*        Set PCS3 to $C0 - turns on RAM and ROM chip selects from the 134.
*
*        Check location $8000-$8002 for the string 'WDC'.
*        If it was there, JMP $8004.
*
*        Check location $0200-$0202 for the string 'WDC'.
*        If it was there, JMP $0204.
*
*        Start the fast clock. (Don't use it, just start it.)
*
*        Copy our interrupt vectors into the RAM interrupt vectors.
*
*        Delay  256 * 5 cycles for fast clock to be stable.
*
*        Switch to fast clock.
*
*        Enable the NE46 interrupt (but not the overall I bit).
*        This interrupt is used to detect power going down.
*
*        Set Timer 2 for a 1 second interrupt (ToD timer).
*
*        Enable T2 interrupt (but not the I bit yet).
*
*        Set up pointers to the serial buffers. (tiny, in uP RAM)
*
*        Figure out the fast crystal frequency by counting it against
*        the 32 KHz ToD clock crystal.
*
*        Check the ToD clock checksum to see if the clock is valid.  If
*        the clock is not valid, reset it and reset the baud rate counters
*        for the serial port to the default values.  If the clock checksum
*        is OK, leave the clock and the serial baud rate alone.
*
*        Set up control port of serial port for Xmit and RX.
*
*        Check location $E000 for $4C.  If a 4C is present, JSR $E000.
*
*        Read the serial port to clear any inital trash data.
*
*        ENABLE INTERRUPTS VIA CLEARING THE I BIT.
*
*        Output the initial message to the serial port.
*        (Small initial buffers and a handshake line held in the FALSE
*         state may cause the monitor to hang here waiting for buffer space
*         that will not be available until the handshake line goes TRUE)
*
*        Execute a BRK instruction (which takes us to the command interpreter)
	 ENDS

	 APPEND MONTXT.ASM
