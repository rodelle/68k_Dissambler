*-----------------------------------------------------------
* Title      : 68k Function Examples
* Written by : No Preference
* Description: Examples of how subroutines work, and a
*   demonstration of the No Preference argument
*   passing convention
*-----------------------------------------------------------
CR      EQU     $0D
LF      EQU     $0A    

START    ORG    $1000            ; first instruction of program

* Output
ProgramStart
    MOVE.L  #kStartMessage,D0 * load start message as arg1
    JSR     PrintMessage
    
    MOVE.L  #$beef, D3  * test callee save of D3
    
    MOVE.L  #$AAAA9f01,D0
    MOVE.L  #12,D1
    MOVE.L  #4,D2
    JSR     GetBits     * expected return value of 0x9

    CMP     #$9,D0
    BEQ     Success
    BNE     Fail
    
Success
    MOVE    #kSuccessMessage,D0
    JSR     PrintMessage
    JMP Done

Fail
    MOVE    #kFailMessage,D0
    JSR     PrintMessage
    JMP Done

Done
    MOVE    #kGoodbyeMessage,D0
    JSR     PrintMessage

    MOVE.B  #9,D0 * quits program
    TRAP    #15
    
*****************************************************************************
* GetBits(value, lowerBit, numBits)
* Args: D0 (value), D1(lowerBit), D2(numBits)
* Returns the bits from value[lowerBit] to value[lowerBit + numBits]
* ex. GetBits(1111 0110 0111, 3, 5) = 1111 [0110 0]111 = 01100
*****************************************************************************
GetBits
    MOVE.L  D3,-(SP)    * callee save D3 so it can be used by the function
    CLR     D3
    MOVE.L  #1,D3
    ASL     D2,D3
    SUB     #1,D3       * create the bit mask
    LSR     D1,D0       * discard lower bits of the value
    AND.L   D3,D0       * mask off the higher bits of the value
                        * store the value in the return register
    MOVE.L  (SP)+,D3    * restore used register(s)
    RTS

*****************************************************************************
* void PrintMessage(String* message)
* Args: D0(message)
* Loads the value stored in D0 as an address and calls Trap task #14
*   to print out its contents as a string
*****************************************************************************
PrintMessage        * void PrintMessage(String* message)
    MOVEA.L D0,A1   * load address of message from argument 1
    MOVE.B  #14,D0  * print contents of A1
    TRAP    #15     
    RTS

kFailMessage
    DC.B    'The expected value is wrong!',CR,LF,0

kSuccessMessage
    DC.B    'The expected value is correct!',CR,LF,0

kStartMessage
    DC.B    'This program tests 68k functions and the No Preference calling '
    DC.B    'convention',CR,LF
    DC.B    'GetBits(0xAAAA9F01, 12, 4) should return the 4 bits starting at '
    DC.B    'bit 12, or 0x9.',CR,LF,CR,LF,0

kGoodbyeMessage
    DC.B    CR,LF,'Goodbye!',0
    
    END START


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
