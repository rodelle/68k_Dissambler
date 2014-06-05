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

        **** LEA ****
        LEA     (A5),A5
        LEA     $34512,A6
        LEA     $320,A6

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
        * SUB.W   #$FFFF,D3 * ASSEMBLES TO SUBI
        SUB.W   (A1)+,D4
        SUB.W   D4,(A4)


        **** SUB.L ****
        SUB.L   (A4),D2
        SUB.L   D1,$424242

        **** SUBQ.B ****
        SUBQ.B  #$4,(A1)
        SUBQ.B  #$8,D7
        
        **** SUBQ.W ****
        SUBQ.W  #$6,$4000
        SUBQ.W  #$3,A3
        
        **** SUBQ.L ****
        SUBQ.L  #$1,$44000
        SUBQ.L  #$1,D2

        **** Bcc/BRA ****
        BCS     bcs_label
        BVC     bvc_label
        BGE     bge_label
        BLT     blt_label
        BRA     bra_label

        **** OR.B ****
        OR.B    (A4),D4
        OR.B    D2,$5600
        
        **** OR.W ****
        OR.W    #$FACE,D6
        OR.W    D3,D0
        
        **** OR.L ****
        OR.L    (A1),D1
        OR.L    -(A3),D4
        
        **** ORI.B ****
        
        **** ORI.W ****
        
        **** ORI.L ****        
        
        **** MULS.W ****
        MULS.W  $5432,D1
        MULS.W  #$ACE,D5

        **** DIVS.W ****
        DIVS.W  D2,D1
        DIVS.W  (A4),D5

        **** CMP.B ****
        
        **** CMP.W ****
        
        **** CMP.L ****    

        **** CMPI.B ****
        
        **** CMPI.W ****
        
        **** CMPI.L ****    
        
        **** EOR.B ****
        
        **** EOR.W ****
        
        **** EOR.L ****

        **** NEG.B ****
        
        **** NEG.W ****
        
        **** NEG.L ****
        
        **** BCLR.B ****
        
        **** BCLR.L ****

        **** JSR ****

        **** RTS ****        
        
*        ro*
*        as*
*        ls*
*        movem
        
        
        **** Error opcodes ****
        DC.W    %0111000000000000      * bad op (based on first 4 bits)
        DC.W    %1010000000000000      * bad op (based on first 4 bits)
        DC.W    %1111000000000000      * bad op (based on first 4 bits)
        DC.W    %0110111100000000      * bad op (variation of Bcc)
        DC.W    %0110000100000000      * bad op (variation of Bcc)
        DC.W    %0110001000000000      * bad op (variation of Bcc)
        DC.W    %0110001100000000      * bad op (variation of Bcc)
        DC.W    %0110010000000000      * bad op (variation of Bcc)
        DC.W    %1110000000010000      * bad op (variation of RO*/AS*/LS*)
        DC.W    %1110010011000000      * bad op (variation of RO*/AS*/LS*)

bcs_label
        DC.W    0
bvc_label
        DC.W    0
bge_label
        DC.W    0
blt_label
        DC.W    0
bra_label
        DC.W    0
jsr_label
        DC.W    0
                
        END     Start       ; last line of source





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
