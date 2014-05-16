*-----------------------------------------------------------
* Title      : 68k String Print Function
* Written by : No Preference
* Description: Functions for printing out literal words and
*   Hexadecimal values.
*-----------------------------------------------------------
CR      EQU     $0D
LF      EQU     $0A    

sNewLine EQU     0
sADD     EQU     $30

sMOVE    EQU     $40
sADDA    EQU     $41
sBCLR    EQU     $42

sMOVEM   EQU     $50
sMOVEA   EQU     $51

START    ORG    $1000            ; first instruction of program
    
* Output
ProgramStart
    MOVE.L  #kStartMessage,D0 * load start message as arg1
    JSR     PrintMessage
    
    MOVE    #sMOVE,D0 * print out literal "MOVE"
    JSR PrintLiteral
    
    MOVE    #sADDA,D0 * print out literal "ADDA"
    JSR PrintLiteral
    
    MOVE    #sBCLR,D0 * print out literal "BCLR"
    JSR PrintLiteral
    
    BRA      Success
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
    
PrintLiteral
    * if d0 == 0, print newline
    * if d0 == beef, print tab
    * if d0 == dead, print space
    MOVEM.L D1-D7, -(SP)    * save registers
    MOVE.L  D0,D7           * save D0
    MOVE.L  #4,D1
    MOVE.L  #4,D2
    JSR     GetBits         * get the number of characters in the word
    MOVE.L  D0,D6
    
    MOVE.L   D7,D0          * restore the original argument
    MOVE.L  #0,D1
    MOVE.L  #4,D2
    JSR     GetBits         * get the array index containg the correct string
    
    * D6 contains the number of characters in the word
    * D0 contains the array index
    * D2 contains 4, the size of the index into the string array
    
    LEA     StringLiterals,A0
    MULU    D6,D2           * get index into correct string array
    ADD.L   D2,A0           * access the correct string array
    MOVEA.L (A0),A0         * get the string array
    
    ADD     #1,D6           * add one for the null terminator
    MULU    D6,D0           * get the correct array index
    ADD     D0,A0           * access the correct string in the array
    
    MOVE    A0,D0           * arg0 for PrintMessage
    MOVEM.L (SP)+, D1-D7    * restore registers
    JSR     PrintMessage    * print the word
    RTS
    
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
    DC.B    CR,LF,'FAIL!!',CR,LF,0

kSuccessMessage
    DC.B    CR,LF,'SUCCESS!!',CR,LF,0

kStartMessage
    DC.B    'This function allows users to print from a set of literal words '
    DC.B    'by passing in an index ',CR,LF,CR,LF,0

kGoodbyeMessage
    DC.B    CR,LF,'Goodbye!',0

StringLiterals3
    DC.B    'ADD',0
    
StringLiterals4
    DC.B    'MOVE',0
    DC.B    'ADDA',0
    DC.B    'BCLR',0
    DC.B    'DIVS',0
    
StringLiterals5
    DC.B    'MOVEM',0
    DC.B    'MOVEQ',0

StringLiterals 
    DC.L 0 * 0 character words
    DC.L 0 * 1 character words
    DC.L 0 * 2 character words
    DC.L StringLiterals3 * 3 character words
    DC.L StringLiterals4 * 4 character words
    DC.L StringLiterals5 * 5 character words


    END START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
