*-----------------------------------------------------------
* Title      : 68k String Print Function
* Written by : No Preference
* Description: Functions for printing out literal words and
*   Hexadecimal values.
*-----------------------------------------------------------

CR      EQU     $0D
LF      EQU     $0A    

sDot    EQU     $10A
sHash   EQU     $10B
sDollar EQU     $10C
sPercent EQU    $10D
sSpace  EQU     $10E

sNewLine EQU    $200
sOR     EQU     $201

sADD    EQU     $300
sBCC    EQU     $301
sBCS    EQU     $302
sBVC    EQU     $303
sBGE    EQU     $304
sBLT    EQU     $305
sBRA    EQU     $306
sCMP    EQU     $307
sEOR    EQU     $308
sROR    EQU     $309
sROL    EQU     $30A
sLSR    EQU     $30B
sLSL    EQU     $30C
sASL    EQU     $30D
sASR    EQU     $30E
sSUB    EQU     $30F
sORI    EQU     $310
sJSR    EQU     $311
sLEA    EQU     $312
sRTS    EQU     $313
sNEG    EQU     $314

sADDA   EQU     $400
sMOVE   EQU     $401
sBCLR   EQU     $402
sDIVS   EQU     $403
sSUBQ   EQU     $404
sMULS   EQU     $405
sCMPI   EQU     $406

sMOVEA   EQU    $500
sMOVEM   EQU    $501

START    ORG    $1000            ; first instruction of program
    
ProgramStart
    JSR PrintHexadecimal

    MOVE.L  #kStartMessage,D0 * load start message as arg1
    JSR     PrintMessage

    MOVE    #sOR,D0 * print out literal "ADD"
    JSR PrintLiteral
    
    MOVE    #sNewLine,D0
    JSR PrintLiteral
    
    MOVE    #sMOVEA,D0 * print out literal "MOVEA"
    JSR PrintLiteral

    MOVE    #sNewLine,D0
    JSR PrintLiteral
    
    MOVE    #sADD,D0 * print out literal "ADD"
    JSR PrintLiteral

    MOVE    #sSpace,D0
    JSR PrintLiteral

    MOVE    #sBRA,D0 * print out literal "BRA"
    JSR PrintLiteral
    
    MOVE    #sSpace,D0
    JSR PrintLiteral
    
    MOVE    #sNEG,D0 * print out literal "NEG"
    JSR PrintLiteral

    MOVE    #sNewLine,D0
    JSR PrintLiteral
    
    MOVE    #sADDA,D0 * print out literal "ADDA"
    JSR PrintLiteral
    
    MOVE    #sSpace,D0
    JSR PrintLiteral
    
    MOVE    #sBCLR,D0 * print out literal "BCLR"
    JSR PrintLiteral
    
    MOVE    #sSpace,D0
    JSR PrintLiteral
    
    MOVE    #sCMPI,D0 * print out literal "CMPI"
    JSR PrintLiteral
    
Done
    MOVE    #kGoodbyeMessage,D0
    JSR     PrintMessage

    MOVE.B  #9,D0 * quits program
    TRAP    #15

* ex. D0=$AFE1 prints "AFE1"
PrintHexadecimal
    MOVE.L  #$3DDE,D1
    MOVEM.L D1-D7, -(SP)    * save registers
    
    MOVE.L  D1,D0
    AND     #$F,D0
    JSR     PrintLiteral
    
    MOVE.L  D1,D0
    LSR     #4,D0
    AND     #$F,D0
    JSR     PrintLiteral

    MOVE.L  D1,D0
    LSR     #4,D0
    AND     #$F,D0
    JSR     PrintLiteral

    MOVEM.L (SP)+, D1-D7    * restore registers
    JSR     PrintMessage    * print the word
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
    
    MOVE.L   D7,D0          * restore the original argument
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
    CMP     #0,D6       
    BNE     RLPL_Endif
    ADD     #1,D6           * Add 1 if using StringLiterals0 for numbers    
RLPL_Endif
    
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
    ASL     D2,D3
    SUB     #1,D3       * create the bit mask
    LSR     D1,D0       * discard lower bits of the value
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

kFailMessage
    DC.B    CR,LF,'FAIL!!',CR,LF,0

kSuccessMessage
    DC.B    CR,LF,'SUCCESS!!',CR,LF,0

kStartMessage
    DC.B    'This function allows users to print from a set of literal words '
    DC.B    CR,LF,'by passing in an index ',CR,LF,CR,LF,0

kGoodbyeMessage
    DC.B    CR,LF,'Goodbye!',0

StringLiterals0
    DC.B    '0',0,'1',0,'2',0,'3',0,'4',0,'5',0,'6',0,'7',0,'8',0,'9',0
    DC.B    'A',0,'B',0,'C',0,'D',0,'E',0,'F',0

StringLiterals1
    DC.B    '0',0,'1',0,'2',0,'3',0,'4',0,'5',0,'6',0,'7',0,'8',0,'9',0
    DC.B    '.',0,'#',0,'$',0,'%',0,' ',0

StringLiterals2
    DC.B    CR,LF,0
    DC.B    'OR',0

StringLiterals3
    DC.B    'ADD',0,'BCC',0,'BCS',0,'BVC',0,'BGE',0
    DC.B    'BLT',0
    DC.B    'BRA',0
    DC.B    'CMP',0
    DC.B    'EOR',0
    DC.B    'ROR',0
    DC.B    'ROL',0
    DC.B    'LSR',0
    DC.B    'LSL',0
    DC.B    'ASL',0
    DC.B    'ASR',0
    DC.B    'SUB',0
    DC.B    'ORI',0
    DC.B    'JSR',0
    DC.B    'LEA',0
    DC.B    'RTS',0
    DC.B    'NEG',0
    
StringLiterals4
    DC.B    'ADDA',0
    DC.B    'MOVE',0
    DC.B    'BCLR',0
    DC.B    'DIVS',0
    DC.B    'SUBQ',0
    DC.B    'MULS',0
    DC.B    'CMPI',0
     
StringLiterals5
    DC.B    'MOVEA',0
    DC.B    'MOVEM',0,0

StringLiterals 
    DC.W StringLiterals0 * numbers
    DC.W StringLiterals1 * 1 character words
    DC.W StringLiterals2 * 2 character words
    DC.W StringLiterals3 * 3 character words
    DC.W StringLiterals4 * 4 character words
    DC.W StringLiterals5 * 5 character words


    END START


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
