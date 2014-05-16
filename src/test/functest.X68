*-----------------------------------------------------------
* Title      : Function Example
* Written by : No Preference
* Date       : 5/15/14
* Description: Function example saving registers with MOVEM
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
    MOVE.L  #1,D1   * dummy values for integrity check
    MOVE.L  #2,D2
    MOVE.L  #3,D3
    MOVE.L  #4,D4
    MOVE.L  #5,D5
    MOVE.L  #6,D6
    MOVE.L  #7,D7
    
    * function call
    MOVE.L  D1,-(SP) 
    MOVE.L  D2,-(SP)
    JSR     ADDER
    ADDQ.L  #8,SP * deallocate parameters on stack
    CMP     #4,D0
    BNE     ERROR
    BRA     DONE

*
* Adds D1 and D2 and saves the result in D0
*
ADDER
    MOVEM.L D1-D7,-(SP)   * 28 byte offset
    MOVE.L  36(SP),D2
    MOVE.L  32(SP),D1
    CLR.L   D3
    CLR.L   D4
    CLR.L   D5
    CLR.L   D6
    CLR.L   D7
    ADD.L   D1,D2
    MOVE.L  D2,D0
    MOVEM.L (SP)+,D1-D7
    RTS

ERROR
    LEA     EMSG,A1
    MOVE.B  #14,D0
    TRAP    #15

DONE
    MOVE.B  #9,D0
    TRAP    #15

* Put variables and constants here

EMSG    DC.B    'Error: did not get expected value',0

    
    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
