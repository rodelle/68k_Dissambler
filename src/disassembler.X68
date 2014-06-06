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


*****************************************************************************
*****************************************************************************
* Main
*****************************************************************************
*****************************************************************************

START    ORG    $1000

NoPreferenceDisassembler        

        MOVE    #START_MSG,D1
        JSR     PrintMessage

NPD_DoWhile        
        MOVE    #gPrintCount,A0
        MOVE    #0,(A0) * set the number of currently printed lines to 0
        
        * JSR     GetStartEndAddress  * Grab ending and starting address from user

        MOVEA.L  #$7FC0,A5
        MOVEA.L  #$8202,A6
        
        JSR     DisassembleLoop     * Ending and starting address are assigned, begin loop
                                    * parsing each opcode
        JSR     PromptForReinput    * Ask the user if they want to dissamble another program

        JSR     PrintNewline        * prints newline, does not modify D0
        CMP     #0,D0
        BEQ     NPD_DoWhile         * User responded they wish to restart

NPD_ProgramDone
        MOVE    #kGoodbyeMessage,D1
        JSR     PrintMessage

        MOVE.B  #9,D0               * quit program
        TRAP    #15

DisassembleLoop
        CMP.L   A5,A6   * compare starting address to ending address
        * if starting address == ending address, done
        BLE     DisassembleDone
    
        JSR     PrintProgramCounter * prints the address of the opcode being looked at
    
        JSR     ResetStringBuffer

        MOVEA.L A5,A4   * save current program counter
        * else decode next instruction
        JSR     DecodeOpcode
        
        * if the opcode is invalid, incremenets A4 by 1 and sets A5 equal to it
        JSR     CheckInvalid  
        
        * actually print the buffer
        JSR     PrintStringBuffer
        JSR     PrintNewLine

        BRA     DisassembleLoop

DisassembleDone
        RTS



*****************************************************************************
*****************************************************************************
* Function Tables
*****************************************************************************
*****************************************************************************


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
*****************************************************************************
* Functions
*****************************************************************************
*****************************************************************************


*****************************************************************************
* PromptForReinput()
* Args: None
* Prompts the user with a question to restart the program and grabs a single
*   character input as response.
* Returns 0 if the user responded yes, 1 otherwise
* Ex. "Would you like to restart the program (y/n)?" y => D0 = 0
*     "Would you like to restart the program (y/n)?" n => D0 = 1
*****************************************************************************
PromptForReinput
        MOVEM.L D1-D2, -(SP) * Save used registers
        MOVE.L #kRestartPrompt,D1
        JSR PrintMessage

        MOVE.B  #5,D0 * Reads letter from the user into D1
        TRAP    #15

        MOVE.B  D1,D2
        SUB.B   #121,D2 * compare to 'y'
        BEQ     PFRRL_ReturnTrue

        MOVE.B  D1,D2
        SUB.B   #89,D1 * compare to 'Y'
        BEQ     PFRRL_ReturnTrue

        MOVE    #1,D0  * user said no, return false
        BRA     PFRRL_Done

PFRRL_ReturnTrue
        MOVE    #0,D0  * user said yes, return true

PFRRL_Done
        MOVEM.L (SP)+, D1-D2 * Restore used registers
        RTS

*****************************************************************************
* PromptToContinue()
* Args: None
* Pauses the program until the user enters a value on the keyboard.
*****************************************************************************
PromptToContinue
        MOVEM.L D0-D2, -(SP) * Save used registers
        MOVE.L  #kContinuePrompt,D1
        JSR     PrintMessage

        MOVE.B  #5,D0 * Reads letter from the user into D1
        TRAP    #15
        
        MOVEM.L (SP)+, D0-D2 * Restore used registers
        RTS

*****************************************************************************
* GetStartEndAddress()
* Args: None
* Gets two addresses from the user and assigns them to A5 and A6 respectively
*   A5 and A6 represent the starting and ending address of the program we
*   are dissambling.
* Ex. User enters 8000 and A000 as the starting and ending address
*     A5 = $00008000, A6 = $0000A000
*****************************************************************************
GetStartEndAddress
        MOVE.L #kStartAddressPrompt,D1
        JSR PrintMessage

        JSR GetFourHexBitsFromUser
        MOVE.L #0,A5
        MOVEA.L D0,A5

        JSR PrintNewline

        MOVE.L #kEndAddressPrompt,D1
        JSR PrintMessage

        JSR GetFourHexBitsFromUser
        MOVE.L #0,A6
        MOVEA.L D0,A6

        JSR PrintNewline

        RTS


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
        MOVEM.L D1, -(SP)   * save registers
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
        MOVEM.L (SP)+, D1   * restore used registers
        RTS



*****************************************************************************
* void JumpAddressTableModeReg(6bit Mode-Register, size)
*                              D1                  D2
* Unsure what to leave in the registers
* Currently leaves nothing in registers
*****************************************************************************
JumpAddressTableModeReg
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
JumpAddressTableRegMode
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
        BRA     Done_JumpAddressTable

* get jump value for NON-Word/Long Address OR Data
NO_ADD_TOGETHER
        LEA     AddressTable,A1
        CLR     D0
        ADD.W   D2,D0
        MULS.W  #4,D0
        ADD.W   A1,D0
        MOVEA.W D0,A1
        BRA     Done_JumpAddressTable

Done_JumpAddressTable
        CLR     D2
        MOVE.B  D6,D2
        MOVE.L  D3,D1       * move register into D1
        MOVEA.L (A1),A1
        JSR     (A1)
        MOVEM.L (SP)+,D0-D6/A1
        RTS

*****************************************************************************
* void MoveInstructionPointer(number of words)
*                                  D1
* expects global variable A5 to contain current address location
*****************************************************************************
MoveInstructionPointer
        MOVEM.L D1,-(SP) * save D1 so we can use it

        LSL.L   #1,D1    * multiply byte by 2 to get word
        ADDA.L  D1,A5    * shift by a word

        MOVEM.L (SP)+,D1 * restore D1
        RTS


*****************************************************************************
* void PrintSizeStandard()
* expects global variable A5 to be pointing at current opcode.
*
* prints the size for instructions who fit the following configuration:
* bits 7,6         (where 6 and 7 are of the first opcode word)
*      0,0 = byte
*      0,1 = word
*      1,0 = long
*      1,1 = ?   (error)
*****************************************************************************
PrintSizeStandard
        MOVEM.L D1-D3,-(SP)

        CLR.L   D1
        MOVE.W  (A5),D1         * copy current "PC" into D1
        MOVE.L  #6,D2           * get bit 6
        MOVE.L  #2,D3           * to bit 7
        JSR     GetBits    * store result in D0

        * print the size string
        MOVE.L  D0,D1           * move size bits into D1

        * if D1 is 0, then it is a byte
        * load 'byte' msg into D0
        CMP     #0,D1
        BNE     Word_PrintSizeStandard
        MOVE    #B_MSG,D1
        BRA     Done_PrintSizeStandard

Word_PrintSizeStandard
        * if D1 is 1, then it is a word
        * load 'word' msg into D0
        CMP     #1,D1
        BNE     Long_PrintSizeStandard
        MOVE    #W_MSG,D1
        BRA     Done_PrintSizeStandard

Long_PrintSizeStandard
        * if D1 is 2, then it is a long
        * load 'long' msg into D0
        CMP     #2,D1
        BNE     Error_PrintSizeStandard
        MOVE    #L_MSG,D1
        BRA     Done_PrintSizeStandard

Error_PrintSizeStandard
        * else it is an error
        JSR     InvalidateStringBuffer
        MOVE    #Q_MSG,D1

Done_PrintSizeStandard
        JSR     AddStringToStringBuffer
        MOVEM.L (SP)+,D1-D3
        RTS


*****************************************************************************
* void AddStringToStringBuffer( StringAddress )
*                                    D1
* add a null-terminated string to the string buffer
* this function provides compatability between the string buffer and
* more conventional 68k string usage
*****************************************************************************
AddStringToStringBuffer
        MOVEM.L D0-D7/A1,-(SP)

        * d1 contains null terminated string
        MOVEA   D1,A1
        CLR.L   D1
Loop_Func_Print
        MOVE.B  (A1)+,D1
        CMP     #0,D1
        BEQ     Done_Func_Print

        MOVE.L  #1,D2
        JSR     AddWordToStringBuffer
        BRA     Loop_Func_Print

Done_Func_Print
        MOVEM.L (SP)+,D0-D7/A1
        RTS


*****************************************************************************
* void DecodeOpcode()
* expects global variable A5 to contain current address location
*****************************************************************************
DecodeOpcode
        MOVEM.L D0-D3/A1,-(SP)     * save registers that will be modified

        * get the 4 MSBits of the address
        CLR.L   D1
        MOVE.W  (A5),D1     * copy current "PC" into D1
        MOVE.L  #12,D2      * starting at bit 12
        MOVE.L  #4,D3       * get 4 bits
        JSR     GetBits     * (returns result in D0)

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
* int GetBits(value, lowerBit, numBits)
* D0          D1     D2        D3
* Returns the bits from value[lowerBit] to value[lowerBit + numBits]
*
* ex.      GetBits( 0000111101100111 , LSB = 3 , length = 5 )
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
        JSR     GetBits     * store result in D0

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
        JSR     GetBits     * store result in D0

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
        JSR     GetBits     * store result in D0

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
        JSR     GetBits     * store result in D0

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
        JSR     GetBits     * store result in D0

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
        JSR     GetBits     * store result in D0

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
        JSR     GetBits   * store result in D0

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
        JSR     GetBits     * store result in D0

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
        JSR     GetBits   * store result in D0

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
        JSR     GetBits  * store result in D0

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
        JSR     GetBits  * store result in D0

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
        JSR     AddStringToStringBuffer

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Gets and prints the <ea> parameter for MOVEA.L
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        MOVE.L  #1,D2
        JSR     JumpAddressTableModeReg

        * Print comma
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Gets and prints the An parameter for MOVEA.L
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        ADD.L   #%001000,D0     * adds mode for An
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

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
        JSR     AddStringToStringBuffer

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Checks for invalid address
        MOVE.L  #6,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetRegMode
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnData
        CMP.B   #0,D0
        BNE     MOVE_L_DONE

        * Gets and prints the Source parameter for MOVE.L
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        MOVE.L  #1,D2
        JSR     JumpAddressTableModeReg

        * Print comma
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Gets and prints the Destination parameter for MOVE.L
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableRegMode

MOVE_L_DONE
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_MOVEA_W()
*****************************************************************************
Func_MOVEA_W
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MOVEA_W_MSG,D1
        JSR     AddStringToStringBuffer

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Gets and prints the <ea> parameter for MOVEA.L
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     JumpAddressTableModeReg

        * Print comma
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Gets and prints the An parameter for MOVEA.L
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        ADD.L   #%001000,D0     * adds mode for An
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

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
        JSR     AddStringToStringBuffer

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Checks for invalid address
        MOVE.L  #6,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetRegMode
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnData
        CMP.B   #0,D0
        BNE     MOVE_W_DONE

        * Gets and prints the source parameter for MOVE.W
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     JumpAddressTableModeReg

        * Print comma
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Gets and prints the destination parameter for MOVE.W
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableRegMode

MOVE_W_DONE
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_MOVE_B()
* NEED TO CHECK FOR #<Data>
*****************************************************************************
Func_MOVE_B
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MOVE_B_MSG,D1
        JSR     AddStringToStringBuffer

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Checks for invalid address
        MOVE.L  #6,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetRegMode
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnData
        CMP.B   #0,D0
        BNE     MOVE_B_DONE

        * Gets and prints the source parameter for MOVE.B
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     JumpAddressTableModeReg

        * Print comma
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Gets and prints the destination parameter for MOVE.B
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableRegMode

MOVE_B_DONE
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_ADD()
*****************************************************************************
Func_ADD
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ADD_MSG,D1
        JSR     AddStringToStringBuffer

        * print the size string (standard is in bits 6-7)
        JSR     PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * determin data first or second
        MOVE.L  #8,D2
        MOVE.L  #1,D3
        JSR     GetBits

        CMP.B   #0,D0
        BNE     Func_ADD_DataFirst
        BEQ     Func_ADD_DataSecond

Func_ADD_DataFirst

        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnDnData
        CMP.B   #0,D0
        BNE     ADD_Done

        * Print Data Register
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        * Print comma
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Print destination effective address
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     JumpAddressTableModeReg
        BRA     ADD_Done

Func_ADD_DataSecond
        * Print destination effective address
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     JumpAddressTableModeReg

        * Print comma
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Print Data Register
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        BRA     ADD_Done

ADD_Done
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer
        MOVEM.L  (SP)+,D1-D4    * restore
        RTS

*****************************************************************************
* void Func_ADDA()
*****************************************************************************
Func_ADDA
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ADDA_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * determin data first or second
        MOVE.L  #8,D2
        MOVE.L  #1,D3
        JSR     GetBits

        CMP.B   #0,D0
        BNE     Func_ADDA_L
        BEQ     Func_ADDA_W

Func_ADDA_W
        * Print W
        MOVE.L  #W_MSG,D1
        JSR     AddStringToStringBuffer

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        MOVE.L  D4,D1

        * Gets and prints the <ea> parameter for ADDA.W
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     JumpAddressTableModeReg

        * Print comma
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Gets and prints the An parameter for ADDA.W
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        ADD.L   #%001000,D0     * adds mode for An
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        BRA     ADDA_Done

Func_ADDA_L
        * Print L
        MOVE.L  #L_MSG,D1
        JSR     AddStringToStringBuffer

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        MOVE.L  D4,D1

        * Gets and prints the <ea> parameter for ADDA.L
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        MOVE.L  #1,D2
        JSR     JumpAddressTableModeReg

        * Print comma
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Gets and prints the An parameter for ADDA.L
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        ADD.L   #%001000,D0     * adds mode for An
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        BRA     ADDA_Done

ADDA_Done
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer
        MOVEM.L  (SP)+,D1-D4    * restore
        RTS

*****************************************************************************
* void Func_OR()
*****************************************************************************
Func_OR
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #OR_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * print the size string (standard is in bits 6-7)
        JSR     PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * determin data first or second
        MOVE.L  D4,D1
        MOVE.L  #8,D2
        MOVE.L  #1,D3
        JSR     GetBits

        CMP.B   #0,D0
        BNE     Func_OR_DataFirst
        BRA     Func_OR_DataSecond

Func_OR_DataFirst
        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnDnData
        CMP.B   #0,D0
        BNE     OR_Done

        * Print Data Register
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        * Print comma
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Print destination effective address
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     JumpAddressTableModeReg
        BRA     OR_Done


Func_OR_DataSecond
        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAn
        CMP.B   #0,D0
        BNE     OR_Done

        * Print destination effective address
        CLR     D1
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     JumpAddressTableModeReg

        * Print comma
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Print Data Register
        CLR.L   D1
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        BRA     OR_Done

OR_Done
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer
        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_BCLR()
*****************************************************************************
Func_BCLR
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BCLR_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnData
        CMP.B   #0,D0
        BNE     BCLR_FINISHED

        * Get destination mode
        MOVE.L  #3,D2
        MOVE.L  #3,D3
        JSR     GetBits

        CMP.B   #0,D0
        BEQ     BCLR_DataDestination
        BRA     BCLR_OtherDestination

BCLR_DataDestination
        *Print size/space
        MOVE.L  #L_MSG,D1
        JSR     AddStringToStringBuffer
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer
        BRA     BCLR_SourceBranch

BCLR_OtherDestination
        *Print size/space
        MOVE.L  #B_MSG,D1
        JSR     AddStringToStringBuffer
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer
        BRA     BCLR_SourceBranch

BCLR_SourceBranch
        MOVE.L  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #3,D3
        JSR     GetBits
        CMP.B   #2,D0
        BEQ     BCLR_ImmediateSource
        CMP.B   #6,D0
        BEQ     BCLR_DataSource
        * CALL INVALIDATE?
        BRA     BCLR_FINISHED

BCLR_DataSource
        * Gets register for source
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        BRA     BCLR_DONE

BCLR_ImmediateSource
        * Gets immediate data
        JSR     Func_WordData
        BRA     BCLR_DONE

BCLR_DONE
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Prints destination
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

BCLR_FINISHED
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_ORI()
*****************************************************************************
Func_ORI
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ORI_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnData
        CMP.B   #0,D0
        BNE     ORI_FINISHED

        * print the size string (standard is in bits 6-7)
        JSR     PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Print immediate data
        MOVE.L  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #2,D3
        JSR     GetBits
        CMP.L   #0,D0
        BEQ     PRINT_WORD
        CMP.L   #1,D0
        BEQ     PRINT_WORD
        CMP.L   #2,D0
        BEQ     PRINT_LONGWORD
        * Not 0/1/2 then incorrect command

PRINT_LONGWORD
        JSR     Func_LongData
        BRA     ORI_DONE

PRINT_WORD
        JSR     Func_WordData
        BRA     ORI_DONE

ORI_DONE
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

ORI_FINISHED
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_CMPI()
*****************************************************************************
Func_CMPI
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #CMPI_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnData
        CMP.B   #0,D0
        BNE     CMPI_FINISHED

        * print the size string (standard is in bits 6-7)
        JSR     PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Print immediate data
        MOVE.L  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #2,D3
        JSR     GetBits
        CMP.L   #0,D0
        BEQ     PRINT_WORD_CMPI
        CMP.L   #1,D0
        BEQ     PRINT_WORD_CMPI
        CMP.L   #2,D0
        BEQ     PRINT_LONGWORD_CMPI
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
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

CMPI_FINISHED
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_NEG()
*****************************************************************************
Func_NEG
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #NEG_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4
    
        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnData
        CMP.B   #0,D0
        BNE     NEG_DONE

        * print the size string (standard is in bits 6-7)
        JSR     PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Get mode/reg and print
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

NEG_DONE
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_MOVEM()
*****************************************************************************
Func_MOVEM
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MOVEM_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Check Direction
        MOVE.L  D4,D1
        MOVE.L  #10,D2
        MOVE.L  #1,D3
        JSR     GetBits
        CMP.B   #0,D0
        BEQ     MOVEM_IN
        BNE     MOVEM_OUT

MOVEM_IN
        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnDnDataAnp
        CMP.B   #0,D0
        BNE     MOVEM_DONE
        
        * print MOVEM registers
        MOVE.L  #1,D1
        JSR     MoveInstructionPointer
        CLR     D1
        MOVE.W  (A5),D1
        JSR     PreDecrementMovemBitMask
        
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer
        
        * print effective address
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        
        BRA     MOVEM_DONE

MOVEM_OUT
        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnDnDataAnm
        CMP.B   #0,D0
        BNE     MOVEM_DONE
        
        * print effective address
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer
        
        * print MOVEM registers
        MOVE.L  #1,D1
        JSR     MoveInstructionPointer
        CLR     D1
        MOVE.W  (A5),D1
        JSR     PreDecrementMovemBitMask
        
        BRA     MOVEM_DONE

MOVEM_DONE
        * increment A5 by 1 words
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_JSR()
*****************************************************************************
Func_JSR
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #JSR_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Get and Print mode/reg
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_LEA()
*****************************************************************************
Func_LEA
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #LEA_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnDnDataAnpAnm
        CMP.B   #0,D0
        BNE     LEA_DONE

        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Get source mode/reg and print
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Get address register
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        ADD.B   #%1000,D0
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

LEA_DONE
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_RTS()
*****************************************************************************
Func_RTS
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #RTS_MSG,D1
        JSR     AddStringToStringBuffer

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_SUBQ()
*****************************************************************************
Func_SUBQ
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #SUBQ_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckData
        CMP.B   #0,D0
        BNE     SUBQ_DONE

        * print the size string (standard is in bits 6-7)
        JSR     PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Print # for data
        MOVE.L  #POUND,D1
        JSR     AddStringToStringBuffer

        * Get number 1-8 for immediate data
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits

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
        JSR     AddStringToStringBuffer

        * Get mode-reg
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits

        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

SUBQ_DONE
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_BCS()
*****************************************************************************
Func_BCS
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BCS_MSG,D1
        JSR     AddStringToStringBuffer

        * Jump to Label Printer
        JSR     Func_PrintLabel

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_BVC()
*****************************************************************************
Func_BVC
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BVC_MSG,D1
        JSR     AddStringToStringBuffer

        * Jump to Label Printer
        JSR     Func_PrintLabel

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_BGE()
*****************************************************************************
Func_BGE
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BGE_MSG,D1
        JSR     AddStringToStringBuffer

        * Jump to Label Printer
        JSR     Func_PrintLabel

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_BLT()
*****************************************************************************
Func_BLT
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BLT_MSG,D1
        JSR     AddStringToStringBuffer

        * Jump to Label Printer
        JSR     Func_PrintLabel

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS



*****************************************************************************
* void Func_BRA()
*****************************************************************************
Func_BRA
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #BRA_MSG,D1
        JSR     AddStringToStringBuffer

        * Jump to Label Printer
        JSR     Func_PrintLabel

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_SUB()
*****************************************************************************
Func_SUB
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #SUB_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * print the size string (standard is in bits 6-7)
        JSR     PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * determin data first or second
        MOVE.L  D4,D1
        MOVE.L  #8,D2
        MOVE.L  #1,D3
        JSR     GetBits

        CMP.B   #0,D0
        BNE     Func_SUB_DataFirst
        BRA     Func_SUB_DataSecond

Func_SUB_DataFirst
        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnDnData
        CMP.B   #0,D0
        BNE     SUB_DONE

        * Print Data Register
        CLR.L   D1
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        * Print comma
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Print destination effective address
        CLR     D1
        MOVE.W  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     JumpAddressTableModeReg
        BRA     SUB_Done


Func_SUB_DataSecond
        * Print destination effective address
        CLR     D1
        MOVE.W  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        MOVE.L  #0,D2
        JSR     JumpAddressTableModeReg

        * Print comma
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Print Data Register
        CLR.L   D1
        MOVE.W  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        BRA     SUB_Done

SUB_Done
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer
        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_CMP()
*****************************************************************************
Func_CMP
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #CMP_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * print the size string (standard is in bits 6-7)
        JSR     PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Get/Print mode/reg for destination
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

         * Get bits for Dn and Print
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_EOR()
*****************************************************************************
Func_EOR
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #EOR_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnData
        CMP.B   #0,D0
        BNE     EOR_DONE

        * print the size string (standard is in bits 6-7)
        JSR     PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Get bits for Dn and Print
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * Get/Print mode/reg for destination
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

EOR_DONE
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_MULS_W()
*****************************************************************************
Func_MULS_W
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MULS_W_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAn
        CMP.B   #0,D0
        BNE     MULS_W_DONE

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Get/Print mode/reg for destination
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

         * Get bits for Dn and Print
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

MULS_W_DONE
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_DIVS_W()
*****************************************************************************
Func_DIVS_W
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #DIVS_W_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAn
        CMP.B   #0,D0
        BNE     DIVS_W_DONE

        * Get/Print mode/reg for source
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

         * Get bits for Dn and Print
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

DIVS_W_DONE
        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_MULS_L()
*****************************************************************************
Func_MULS_L
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #MULS_L_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Get/Print mode/reg for destination
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * increment A5 by 1 words
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Get size bit
        MOVE.L  #10,D2
        MOVE.L  #1,D3
        JSR     GetBits
        CMP.L   #0,D0
        BEQ     MULS_ONE_DESTINATION
        BRA     MULS_TWO_DESTINATIONS

MULS_ONE_DESTINATION
        * Print Address Destination
        MOVE.L  D4,D1
        MOVE.L  #12,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        BRA     MULS_DONE

MULS_TWO_DESTINATIONS
        * Print First Address Destination
        MOVE.L  D4,D1
        MOVE.L  #12,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        * Print '-'
        MOVE.L  #MINUS,D1
        JSR     AddStringToStringBuffer

        * Print Second Address Destination
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        BRA     MULS_DONE

MULS_DONE
        * increment A5 by 1 words
        MOVE.L  #1,D1   * put 2 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_DIVS_L()
*****************************************************************************
Func_DIVS_L
        MOVEM.L  D1-D4,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #DIVS_L_MSG,D1
        JSR     AddStringToStringBuffer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Get/Print mode/reg for destination
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer

        * increment A5 by 1 words
        MOVE.L  #1,D1   * put 2 in D1 for parameter 1
        JSR     MoveInstructionPointer

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Get size bit
        MOVE.L  #10,D2
        MOVE.L  #1,D3
        JSR     GetBits
        CMP.L   #0,D0
        BEQ     DIVS_ONE_DESTINATION
        BRA     DIVS_TWO_DESTINATIONS

DIVS_ONE_DESTINATION
        * Print Address Destination
        MOVE.L  D4,D1
        MOVE.L  #12,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        BRA     DIVS_DONE

DIVS_TWO_DESTINATIONS
        * Print First Address Destination
        MOVE.L  D4,D1
        MOVE.L  #12,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

        * Print '-'
        MOVE.L  #MINUS,D1
        JSR     AddStringToStringBuffer

        * Print Second Address Destination
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        BRA     DIVS_DONE

DIVS_DONE
        * increment A5 by 1 words
        MOVE.L  #1,D1   * put 2 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* void Func_LSR()
*****************************************************************************
Func_LSR
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #LSR_MSG,D1
        JSR     AddStringToStringBuffer

        JSR     Func_PrintRotate

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_LSL()
*****************************************************************************
Func_LSL
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #LSL_MSG,D1
        JSR     AddStringToStringBuffer

        JSR     Func_PrintRotate

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_ASR()
*****************************************************************************
Func_ASR
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ASR_MSG,D1
        JSR     AddStringToStringBuffer

        JSR     Func_PrintRotate

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_ASL()
*****************************************************************************
Func_ASL
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ASL_MSG,D1
        JSR     AddStringToStringBuffer

        JSR     Func_PrintRotate

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_ROR()
*****************************************************************************
Func_ROR
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ROR_MSG,D1
        JSR     AddStringToStringBuffer

        JSR     Func_PrintRotate

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_ROL()
*****************************************************************************
Func_ROL
        MOVEM.L  D1,-(SP)    * save D1

        * print pseudo assembly
        MOVE    #ROL_MSG,D1
        JSR     AddStringToStringBuffer

        JSR     Func_PrintRotate

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

        MOVEM.L  (SP)+,D1    * restore
        RTS


*****************************************************************************
* void Func_NO_OP()
*****************************************************************************
Func_NO_OP
        MOVEM.L  D1,-(SP)    * save D1

        JSR     InvalidateStringBuffer

        * increment A5 by 1 word
        MOVE.L  #1,D1   * put 1 in D1 for parameter 1
        JSR     MoveInstructionPointer

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
        JSR         AddStringToStringBuffer
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
        JSR         AddStringToStringBuffer
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
        JSR         AddStringToStringBuffer
        CLR         D1
        MOVE.B      D0,D1
        JSR         Func_An
        MOVE.L      #PAR_CLOSE,D1
        JSR         AddStringToStringBuffer
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
        JSR         AddStringToStringBuffer
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
        JSR         AddStringToStringBuffer
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
        JSR         AddStringToStringBuffer
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
        JSR         AddStringToStringBuffer
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
        MOVE.L      #1,D1
        JSR         MoveInstructionPointer
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
        JSR         GetBits
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
        JSR         GetBits
        MOVE.B      D0,D1
        JSR         AddStringToStringBuffer
        MOVEM.L     (SP)+,D1-D3
        RTS


*****************************************************************************
* Func_WordData()
* Prints #<data>
*****************************************************************************
Func_WordData
        MOVEM.L     D1,-(SP)
        MOVE.L      #POUND,D1
        JSR         AddStringToStringBuffer
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
        JSR         AddStringToStringBuffer
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
        JSR         AddStringToStringBuffer
        MOVEM.L     (SP)+,D0-D1
        RTS


*****************************************************************************
* Func_Junk()
* Dummy Return
*****************************************************************************
Func_Junk
        JSR     InvalidateStringBuffer
        RTS
        
*****************************************************************************
* void CheckInvalid()
* Args: none
* Checks if the string buffer has been invalidated. If it has, it increments
* the program counter by 1 word invalidating all of the incrementing done 
* prior to this function
*****************************************************************************
CheckInvalid
        MOVEM.L D0-D2/A0, -(SP) * Save used registers
        MOVE    #kStringBuffer,A0
        MOVE.L  (A0),D1
        AND.L   #$FF000000,D1
        BNE     CI_IsValid   * if string is valid, do nothing
        
CI_IsInvalid
        MOVEA.L A4,A5   * invalidates all PC changes prior to this call
        MOVE    #1,D1
        JSR     MoveInstructionPointer * incremenets program counter by 4
        
CI_IsValid
        MOVEM.L (SP)+, D0-D2/A0 * Restore used registers
        RTS

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
        BRA     PSB_Continue
PSB_PrintInvalid
        MOVE.L  #kInvalidOpcode,D1
        JSR     PrintMessage

PSB_Continue
        MOVE    #gPrintCount,A0     
        MOVE    (A0),D0             * read the number of lines printed since last prompt
        ADD     #1,D0               * LinesPrinted++
        CMP     #kLinesPerScreen,D0 
        BLT     PSB_Done            * if (linesPrinted < kNumLinesPerScreen)
        
        MOVE    #0,D0               * reset the number of printed lines
        JSR     PrintNewline
        JSR     PromptToContinue    * pause the output

PSB_Done
        MOVE    D0,(A0)             * save the number of printed lines
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
* void PrintProgramCounter ()
* Args: none
* Prints the contents of A5 as a hex address
* ex. A5 = $7FC0
*     prints "$00007FC0    "
*****************************************************************************
PrintProgramCounter
        JSR     ResetStringBuffer
        MOVE    #MONEY,D1               * print dollar sign
        JSR     AddStringToStringBuffer
        
        MOVE.L  A5,D1
        MOVE    #8,D2
        JSR     PrintHexadecimal        * print the address

        MOVE    #SPACE,D1
        JSR     AddStringToStringBuffer 
        JSR     AddStringToStringBuffer
        JSR     AddStringToStringBuffer
        JSR     AddStringToStringBuffer * add spaces
        
        JSR     PrintStringBuffer       * print the string

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
        JSR     AddStringToStringBuffer

        * Get Displacement
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits

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

        * Gets address
        MOVE.W  (A5),D1
        MOVE.W  (A5),D4

        * Check for memory rotate XXX <ea>
        MOVE.L  D4,D1
        MOVE.L  #6,D2
        MOVE.L  #2,D3
        JSR     GetBits
        CMP.B   #3,D0
        BEQ     ROTATE_MEMORY

        * print the size string (standard is in bits 6-7)
        JSR     PrintSizeStandard

        * Print space
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Get source
        MOVE.L  D4,D1
        MOVE.L  #5,D2
        MOVE.L  #1,D3
        JSR     GetBits
        CMP.B   #0,D0
        BEQ     ROTATE_DATA
        BRA     ROTATE_REG

ROTATE_DATA
        MOVE.L  #POUND,D1
        JSR     AddStringToStringBuffer
        MOVE.L  #MONEY,D1
        JSR     AddStringToStringBuffer
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     Func_Print_Number
        BRA     ROTATE_CONTINUE

ROTATE_REG
        MOVE.L  D4,D1
        MOVE.L  #9,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        BRA     ROTATE_CONTINUE

ROTATE_MEMORY
        MOVE.L  #SPACE,D1
        JSR     AddStringToStringBuffer

        * Checks for invalid address
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     GetModeReg
        MOVE.L  D1,D2
        MOVE.L  D0,D1
        CLR     D0
        JSR     CheckAnDnData
        CMP.B   #0,D0
        BNE     ROTATE_DONE

        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #6,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg
        BRA     ROTATE_DONE

ROTATE_CONTINUE
        MOVE.L  #COMMA,D1
        JSR     AddStringToStringBuffer
        MOVE.L  D4,D1
        MOVE.L  #0,D2
        MOVE.L  #3,D3
        JSR     GetBits
        MOVE.L  D0,D1
        JSR     JumpAddressTableModeReg

ROTATE_DONE
        MOVEM.L  (SP)+,D1-D4    * restore
        RTS


*****************************************************************************
* int CheckAn(3-bit mode, 3-bit reg)
* D0          D1          D2
* Dummy Return
*****************************************************************************
CheckAn
        MOVEM.L D1-D2,-(SP)
        CMP.B   #%001,D1
        BNE     CheckAnDone
        ADD.B   #1,D0
        JSR     InvalidateStringBuffer
CheckAnDone     
        MOVEM.L (SP)+,D1-D2
        RTS


*****************************************************************************
* int CheckDn(3-bit mode, 3-bit reg)
* D0          D1          D2
* Dummy Return
*****************************************************************************
CheckDn
        MOVEM.L D1-D2,-(SP)
        CMP.B   #%000,D1
        BNE     CheckDnDone
        ADD.B   #1,D0
        JSR     InvalidateStringBuffer
CheckDnDone     
        MOVEM.L (SP)+,D1-D2
        RTS


*****************************************************************************
* int CheckData(3-bit mode, 3-bit reg)
* DO            D1          D2
* Dummy Return
*****************************************************************************
CheckData
        MOVEM.L D1-D2,-(SP)
        CMP.B   #%111,D1
        BEQ     CheckDataReg
        BRA     CheckDataDone
CheckDataReg
        CMP.B   #%100,D2
        BNE     CheckDataDone
        ADD.B   #1,D0
        JSR     InvalidateStringBuffer
CheckDataDone     
        MOVEM.L (SP)+,D1-D2
        RTS


*****************************************************************************
* int CheckAnp(3-bit mode, 3-bit reg)
* D0           D1          D2
* Dummy Return
*****************************************************************************
CheckAnp
        MOVEM.L D1-D2,-(SP)
        CMP.B   #%011,D1
        BNE     CheckAnpDone
        ADD.B   #1,D0
        JSR     InvalidateStringBuffer
CheckAnpDone     
        MOVEM.L (SP)+,D1-D2
        RTS


*****************************************************************************
* int CheckAnm(3-bit mode, 3-bit reg)
* Do           D1          D2
* Dummy Return
*****************************************************************************
CheckAnm
        MOVEM.L D1-D2,-(SP)
        CMP.B   #%100,D1
        BNE     CheckAnmDone
        ADD.B   #1,D0
        JSR     InvalidateStringBuffer
CheckAnmDone     
        MOVEM.L (SP)+,D1-D2
        RTS


*****************************************************************************
* int CheckAnData(3-bit mode, 3-bit reg)
* D0              D1          D2
* Dummy Return
*****************************************************************************
CheckAnData
        JSR     CheckAn
        JSR     CheckData
        RTS


*****************************************************************************
* int CheckAnDnData(3-bit mode, 3-bit reg)
* D0                D1          D2
* Dummy Return
*****************************************************************************
CheckAnDnData
        JSR     CheckAnData
        JSR     CheckDn
        RTS
        
        
*****************************************************************************
* int CheckAnDnDataAnpAnm(3-bit mode, 3-bit reg)
* D0                      D1          D2
* Dummy Return
*****************************************************************************
CheckAnDnDataAnpAnm
        JSR     CheckAnDnData
        JSR     CheckAnm
        JSR     CheckAnp
        RTS


*****************************************************************************
* int CheckAnDnDataAnm(3-bit mode, 3-bit reg)
* D0                   D1          D2
* Dummy Return
*****************************************************************************
CheckAnDnDataAnm
        JSR     CheckAnDnData
        JSR     CheckAnm
        RTS
        
        
*****************************************************************************
* int CheckAnDnDataAnp(3-bit mode, 3-bit reg)
* D0                   D1          D2
* Dummy Return
*****************************************************************************
CheckAnDnDataAnp
        JSR     CheckAnDnData
        JSR     CheckAnp
        RTS

*****************************************************************************
* mode reg GetRegMode(6-bit)
* D0   D1             D1
* mode AND reg
*****************************************************************************
GetRegMode
        MOVE.L  D1,D0
        LSR     #3,D1
        LSL     #5,D0
        LSR     #5,D0
        RTS


*****************************************************************************
* mode reg GetModeReg(6-bit)
* D0   D1             D1
* mode AND reg
*****************************************************************************
GetModeReg
        MOVE.L  D1,D0
        LSR.B   #3,D0
        LSL.B   #5,D1
        LSR.B   #5,D1
        RTS


*****************************************************************************
* PostIncrementMovemBitMask
* Args: D1 (bit mask)
* Traverses the bit mask and add the associated register to the bit mask
* ex.   BitMask - 1  1  1  0  1  0  0  0  1  1  0  0  1  1  0  1 
*                 A7 A6 A5 A4 A3 A2 A1 A0 D7 D6 D5 D4 D3 D2 D1 D0
*       prints - D0/D2/D3/D6/D7/A3/A5/A6/A7                 
*****************************************************************************
PostIncrementMovemBitMask
        MOVEM   D0-D3,-(SP)
        MOVE    #0,D2       * printing first half of registers
        MOVE    #DataRegisterStrings,D3
        JSR     PrintRegistersFromBitMask

        LSR     #8,D1       * read the left half of the bit mask
        MOVE    D0,D2       * may or may not have previously printed registers
        MOVE    #AddressRegisterStrings,D3
        JSR     PrintRegistersFromBitMask
        MOVEM   (SP)+,D0-D3
        RTS

*****************************************************************************
* PreDecrementMovemBitMask
* Args: D1 (bit mask)
* Traverses the bit mask and add the associated register to the bit mask
* ex.   BitMask - 1  1  1  0  1  0  0  0  1  1  0  0  1  1  0  1 
*                 D0 D1 D2 D3 D4 D5 D6 D7 A0 A1 A2 A3 A4 A5 A6 A7
*       prints - A7/A5/A4/A1/A0/D4/D2/D1/D0
*****************************************************************************
PreDecrementMovemBitMask
        MOVEM   D0-D7,-(SP)    
        MOVE    #0,D2       * printing first half of registers
        MOVE    #ReversedAddressRegisterStrings,D3
        JSR     PrintRegistersFromBitMask

        LSR     #8,D1       * read the left half of the bit mask
        MOVE    D0,D2       * may or may not have previously printed registers
        MOVE    #ReversedDataRegisterStrings,D3
        JSR     PrintRegistersFromBitMask
        MOVEM   (SP)+,D0-D7
        RTS


*****************************************************************************
* PrintRegistersFromBitMask
* Args: D1 (bit mask), D2 (isFirst), D3 (registerStrings)
* Traverses the bit mask and add the associated register to the bit mask
*****************************************************************************
PrintRegistersFromBitMask
        MOVEM   D1-D7/A0-A6,-(SP)

        MOVE    D3,A0
        MOVE    #8,D7
        
        MOVE    D1,-(SP)
        MOVE    D2,D5
        CLR     D6
    
PRFBM_While
        CMP     #0,D7
        BEQ     PRFBM_Done
        
        MOVE.L  A0,D4           * D4 contains the pointer to the register string
        ADD     #4,A0           * go to the next register
        
        MOVE    (SP)+,D1        * restore the bit mask
        MOVE    #0,D2           * bit 0
        MOVE    #1,D3               
        JSR     GetBits    * mask the value, D0 contains the bit value
        
        LSR     #1,D1           * look at the next bit
        MOVEM   D1,-(SP)        * save the bit mask
        SUB     #1,D7           * bitCounter --
        CMP     #0,D0           * if the bit is not set, continue
        BEQ     PRFBM_While
        
        BNE     PRFBM_AddSlash
PRFBM_AddSlashContinue

        ADD     #1,D6       * printedRegisters++
        MOVE.L  D4,D1       * move the register string into arg1
        JSR     AddStringToStringBuffer  * add the register string to the string buffer
        BRA     PRFBM_While
    
PRFBM_AddSlash
    
        CMP     #0,D6   * if this is the first printed register
        ADD     D5,D6   * && previouslyPrintedRegisters == 0
        BEQ     PRFBM_AddSlashContinue * don't add the trailing slash
        
        MOVE    #SLASH,D1 
        JSR     AddStringToStringBuffer  * adds a slash to the string buffer
        BRA     PRFBM_AddSlashContinue
    
PRFBM_Done
        MOVE    D6,D0   * return the number of registers printed
        MOVEM   (SP)+,D1
        MOVEM   (SP)+,D1-D7/A0-A6
        RTS



*****************************************************************************
*****************************************************************************
* Data
*****************************************************************************
*****************************************************************************

CR      EQU     $0D
LF      EQU     $0A

* Ascii Table Reference
* A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z
* 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F 50 51 52 53 54 55 56 57 58 59 5A

* _  !  "  #  $  %  &  '  (  )  *  +  ,  -  .  /
* 20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F

* 0  1  2  3  4  5  6  7  8  9
* 30 31 32 33 34 35 36 37 38 39

DataRegisterStrings
        DC.B    'D0',0,0
        DC.B    'D1',0,0
        DC.B    'D2',0,0
        DC.B    'D3',0,0
        DC.B    'D4',0,0
        DC.B    'D5',0,0
        DC.B    'D6',0,0
        DC.B    'D7',0,0
    
ReversedDataRegisterStrings
        DC.B    'D7',0,0
        DC.B    'D6',0,0
        DC.B    'D5',0,0
        DC.B    'D4',0,0
        DC.B    'D3',0,0
        DC.B    'D2',0,0
        DC.B    'D1',0,0
        DC.B    'D0',0,0
    
AddressRegisterStrings
        DC.B    'A0',0,0
        DC.B    'A1',0,0
        DC.B    'A2',0,0
        DC.B    'A3',0,0
        DC.B    'A4',0,0
        DC.B    'A5',0,0
        DC.B    'A6',0,0
        DC.B    'A7',0,0
    
ReversedAddressRegisterStrings
        DC.B    'A7',0,0
        DC.B    'A6',0,0
        DC.B    'A5',0,0
        DC.B    'A4',0,0
        DC.B    'A3',0,0
        DC.B    'A2',0,0
        DC.B    'A1',0,0
        DC.B    'A0',0,0

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

NEW_LINE        DC.B    CR,LF,0
START_MSG
    DC.B    '    __   ___  _                       _   _       ',CR,LF
    DC.B    '   / /  / _ \| |                     | \ | |      ',CR,LF
    DC.B    '  / /_ | (_) | | __                  |  \| | ___  ',CR,LF
    DC.B    ' |  _ \ > _ <| |/ /                  | . ` |/ _ \ ',CR,LF
    DC.B    ' | (_) | (_) |   <                   | |\  | (_) |',CR,LF
    DC.B    '  \___/ \___/|_|\_\_                 |_| \_|\___/ ',CR,LF
    DC.B    ' |  __ \         / _|                             ',CR,LF
    DC.B    ' | |__) | __ ___| |_ ___ _ __ ___ _ __   ___ ___  ',CR,LF
    DC.B    ' |  ___/ ''__/ _ \  _/ _ \ ''__/ _ \ ''_ \ / __/ _ \ ',CR,LF
    DC.B    ' | |   | | |  __/ ||  __/ | |  __/ | | | (_|  __/ ',CR,LF
    DC.B    ' |_|   |_|  \___|_| \___|_|  \___|_| |_|\___\___| ',CR,LF,0

kLinesPerScreen EQU  44 * 22 * 2 to account for printing program counter
gPrintCount
        DS  2

kStringBufferSize EQU 128
kStringBuffer
    DS  kStringBufferSize

kInvalidOpCode
    DC.B    'Invalid Opcode',0

kGoodbyeMessage
    DC.B    'Goodbye!',0

kNewline
    DC.B    CR,LF,0

kStartAddressPrompt
    DC.B 'Please enter the starting address: ',0

kEndAddressPrompt
    DC.B 'Please enter the ending address: ',0

kRestartPrompt
    DC.B 'Would you like to dissamble another program (y/n)? ',0
    
kContinuePrompt
    DC.B 'Press any key to continue',CR,LF,0

* opcode print outs
MOVE_B_MSG      DC.B    'MOVE.B',0
MOVE_W_MSG      DC.B    'MOVE.W',0
MOVEA_W_MSG     DC.B    'MOVEA.W',0
MOVE_L_MSG      DC.B    'MOVE.L',0
MOVEA_L_MSG     DC.B    'MOVEA.L',0
ADD_MSG         DC.B    'ADD',0
ADDA_MSG        DC.B    'ADDA',0
OR_MSG          DC.B    'OR',0
DIVS_W_MSG      DC.B    'DIVS.W',0
MULS_W_MSG      DC.B    'MULS.W',0
DIVS_L_MSG      DC.B    'DIVS.L',0
MULS_L_MSG      DC.B    'MULS.L',0
SUB_MSG         DC.B    'SUB',0
SUBQ_MSG        DC.B    'SUBQ',0
CMP_MSG         DC.B    'CMP',0
EOR_MSG         DC.B    'EOR',0
BCS_MSG         DC.B    'BCS',0
BVC_MSG         DC.B    'BVC',0
BGE_MSG         DC.B    'BGE',0
BLT_MSG         DC.B    'BLT',0
BRA_MSG         DC.B    'BRA',0
LSR_MSG         DC.B    'LSR',0
LSL_MSG         DC.B    'LSL',0
ASR_MSG         DC.B    'ASR',0
ASL_MSG         DC.B    'ASL',0
ROR_MSG         DC.B    'ROR',0
ROL_MSG         DC.B    'ROL',0
BCLR_MSG        DC.B    'BCLR',0
ORI_MSG         DC.B    'ORI',0
CMPI_MSG        DC.B    'CMPI',0
JSR_MSG         DC.B    'JSR',0
LEA_MSG         DC.B    'LEA',0
NEG_MSG         DC.B    'NEG',0
MOVEM_MSG       DC.B    'MOVEM',0
RTS_MSG         DC.B    'RTS',0

* data size types
B_MSG           DC.B    '.B',0
W_MSG           DC.B    '.W',0
L_MSG           DC.B    '.L',0
Q_MSG           DC.B    0

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
SLASH           DC.B    '/',0

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



*****************************************************************************
*****************************************************************************
* Disassembler End
*****************************************************************************
*****************************************************************************
    END         START














*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
