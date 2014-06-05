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

sA      EQU     $41
sD      EQU     $44
sDot    EQU     $2E
sHash   EQU     $23
sDollar EQU     $24
sPercent EQU    $25
sPlus   EQU     $2B
sMinus  EQU     $2D
sLParen EQU     $28
sRParen EQU     $29
sSpace  EQU     $20
sComma  EQU     $2C

sOR     EQU     $4F52

sADD    EQU     $414444
sBCC    EQU     $424343
sBCS    EQU     $424353
sBVC    EQU     $425643
sBGE    EQU     $424745
sBLT    EQU     $424C54
sBRA    EQU     $425241
sCMP    EQU     $434D50
sEOR    EQU     $454F52
sROR    EQU     $524F52
sROL    EQU     $524F4C
sLSR    EQU     $4C5352
sLSL    EQU     $4C534C
sASL    EQU     $41534C
sASR    EQU     $415352
sSUB    EQU     $535542
sORI    EQU     $4F5249
sJSR    EQU     $4A5352
sLEA    EQU     $4C4541
sRTS    EQU     $525453
sNEG    EQU     $4E4547

sADDA   EQU     $41444441
sMOVE   EQU     $4D4F5645
sBCLR   EQU     $42434C52
sDIVS   EQU     $44495653
sSUBQ   EQU     $53554251
sMULS   EQU     $4D554C53
sCMPI   EQU     $434D5049

START    ORG    $1000
    
ProgramStart
    MOVE.L  #kStartMessage,D1   * load start message as arg1
    JSR     PrintMessage

    JSR     ResetStringBuffer
    MOVE.L  #sOR,D1
    MOVE.B  #2,D2
    JSR     AddWordToStringBuffer
    JSR     AddWordToStringBuffer
    JSR     InvalidateStringBuffer  * InvalidateStringBuffer was called
    JSR     PrintStringBuffer       * this print call prints out "Invalid Opcode"
    JSR     PrintNewline
    
    JSR     ResetStringBuffer
    MOVE.L  #sDollar,D1
    JSR     AddWordToStringBuffer
     * PrintStringBuffer was not called, nothing is printed

    JSR     ResetStringBuffer    
    MOVE.L  #$deadbeef,D1       * print out literal "DEADBEEF"
    MOVE    #8,D2
    JSR     PrintHexadecimal
    JSR     PrintStringBuffer
    
    JSR     PrintNewline

    *****************************************************
    * Prints "MOVE D3,(A4)+"
    *****************************************************
    JSR     ResetStringBuffer
    
    MOVE.L  #sMove,D1           * prints "MOVE"
    MOVE.B  #4,D2
    JSR     AddWordToStringBuffer
    
    MOVE.L  #$204433,D1         * prints " D3"
    MOVE.B  #3,D2
    JSR     AddWordToStringBuffer

    MOVE.L  #$2C284134,D1       * prints ",(A4"
    MOVE.B  #4,D2
    JSR     AddWordToStringBuffer
       
    MOVE.L  #$292B,D1           * prints ")+"
    MOVE.B  #2,D2
    JSR     AddWordToStringBuffer

    JSR     PrintStringBuffer
    JSR     PrintNewline
    *****************************************************

    JSR     ResetStringBuffer    
    MOVE.B  #2,D2
    MOVE.L  #sOR,D1             * print out literal "OR"
    JSR     AddWordToStringBuffer

    JSR     PrintNewline
    
    *****************************************************
    * 3 Letter words
    *****************************************************
    JSR     ResetStringBuffer
    MOVE.L  #sADD,D1            * print out literal "ADD"
    MOVE.B  #3,D2
    JSR     AddWordToStringBuffer

    MOVE.L  #sSpace,D1
    MOVE.B  #1,D2
    JSR     AddWordToStringBuffer

    MOVE.L  #sBRA,D1            * print out literal "BRA"
    MOVE.B  #3,D2
    JSR AddWordToStringBuffer
    
    MOVE.L  #sSpace,D1
    MOVE.B  #1,D2
    JSR     AddWordToStringBuffer
    
    MOVE.L  #sNEG,D1            * print out literal "NEG"
    MOVE.B  #3,D2
    JSR     AddWordToStringBuffer
    JSR     PrintStringBuffer
    
    JSR     PrintNewline
    
    *****************************************************
    * 4 letter words
    *****************************************************
*    JSR     ResetStringBuffer
*    MOVE.B  #4,D2               * 4 letter words
*    MOVE.L  #sADDA,D1           * print out literal "ADDA"
*    JSR     AddWordToStringBuffer
*    
*    JSR     PrintSpace
*    
*    MOVE.L  #sBCLR,D1           * print out literal "BCLR"
*    MOVE.B  #4,D2    
*    JSR     AddWordToStringBuffer
*
*    JSR     PrintSpace
*    
*    MOVE.L  #sCMPI,D1           * print out literal "CMPI"
*    MOVE.B  #4,D2
*    JSR     AddWordToStringBuffer
    *****************************************************
    
Done
    MOVE.L  #kGoodbyeMessage,D1
    JSR     PrintMessage

    MOVE.B  #9,D0               * quits program
    TRAP    #15

*****************************************************************************
* void PrintStringBuffer()
* Args: none
* Prints the current contents of the string buffer to the screen
* Does not print the word if InvalidateStringBuffer was called prior to this
*   function.
*****************************************************************************
PrintStringBuffer
    MOVEM.L D0-D2/A0, -(SP) * Save used registers
    MOVE    #kStringBuffer,A0
    MOVE.L  (A0)+,D1
    AND.L   #$FF000000,D1
    BEQ     PSB_PrintInvalid   * if valid bit is not set, do not print
    MOVE.L  A0,D1
    JSR     PrintMessage
    BRA     PSB_Done
PSB_PrintInvalid
    MOVE.L  #kInvalidOpcode,D1
    JSR     PrintMessage
 
PSB_Done
    MOVEM.L (SP)+, D0-D2/A0 * Restore used registers
    RTS
 
*****************************************************************************
* void InvalidateStringBuffer()
* Args: none
* Invalidates the string buffer so that its contents will not be printed.
*****************************************************************************   
InvalidateStringBuffer
    MOVE    #kStringBuffer,A0
    MOVE.L  #$0,(A0)       * set the valid bit to false
    RTS
 
*****************************************************************************
* void ResetStringBuffer()
* Args: none
* Resets the contents of the string buffer and sets the valid bit to true
*****************************************************************************    
ResetStringBuffer
    MOVEM.L D0/A0, -(SP) * Save used registers
    
    MOVE.L  #kStringBufferSize,D0
    MOVE    #kStringBuffer,A0    
    MOVE.L  #$01000000,(A0)+        * reset the string head
    SUB     #4,D0
    
RSB_While
    CMP     #0,D0
    BEQ     RSB_EndWhile
    
    MOVE.L  #0,(A0)+                * zero out the string buffer
    
    SUB     #4,D0
    BRA     RSB_While
RSB_EndWhile
    MOVEM.L (SP)+, D0/A0 * Restore used registers
    RTS

*****************************************************************************
* void AddWordToStringBuffer(word, numChars)
* Args: D1 (ascii values of words), D2 (number of characters
* Prints the word using each byte of the argument as an ascii value
* ex. AddWordToStringBuffer($41444400) prints out "ADD"
*                 A D D x
*     AddWordToStringBuffer($2C284134) prints out ",(A4"
*                 , ( A 4
*****************************************************************************  
AddWordToStringBuffer
    MOVEM.L D0-D7/A0-A1, -(SP) * Save used registers
    MOVE    D2,D4
        
    MOVE    #kStringBuffer,A1
    MOVE.L  (A1),D5     * D5 contains the string meta
    AND.L   #$00FFFFFF,D5   * mask out the size of the string
    MOVE    D4,D6       * save the amount of characters being added
    
    MOVE    #kStringBuffer,A0
    ADD     #4,A0       * ignore string head
    ADD     D5,A0       * offset to the end of the string
    
AWTS_While
    CMP     #0,D4       * while (index != 0)
    BEQ     AWTS_EndWhile  
    
    MOVE    D4,D2
    SUB     #1,D2
    MULS    #8,D2       * get the bit number
    MOVE    #8,D3       * read the byte
    JSR     GetBits
    
    MOVE.B  D0,(A0)+
    
    SUB     #1,D4       * index --
    BRA AWTS_While      
    
AWTS_EndWhile

    MOVE    #kStringBuffer,A1     * retreive the string meta
    MOVE.L  (A1),D5
    ADD     D6,D5                 * add to the size of the string

    MOVE.L  D5,(A1)               * save the new string size
    MOVEM.L (SP)+, D0-D7/A0-A1 * Restore used registers
    RTS

*****************************************************************************
* PrintNewline()
* Args: None
* Prints a literal newline
*****************************************************************************
PrintNewline
    MOVEM.L D0-D1, -(SP) * Save used registers
    MOVE.L #kNewline,D1
    JSR PrintMessage
    MOVEM.L (SP)+, D0-D1 * Restore used registers
    RTS

*****************************************************************************
* PrintSpace()
* Args: None
* Prints a literal newline
*****************************************************************************
PrintSpace
    MOVEM.L D1-D2, -(SP) * Save used registers
    MOVE.L  #sSpace,D1
    MOVE.B  #1,D2
    JSR     AddWordToStringBuffer
    MOVEM.L (SP)+, D1-D2 * Restore used registers
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
    MOVE    D2,D4   * save D2
    MOVE    #1,D2   * adding 1 character to string buffer
    JSR     AddWordToStringBuffer * print the letter
    MOVE    D4,D2   * restore D2
    
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
* Args: D1(message)
* Loads the value stored in D1 as an address and calls Trap task #14
*   to print out its contents as a string
*****************************************************************************
PrintMessage        * void PrintMessage(String* message)
    MOVEM.L D1-D7, -(SP)    * save registers
    MOVEA.L D1,A1   * load address of message from argument 1
    MOVE.B  #14,D0  * print contents of A1
    TRAP    #15     
    MOVEM.L (SP)+, D1-D7    * restore registers
    RTS

kStringBufferSize EQU 128
kStringBuffer
    DS  kStringBufferSize

kStartMessage
    DC.B    'These function allows users to print from a literal word',CR,LF
    DC.B    'by passing in a number containing the ascii values of',CR,LF
    DC.B    'of each character to be printed',CR,LF
    DC.B    CR,LF,0

kInvalidOpCode
    DC.B    'Invalid Opcode',0

kGoodbyeMessage
    DC.B    'Goodbye!',0

kNewline
    DC.B    CR,LF,0

    END START



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
