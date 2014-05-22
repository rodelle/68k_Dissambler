*-----------------------------------------------------------
* Title      : Op-code Jump Tables
* Written by : No Preference
* Date       : 5/15/14
* Description: Jump tables arranged to take advantage of
*              offset
*-----------------------------------------------------------
* print constants 
CR      EQU     $0D
LF      EQU     $0A


START   ORG     $1000   * first instruction of program
        MOVE    #START_MSG,D1
        JSR     Print
        
        * test opcodes in memory
        MOVE.L  #MOVE_B_OP,A5
        MOVE.L  #NO_MORE_OPS,A6
        
MAIN_LOOP
        CMP.L   A5,A6   * compare starting address to ending address
        BEQ     DONE    * if starting address == ending address, done
        
        JSR     JumpUsingFuncTable
        BRA     MAIN_LOOP


DONE    MOVE.B  #9,D0   * terminate program
        TRAP    #15

FuncTable
        DC.L    Func_BCLR_ORI_CMPI
        DC.L    Func_MOVE_B
        DC.L    Func_MOVE_MOVEA_L
        DC.L    Func_MOVE_MOVEA_W        
        DC.L    Func_MISC        
        DC.L    Func_SUBQ
        DC.L    Func_BRANCH
        DC.L    Func_NO_OP
        DC.L    Func_OR_DIVS
        DC.L    Func_SUB
        DC.L    Func_NO_OP
        DC.L    Func_CMP_EOR
        DC.L    Func_MULS
        DC.L    Func_ADD
        DC.L    Func_SHIFT
        DC.L    Func_NO_OP


*-----------------------------------------------------------
* Functions
*-----------------------------------------------------------

* void IncrementTheirPC(number of words)
*                       D1
* expects global variable A5 to contain current address location
IncrementTheirPC
        MOVEM.L D1,-(SP) * save D1 so we can use it
        
        LSL.L   #1,D1
        ADDA    D1,A5
        
        MOVEM.L (SP)+,D1 * restore D1
        RTS


* void Print(MsgAddress)
*            D1
Print   MOVEM.L D0/A1,-(SP)
        
        MOVEA   D1,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVEM.L (SP)+,D0/A1
        RTS
        

* void JumpUsingFuncTable()
* expects global variable A5 to contain current address location
JumpUsingFuncTable
        MOVEM.L D0-D3/A1,-(SP)     * save registers that will be modified
        
        * get the 4 MSBits of the address
        MOVE.L  (A5),D1       * copy current "PC" into D1
        MOVE.L  #12,D2      * starting at bit 12
        MOVE.L  #4,D3       * get 4 bits
        JSR     GetBits     * (returns result in D0)
        
        * multiply nibble by 4 to get longword offset
        * into the func table (DC.L)
        LSL.L   #2,D0
        LEA     FuncTable,A1    * get the func table address
        ADD.L   D0,A1           * offset into table
        MOVEA.L (A1),A1         * dereference offset
        JSR     (A1)            * dereference and call function
        
        MOVEM.L (SP)+,D0-D3/A1     * restore registers
        RTS


* int GetBits(value, lowerBit, numBits)
* D0          D1     D2        D3
* Returns the bits from value[lowerBit] to value[lowerBit + numBits]
* ex. GetBits(1111 0110 0111, 3, 5) = 1111 [0110 0]111 = 01100
GetBits
        MOVEM.L  D4,-(SP)    * save D4 so it can be used by the function
        MOVE.L  D1,D0       * store initial value in return register
    
        * bit mask set up
        CLR     D4
        MOVE.L  #1,D4
        LSL     D3,D4       * calculate 2^n (n = number of bits)
        SUB     #1,D4       * create the bit mask with 2^n-1
    
        LSR     D2,D0       * shift right, discarding lower bits
        AND.L   D4,D0       * mask out higher bits

        MOVEM.L  (SP)+,D4    * restore used register(s)
        RTS


* void Func_MOVE_MOVEA_L()
* expects global variable A5 to contain current address location
Func_MOVE_MOVEA_L
        MOVEM.L  D1-D3,-(SP)    * save D1-D3 so they can be modified
        
        MOVE.L  A5,D1       * copy current "PC" into D1
        MOVE.L  #6,D2       * get bit 6
        MOVE.L  #3,D3       * to bit 8
        JSR     GetBits     * store result in D0
        
        * if (D0 contains 1)
        CMP     #1,D0
        * then the function is MOVEA
        BEQ     CALL_MOVEA_Func_MOVE_MOVEA_L
        
        * else it is MOVE
        JSR     Func_MOVE_L
        BRA     DONE_Func_MOVE_MOVEA_L

CALL_MOVEA_Func_MOVE_MOVEA_L
        JSR     Func_MOVEA_L

DONE_Func_MOVE_MOVEA_L
        * done determining between move and movea
        MOVEM.L  (SP)+,D1-D3    * restore
        RTS


* void Func_MOVEA_L()              
Func_MOVEA_L
        MOVE    #MOVEA_L_MSG,D1
        JSR     Print
        
        ADDA    #2,A5        * increment A5 by 1 word

        RTS
        
        
* void Func_MOVE_L()             
Func_MOVE_L
        MOVE    #MOVE_L_MSG,D1
        JSR     Print

        ADDA    #2,A5        * increment A5 by 1 word

        RTS


; void Func_MOVE_MOVEA_W()
Func_MOVE_MOVEA_W
        MOVEM.L  D1-D3,-(SP)    * save D1-D3 so they can be modified
        
        MOVE.L  A5,D1       * copy current "PC" into D1
        MOVE.L  #6,D2       * get bit 6
        MOVE.L  #3,D3       * to bit 8
        JSR     GetBits     * store result in D0
        
        * if (D0 contains 1)
        CMP     #1,D0
        * then the function is MOVEA
        BEQ     CALL_MOVEA_Func_MOVE_MOVEA_W
        
        * else it is MOVE
        JSR     Func_MOVE_W
        BRA     DONE_Func_MOVE_MOVEA_W

CALL_MOVEA_Func_MOVE_MOVEA_W
        JSR     Func_MOVEA_W

DONE_Func_MOVE_MOVEA_W
        * done determining between move and movea
        MOVEM.L  (SP)+,D1-D3    * restore
        RTS
        

* void Func_MOVEA_W()              
Func_MOVEA_W
        MOVEM.L  D1,-(SP)    * save D1-D3 so they can be modified

        MOVE    #MOVEA_W_MSG,D1
        JSR     Print
        
        ADDA    #2,A5        * increment A5 by 1 word
    
        MOVEM.L  (SP)+,D1    * restore
        RTS
        
        
* void Func_MOVE_W()             
Func_MOVE_W
        MOVE    #MOVE_W_MSG,D1
        JSR     Print
        
        * pretend MOVE_W is 16 bit instruction
        * so increment A5 by a word
        ADDA    #2,A5
        
        RTS
        

; void Func_MOVE_B()
Func_MOVE_B
        MOVE    #MOVE_B_MSG,D1
        JSR     Print
        
        * pretend MOVE_W is 16 bit instruction
        * so increment A5 by a word
        ADDA    #2,A5
        
        RTS     


; void Func_BCLR_ORI_CMPI()
Func_BCLR_ORI_CMPI
        MOVE    #BCLR_ORI_CMPI_MSG,D1
        JSR     Print

        ADDA    #2,A5        * increment A5 by 1 word

        RTS


; void Func_MISC()
Func_MISC
        MOVE    #MISC_MSG,D1
        JSR     Print

        ADDA    #2,A5        * increment A5 by 1 word

        RTS

        
; void Func_SUBQ()
Func_SUBQ
        MOVE    #SUBQ_MSG,D1
        JSR     Print

        ADDA    #2,A5        * increment A5 by 1 word

        RTS
        

; void Func_BRANCH()
Func_BRANCH
        MOVE    #BRANCH_MSG,D1
        JSR     Print

        ADDA    #2,A5        * increment A5 by 1 word

        RTS


; void Func_OR_DIVS()
Func_OR_DIVS
        MOVE    #OR_DIVS_MSG,D1
        JSR     Print
        
        ADDA    #2,A5        * increment A5 by 1 word

        RTS


; void Func_SUB()
Func_SUB
        MOVE    #SUB_MSG,D1
        JSR     Print
        
        ADDA    #2,A5        * increment A5 by 1 word

        RTS


; void Func_CMP_EOR()
Func_CMP_EOR
        MOVE    #CMP_EOR_MSG,D1
        JSR     Print
        
        ADDA    #2,A5        * increment A5 by 1 word

        RTS


; void Func_MULS()
Func_MULS
        Move    #MULS_MSG,D1
        JSR     Print
        
        ADDA    #2,A5        * increment A5 by 1 word

        RTS


; void Func_ADD()
Func_ADD
        MOVE    #ADD_MSG,D1
        JSR     Print
        
        ADDA    #2,A5        * increment A5 by 1 word

        RTS


; void Func_SHIFT()
Func_SHIFT
        MOVE    #SHIFT_MSG,D1
        JSR     Print

        ADDA    #2,A5        * increment A5 by 1 word

        RTS


; void Func_NO_OP()
Func_NO_OP
        MOVE    #NO_OP_MSG,D1
        JSR     Print

        ADDA    #2,A5        * increment A5 by 1 word

        RTS

*-----------------------------------------------------------
* Data
*-----------------------------------------------------------

* messages for tracing output
START_MSG           DC.B    'Jump table example',CR,LF,'------------------',CR,LF,0
NO_OP_MSG           DC.B    'Error: invalid opcode',CR,LF,0
MOVE_B_MSG          DC.B    'MOVE.B  <ea>,<ea>',CR,LF,0
MOVE_W_MSG          DC.B    'MOVE.W  <ea>,<ea>',CR,LF,0
MOVEA_W_MSG         DC.B    'MOVEA.W <ea>,An',CR,LF,0
MOVE_L_MSG          DC.B    'MOVE.L  <ea>,<ea>',CR,LF,0
MOVEA_L_MSG         DC.B    'MOVEA.L <ea>,An',CR,LF,0
BCLR_ORI_CMPI_MSG   DC.B    'BCLR/ORI/CMPI   instruction',CR,LF,0
MISC_MSG            DC.B    'JSR/LEA/RTS/NEG/DIVS/MULS/MOVEM instruction',CR,LF,0
SUBQ_MSG            DC.B    'SUBQ            instruction',CR,LF,0
BRANCH_MSG          DC.B    'Bcc/BRA         instruction',CR,LF,0
OR_DIVS_MSG         DC.B    'OR/DIVS         instruction',CR,LF,0
SUB_MSG             DC.B    'SUB             instruction',CR,LF,0
CMP_EOR_MSG         DC.B    'CMP/EOR         instruction',CR,LF,0
MULS_MSG            DC.B    'MULS            instruction',CR,LF,0
ADD_MSG             DC.B    'ADD             instruction',CR,LF,0
SHIFT_MSG           DC.B    'LSR/LSL/ASR/ASL instruction',CR,LF,0



* opcodes loaded into memory
* output should be in the same order
MOVE_B_OP           DC.W     %0001001111111111
MOVE_L_OP           DC.W     %0010000000000000
MOVEA_L_OP          DC.W     %0010000001000000
MOVE_W_OP           DC.W     %0011000000000000
MOVEA_W_OP          DC.W     %0011000001000000
BCLR_ORI_CMPI_OP    DC.W     %0000000000000000
MISC_OP             DC.W     %0100001111111111
SUBQ_OP             DC.W     %0101000000000000
BRANCH_OP           DC.W     %0110000000000000
NO_OP_1             DC.W     %0111000000000000
OR_DIVS_OP          DC.W     %1000001111111111
SUB_OP              DC.W     %1001000000000000
NO_OP_2             DC.W     %1010000000000000
CMP_EOR_OP          DC.W     %1011000000000000
MULS_OP             DC.W     %1100001111111111
ADD_OP              DC.W     %1101000000000000
SHIFT_OP            DC.W     %1110001111111111
NO_OP_3             DC.W     %1111000000000000
NO_MORE_OPS         DC.W     %0000000000000000


        END    START        * last line of source





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
