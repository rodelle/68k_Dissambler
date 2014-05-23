*-----------------------------------------------------------
* Title      : 68k Grabs Input from the User and prints it
* Written by : No Preference
* Description: Demonstrates the input loop that grabs the 
*   starting and ending address of the test program.
*-----------------------------------------------------------

CR      EQU     $0D
LF      EQU     $0A    

START    ORG    $1000
    
ProgramStart
    MOVE.L #kStartAddressPrompt,D0
    JSR PrintMessage
    
    JSR GetFourHexBitsFromUser
    MOVE.L #0,A5
    MOVEA.L D0,A5
    
    MOVE.L #kNewline,D0
    JSR PrintMessage
    
    MOVE.L #kEndAddressPrompt,D0
    JSR PrintMessage
    
    JSR GetFourHexBitsFromUser
    MOVE.L #0,A6
    MOVEA.L D0,A6
    
    * MOVE.B #4, D1
    * JSR PrintHexadecimal
    
Done
    MOVE    #kGoodbyeMessage,D0
    JSR     PrintMessage

    MOVE.B  #9,D0 * quits program
    TRAP    #15
    
*****************************************************************************
* GetFourHexBitsFromUser()
* Args: None
* Returns the hexadecimal value of the next 4 characters entered by the user
* Ex. "AD12" returns $AD12
*****************************************************************************
GetFourHexBitsFromUser
    MOVEM.L D2-D4, -(SP) * Save used registers
    CLR     D2
    CLR     D0
    MOVE.B  #4,D3 * Read the next 4 letters entered by user
    
GFHBRL_DoWhile
    MOVE.B  #5,D0 * Reads letter from the user into D1
    TRAP    #15

    JSR ValueFromHexadecimal * convert to decimal

    LSL.L   #4,D2 * Create space for next hex bit
    ADD.B   D0,D2 * Add the just read hex bit into the return value

    SUB.B   #1,D3       * Read the next hex bit
    BEQ GFHBRL_Done     * (while --D3 != 0)
    BRA GFHBRL_DoWhile
    
GFHBRL_Done
    MOVE.L  D2,D0
    MOVEM.L (SP)+, D2-D4 * Restore used registers
    RTS

*****************************************************************************
* ValueFromHexAscii(hexNumber)
* Args: D1 (the hexBit ascii value)
* Converts the hex bit ascii value into decimal value
* Ex. ValueFromHexAscii(65) = $A * The ascii value of 'A' is 65
*     ValueFromHexAscii(51) = $3 * The ascii value of '3' is 51
*****************************************************************************
ValueFromHexadecimal
    MOVEM.L D2, -(SP)   * save registers
    CMP.B   #58,D1      * Ascii Value '9' is at 57
    BLT     VFHRL_ParseNumber
    BRA     VFHRL_ParseLetter

VFHRL_ParseNumber
    SUB.B   #48,D1      * Ascii value '0' = 48
    BRA VFHRL_Done
VFHRL_ParseLetter
    SUB.B   #55,D1      * Ascii value 'A' = 65
VFHRL_Done
    MOVE.L  D1,D0
    MOVEM.L (SP)+, D2   * restore used registers
    RTS

*****************************************************************************
* PrintHexadecimal(number, size)
* Args: D0 (the number to print), D1 (how many numbers to print)     
* Prints the hexadecimal number stored in D0. The size is used to print or 
* omit trailing zeros;
* ex. PrintHexadecimal($AFE1, 4) prints "AFE1"
*     PrintHexadecimal($00BC, 4) prints "00E1", leading 0s to fit 4 chars
*     PrintHexadecimal($0012, 2) prints   "12", no leading 0s
*****************************************************************************
PrintHexadecimal    
    MOVEM.L D1-D7, -(SP)    * save registers
    MOVE.L  D0,D7   * save the register
    MOVE    D1,D6   * counter
    
    SUB     #1,D1
    ASL.L   #2,D1   * offset to the correct hex bit
    MOVE    #4,D2   * pass the size of a hex bit to GetBits
    
RLPH_DoWhile        * individually mask and print each hex bit
    MOVE.L  D7,D0   
    JSR     GetBits
    ADD     #$100,D0 * 1 character string literal
    JSR     PrintLiteral
    SUB.L   #4,D1   * get the offset to the next hex bit
    
    SUB     #1,D6
    BEQ RLPH_Done   * (while --D6 != 0)
    BRA RLPH_DoWhile
    
RLPH_Done
    MOVEM.L (SP)+, D1-D7    * restore registers
    RTS
    
*****************************************************************************
* PrintLiteral(wordIndex)
* Args: D0 ($<size><index>)
* Prints the word using the size and index to look up values in a
* pre-initialized 2d array of words.
* ex. PrintLiteral($30A) prints out the 10th, 3 letter word, or "ROL"
*     Words have been assigned user-friendly constants for your pleasure.
*     Passing in sMOVE as an argument to PrintLiteral prints out "MOVE", etc.
*****************************************************************************
PrintLiteral
    MOVEM.L D1-D7, -(SP)    * save registers
    MOVE.L  D0,D7           * save D0
    MOVE.L  #8,D1
    MOVE.L  #4,D2
    JSR     GetBits         * get the number of characters in the word
    MOVE.L  D0,D6
    
    MOVE.L  D7,D0          * restore the original argument
    MOVE.L  #0,D1
    MOVE    #8,D2
    JSR     GetBits         * get the array index containg the correct string
    MOVE    #2,D2
    
    * D6 contains the number of characters in the word
    * D0 contains the array index
    * D2 contains 2, the size of the index into the string array
    
    LEA     StringLiterals,A0
    MULU    D6,D2           * get index into correct string array
    ADD.L   D2,A0           * access the correct string array
    MOVEA  (A0),A0          * get the string array    
    
    * if numCharacters == 0, numCharacters++
*    CMP     #0,D6       
*    BNE     RLPL_Endif
*    ADD     #1,D6           * Add 1 if using StringLiterals0 for numbers    
*RLPL_Endif
    
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
    MOVEM.L D1-D7, -(SP)    * save registers
    CLR     D3
    MOVE.L  #1,D3
    ASL.L   D2,D3
    SUB.L   #1,D3       * create the bit mask
    LSR.L   D1,D0       * discard lower bits of the value
    AND.L   D3,D0       * mask off the higher bits of the value
                        * store the value in the return register
    MOVEM.L (SP)+, D1-D7    * restore registers
    RTS

*****************************************************************************
* void PrintMessage(String* message)
* Args: D0(message)
* Loads the value stored in D0 as an address and calls Trap task #14
*   to print out its contents as a string
*****************************************************************************
PrintMessage        * void PrintMessage(String* message)
    MOVEM.L D1-D7, -(SP)    * save registers
    MOVEA.L D0,A1   * load address of message from argument 1
    MOVE.B  #14,D0  * print contents of A1
    TRAP    #15     
    MOVEM.L (SP)+, D1-D7    * restore registers
    RTS

kStartMessage
    DC.B    'This functions grabs two values from the user and stores them ',CR,LF
    DC.B    'in A5 and A6, the starting and ending address of the test program'
    DC.B    CR,LF,CR,LF,0,0

kGoodbyeMessage
    DC.B    CR,LF,'Goodbye!',0

StringLiterals1
    DC.B    '0',0,'1',0,'2',0,'3',0,'4',0,'5',0,'6',0,'7',0
    DC.B    '8',0,'9',0,'A',0,'B',0,'C',0,'D',0,'E',0,'F',0
    DC.B    '.',0,'#',0,'$',0,'%',0,'+',0,'-',0,'(',0,')',0
    DC.B    ' ',0,',',0

StringLiterals2
    DC.B    CR,LF,0
    DC.B    'OR',0

StringLiterals3
    DC.B    'ADD',0,'BCC',0,'BCS',0,'BVC',0,'BGE',0
    DC.B    'BLT',0,'BRA',0,'CMP',0,'EOR',0,'ROR',0
    DC.B    'ROL',0,'LSR',0,'LSL',0,'ASL',0,'ASR',0
    DC.B    'SUB',0,'ORI',0,'JSR',0,'LEA',0,'RTS',0
    DC.B    'NEG',0
    
StringLiterals4
    DC.B    'ADDA',0,'MOVE',0,'BCLR',0,'DIVS',0
    DC.B    'SUBQ',0,'MULS',0,'CMPI',0
     
StringLiterals5
    DC.B    'MOVEA',0
    DC.B    'MOVEM',0,0

StringLiterals 
    DC.W 0 * 0 character words
    DC.W StringLiterals1 * numbers and symbols
    DC.W StringLiterals2 * 2 character words
    DC.W StringLiterals3 * 3 character words
    DC.W StringLiterals4 * 4 character words
    DC.W StringLiterals5 * 5 character words

kNewline
    DC.B CR,LF,0

kStartAddressPrompt
    DC.B 'Please enter the starting address: ',0

kEndAddressPrompt
    DC.B 'Please enter the ending address: ',0

kRestartPrompt
    DC.B 'Would you like to dissamble another program (y/n)? ',0

    END START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
