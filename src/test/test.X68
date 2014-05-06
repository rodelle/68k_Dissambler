*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
CR      EQU     $0D
LF      EQU     $0A

NIBBLE0      EQU     $F000

EX_OPCODE    EQU     $9FE2
    

START    ORG    $1000            ; first instruction of program

* Output
PROGRAM_START    
    LEA     START_MESSAGE,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.W  #NIBBLE0,D0
    AND.W   #EX_OPCODE,D0
    
    LEA FUNCTION_TABLE,A1
    ADD #2*1,A1
    MOVEA (A1),A1
    JMP (A1)
    
    JMP DONE    
    
DONE    LEA     GOODBYE_MESSAGE,A1
        MOVE.B  #14,D0
        TRAP    #15

        MOVE.B  #9,D0 * quits program
        TRAP    #15
        
SOMETHING
    LEA     msgSomething,A1
    MOVE.B  #14,D0
    TRAP    #15

ELSE
    LEA     msgSomething,A1
    MOVE.B  #14,D0
    TRAP    #15

FUNCTION_TABLE
    DC.W    SOMETHING
    DC.W    ELSE

START_MESSAGE
    DC.B    'Welcome to No Preference''s 68k Dissambler',CR,LF
    DC.B    'Please give us 100%',CR,LF,CR,LF
    DC.B    'Enter the starting address to continue:  ',0

msgSomething
    DC.B    'doing something',CR,LF,0

GOODBYE_MESSAGE
    DC.B    CR,LF,'Goodbye!',0
    
    END START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
