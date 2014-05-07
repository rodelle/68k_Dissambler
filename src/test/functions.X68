*-----------------------------------------------------------
* Title      : 68k Function Examples 
* Written by : No Preference
* Description: Examples of how subroutines work, and a
*   demonstration of the No Preference argument
*   passing convention
*-----------------------------------------------------------
CR      EQU     $0D
LF      EQU     $0A    

START    ORG    $1000            ; first instruction of program

* Output
PROGRAM_START
    MOVE.L  #kStartMessage,D7 * load start message as arg1
    JSR     PrintMessage

    JMP DONE    
    
DONE
    MOVE    #kGoodbyeMessage,D7
    JSR     PrintMessage

    MOVE.B  #9,D0 * quits program
    TRAP    #15

PrintMessage        * void PrintMessage(String* message)
    MOVEA.L D7,A1   * load address of message from argument 1
    MOVE.B  #14,D0  * print contents of A1
    TRAP    #15     
    RTS
        
kStartMessage
    DC.B    'Welcome to No Preference''s 68k Dissambler',CR,LF
    DC.B    'Please give us 100%',CR,LF,CR,LF
    DC.B    'Enter the starting address to continue:  ',0

kGoodbyeMessage
    DC.B    CR,LF,'Goodbye!',0
    
    END START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
