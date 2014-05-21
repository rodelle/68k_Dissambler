*-----------------------------------------------------------
* Title      : Addressing Jump Table
* Written by : No Preference
* Date       : 5/20/14
* Description: Jump tables for determining Address Modes
*-----------------------------------------------------------
    
* print constants
CR              EQU     $0D
LF              EQU     $0A

Func_Dn         EQU     1     * 000 xxx 0
Func_An         EQU     2     * 001 xxx 1
Func_An_i       EQU     3     * 010 xxx 2
Func_An_ip      EQU     4     * 011 xxx 3
Func_An_im      EQU     5     * 100 xxx 4
Func_Junk       EQU     6     * 101 xxx 5-
Func_Junk_2     EQU     7     * 110 xxx 6-
Func_Word_A     EQU     8     * 111 000 7
Func_Long_A     EQU     9     * 111 001 8
Func_Junk_3     EQU     10    * 101 xxx 9-
Func_Junk_4     EQU     11    * 110 xxx 10-
Func_Data       EQU     12    * 111 100 11

    
START       ORG     $1000 

            MOVE.B  #%00111001,D1
            JSR     JumpUsingFuncTable

DONE        MOVE.B  #9,D0
            TRAP    #15

FuncTable
            DC.L    Func_Dn     * 000 xxx 0
            DC.L    Func_An     * 001 xxx 1
            DC.L    Func_An_i   * 010 xxx 2
            DC.L    Func_An_ip  * 011 xxx 3
            DC.L    Func_An_im  * 100 xxx 4
            DC.L    Func_Junk   * 101 xxx 5-
            DC.L    Func_Junk_2 * 110 xxx 6-
            DC.L    Func_Word_A * 111 000 7
            DC.L    Func_Long_A * 111 001 8
            DC.L    Func_Junk_3 * 101 xxx 9-
            DC.L    Func_Junk_4 * 110 xxx 10-
            DC.L    Func_Data   * 111 100 11

*-----------------------------------------------------------
* Functions
*-----------------------------------------------------------

* void JumpUsingFunctTable(1-Byte-Mode-Register)
*                          D1
JumpUsingFuncTable
            MOVEM.L D0-D4/A1,-(SP)
            
            * preping D2/D3 for mode/register
            CLR     D2
            CLR     D3
            MOVE.B  D1,D2   * Mode
            MOVE.B  D1,D3   * Register
            
            * get mode
            MOVE    #3,D4   * Shift Mode down into LS 3 bits
            LSR.B   D4,D2   * Mode
            
            * get register
            MOVE    #5,D4   * Shift non-register bits out
            LSL.B   D4,D3   * And register into LS 3 bits
            LSR.B   D4,D3   * Register
            
            * get jump value
            LEA     FuncTable,A1
            CLR     D0
            ADD.W   D2,D0
            ADD.W   D3,D0
            MULS.W  #4,D0
            ADD.W   A1,D0
            MOVEA.W D0,A1
            
            RTS

* int GetBits(value, lowerBit, numBits)
* D0          D1     D2        D3
* Returns the bits from value[lowerBit] to value[lowerBit + numBits]
* ex. GetBits(1111 0110 0111, 3, 5) = 1111 [0110 0]111 = 01100
GetBits
        MOVE.L  D4,-(SP)    * save D4 so it can be used by the function
        MOVE.L  D1,D0       * store initial value in return register
    
        * bit mask set up
        CLR     D4
        MOVE.L  #1,D4
        LSL     D3,D4       * calculate 2^n (n = number of bits)
        SUB     #1,D4       * create the bit mask with 2^n-1
    
        LSR     D2,D0       * shift right, discarding lower bits
        AND.L   D4,D0       * mask out higher bits

        MOVE.L  (SP)+,D4    * restore used register(s)
        RTS


*-----------------------------------------------------------
            END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
