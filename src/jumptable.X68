*****************************************************************************
* Title      : Op-code Decoding
* Written by : No Preference
* Date       : 5/22/14
*****************************************************************************

* print constants
CR      EQU     $0D
LF      EQU     $0A



*****************************************************************************
* Main
*****************************************************************************
Main    ORG     $1000   * first instruction of program
        MOVE    #START_MSG,D1
        JSR     Func_Print

        * test opcodes in memory
        MOVE.L  #FirstOpcode,A5
        MOVE.L  #NoMoreOpcodes,A6

Loop_Main
        CMP.L   A5,A6   * compare starting address to ending address

        * if starting address == ending address, done
        BEQ     Done_Main

        * else decode next instruction
        JSR     Func_UseJumpTable

        BRA     Loop_Main

Done_Main
        MOVE.B  #9,D0   * terminate program
        TRAP    #15




*****************************************************************************
* Jump Table
* top level jump table determines first step function
* based on 4 MSBs of opcode
* Instructions are stored as longwords in memory
*****************************************************************************
JumpTable
        DC.L    Func_BCLR_ORI_CMPI
        DC.L    Func_MOVE_B
        DC.L    Func_MOVE_MOVEA_L
        DC.L    Func_MOVE_MOVEA_W
        DC.L    Func_MISC
        DC.L    Func_SUBQ
        DC.L    Func_Bcc_BRA
        DC.L    Func_NO_OP
        DC.L    Func_OR_DIVS
        DC.L    Func_SUB
        DC.L    Func_NO_OP
        DC.L    Func_CMP_EOR
        DC.L    Func_MULS
        DC.L    Func_ADD_ADDA
        DC.L    Func_SHIFT_ROTATE
        DC.L    Func_NO_OP



*****************************************************************************
* Functions
*****************************************************************************


*****************************************************************************
* void Func_MoveInstructionPointer(number of words)
*                                  D1
* expects global variable A5 to contain current address location
*****************************************************************************
Func_MoveInstructionPointer
        MOVEM.L D1,-(SP) * save D1 so we can use it

        LSL.L   #1,D1    * multiply byte by 2 to get word
        ADDA.L  D1,A5    * shift by a word

        MOVEM.L (SP)+,D1 * restore D1
        RTS

*****************************************************************************
* void Func_Print(MsgAddress)
*                 D1
* prints the contents of memory location specified by D1
*****************************************************************************
Func_Print   MOVEM.L D0/A1,-(SP)

        MOVEA   D1,A1
        MOVE.B  #14,D0
        TRAP    #15

        MOVEM.L (SP)+,D0/A1
        RTS


*****************************************************************************
* void Func_UseJumpTable()
* expects global variable A5 to contain current address location
*****************************************************************************
Func_UseJumpTable
        MOVEM.L D0-D3/A1,-(SP)     * save registers that will be modified

        * get the 4 MSBits of the address
        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        MOVE.L  #12,D2      * starting at bit 12
        MOVE.L  #4,D3       * get 4 bits
        JSR     Func_GetBits     * (returns result in D0)

        * multiply nibble by 4 to get longword offset
        * into the func table (DC.L)
        LSL.L   #2,D0
        LEA     JumpTable,A1    * get the func table address
        ADDA.L  D0,A1           * offset into table
        MOVEA.L (A1),A1         * dereference offset
        JSR     (A1)            * dereference and call function

        MOVEM.L (SP)+,D0-D3/A1     * restore registers
        RTS


*****************************************************************************
* int Func_GetBits(value, lowerBit, numBits)
* D0               D1     D2        D3
* Returns the bits from value[lowerBit] to value[lowerBit + numBits]
*
* ex. Func_GetBits( 0000111101100111 , LSB = 3 , length = 5 )
*   extracts:       FEDCBA98^^^^^210
*   so D0 will be:          01100
*****************************************************************************
Func_GetBits
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


*****************************************************************************
* void Func_MOVE_MOVEA_L()
* second level opcode decoding
* determines between move.L and movea.L
*****************************************************************************
Func_MOVE_MOVEA_L
        MOVEM.L  D1-D3,-(SP)    * save D1-D3 so they can be modified

        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        MOVE.L  #6,D2       * get bit 6
        MOVE.L  #3,D3       * to bit 8
        JSR     Func_GetBits     * store result in D0

        * if (D0 contains 1)
        CMP     #1,D0
        * then the instruction is MOVEA
        BEQ     Call_MOVEA_Func_MOVE_MOVEA_L

        * else it is MOVE
        JSR     Func_MOVE_L
        BRA     Done_Func_MOVE_MOVEA_L

Call_MOVEA_Func_MOVE_MOVEA_L
        JSR     Func_MOVEA_L

Done_Func_MOVE_MOVEA_L
        * done determining between move and movea
        MOVEM.L  (SP)+,D1-D3    * restore
        RTS


*****************************************************************************
* void Func_MOVE_MOVEA_W()
* second level opcode decoding
* determines between move.W and movea.W
*****************************************************************************
Func_MOVE_MOVEA_W
        MOVEM.L  D1-D3,-(SP)    * save D1-D3 so they can be modified

        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        MOVE.L  #6,D2       * get bit 6
        MOVE.L  #3,D3       * to bit 8
        JSR     Func_GetBits     * store result in D0

        * if (D0 contains 1)
        CMP     #1,D0
        * then the instruction is MOVEA
        BEQ     Call_MOVEA_Func_MOVE_MOVEA_W

        * else it is MOVE
        JSR     Func_MOVE_W
        BRA     Done_Func_MOVE_MOVEA_W

Call_MOVEA_Func_MOVE_MOVEA_W
        JSR     Func_MOVEA_W

Done_Func_MOVE_MOVEA_W
        * done determining between move and movea
        MOVEM.L  (SP)+,D1-D3    * restore
        RTS



*****************************************************************************
* void Func_ADD_ADDA()
* second level opcode decoding
* determines between add and adda
*****************************************************************************
Func_ADD_ADDA
        MOVEM.L  D1-D3,-(SP)    * save D1-D3 so they can be modified

        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        MOVE.L  #6,D2       * get bit 6
        MOVE.L  #2,D3       * to bit 7
        JSR     Func_GetBits     * store result in D0

        * if (D0 contains 3)
        CMP     #3,D0
        * then the instruction is ADDA
        BEQ     Call_ADDA_Func_ADD_ADDA

        * else it is ADD
        JSR     Func_ADD
        BRA     Done_Func_ADD_ADDA

Call_ADDA_Func_ADD_ADDA
        JSR     Func_ADDA

Done_Func_ADD_ADDA
        * done determining between add and adda
        MOVEM.L  (SP)+,D1-D3    * restore
        RTS


*****************************************************************************
* void Func_OR_DIVS()
* second level opcode decoding
* determines between OR and DIVS
*****************************************************************************
Func_OR_DIVS
        MOVEM.L  D1-D3,-(SP)    * save D1-D3 so they can be modified

        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        MOVE.L  #6,D2       * get bit 6
        MOVE.L  #2,D3       * to bit 7
        JSR     Func_GetBits     * store result in D0

        * if (D0 contains 3)
        CMP     #3,D0
        * then the instruction is DIVS
        BEQ     Call_DIVS_Func_OR_DIVS

        * else it is OR
        JSR     Func_OR
        BRA     Done_Func_OR_DIVS

Call_DIVS_Func_OR_DIVS
        JSR     Func_DIVS

Done_Func_OR_DIVS
        * done determining between divs and or
        MOVEM.L  (SP)+,D1-D3    * restore
        RTS


*****************************************************************************
* void Func_CMP_EOR()
* second level opcode decoding
* determines between cmp and eor
*****************************************************************************
Func_CMP_EOR
        MOVEM.L  D1,-(SP)    * save D1

        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        BTST    #8,D1       * test if bit 8 is 0

        * if bit 8 is 0 then the instruction is EOR
        BEQ     Call_CMP_Func_CMP_EOR

        * else it is EOR
        JSR     Func_EOR
        BRA     Done_Func_CMP_EOR

Call_CMP_Func_CMP_EOR
        JSR     Func_CMP

Done_Func_CMP_EOR
        * done determining between cmp and eor
        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_Bcc_BRA()
* second level opcode decoding
* determines between BCS, BVC, BGE, BLT and BRA
*****************************************************************************
Func_Bcc_BRA
        MOVEM.L  D1-D3,-(SP)    * save D1-D3 so they can be modified

        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        MOVE.L  #8,D2       * get bit 8
        MOVE.L  #4,D3       * to bit 11
        JSR     Func_GetBits     * store result in D0

        * if (D0 contains 0)
        * then the instruction is BRA
        CMP     #0,D0
        BNE     BCS_Func_Bcc_BRA
        JSR     Func_BRA
        BRA     Done_Func_Bcc_BRA

BCS_Func_Bcc_BRA
        * else if (D0 is 5)
        * then the instruction is BCS
        CMP     #5,D0
        BNE     BVC_Func_Bcc_BRA
        JSR     Func_BCS
        BRA     Done_Func_Bcc_BRA
        
BVC_Func_Bcc_BRA
        * else if (D0 is 8)
        * then the instruction is BVC
        CMP     #8,D0
        BNE     BGE_Func_Bcc_BRA
        JSR     Func_BVC
        BRA     Done_Func_Bcc_BRA

BGE_Func_Bcc_BRA
        * else if (D0 is 12)
        * then the instruction is BGE
        CMP     #12,D0
        BNE     BLT_Func_Bcc_BRA
        JSR     Func_BGE
        BRA     Done_Func_Bcc_BRA
        
BLT_Func_Bcc_BRA
        * else if (D0 is 13)
        * then the instruction is BLT
        CMP     #13,D0
        BNE     Error_Func_Bcc_BRA
        JSR     Func_BLT
        BRA     Done_Func_Bcc_BRA

Error_Func_Bcc_BRA
        JSR     Func_NO_OP

Done_Func_Bcc_BRA
        * done determining Bcc/BRA
        MOVEM.L  (SP)+,D1-D3    * restore
        RTS


*****************************************************************************
* void Func_SHIFT_ROTATE()
* second level opcode decoding
* determines shift/rotate type
*****************************************************************************
Func_SHIFT_ROTATE
        MOVEM.L  D1-D3,-(SP)    * save D1-D3 so they can be modified

        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        MOVE.L  #6,D2       * get bit 6
        MOVE.L  #2,D3       * to bit 7
        JSR     Func_GetBits  * store result in D0

        * if (D0 contains 3)
        CMP     #3,D0

        * then use bits 9 and 10 to determine type
        BEQ     Use_9_10_Func_SHIFT_ROTATE

        * else use bits 3 and 4
        MOVE.L  #3,D2
        MOVE.L  #2,D3
        BRA     Determine_Type_Func_SHIFT_ROTATE

Use_9_10_Func_SHIFT_ROTATE
        MOVE.L  #9,D2
        MOVE.L  #2,D3

Determine_Type_Func_SHIFT_ROTATE
        JSR     Func_GetBits  * store result in D0

        * if (D0 contains 3)
        * it is ROx
        CMP     #3,D0
        BNE     LSx_Type_Func_SHIFT_ROTATE
        JSR     Func_ROL_ROR
        BRA     Done_Func_SHIFT_ROTATE

LSx_Type_Func_SHIFT_ROTATE
        * else if (D0 contains 1)
        * it is LSx
        CMP     #1,D0
        BNE     ASx_Type_Func_SHIFT_ROTATE
        JSR     Func_LSL_LSR
        BRA     Done_Func_SHIFT_ROTATE

ASx_Type_Func_SHIFT_ROTATE
        * else if (D0 contains 0)
        * it is ASx
        CMP     #0,D0
        BNE     Error_Func_SHIFT_ROTATE
        JSR     Func_LSL_LSR
        BRA     Done_Func_SHIFT_ROTATE

Error_Func_SHIFT_ROTATE
        JSR     Func_NO_OP

Done_Func_SHIFT_ROTATE
        * done determining asl, asr, lsl, lsr, rol, ror
        MOVEM.L  (SP)+,D1-D3    * restore
        RTS


*****************************************************************************
* void Func_ASL_ASR()
* third level opcode decoding
* determines between asr asl
*****************************************************************************
Func_ASL_ASR
        MOVEM.L  D1,-(SP)       * save D1

        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        BTST    #8,D1       * test if bit 8 is 0

        * if bit 8 is 0 then the instruction is ASR
        BEQ     Call_ASR_Func_ASL_ASR

        * else it is ASL
        JSR     Func_ASL
        BRA     Done_Func_ASL_ASR

Call_ASR_Func_ASL_ASR
        JSR     Func_ASR

Done_Func_ASL_ASR
        * done determining between asr and asl
        MOVEM.L  (SP)+,D1       * restore
        RTS


*****************************************************************************
* void Func_LSL_LSR()
* third level opcode decoding
* determines between LSR, LSL
*****************************************************************************
Func_LSL_LSR
        MOVEM.L  D1,-(SP)       * save D1

        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        BTST    #8,D1       * test if bit 8 is 0

        * if bit 8 is 0 then the instruction is LSR
        BEQ     Call_LSR_Func_LSL_LSR

        * else it is LSL
        JSR     Func_LSL
        BRA     Done_Func_LSL_LSR

Call_LSR_Func_LSL_LSR
        JSR     Func_LSR

Done_Func_LSL_LSR
        * done determining between LSR and LSL
        MOVEM.L  (SP)+,D1       * restore
        RTS


*****************************************************************************
* void Func_ROL_ROR()
* third level opcode decoding
* determines between ROR, ROL
*****************************************************************************
Func_ROL_ROR
        MOVEM.L  D1,-(SP)       * save D1

        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        BTST    #8,D1       * test if bit 8 is 0

        * if bit 8 is 0 then the instruction is ROR
        BEQ     Call_ROR_Func_ROL_ROR

        * else it is ROL
        JSR     Func_ROL
        BRA     Done_Func_ROL_ROR

Call_ROR_Func_ROL_ROR
        JSR     Func_ROR

Done_Func_ROL_ROR
        * done determining between ROR and ROL
        MOVEM.L  (SP)+,D1       * restore
        RTS


*****************************************************************************
* void Func_MOVEA_L()
*****************************************************************************
Func_MOVEA_L
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MOVEA_L_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_MOVE_L()
*****************************************************************************
Func_MOVE_L
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MOVE_L_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_MOVEA_W()
*****************************************************************************
Func_MOVEA_W
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MOVEA_W_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_MOVE_W()
*****************************************************************************
Func_MOVE_W
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MOVE_W_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_MOVE_B()
*****************************************************************************
Func_MOVE_B
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MOVE_B_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_ADD()
*****************************************************************************
Func_ADD
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ADD_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_ADDA()
*****************************************************************************
Func_ADDA
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ADDA_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_OR()
*****************************************************************************
Func_OR
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #OR_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_DIVS()
*****************************************************************************
Func_DIVS
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #DIVS_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_BCLR_ORI_CMPI()
*****************************************************************************
Func_BCLR_ORI_CMPI
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BCLR_ORI_CMPI_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_MISC()
*****************************************************************************
Func_MISC
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MISC_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_SUBQ()
*****************************************************************************
Func_SUBQ
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #SUBQ_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_BCS()
*****************************************************************************
Func_BCS
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BCS_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS
        

*****************************************************************************
* void Func_BVC()
*****************************************************************************
Func_BVC
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BVC_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS
        

*****************************************************************************
* void Func_BGE()
*****************************************************************************
Func_BGE
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BGE_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS
        

*****************************************************************************
* void Func_BLT()
*****************************************************************************
Func_BLT
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BLT_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_BRA()
*****************************************************************************
Func_BRA
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BRA_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_SUB()
*****************************************************************************
Func_SUB
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #SUB_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_CMP()
*****************************************************************************
Func_CMP
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #CMP_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_EOR()
*****************************************************************************
Func_EOR
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #EOR_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_MULS()
*****************************************************************************
Func_MULS
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MULS_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_LSR()
*****************************************************************************
Func_LSR
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #LSR_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_LSL()
*****************************************************************************
Func_LSL
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #LSL_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_ASR()
*****************************************************************************
Func_ASR
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ASR_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_ASL()
*****************************************************************************
Func_ASL
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ASL_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_ROR()
*****************************************************************************
Func_ROR
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ROR_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_ROL()
*****************************************************************************
Func_ROL
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ROL_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_NO_OP()
*****************************************************************************
Func_NO_OP
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #NO_OP_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS



*****************************************************************************
* Data
*****************************************************************************

* messages for tracing output
START_MSG           DC.B    'Jump table example',CR,LF,'------------------',CR,LF,0
NO_OP_MSG           DC.B    'Error: invalid opcode',CR,LF,0
MOVE_B_MSG          DC.B    'MOVE.B  <ea>,<ea>',CR,LF,0
MOVE_W_MSG          DC.B    'MOVE.W  <ea>,<ea>',CR,LF,0
MOVEA_W_MSG         DC.B    'MOVEA.W <ea>,An',CR,LF,0
MOVE_L_MSG          DC.B    'MOVE.L  <ea>,<ea>',CR,LF,0
MOVEA_L_MSG         DC.B    'MOVEA.L <ea>,An',CR,LF,0
ADD_MSG             DC.B    'ADD.*   <ea>/Dn,Dn/<ea>',CR,LF,0
ADDA_MSG            DC.B    'ADDA.*  <ea>,An',CR,LF,0
OR_MSG              DC.B    'OR.*    <ea>/Dn,Dn/<ea>',CR,LF,0
DIVS_MSG            DC.B    'DIVS.W  <ea>,Dn',CR,LF,0
MULS_MSG            DC.B    'MULS.W  <ea>,Dn',CR,LF,0
SUB_MSG             DC.B    'SUB.*   <ea>/Dn,Dn/<ea>',CR,LF,0
SUBQ_MSG            DC.B    'SUBQ.*  #<data>,<ea>',CR,LF,0
CMP_MSG             DC.B    'CMP.*   <ea>,Dn',CR,LF,0
EOR_MSG             DC.B    'EOR.*   Dn,<ea>',CR,LF,0
BCS_MSG             DC.B    'BCS     (addr)',CR,LF,0
BVC_MSG             DC.B    'BVC     (addr)',CR,LF,0
BGE_MSG             DC.B    'BGE     (addr)',CR,LF,0
BLT_MSG             DC.B    'BLT     (addr)',CR,LF,0
BRA_MSG             DC.B    'BRA     (addr)',CR,LF,0
LSR_MSG             DC.B    'LSR.*   Dx/#<data>/<ea>,Dy/Dy/-',CR,LF,0
LSL_MSG             DC.B    'LSL.*   Dx/#<data>/<ea>,Dy/Dy/-',CR,LF,0
ASR_MSG             DC.B    'ASR.*   Dx/#<data>/<ea>,Dy/Dy/-',CR,LF,0
ASL_MSG             DC.B    'ASL.*   Dx/#<data>/<ea>,Dy/Dy/-',CR,LF,0
ROR_MSG             DC.B    'ROR.*   Dx/#<data>/<ea>,Dy/Dy/-',CR,LF,0
ROL_MSG             DC.B    'ROL.*   Dx/#<data>/<ea>,Dy/Dy/-',CR,LF,0
BCLR_ORI_CMPI_MSG   DC.B    'BCLR/ORI/CMPI                    instruction',CR,LF,0
MISC_MSG            DC.B    'JSR/LEA/RTS/NEG/DIVS/MULS/MOVEM  instruction',CR,LF,0



* opcodes loaded into memory
* output should be in the same order
FirstOpcode     DC.W     %0001000000000000      * MOVE.B
                DC.W     %0010000000000000      * MOVE.L
                DC.W     %0010000001000000      * MOVEA.L
                DC.W     %0011000000000000      * MOVE.W
                DC.W     %0011000001000000      * MOVEA.W
                DC.W     %1101000000000000      * ADD
                DC.W     %1101000011000000      * ADDA
                DC.W     %1000000000000000      * OR
                DC.W     %1000000011000000      * DIVS
                DC.W     %1100000000000000      * MULS
                DC.W     %1001000000000000      * SUB
                DC.W     %0101000000000000      * SUBQ
                DC.W     %1011000000000000      * CMP
                DC.W     %1011000100000000      * EOR
                DC.W     %0110010100000000      * BCS
                DC.W     %0110100000000000      * BVC
                DC.W     %0110110000000000      * BGE
                DC.W     %0110110100000000      * BLT
                DC.W     %0110000000000000      * BRA
                DC.W     %1110000000001000      * LSR
                DC.W     %1110001011000000      * LSR <ea>
                DC.W     %1110000100001000      * LSL
                DC.W     %1110001111000000      * LSL <ea>
                DC.W     %1110000000000000      * ASR
                DC.W     %1110000011000000      * ASR <ea>
                DC.W     %1110000100000000      * ASL
                DC.W     %1110000111000000      * ASL <ea>
                DC.W     %1110000000011000      * ROR
                DC.W     %1110011011000000      * ROR <ea>
                DC.W     %1110000100011000      * ROL
                DC.W     %1110011111000000      * ROL <ea>
                DC.W     %0000000000000000      * BCLR, ORI, CMPI
                DC.W     %0100000000000000      * JSR, LEA, RTS, NEG, DIVS, MULS, MOVEM
                DC.W     %0111000000000000      * bad op (based on first 4 bits)
                DC.W     %1010000000000000      * bad op (based on first 4 bits)
                DC.W     %1111000000000000      * bad op (based on first 4 bits)
                DC.W     %0110111100000000      * bad op (variation of Bcc)
                DC.W     %0110000100000000      * bad op (variation of Bcc)
                DC.W     %0110001000000000      * bad op (variation of Bcc)
                DC.W     %0110001100000000      * bad op (variation of Bcc)
                DC.W     %0110010000000000      * bad op (variation of Bcc)
NoMoreOpcodes   DC.W     %1111111111111111


        END    Main        * last line of source









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
