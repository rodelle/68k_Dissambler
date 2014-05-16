*-----------------------------------------------------------
* Title      : Op-code Jump Tables
* Written by : No Preference
* Date       : 5/15/14
* Description: Jump tables arranged to take advantage of
*              offset
*-----------------------------------------------------------

; print constants 
CR                  EQU     $0D
LF                  EQU     $0A

; opcode examples (first nibble)
; for testing function jump table
MOVE_B_OP           EQU     %0001
MOVE_L_OP           EQU     %0010
BCLR_ORI_CMPI_OP    EQU     %0000
MOVE_W_OP           EQU     %0011
MISC_OP             EQU     %0100
SUBQ_OP             EQU     %0101
BRANCH_OP           EQU     %0110
NO_OP_1             EQU     %0111
OR_DIVS_OP          EQU     %1000
SUB_OP              EQU     %1001
NO_OP_2             EQU     %1010
CMP_EOR_OP          EQU     %1011
MULS_OP             EQU     %1100
ADD_OP              EQU     %1101
SHIFT_OP            EQU     %1110
NO_OP_3             EQU     %1111


START   ORG     $1000   ; first instruction of program
        MOVE    #START_MSG,D1
        JSR     Print
        
        ; test opcodes
        
        MOVE.L  #MOVE_W_OP,D1           ; test move.w function
        JSR     JumpUsingFuncTable
        
        MOVE.L  #BCLR_ORI_CMPI_OP,D1    ; test bclr function
        JSR     JumpUsingFuncTable
        
        MOVE.L  #MISC_OP,D1             ; test misc function
        JSR     JumpUsingFuncTable
        
        MOVE.L  #SHIFT_OP,D1
        JSR     JumpUsingFuncTable
        
        MOVE.L  #MULS_OP,D1
        JSR     JumpUsingFuncTable
        
        MOVE.L  #ADD_OP,D1
        JSR     JumpUsingFuncTable
        
        MOVE.L  #CMP_EOR_OP,D1
        JSR     JumpUsingFuncTable
        
        MOVE.L  #SUB_OP,D1
        JSR     JumpUsingFuncTable
        
        MOVE.L  #OR_DIVS_OP,D1
        JSR     JumpUsingFuncTable
        
        MOVE.L  #BRANCH_OP,D1
        JSR     JumpUsingFuncTable
           
        MOVE.L  #SUBQ_OP,D1
        JSR     JumpUsingFuncTable
                
        MOVE.L  #MOVE_B_OP,D1
        JSR     JumpUsingFuncTable
                
        MOVE.L  #MOVE_L_OP,D1
        JSR     JumpUsingFuncTable
        
        ; test errors
        MOVE.L  #NO_OP_1,D1             
        JSR     JumpUsingFuncTable
        MOVE.L  #NO_OP_2,D1             
        JSR     JumpUsingFuncTable
        MOVE.L  #NO_OP_3,D1             
        JSR     JumpUsingFuncTable
                
        JMP     DONE

DONE    MOVE.B  #9,D0  ; terminate program
        TRAP    #15


FuncTable
        DC.L    Func_BCLR_ORI_CMPI
        DC.L    Func_MOVE_B
        DC.L    Func_MOVE_L
        DC.L    Func_MOVE_W        
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

; void Print(D1 = Msg Address)
; no changes to registers
Print   MOVEM.L D0,-(SP)
        MOVEA   D1,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVEM.L (SP)+,D0
        RTS
        

; void JumpUsingFuncTable(D1 = OpcodeNibble0)
; no changes to registers
JumpUsingFuncTable
        MOVEM.L D1/A1,-(SP)     ; save A1 and D1
        
        ; multiply nibble by 4 to get longword offset
        ; into the func table (DC.L)
        LSL.L   #2,D1
        LEA     FuncTable,A1    ; get the func table address
        ADD.L   D1,A1           ; offset into table
        MOVEA.L (A1),A1         ; dereference offset
        JSR     (A1)            ; dereference and call function
        
        MOVEM.L (SP)+,D1/A1     ; restore A1 and D1
        RTS


; void Func_NO_OP()
Func_NO_OP
        MOVE    #NO_OP_MSG,D1
        JSR     Print
        RTS
        

; void Func_MOVE_B()
Func_MOVE_B
        MOVE    #MOVE_B_MSG,D1
        JSR     Print
        RTS     
        
        
; void Func_MOVE_W()
Func_MOVE_W
        MOVE    #MOVE_W_MSG,D1
        JSR     Print
        RTS


; void Func_MOVE_L()
Func_MOVE_L
        MOVE    #MOVE_L_MSG,D1
        JSR     Print
        RTS


; void Func_BCLR_ORI_CMPI()
Func_BCLR_ORI_CMPI
        MOVE    #BCLR_ORI_CMPI_MSG,D1
        JSR     Print
        RTS


; void Func_MISC()
Func_MISC
        MOVE    #MISC_MSG,D1
        JSR     Print
        RTS

        
; void Func_SUBQ()
Func_SUBQ
        MOVE    #SUBQ_MSG,D1
        JSR     Print
        RTS
        

; void Func_BRANCH()
Func_BRANCH
        MOVE    #BRANCH_MSG,D1
        JSR     Print
        RTS


; void Func_OR_DIVS()
Func_OR_DIVS
        MOVE    #OR_DIVS_MSG,D1
        JSR     Print
        RTS


; void Func_SUB()
Func_SUB
        MOVE    #SUB_MSG,D1
        JSR     Print
        RTS


; void Func_CMP_EOR()
Func_CMP_EOR
        MOVE    #CMP_EOR_MSG,D1
        JSR     Print
        RTS


; void Func_MULS()
Func_MULS
        Move    #MULS_MSG,D1
        JSR     Print
        RTS


; void Func_ADD()
Func_ADD
        MOVE    #ADD_MSG,D1
        JSR     Print
        RTS


; void Func_SHIFT()
Func_SHIFT
        MOVE    #SHIFT_MSG,D1
        JSR     Print
        RTS



*-----------------------------------------------------------
* Data
*-----------------------------------------------------------

; messages for tracing output
START_MSG           DC.B    'Jump table example',CR,LF,0
NO_OP_MSG           DC.B    'Invalid instruction',CR,LF,0
MOVE_W_MSG          DC.B    'MOVE.W instruction',CR,LF,0
MOVE_B_MSG          DC.B    'MOVE.B instruction',CR,LF,0
MOVE_L_MSG          DC.B    'MOVE.L instruction',CR,LF,0
BCLR_ORI_CMPI_MSG   DC.B    'BCLR/ORI/CMPI instruction',CR,LF,0
MISC_MSG            DC.B    'JSR/LEA/RTS/NEG/DIVS/MULS/MOVEM instruction',CR,LF,0
SUBQ_MSG            DC.B    'SUBQ instruction',CR,LF,0
BRANCH_MSG          DC.B    'Bcc/BRA instruction',CR,LF,0
OR_DIVS_MSG         DC.B    'OR/DIVS instruction',CR,LF,0
SUB_MSG             DC.B    'SUB instruction',CR,LF,0
CMP_EOR_MSG         DC.B    'CMP/EOR instruction',CR,LF,0
MULS_MSG            DC.B    'MULS instruction',CR,LF,0
ADD_MSG             DC.B    'ADD instruction',CR,LF,0
SHIFT_MSG           DC.B    'LSR/LSL/ASR/ASL instruction',CR,LF,0


        END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
