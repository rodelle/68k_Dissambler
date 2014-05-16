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
MOVE_B_OP           EQU     %0001
MOVE_L_OP           EQU     %0010
BCLR_ORI_CMPI_OP    EQU     %0000
MOVE_W_OP           EQU     %0011


START   ORG     $1000   ; first instruction of program
    
        LEA     START_MSG,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        MOVE.L  #MOVE_W_OP,D0       ; test move.w function
        LSL.L   #2,D0               ; * 4, for dc.l in jump table
        
        LEA     FuncTableNibble0,A1
        ADD.L   D0,A1               ; offset into table
        MOVEA.L (A1),A1
        JSR     (A1)
        
        
        MOVE.L  #BCLR_ORI_CMPI_OP,D0       ; test move.w function
        LSL.L   #2,D0               ; * 4, for dc.l in jump table
        
        LEA     FuncTableNibble0,A1
        ADD.L   D0,A1               ; offset into table
        MOVEA.L (A1),A1
        JSR     (A1)
        
        JMP     DONE

FuncTableNibble0
        DC.L    Func_BCLR_ORI_CMPI
        DC.L    Func_MOVE_B
        DC.L    Func_MOVE_L
        DC.L    Func_MOVE_W
        
        


Func_MOVE_B
    LEA     MOVE_B_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS

Func_MOVE_W
    LEA     MOVE_W_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS

Func_MOVE_L
    LEA     MOVE_L_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS

Func_BCLR_ORI_CMPI
    LEA     BCLR_ORI_CMPI_MSG,A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS


DONE    MOVE.B  #9,D0  ; terminate program
        TRAP    #15

* Put variables and constants here
START_MSG   DC.B    'Jump table example',CR,LF,0
MOVE_W_MSG  DC.B    'Determined MOVE.W instruction',CR,LF,0
MOVE_B_MSG  DC.B    'Determined MOVE.B instruction',CR,LF,0
MOVE_L_MSG  DC.B    'Determined MOVE.L instruction',CR,LF,0
BCLR_ORI_CMPI_MSG  DC.B    'Determined BCLR/ORI/CMPI instruction',CR,LF,0



        END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
