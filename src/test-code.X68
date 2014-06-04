*-----------------------------------------------------------
* Title      : Disassembler Test Code
* Written by : No Preference
* Date       : 6/3/14
*-----------------------------------------------------------


Start   ORG     $7FC0    ; first instruction of program


        **** MOVE ****
        MOVE.B  D0,D1
        MOVE.W  D0,D1
        MOVE.L  D0,D1

        MOVE.B  (A0),D1
        MOVE.W  (A0),D1
        MOVE.L  (A0),D1

        MOVE.B  #42,D1
        MOVE.W  #42,D1
        MOVE.L  #42,D1

        MOVE.B  $2000,D1
        MOVE.W  $2000,D1
        MOVE.L  $2000,D1


        **** MOVEA ****
        MOVEA.W  D0,A3
        MOVEA.L  D0,A3

        MOVEA.W  (A0),A3
        MOVEA.L  (A0),A3

        MOVEA.W  #42,A3
        MOVEA.L  #42,A3

        MOVEA.W  $2000,A3
        MOVEA.L  $2000,A3


        **** ADD ****
        ADD.B  D0,D1
        ADD.W  D0,D1
        ADD.L  D0,D1

        ADD.B  (A0),D1
        ADD.W  (A0),D1
        ADD.L  (A0),D1

        ADD.B  #42,D1
        ADD.W  #42,D1
        ADD.L  #42,D1

        ADD.B  $2000,D1
        ADD.W  $2000,D1
        ADD.L  $2000,D1


        **** ADDA ****
        ADDA.W  D0,A3
        ADDA.L  D0,A3

        ADDA.W  (A0),A3
        ADDA.L  (A0),A3

        ADDA.W  #42,A3
        ADDA.L  #42,A3

        ADDA.W  $2000,A3
        ADDA.L  $2000,A3


        **** SUB ****
        SUB.B  D0,D1
        SUB.W  D0,D1
        SUB.L  D0,D1

        SUB.B  (A0),D1
        SUB.W  (A0),D1
        SUB.L  (A0),D1

        SUB.B  #42,D1
        SUB.W  #42,D1
        SUB.L  #42,D1

        SUB.B  $2000,D1
        SUB.W  $2000,D1
        SUB.L  $2000,D1


        **** SUBQ ****
        SUBQ.B  #6,D0
        SUBQ.W  #6,D0
        SUBQ.L  #6,D0

        SUBQ.B  #6,(A0)
        SUBQ.W  #6,(A0)
        SUBQ.L  #6,(A0)

        SUBQ.B  #6,$2000
        SUBQ.W  #6,$2000
        SUBQ.L  #6,$2000




        MOVE.B  #9,D0       ; terminate program
        TRAP    #15

        END     Start       ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
