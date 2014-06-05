*-----------------------------------------------------------
* Title      : Disassembler Test Code
* Written by : No Preference
* Date       : 6/3/14
*-----------------------------------------------------------


Start   ORG     $7FC0    ; first instruction of program

        **** MOVEA.W ****
        MOVEA.W D4,A4
        MOVEA.W #$1C44,A5
        MOVEA.W $1F23F,A6
        MOVEA.W (A1),A7
        MOVEA.W -(A1),A7
        MOVEA.W (A1)+,A7
        
        **** MOVEA.L ****
        MOVEA.L D0,A0
        MOVEA.L #$1234F5,A1
        MOVEA.L $10238,A2
        MOVEA.L (A3),A3
        MOVEA.L -(A3),A3
        MOVEA.L (A3)+,A3

        **** MOVE.B ****        
        MOVE.B  D2,D2
        MOVE.B  #$23,(A6)
        MOVE.B  (A0),(A2)
        MOVE.B  $991,$1001
        MOVE.B  $22457,D0
        MOVE.B  -(A5),D3

        **** MOVE.W ****        
        MOVE.W  D5,D4
        MOVE.W  #$234,(A3)
        MOVE.W  A6,D7
        MOVE.W  (A1),D6
        MOVE.W  $9998,$10000
        MOVE.W  $227,D0
        MOVE.W  (A4)+,D3

        **** MOVE.L ****
        MOVE.L  D1,D2
        MOVE.L  #$234,D4
        MOVE.L  A5,D2
        MOVE.L  (A5),D6
        MOVE.L  D1,$4567
        MOVE.L  $6543,D0
        MOVE.L  -(A2),D3
        
        **** ADD.B ****
        ADD.B   D3,D4
        ADD.B   (A5),D0
        * ADD.B   #$45,$5555 * assembles to addi
        
        **** ADD.W ****
        ADD.W   (A5),D5
        ADD.W   D6,D7
        ADD.W   D1,$ABCD
              
        **** ADD.L ****
        ADD.L   (A4),D1
        ADD.L   $34564,D2
        ADD.L   D3,D0
        ADD.L   D6,(A5)
        * ADD.L   #$32423F,D0 * assembles to addi

        **** ADDA.W ****
        ADDA.W  (A5),A5
        ADDA.W  D0,A5        
        ADDA.W  -(A3),A3
        
        **** ADDA.L ****
        ADDA.L  #$F452,A6
        ADDA.L  $234546,A5
        ADDA.L  (A4)+,A5
        
        **** SUB.B ****
        SUB.B   $7CF000,D1
        SUB.B   D6,(A4)
        
        **** SUB.W ****
        SUB.W   #$ABCD,D3
        SUB.W   (A1)+,D4

        **** SUB.L ****
        SUB.B   (A4),D2
        SUB.B   D1,$424242

        **** SUBQ.B ****
        SUBQ.B  #$4,(A1)
        SUBQ.B  #$8,D7
        
        **** SUBQ.W ****
        SUBQ.W  #$6,$4000
        SUBQ.W  #$3,A3
        
        **** SUBQ.L ****
        SUBQ.L  #$1,$44000
        SUBQ.L  #$1,D2

        MOVE.B  #9,D0       ; terminate program
        TRAP    #15

        END     Start       ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
