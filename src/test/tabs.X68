*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
* print constants
CR      EQU     $0D
LF      EQU     $0A    

    ORG    $1000
START:                  ; first instruction of program

* Put program code here

    MOVEM.L     D0/D1/D2/D3/D4/D5/D6/D7,-(SP)
    
    MOVE.L      #MSG_1,D1
    JSR         Func_Print
    MOVE.L      #MSG_2,D1
    JSR         Func_Print
    MOVE.L      #MSG_3,D1
    JSR         Func_Print
    MOVE.L      #MSG_4,D1
    JSR         Func_Print
    MOVE.L      #MSG_5,D1
    JSR         Func_Print
    MOVE.L      #MSG_6,D1
    JSR         Func_Print
    MOVE.L      #MSG_7,D1
    JSR         Func_Print
    
    
    
    SIMHALT             ; halt simulator

****
Func_Print
        MOVEM.L D0/A1,-(SP)

        MOVEA   D1,A1
        MOVE.B  #14,D0
        TRAP    #15

        MOVEA   #TAB,A1
        MOVE.B  #14,D0
        TRAP    #15

        MOVEA   #NEXT,A1
        MOVE.B  #14,D0
        TRAP    #15

        MOVEM.L (SP)+,D0/A1
        RTS


* Put variables and constants here

TAB     DC.B    $09,0
NEXT    DC.B    'XXX',CR,LF,0
MSG_1   DC.B    '1',0
MSG_2   DC.B    '12',0
MSG_3   DC.B    '123',0
MSG_4   DC.B    '1234',0
MSG_5   DC.B    '12345',0
MSG_6   DC.B    '123456',0
MSG_7   DC.B    '1234567',0






    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
