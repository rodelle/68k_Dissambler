*-----------------------------------------------------------
* Title      : 68k String Print Function
* Written by : No Preference
* Description: Functions for printing out literal words and
*   Hexadecimal values.
*-----------------------------------------------------------

CR      EQU     $0D
LF      EQU     $0A    

* Ascii Table Reference
* A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z
* 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F 50 51 52 53 54 55 56 57 58 59 5A

* _  !  "  #  $  %  &  '  (  )  *  +  ,  -  .  /
* 20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F

* 0  1  2  3  4  5  6  7  8  9
* 30 31 32 33 34 35 36 37 38 39

sA      EQU     $41000000
sD      EQU     $44000000
sDot    EQU     $2E000000
sHash   EQU     $23000000
sDollar EQU     $24000000
sPercent EQU    $25000000
sPlus   EQU     $2B000000
sMinus  EQU     $2D000000
sLParen EQU     $28000000
sRParen EQU     $29000000
sSpace  EQU     $20000000
sComma  EQU     $2C000000

sOR     EQU     $4F520000

sADD    EQU     $41444400
sBCC    EQU     $42434300
sBCS    EQU     $42435300
sBVC    EQU     $42564300
sBGE    EQU     $42474500
sBLT    EQU     $424C5400
sBRA    EQU     $42524100
sCMP    EQU     $434D5000
sEOR    EQU     $454F5200
sROR    EQU     $524F5200
sROL    EQU     $524F4C00
sLSR    EQU     $4C535200
sLSL    EQU     $4C534C00
sASL    EQU     $41534C00
sASR    EQU     $41535200
sSUB    EQU     $53554200
sORI    EQU     $4F524900
sJSR    EQU     $4A535200
sLEA    EQU     $4C454100
sRTS    EQU     $52545300
sNEG    EQU     $4E454700

sADDA   EQU     $41444441
sMOVE   EQU     $4D4F5645
sBCLR   EQU     $42434C52
sDIVS   EQU     $44495653
sSUBQ   EQU     $53554251
sMULS   EQU     $4D554C53
sCMPI   EQU     $434D5049

START    ORG    $1000
    
ProgramStart
    MOVE.L  #kStartMessage,D0   * load start message as arg1
    JSR     PrintMessage

    MOVE.L  #sHash,D1
    JSR     PrintWord
    
    MOVE.L  #sDollar,D1
    JSR     PrintWord
    
    MOVE.L  #$deadbeef,D1       * print out literal "DEADBEEF"
    MOVE    #8,D2
    JSR     PrintHexadecimal
    
    JSR     PrintNewline

    *****************************************************
    * Prints "MOVE D3,(A4)+"
    *****************************************************
    MOVE.L  #sMove,D1           * prints "MOVE"
    JSR     PrintWord
    
    MOVE.L  #$20443300,D1       * prints " D3"
    JSR     PrintWord

    MOVE.L  #$2C284134,D1       * prints ",(A4"
    JSR     PrintWord
       
    MOVE.L  #$292B0000,D1       * prints ")+"
    JSR     PrintWord

    JSR     PrintNewline
    *****************************************************
    
    MOVE.L  #sOR,D1             * print out literal "OR"
    JSR     PrintWord

    JSR     PrintNewline
    
    MOVE.L  #sADD,D1            * print out literal "ADD"
    JSR     PrintWord

    MOVE.L  #sSpace,D1
    JSR     PrintWord

    MOVE.L  #sBRA,D1            * print out literal "BRA"
    JSR PrintWord
    
    MOVE.L  #sSpace,D1
    JSR     PrintWord
    
    MOVE.L  #sNEG,D1            * print out literal "NEG"
    JSR     PrintWord

    JSR     PrintNewline
    
    MOVE.L  #sADDA,D1           * print out literal "ADDA"
    JSR     PrintWord
    
    MOVE.L  #sSpace,D1
    JSR     PrintWord
    
    MOVE.L  #sBCLR,D1           * print out literal "BCLR"
    JSR     PrintWord
    
    MOVE.L  #sSpace,D1
    JSR     PrintWord
    
    MOVE.L  #sCMPI,D1           * print out literal "CMPI"
    JSR     PrintWord
    
Done
    MOVE    #kGoodbyeMessage,D0
    JSR     PrintMessage

    MOVE.B  #9,D0               * quits program
    TRAP    #15

*****************************************************************************
* PrintWord(word)
* Args: D1 (ascii values of words)
* Prints the word using each byte of the argument as an ascii value
* ex. PrintWord($41444400) prints out "ADD"
*                 A D D x
*     PrintWord($2C284134) prints out ",(A4"
*                 , ( A 4
*****************************************************************************  
PrintWord
    MOVE    #kStringBuffer,A0
    MOVE.L  #0,(A0)+
    MOVE.L  #0,(A0)+
    MOVE.L  #0,(A0)+
    SUB     #12,A0
    MOVE.L  D1,(A0)
    MOVE.L  A0,D0
    JSR     PrintMessage
    RTS

*****************************************************************************
* PrintNewline()
* Args: None
* Prints a literal newline
*****************************************************************************
PrintNewline
    MOVEM.L D0, -(SP) * Save used registers
    MOVE.L #kNewline,D0
    JSR PrintMessage
    MOVEM.L (SP)+, D0 * Restore used registers
    RTS

*****************************************************************************
* void PrintHexadecimal(number, size)
* Args: D1 (the number to print), D2 (how many numbers to print)     
* Prints the hexadecimal number stored in D0. The size is used to print or 
* omit trailing zeros;
* ex. PrintHexadecimal($AFE1, 4) prints "AFE1"
*     PrintHexadecimal($00BC, 4) prints "00E1", leading 0s to fit 4 chars
*     PrintHexadecimal($0012, 2) prints   "12", no leading 0s
*****************************************************************************
PrintHexadecimal    
    MOVEM.L D1-D7, -(SP)    * save registers
    MOVE.L  D1,D7   * save the register
    MOVE    D2,D6   * counter
    
    SUB     #1,D2
    ASL.L   #2,D2   * offset to the correct hex bit
    MOVE    #4,D3   * pass the size of a hex bit to GetBits
    
RLPH_DoWhile        * individually mask and print each hex bit
    MOVE.L  D7,D1
    JSR     GetBits
    MOVE    D0,D1
    CMP     #10,D1  
    BGE     RLPH_ToAsciiLetter  * if (hexBit >= $A)
                                * else
    ADD     #48,D1  * add 48 to convert number to ascii
    BRA RLPH_Continue

RLPH_ToAsciiLetter
    ADD     #55,D1  * add 55 to convert $A to 'A'
                    * ascii value of 'A' is 65, 65-10 = 55
                    
    BRA RLPH_Continue
    
RLPH_Continue
    ASL.L   #8,D1
    ASL.L   #8,D1
    ASL.L   #8,D1   * put number in index 0 of string
    JSR     PrintWord * print the letter
    
    SUB.L   #4,D2   * get the offset to the next hex bit
    
    SUB     #1,D6
    BEQ RLPH_Done   * (while --D6 != 0)
    BRA RLPH_DoWhile
    
RLPH_Done
    MOVEM.L (SP)+, D1-D7    * restore registers
    RTS
        
*****************************************************************************
* int GetBits(value, lowerBit, numBits)
* D0          D1     D2        D3
* Returns the bits from value[lowerBit] to value[lowerBit + numBits]
*
* ex. Func_GetBits( 0000111101100111 , LSB = 3 , length = 5 )
*   extracts:       FEDCBA98^^^^^210
*   so D0 will be:          01100
*****************************************************************************
GetBits
    MOVEM.L  D1-D4,-(SP)    * save D4 so it can be used by the function
    MOVE.L  D1,D0       * store initial value in return register

    * bit mask set up
    CLR     D4
    MOVE.L  #1,D4
    LSL     D3,D4       * calculate 2^n (n = number of bits)
    SUB     #1,D4       * create the bit mask with 2^n-1

    LSR.L   D2,D0       * shift right, discarding lower bits
    AND.L   D4,D0       * mask out higher bits

    MOVEM.L  (SP)+,D1-D4    * restore used register(s)
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
    DC.B    'These function allows users to print from a set of literal ',CR,LF
    DC.B    'word by passing in a value containing the ascii values of',CR,LF
    DC.B    'of each character to be printed',CR,LF
    DC.B    CR,LF,0,0

kGoodbyeMessage
    DC.B    CR,LF,'Goodbye!',0

kNewline
    DC.B    CR,LF,0,0

kStringBuffer
    DS  12

    END START
