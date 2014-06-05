*-----------------------------------------------------------
* Title      : Disassembler Test Code
* Written by : No Preference
* Date       : 6/3/14
*-----------------------------------------------------------


Start   ORG     $7FC0    ; first instruction of program


        **** MOVE ****
        MOVE.L  D1,D2
        MOVE.L  #$234,D4
        MOVE.L  A5,D2
        MOVE.L  (A5),D6
        MOVE.L  D1,$4567
        MOVE.L  $6543,D0
        MOVE.L  -(A2),D3
        
        MOVE.W  D1,D2
        
        MOVE.B  D1,D2
        
        
        **** MOVEA ****
        **** ADD ****
        **** ADDA ****
        **** SUB ****
        **** SUBQ ****
        MOVE.B  #9,D0       ; terminate program
        TRAP    #15

        END     Start       ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
