*-----------------------------------------------------------
* Title      : Addressing Jump Table
* Written by : No Preference
* Date       : 5/20/14
* Description: Jump tables for determining Address Modes
*-----------------------------------------------------------
    
* print constants
CR              EQU     $0D
LF              EQU     $0A

Func_Dn         EQU     0     * 000 xxx 0
Func_An         EQU     1     * 001 xxx 1
Func_An_i       EQU     2     * 010 xxx 2
Func_An_ip      EQU     3     * 011 xxx 3
Func_An_im      EQU     4     * 100 xxx 4
Func_Junk       EQU     5     * 101 xxx 5-
Func_Junk_2     EQU     6     * 110 xxx 6-
Func_Word_A     EQU     7     * 111 000 7
Func_Long_A     EQU     8     * 111 001 8
Func_Junk_3     EQU     9     * 111 010 9-
Func_Junk_4     EQU     10    * 111 011 10-
Func_Data       EQU     11    * 111 100 11

    
START       ORG     $1000 

            MOVE.B  #%00111001,D1
            JSR     JumpUsingFuncTableModeReg
            MOVE.B  #%00001111,D1
            JSR     JumpUsingFuncTableRegMode

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

* void JumpUsingFuncTable(1-Byte-Mode-Register)
*                         D1
JumpUsingFuncTableModeReg
            MOVEM.L D0-D5/A1,-(SP)
            
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
            
            * check if Mode is 0 - 6
            MOVE.B  #7,D5
            SUB.B   D2,D5
            BNE     NO_ADD_TOGETHER
            BRA     ADD_TOGETHER

* void JamesUsingFuncTable(1-Byte-Register-Mode)
*                          D1
JumpUsingFuncTableRegMode
            MOVEM.L D0-D5/A1,-(SP)
            
            * preping D2/D3 for mode/register
            CLR     D2
            CLR     D3
            MOVE.B  D1,D2
            MOVE.B  D1,D3
            
            * get mode
            MOVE    #3,D4
            LSR.B   D4,D3
            
            * get register
            MOVE    #5,D4
            LSL.B   D4,D2
            LSR.B   D4,D2
            
            * check if Mode is 0 - 6
            MOVE.B  #7,D5
            SUB.B   D2,D5
            BNE     NO_ADD_TOGETHER
            BRA     ADD_TOGETHER
            
* get jump value for Word/Long Address OR data
ADD_TOGETHER            
            LEA     FuncTable,A1
            CLR     D0
            ADD.W   D2,D0
            ADD.W   D3,D0
            MULS.W  #4,D0
            ADD.W   A1,D0
            MOVEA.W D0,A1
            BRA     END_JumpFuncTable

* get jump value for NON-Word/Long Address OR Data
NO_ADD_TOGETHER
            LEA     FuncTable,A1
            ADD.W   D2,D0
            MULS.W  #4,D0
            ADD.W   A1,D0
            MOVEA.W D0,A1
            BRA     END_JumpFuncTable
            
END_JumpFuncTable
            MOVEM.L (SP)+,D0-D5/A1
            RTS

*-----------------------------------------------------------
            END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
