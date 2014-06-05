*****************************************************************************
* Title      : Disassembler
* Written by : No Preference
* Date       : 5/30/14
*  
* 68000 Machine Code Disassembler
*****************************************************************************
*
* Global variables:
*   A5 - target instruction pointer.
*        points to the current machine code in memory, for disassembly.
*   A6 - final target machine code in memory
*
* Subroutine conventions:
*   Parameters   - pass using Func_MyFunc(D1, D2, ...)
*   Return       - return through D0
*   Preservation - all Dn and An registers that are modified must be saved
*                  at entry on the stack, and restored from the stack before
*                  RTS (D0 and A5 are exceptions).
* 
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

        CLR     D1
        CLR     D2
        


        *CLR     D1        
        *MOVE.B  #$F,D0
        *MOVE.B  #$EE,D1
        *MOVE.W  #$DDD,D2
        *MOVE.W  #$CCCC,D3
        *MOVE.W  #$AAA,D3
        *MOVE.L  #$BBBBB,D4
        
        *MOVEA.L #$A000,A5
        *JSR     Func_Long_A
        *MOVE.L  #1,D1
        *JSR     Func_Data
        *JSR     Func_Long_A
        *JSR     Done_Main

        MOVE.L  #$7FC0,A5
        MOVE.L  #$805C,A6

        * test opcodes in memory
        *MOVE.L  #FirstOpcode,A5
        *MOVE.L  #NoMoreOpcodes,A6

Loop_Main
        CMP.L   A5,A6   * compare starting address to ending address

        * if starting address == ending address, done
        BEQ     Done_Main

        * else decode next instruction
        JSR     Func_JumpOpcodeTable
        
        MOVE    #NEW_LINE,D1
        JSR     Func_Print      # print a new line after each instruction

        BRA     Loop_Main

Done_Main
        MOVE.B  #9,D0   * terminate program
        TRAP    #15




*****************************************************************************
* Opcode Table
* top level jump table determines first step function
* based on 4 MSBs of opcode
* Instructions are stored as longwords in memory
*****************************************************************************
OpcodeTable
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
        DC.L    Func_MULS_W
        DC.L    Func_ADD_ADDA
        DC.L    Func_SHIFT_ROTATE
        DC.L    Func_NO_OP

*****************************************************************************
* Address Table
* jump table for determining addressing modes and registers
* based on 6 bits, 3 for mode and 3 for address
* Instructions are stored as longwords in memory
*****************************************************************************
AddressTable
        DC.L    Func_Dn     * 000 xxx 0
        DC.L    Func_An     * 001 xxx 1
        DC.L    Func_An_i   * 010 xxx 2
        DC.L    Func_An_ip  * 011 xxx 3
        DC.L    Func_An_im  * 100 xxx 4
        DC.L    Func_Junk   * 101 xxx 5-
        DC.L    Func_Junk   * 110 xxx 6-
        DC.L    Func_Word_A * 111 000 7
        DC.L    Func_Long_A * 111 001 8
        DC.L    Func_Junk   * 101 xxx 9-
        DC.L    Func_Junk   * 110 xxx 10-
        DC.L    Func_Data   * 111 100 11


*****************************************************************************
* Functions
*****************************************************************************


*****************************************************************************
* void JumpAddressTableModeReg(6bit Mode-Register, size)
*                              D1                  D2
* Unsure what to leave in the registers
* Currently leaves nothing in registers
*****************************************************************************
Func_JumpAddressTableModeReg
            MOVEM.L D0-D6/A1,-(SP)
            
            CLR     D6
            MOVE.B  D2,D6
            
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

*****************************************************************************
* void JumpAddressTableRegMode(6bit Register-Mode, size)
*                              D1                  D2
* Unsure what to leave in the registers
* Currently leaves nothing in registers
*****************************************************************************
Func_JumpAddressTableRegMode
            MOVEM.L D0-D6/A1,-(SP)
            
            CLR     D6
            MOVE.B  D2,D6
            
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
            
*****************************************************************************
* Helpers for the JumpAddressTable Functions
*****************************************************************************
* get jump value for Word/Long Address OR data
ADD_TOGETHER            
            LEA     AddressTable,A1
            CLR     D0
            ADD.W   D2,D0
            ADD.W   D3,D0
            MULS.W  #4,D0
            ADD.W   A1,D0
            MOVEA.W D0,A1
            BRA     Done_Func_JumpAddressTable

* get jump value for NON-Word/Long Address OR Data
NO_ADD_TOGETHER
            LEA     AddressTable,A1
            CLR     D0
            ADD.W   D2,D0
            MULS.W  #4,D0
            ADD.W   A1,D0
            MOVEA.W D0,A1
            BRA     Done_Func_JumpAddressTable
            
Done_Func_JumpAddressTable
            CLR     D2
            MOVE.B  D6,D2
            MOVE.L  D3,D1       * move register into D1
            MOVEA.L (A1),A1
            JSR     (A1)
            MOVEM.L (SP)+,D0-D6/A1
            RTS

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
* void Func_PrintSizeStandard()
* expects global variable A5 to be pointing at current opcode.
*
* prints the size for instructions who fit the following configuration:
* bits 7,6         (where 6 and 7 are of the first opcode word)
*      0,0 = byte
*      0,1 = word
*      1,0 = long
*      1,1 = ?   (error)
*****************************************************************************
Func_PrintSizeStandard
        MOVEM.L D1-D3,-(SP)
        
        CLR.L   D1
        MOVE.W  (A5),D1         * copy current "PC" into D1
        MOVE.L  #6,D2           * get bit 6
        MOVE.L  #2,D3           * to bit 7
        JSR     Func_GetBits    * store result in D0
        
        * print the size string
        MOVE.L  D0,D1           * move size bits into D1
        
        * if D1 is 0, then it is a byte
        * load 'byte' msg into D0
        CMP     #0,D1
        BNE     Word_Func_PrintSizeStandard
        MOVE    #B_MSG,D1
        BRA     Done_Func_PrintSizeStandard

Word_Func_PrintSizeStandard
        * if D1 is 1, then it is a word
        * load 'word' msg into D0
        CMP     #1,D1
        BNE     Long_Func_PrintSizeStandard
        MOVE    #W_MSG,D1
        BRA     Done_Func_PrintSizeStandard
   
Long_Func_PrintSizeStandard
        * if D1 is 2, then it is a long
        * load 'long' msg into D0
        CMP     #2,D1
        BNE     Error_Func_PrintSizeStandard
        MOVE    #L_MSG,D1
        BRA     Done_Func_PrintSizeStandard

Error_Func_PrintSizeStandard 
        * else it is an error
        MOVE    #Q_MSG,D1

Done_Func_PrintSizeStandard
        JSR     Func_Print
        MOVEM.L (SP)+,D1-D3     
        RTS
        

*****************************************************************************
* void Func_Print(MsgAddress)
*                 D1
* prints the contents of memory location specified by D1
*****************************************************************************
Func_Print
        MOVEM.L D0/A1,-(SP)

        MOVEA   D1,A1
        MOVE.B  #14,D0
        TRAP    #15

        MOVEM.L (SP)+,D0/A1
        RTS


*****************************************************************************
* void Func_JumpOpcodeTable()
* expects global variable A5 to contain current address location
*****************************************************************************
Func_JumpOpcodeTable
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
        LEA     OpcodeTable,A1    * get the func table address
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
        MOVE.L  D1,D0        * store initial value in return register

        * bit mask set up
        CLR     D4
        MOVE.L  #1,D4
        LSL     D3,D4        * calculate 2^n (n = number of bits)
        SUB     #1,D4        * create the bit mask with 2^n-1

        LSR     D2,D0        * shift right, discarding lower bits
        AND.L   D4,D0        * mask out higher bits

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
* determines between OR and DIVS.W
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
        * then the instruction is DIVS.W
        BEQ     Call_DIVS_Func_OR_DIVS

        * else it is OR
        JSR     Func_OR
        BRA     Done_Func_OR_DIVS

Call_DIVS_Func_OR_DIVS
        JSR     Func_DIVS_W

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
* void Func_BCLR_ORI_CMPI()
* second level opcode decoding
* determines between BCLR, ORI, and CMPI
*****************************************************************************
Func_BCLR_ORI_CMPI
        MOVEM.L  D1-D3,-(SP)    * save D1-D3 so they can be modified

        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        MOVE.L  #7,D2       * get bit 7
        MOVE.L  #2,D3       * to bit 8
        JSR     Func_GetBits     * store result in D0

        * if (D0 contains 3)
        * then the instruction is BCLR
        CMP     #3,D0
        BNE     Use_10_11_Func_BCLR_ORI_CMPI
        JSR     Func_BCLR
        BRA     Done_Func_BCLR_ORI_CMPI

Use_10_11_Func_BCLR_ORI_CMPI
        * else we need to check bits 10 and 11
        MOVE.L  #8,D2      * get bit 8
        MOVE.L  #4,D3       * to bit 11
        JSR     Func_GetBits   * store result in D0

        * if (D0 is 8)
        * then the instruction is BCLR
        CMP     #8,D0
        BNE     ORI_Func_BCLR_ORI_CMPI
        JSR     Func_BCLR
        BRA     Done_Func_BCLR_ORI_CMPI

ORI_Func_BCLR_ORI_CMPI
        * else if (D0 is 0)
        * then the instruction is ORI
        CMP     #0,D0
        BNE     CMPI_Func_BCLR_ORI_CMPI
        JSR     Func_ORI
        BRA     Done_Func_BCLR_ORI_CMPI

CMPI_Func_BCLR_ORI_CMPI
        * else if (D0 is 12)
        * then the instruction is CMPI
        CMP     #12,D0
        BNE     Error_Func_BCLR_ORI_CMPI
        JSR     Func_CMPI
        BRA     Done_Func_BCLR_ORI_CMPI

Error_Func_BCLR_ORI_CMPI
        * else it is an error
        JSR     Func_NO_OP

Done_Func_BCLR_ORI_CMPI
        * done determining BCLR ORI CMPI
        MOVEM.L  (SP)+,D1-D3    * restore
        RTS


*****************************************************************************
* void Func_MISC()
* second level opcode decoding
* determines between JSR, LEA, RTS, NEG, DIVS, MULS, MOVEM
*****************************************************************************
Func_MISC
        MOVEM.L  D1-D3,-(SP)    * save D1-D3 so they can be modified

        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        MOVE.L  #6,D2       * get bit 6
        MOVE.L  #3,D3       * to bit 8
        JSR     Func_GetBits     * store result in D0

        * if (D0 contains 7)
        * then the instruction is LEA
        CMP     #7,D0
        BNE     Check_RTS_JSR_Func_MISC
        JSR     Func_LEA
        BRA     Done_Func_MISC

Check_RTS_JSR_Func_MISC
        * else we need to check bits 6 thru 11 for JSR or RTS
        MOVE.L  #6,D2      * get bit 6
        MOVE.L  #6,D3      * to bit 11
        JSR     Func_GetBits   * store result in D0

        * if (D0 is 58)
        * then the instruction is JSR
        CMP     #58,D0
        BNE     RTS_Func_MISC
        JSR     Func_JSR
        BRA     Done_Func_MISC

RTS_Func_MISC
        * else if (D0 is 57)
        * then the instruction is RTS
        CMP     #57,D0
        BNE     MULS_Func_MISC
        JSR     Func_RTS
        BRA     Done_Func_MISC

MULS_Func_MISC
        * else if (D0 is 48)
        * then the instruction is MULS.L
        CMP     #48,D0
        BNE     DIVS_Func_MISC
        JSR     Func_MULS_L
        BRA     Done_Func_MISC

DIVS_Func_MISC
        * else if (D0 is 49)
        * then the instruction is DIVS.L
        CMP     #49,D0
        BNE     NEG_MOVEM_Func_MISC
        JSR     Func_DIVS_L
        BRA     Done_Func_MISC

NEG_MOVEM_Func_MISC
        * else
        * the instruction is NEG or MOVEM
        BTST    #11,D1       * test if bit 11 is 0

        * if bit 11 is 0 then the instruction is probably NEG
        BEQ     NEG_Func_ASL_ASR
        
        * else it is probably MOVEM
        JSR     Func_MOVEM
        BRA     Done_Func_MISC
        
NEG_Func_ASL_ASR
        JSR     Func_NEG

Done_Func_MISC
        * done determining JSR, LEA, RTS, NEG, DIVS, MULS, MOVEM
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

        * then use bits 9 & 10 to determine type
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
        JSR     Func_ASL_ASR
        BRA     Done_Func_SHIFT_ROTATE

Error_Func_SHIFT_ROTATE
        * else it is an error
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
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MOVEA_L_MSG,D1
        JSR     Func_Print
        
        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Gets and prints the <ea> parameter for MOVEA.L
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        MOVE.L  #1,D2
        JSR     Func_JumpAddressTableModeReg
        
        * Print comma
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Gets and prints the An parameter for MOVEA.L
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        ADD.L   #%001000,D0     * adds mode for An
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_MOVE_L()
* NEED TO CHECK FOR #<Data>
*****************************************************************************
Func_MOVE_L
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MOVE_L_MSG,D1
        JSR     Func_Print

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Gets and prints the Source parameter for MOVE.L
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        MOVE.L  #1,D2
        JSR     Func_JumpAddressTableModeReg
        
        * Print comma
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Gets and prints the Destination parameter for MOVE.L
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableRegMode

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

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Gets and prints the <ea> parameter for MOVEA.L
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     Func_JumpAddressTableModeReg
        
        * Print comma
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Gets and prints the An parameter for MOVEA.L
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        ADD.L   #%001000,D0     * adds mode for An
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_MOVE_W()
* NEED TO CHECK FOR #<Data>
*****************************************************************************
Func_MOVE_W
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MOVE_W_MSG,D1
        JSR     Func_Print

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Gets and prints the source parameter for MOVE.W
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     Func_JumpAddressTableModeReg
        
        * Print comma
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Gets and prints the destination parameter for MOVE.W
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableRegMode

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_MOVE_B()
* NEED TO CHECK FOR #<Data>
*****************************************************************************
Func_MOVE_B
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MOVE_B_MSG,D1
        JSR     Func_Print

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Gets and prints the source parameter for MOVE.B
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     Func_JumpAddressTableModeReg
        
        * Print comma
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Gets and prints the destination parameter for MOVE.B
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableRegMode


        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_ADD()
*****************************************************************************
Func_ADD
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ADD_MSG,D1
        JSR     Func_Print
        
        * print the size string (standard is in bits 6-7)
        JSR     Func_PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * determin data first or second
        MOVE.L  #8,D2
        MOVE.L  #1,D3
        JSR     Func_GetBits
        
        CMP.B   #0,D0
        BNE     Func_ADD_DataFirst
        BEQ     Func_ADD_DataSecond

Func_ADD_DataFirst
        * Print Data Register
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg
        
        * Print comma
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Print destination effective address
        CLR     D1
        MOVE.W  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     Func_JumpAddressTableModeReg
        BRA     ADD_Done
        
Func_ADD_DataSecond
        * Print destination effective address
        CLR     D1
        MOVE.W  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     Func_JumpAddressTableModeReg
        
        * Print comma
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Print Data Register
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg
        BRA     ADD_Done
        
ADD_Done
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer
        MOVEM.L  (SP)+,D1-D4    * restore
        RTS

*****************************************************************************
* void Func_ADDA()
*****************************************************************************
Func_ADDA
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ADDA_MSG,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * determin data first or second
        MOVE.L  #8,D2
        MOVE.L  #1,D3
        JSR     Func_GetBits
        
        CMP.B   #0,D0
        BNE     Func_ADDA_L
        BEQ     Func_ADDA_W

Func_ADDA_W
        * Print W
        MOVE.L  #W_MSG,D1
        JSR     Func_Print

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print

        CLR     D1
        MOVE.W  D4,D1

        * Gets and prints the <ea> parameter for ADDA.W
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     Func_JumpAddressTableModeReg
        
        * Print comma
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Gets and prints the An parameter for ADDA.W
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        ADD.L   #%001000,D0     * adds mode for An
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg
        BRA     ADDA_Done

Func_ADDA_L
        * Print L
        MOVE.L  #L_MSG,D1
        JSR     Func_Print

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print
        
        CLR     D1
        MOVE.W  D4,D1

        * Gets and prints the <ea> parameter for ADDA.L
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        MOVE.L  #1,D2
        JSR     Func_JumpAddressTableModeReg
        
        * Print comma
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Gets and prints the An parameter for ADDA.L
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        ADD.L   #%001000,D0     * adds mode for An
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg
        BRA     ADDA_Done
        
ADDA_Done
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer
        MOVEM.L  (SP)+,D1-D4    * restore
        RTS

*****************************************************************************
* void Func_OR()
*****************************************************************************
Func_OR
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #OR_MSG,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * print the size string (standard is in bits 6-7)
        JSR     Func_PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print
        
        * determin data first or second
        MOVE.L  #8,D2
        MOVE.L  #1,D3
        JSR     Func_GetBits
        
        CMP.B   #0,D0
        BNE     Func_OR_DataFirst
        BEQ     Func_OR_DataSecond
        
Func_OR_DataFirst
        * Print Data Register
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg
        
        * Print comma
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Print destination effective address
        CLR     D1
        MOVE.W  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     Func_JumpAddressTableModeReg
        BRA     OR_Done

        
Func_OR_DataSecond
        * Print destination effective address
        CLR     D1
        MOVE.W  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     Func_JumpAddressTableModeReg
        
        * Print comma
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Print Data Register
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg
        BRA     OR_Done
        
OR_Done
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer
        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_BCLR()
*****************************************************************************
Func_BCLR
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BCLR_MSG,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Get destination mode
        MOVE.L  #3,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        
        CMP.B   #0,D0
        BEQ     BCLR_DataDestination
        BRA     BCLR_OtherDestination
        
BCLR_DataDestination
        *Print size/space
        MOVE.L  #L_MSG,D1
        JSR     Func_Print
        MOVE.L  #SPACE,D1
        JSR     Func_Print
        BRA     BCLR_SourceBranch

BCLR_OtherDestination
        *Print size/space
        MOVE.L  #B_MSG,D1
        JSR     Func_Print
        MOVE.L  #SPACE,D1
        JSR     Func_Print
        BRA     BCLR_SourceBranch
        
BCLR_SourceBranch
        MOVE.L  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        CMP.B   #2,D0
        BEQ     BCLR_ImmediateSource
        CMP.B   #6,D0
        BEQ     BCLR_DataSource
        * ELSE Not valid

BCLR_DataSource
        * Gets register for source
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg
        BRA     BCLR_DONE

BCLR_ImmediateSource
        * Gets immediate data
        JSR     Func_WordData
        BRA     BCLR_DONE

BCLR_DONE
        MOVE.L  #COMMA,D1
        JSR     Func_Print

        * Prints destination
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_ORI()
*****************************************************************************
Func_ORI
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ORI_MSG,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * print the size string (standard is in bits 6-7)
        JSR     Func_PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print

        * Print immediate data
        MOVE.L  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #2,D3
        JSR     Func_GetBits
        CMP.L   #0,D0
        BEQ     PRINT_LONGWORD
        CMP.L   #1,D0
        BEQ     PRINT_WORD
        CMP.L   #2,D0
        BEQ     PRINT_WORD
        * Not 0/1/2 then incorrect command

PRINT_LONGWORD        
        JSR     Func_LongData
        BRA     ORI_DONE

PRINT_WORD
        JSR     Func_WordData
        BRA     ORI_DONE

ORI_DONE
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_CMPI()
*****************************************************************************
Func_CMPI
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #CMPI_MSG,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * print the size string (standard is in bits 6-7)
        JSR     Func_PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print

        * Print immediate data
        MOVE.L  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #2,D3
        JSR     Func_GetBits
        CMP.L   #0,D0
        BEQ     PRINT_LONGWORD_CMPI
        CMP.L   #1,D0
        BEQ     PRINT_WORD_CMPI
        CMP.L   #2,D0
        BEQ     PRINT_WORD_CMPI
        * Not 0/1/2 then incorrect command

PRINT_LONGWORD_CMPI 
        JSR     Func_LongData
        BRA     CMPI_DONE

PRINT_WORD_CMPI
        JSR     Func_WordData
        BRA     CMPI_DONE

CMPI_DONE
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg


        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_NEG()
*****************************************************************************
Func_NEG
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #NEG_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_MOVEM()
*****************************************************************************
Func_MOVEM
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MOVEM_MSG,D1
        JSR     Func_Print

        * increment A5 by 2 words
        MOVE.L  #2,D1   * put 2 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS
        

*****************************************************************************
* void Func_JSR()
*****************************************************************************
Func_JSR
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #JSR_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_LEA()
*****************************************************************************
Func_LEA
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #LEA_MSG,D1
        JSR     Func_Print

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_RTS()
*****************************************************************************
Func_RTS
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #RTS_MSG,D1
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
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #SUBQ_MSG,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * print the size string (standard is in bits 6-7)
        JSR     Func_PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print
        
        * Print # for data
        MOVE.L  #POUND,D1
        JSR     Func_Print
        
        * Get number 1-8 for immediate data
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        
        * If D0 == 0 change to 8
        CMP.L   #0,D0
        BEQ     ADD_EIGHT
        BRA     SUBQ_CONTINUE
        
ADD_EIGHT
        ADD.B   #8,D0
        BRA     SUBQ_CONTINUE
        
SUBQ_CONTINUE
        * Print immediate data
        MOVE.L  D0,D1
        JSR     Func_Print_Number
        
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Get mode-reg
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        JSR     Func_JumpAddressTableModeReg

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_BCS()
*****************************************************************************
Func_BCS
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BCS_MSG,D1
        JSR     Func_Print

        * Jump to Label Printer
        JSR     Func_PrintLabel

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

        * Jump to Label Printer
        JSR     Func_PrintLabel

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

        * Jump to Label Printer
        JSR     Func_PrintLabel

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

        * Jump to Label Printer
        JSR     Func_PrintLabel

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

        * Jump to Label Printer
        JSR     Func_PrintLabel

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_SUB()
*****************************************************************************
Func_SUB
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #SUB_MSG,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * print the size string (standard is in bits 6-7)
        JSR     Func_PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print
        
        * determin data first or second
        MOVE.L  #8,D2
        MOVE.L  #1,D3
        JSR     Func_GetBits
        
        CMP.B   #0,D0
        BNE     Func_SUB_DataFirst
        BEQ     Func_SUB_DataSecond

Func_SUB_DataFirst
        * Print Data Register
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg
        
        * Print comma
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Print destination effective address
        CLR     D1
        MOVE.W  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     Func_JumpAddressTableModeReg
        BRA     SUB_Done

 
Func_SUB_DataSecond
        * Print destination effective address
        CLR     D1
        MOVE.W  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     Func_JumpAddressTableModeReg
        
        * Print comma
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Print Data Register
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg
        BRA     SUB_Done
        
SUB_Done
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer
        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_CMP()
*****************************************************************************
Func_CMP
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #CMP_MSG,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * print the size string (standard is in bits 6-7)
        JSR     Func_PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print
        
        * Get/Print mode/reg for destination
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg

        MOVE.L  #COMMA,D1
        JSR     Func_Print

         * Get bits for Dn and Print
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_EOR()
*****************************************************************************
Func_EOR
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #EOR_MSG,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * print the size string (standard is in bits 6-7)
        JSR     Func_PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print
        
        * Get bits for Dn and Print
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg

        MOVE.L  #COMMA,D1
        JSR     Func_Print
        
        * Get/Print mode/reg for destination
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_MULS_W()
*****************************************************************************
Func_MULS_W
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MULS_W_MSG,D1
        JSR     Func_Print

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print
        
        * Get/Print mode/reg for destination
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg

        MOVE.L  #COMMA,D1
        JSR     Func_Print

         * Get bits for Dn and Print
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg        

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_DIVS_W()
*****************************************************************************
Func_DIVS_W
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #DIVS_W_MSG,D1
        JSR     Func_Print
        
        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print
        
        * Get/Print mode/reg for destination
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg

        MOVE.L  #COMMA,D1
        JSR     Func_Print

         * Get bits for Dn and Print
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg        

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_MULS_L()
*****************************************************************************
Func_MULS_L
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MULS_L_MSG,D1
        JSR     Func_Print

        * increment A5 by 2 words
        MOVE.L  #2,D1   * put 2 in D1 for parameter 1
        JSR     Func_MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_DIVS_L()
*****************************************************************************
Func_DIVS_L
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #DIVS_L_MSG,D1
        JSR     Func_Print

        * increment A5 by 2 words
        MOVE.L  #2,D1   * put 2 in D1 for parameter 1
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

        JSR     Func_PrintRotate
        
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

        JSR     Func_PrintRotate
        
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

        JSR     Func_PrintRotate
        
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
        
        JSR     Func_PrintRotate
        
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

        JSR     Func_PrintRotate

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

        JSR     Func_PrintRotate        
        
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
* Func_Dn(Register)
*         D1
* Prints Dn address
*****************************************************************************
Func_Dn
        MOVEM.L     D0-D1,-(SP)
        CLR         D0
        MOVE.B      D1,D0
        CLR         D1
        MOVE.L      #DATA_REG,D1
        JSR         Func_Print
        CLR         D1
        MOVE.B      D0,D1
        JSR         Func_Print_Number
        MOVEM.L     (SP)+,D0-D1
        RTS

*****************************************************************************
* Func_An(Register)
*         D1
* Prints An address
*****************************************************************************
Func_An
        MOVEM.L     D0-D1,-(SP)
        CLR         D0
        MOVE.B      D1,D0
        CLR         D1
        MOVE.L      #ADDRESS_REG,D1
        JSR         Func_Print
        CLR         D1
        MOVE.B      D0,D1
        JSR         Func_Print_Number
        MOVEM.L     (SP)+,D0-D1
        RTS


*****************************************************************************
* Func_An_i(Register)
*           D1
* Prints (An) address
*****************************************************************************
Func_An_i
        MOVEM.L     D0-D1,-(SP)
        CLR         D0
        MOVE.B      D1,D0
        CLR         D1
        MOVE.L      #PAR_OPEN,D1
        JSR         Func_Print
        CLR         D1
        MOVE.B      D0,D1
        JSR         Func_An
        MOVE.L      #PAR_CLOSE,D1
        JSR         Func_Print
        MOVEM.L     (SP)+,D0-D1
        RTS


*****************************************************************************
* Func_An_ip(Register)
*           D1
* Prints (An)+ Address
*****************************************************************************
Func_An_ip
        MOVEM.L     D0-D1,-(SP)
        JSR         Func_An_i
        MOVE.L      #PLUS,D1
        JSR         Func_Print
        MOVEM.L     (SP)+,D0-D1
        RTS


*****************************************************************************
* Func_An_im(Register)
*            D1
* Prints -(An) Address
*****************************************************************************
Func_An_im
        MOVEM.L     D0-D1,-(SP)
        MOVE.B      D1,D0
        MOVE.L      #MINUS,D1
        JSR         Func_Print
        CLR         D1
        MOVE.B      D0,D1
        JSR         Func_An_i
        MOVEM.L     (SP)+,D0-D1
        RTS


*****************************************************************************
* Func_Word_A()
* Prints xxx.W address
*****************************************************************************
Func_Word_A
        MOVEM.L     D1,-(SP)
        MOVE.L      #MONEY,D1
        JSR         Func_Print
        JSR         Func_HexWord
        MOVEM.L     (SP)+,D1
        RTS


*****************************************************************************
* Func_Long_A()
* Prints xxx.L address
*****************************************************************************
Func_Long_A
        MOVEM.L     D1,-(SP)
        MOVE.L      #MONEY,D1
        JSR         Func_Print
        JSR         Func_HexWord
        JSR         Func_HexWord
        MOVEM.L     (SP)+,D1
        RTS


*****************************************************************************
* Func_HexWord()
* Prints a HexWord
*****************************************************************************
Func_HexWord
        MOVEM.L     D1-D2,-(SP)
        CLR         D1
        MOVE.B      #1,D1
        JSR         Func_MoveInstructionPointer
        MOVE.W      (A5),D1
        MOVE.B      #3,D2
        JSR         Func_PrintHexLoop
        MOVEM.L     (SP)+,D1-D2
        RTS

*****************************************************************************
* void Func_PrintHexLoop(Number, StartHighIndex)
*                        D1      D2
* Prints a Hex number
*****************************************************************************
Func_PrintHexLoop
        MOVEM.L     D1-D4,-(SP)
        MOVE.L      D1,D4
        MULS.W      #4,D2
        MOVE.B      #4,D3
        BRA         HexLoop

HexLoop
        JSR         Func_GetBits
        CLR         D1
        MOVE.B      D0,D1
        JSR         Func_Print_Number
        MOVE.L      D4,D1
        SUB.B       #4,D2
        CMP.B       #-4,D2
        BNE         HexLoop
        MOVEM.L     (SP)+,D1-D4
        RTS


*****************************************************************************
* Func_PrintHex(Number, HexPlace)
*               D1      D2
* Gets the HexNumber in a given position from the Number
*****************************************************************************
Func_PrintHex
        MOVEM.L     D1-D3,-(SP)
        MULS.W      #4,D2
        MOVE.B      #4,D3
        JSR         Func_GetBits
        MOVE.B      D0,D1
        JSR         Func_Print
        MOVEM.L     (SP)+,D1-D3
        RTS


*****************************************************************************
* Func_WordData()
* Prints #<data>
*****************************************************************************
Func_WordData
        MOVEM.L     D1,-(SP)
        MOVE.L      #POUND,D1
        JSR         Func_Print
        JSR         Func_Word_A
        MOVEM.L     (SP)+,D1
        RTS
        
        
*****************************************************************************
* Func_LongData()
* Prints #<data>
*****************************************************************************
Func_LongData
        MOVEM.L     D1,-(SP)
        MOVE.L      #POUND,D1
        JSR         Func_Print
        JSR         Func_Long_A
        MOVEM.L     (SP)+,D1
        RTS
        
        
*****************************************************************************
* Func_Data(Dummy, Size)
*           D1     D2
* (D2 == 0) == Word || (D2 != 0) == Long
* Prints #<data>
* !! Can logic for when Word vs Long !!
*****************************************************************************
Func_Data
        MOVEM.L     D1-D2,-(SP)
        * Needs to get size here
        CMP.B       #0,D2
        BEQ         WORD
        BNE         LONG
WORD
        JSR         Func_WordData
        MOVEM.L     (SP)+,D1-D2
        RTS
LONG
        JSR         Func_LongData
        MOVEM.L     (SP)+,D1-D2
        RTS
    

*****************************************************************************
* Func_Print_Number(Number)
*                   D1
* Prints number
*****************************************************************************
Func_Print_Number
        MOVEM.L     D0-D1,-(SP)
        CLR         D0
        MOVE.B      D1,D0
        CLR         D1
        MOVE.L      #ZERO,D1
        MULS.W      #2,D0
        ADD.W       D0,D1
        JSR         Func_Print
        MOVEM.L     (SP)+,D0-D1        
        RTS

*****************************************************************************
* Func_Junk()
* Dummy Return
*****************************************************************************
Func_Junk
        RTS


*****************************************************************************
* Func_PrintLabel()
* Dummy Return
*****************************************************************************
Func_PrintLabel
        MOVEM.L     D1-D4,-(SP)

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4
        
        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print
        
        * Get Displacement
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        
        * If displacement == 00
        CMP.L   #0,D0
        BEQ     DISPLACEMENT_WORD
        
        * If displacement == FF
        CMP.L   #$FF,D0
        BEQ     DISPLACEMENT_LONG
        
        * Else
        MOVE.B  D0,D1
        LSL     #4,D1
        LSR     #4,D1
        JSR     Func_Print_Number
        MOVE.B  D0,D1
        LSR     #4,D1
        JSR     Func_Print_Number
        BRA     LABEL_DONE
        
DISPLACEMENT_WORD
        JSR     Func_WordData
        BRA     LABEL_DONE

DISPLACEMENT_LONG
        JSR     Func_LongData
        BRA     LABEL_DONE

LABEL_DONE
        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* Func_PrintRotate()
* Dummy Return
*****************************************************************************
Func_PrintRotate
        MOVEM.L     D1-D4,-(SP)

        * print the size string (standard is in bits 6-7)
        JSR     Func_PrintSizeStandard
        
        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Print space
        MOVE.L  #SPACE,D1
        JSR     Func_Print
        
        * Check for memory rotate XXX <ea>
        MOVE.L  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #2,D3
        JSR     Func_GetBits
        CMP.B   #3,D0
        BEQ     ROTATE_MEMORY
        
        * Get source
        MOVE.L  D4,D1
        MOVE.L  #5,D2
        MOVE.L  #1,D3
        JSR     Func_GetBits
        CMP.B   #0,D0
        BEQ     ROTATE_DATA
        BRA     ROTATE_REG
        
ROTATE_DATA
        MOVE.L  #POUND,D1
        JSR     Func_Print
        MOVE.L  #MONEY,D1
        JSR     Func_Print
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_Print_Number
        BRA     ROTATE_CONTINUE
        
ROTATE_REG
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg
        BRA     ROTATE_CONTINUE
        
ROTATE_MEMORY
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg

ROTATE_CONTINUE
        MOVE.L  #COMMA,D1
        JSR     Func_Print
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #3,D3
        JSR     Func_GetBits
        MOVE.L  D0,D1
        JSR     Func_JumpAddressTableModeReg
        
ROTATE_DONE
        MOVEM.L  (SP)+,D1-D4    * restore
        RTS

*****************************************************************************
* Data
*****************************************************************************
NEW_LINE        DC.B    CR,LF,0
START_MSG       DC.B    '68k_Disassemlber',CR,LF,'------------------',CR,LF,0

* opcode print outs
NO_OP_MSG       DC.B    'Error: invalid opcode',0
MOVE_B_MSG      DC.B    'MOVE.B',0
MOVE_W_MSG      DC.B    'MOVE.W',0
MOVEA_W_MSG     DC.B    'MOVEA.W',0
MOVE_L_MSG      DC.B    'MOVE.L',0
MOVEA_L_MSG     DC.B    'MOVEA.L',0
ADD_MSG         DC.B    'ADD.',0
ADDA_MSG        DC.B    'ADDA.',0
OR_MSG          DC.B    'OR.',0
DIVS_W_MSG      DC.B    'DIVS.W',0
MULS_W_MSG      DC.B    'MULS.W',0
DIVS_L_MSG      DC.B    'DIVS.L',0
MULS_L_MSG      DC.B    'MULS.L',0
SUB_MSG         DC.B    'SUB.',0
SUBQ_MSG        DC.B    'SUBQ.*',0
CMP_MSG         DC.B    'CMP.',0
EOR_MSG         DC.B    'EOR.*',0
BCS_MSG         DC.B    'BCS',0
BVC_MSG         DC.B    'BVC',0
BGE_MSG         DC.B    'BGE',0
BLT_MSG         DC.B    'BLT',0
BRA_MSG         DC.B    'BRA',0
LSR_MSG         DC.B    'LSR.',0
LSL_MSG         DC.B    'LSL.',0
ASR_MSG         DC.B    'ASR.',0
ASL_MSG         DC.B    'ASL.',0
ROR_MSG         DC.B    'ROR.',0
ROL_MSG         DC.B    'ROL.',0
BCLR_MSG        DC.B    'BCLR.*',0
ORI_MSG         DC.B    'ORI.*',0
CMPI_MSG        DC.B    'CMPI.*',0
JSR_MSG         DC.B    'JSR',0
LEA_MSG         DC.B    'LEA',0
NEG_MSG         DC.B    'NEG.*',0
MOVEM_MSG       DC.B    'MOVEM.*',0
RTS_MSG         DC.B    'RTS',0

* data size types
B_MSG           DC.B    'B',0
W_MSG           DC.B    'W',0
L_MSG           DC.B    'L',0
Q_MSG           DC.B    '?',0

* Address print outs
DATA_REG        DC.B    'D',0
ADDRESS_REG     DC.B    'A',0
PAR_OPEN        DC.B    '(',0
PAR_CLOSE       DC.B    ')',0
PLUS            DC.B    '+',0
MINUS           DC.B    '-',0
POUND           DC.B    '#',0
MONEY           DC.B    '$',0
SPACE           DC.B    ' ',0
COMMA           DC.B    ',',0

* Number Table 
ZERO            DC.B    '0',0
ONE             DC.B    '1',0
TWO             DC.B    '2',0
THREE           DC.B    '3',0
FOUR            DC.B    '4',0
FIVE            DC.B    '5',0
SIX             DC.B    '6',0
SEVEN           DC.B    '7',0
EIGHT           DC.B    '8',0
NINE            DC.B    '9',0
TEN             DC.B    'A',0
ELEVEN          DC.B    'B',0
TWELVE          DC.B    'C',0
THIRTEEN        DC.B    'D',0
FOURTEEN        DC.B    'E',0
FIFTEEN         DC.B    'F',0

* opcodes loaded into memory
* output should be in the same order
FirstOpcode     * MOVEA.L
                DC.W    $267C
                DC.W    $04C5
                DC.W    $D770
                DC.W    $2240
                DC.W    $2C78
                DC.W    $4000
                DC.W    $2E53
                * MOVEA.W
                DC.W    $307C
                DC.W    $04C5
                DC.W    $3A40
                DC.W    $3878
                DC.W    $1000
                DC.W    $3453
                * MOVE.L
NoMoreOpcodes   DC.W    %1111111111111111


        END    Main        * last line of source








*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
