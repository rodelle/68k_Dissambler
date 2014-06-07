*****************************************************************************
* Title      : Disassembler Test Code
* Written by : No Preference
* Date       : 6/6/14
*****************************************************************************
* 68000 Machine Code Disassembler
*****************************************************************************


Start   ORG     $7FC0    ; first instruction of program

        **** Generic Invalid Opcodes ****
        DC.W    %0111000000000000      * bad op (based on first 4 bits)
        DC.W    %1010000000000000      * bad op (based on first 4 bits)
        DC.W    %1111000000000000      * bad op (based on first 4 bits)

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

        **** Invalid LEA ****
        DC.W    %0100101111000100     
        DC.W    %0100101111100100     
        DC.W    %0100101111001100     
        DC.W    %0100101111011100     
        DC.W    %0100101111101100     
        DC.W    %0100101111110100     

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

        **** Invalid ADD ****
        DC.W    %1101 011 011 101 010 * opmode field invalid
        
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

        **** Invalid SUB ****
        DC.W    %1001011011101010 *1001 011 011 101 010 - opmode field invalid
        DC.W    %1001010111010101 *1001 010 111 010 101 - opmode field invalid

        **** SUBQ.B ****
        SUBQ.B  #$4,(A1)
        SUBQ.B  #$8,D7
        
        **** SUBQ.W ****
        SUBQ.W  #$6,$4000
        SUBQ.W  #$3,A3
        
        **** SUBQ.L ****
        SUBQ.L  #$1,$44000
        SUBQ.L  #$1,D2

        **** Invalid SUBQ ****
        DC.W    %0101011111000010 * size field invalid
        DC.W    %0101010110111100 * <ea> field invalid (write into data literal)

        **** Bcc/BRA ****
        BCS     bcs_label
        BVC     bvc_label
        BGE     bge_label
        BLT     blt_label
        BRA     bra_label

        **** Invalid Bcc ****        
        DC.W    %0110111100000000
        DC.W    %0110000100000000
        DC.W    %0110001000000000
        DC.W    %0110001100000000
        DC.W    %0110010000000000
        
        **** JSR/RTS ****
        JSR     jsr_label
        RTS

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
        ORI.B   #$4,D1
        ORI.B   #$13,(A6)
        ORI.B   #$50,$0ACE
        ORI.B   #$A7,$0001FACE
        ORI.B   #$8,-(A3)

        **** ORI.W ****
        ORI.W   #$0F44,D3
        ORI.W   #$FFF0,(A2)+
        ORI.W   #$FFA7,$0001FACE
        
        **** ORI.L ****        
        ORI.L   #$FF00FF00,$12345
        ORI.L   #$8F120,D6
        
        **** MULS.W ****
        MULS.W  $5432,D1
        MULS.W  #$0ACE,D5

        **** DIVS.W ****
        DIVS.W  D2,D1
        DIVS.W  (A4),D5

        **** CMP.B ****
        CMP.B   #$F,D3
        CMP.B   D2,D4
        CMP.B   $1FACE,D7
        
        **** CMP.W ****
        CMP.W   #$98AE,D3
        CMP.W   (A2)+,D2
        
        **** CMP.L **** 
        CMP.L   #$FAFAE67,D4
        CMP.L   A3,D6

        **** Invalid CMP ****
        DC.W    %1011011000001100 * An can't be used as source if byte size

        **** CMPI.B ****
        CMPI.B  #$42,$42
        CMPI.B  #$24,(A4)  

        **** CMPI.W ****
        CMPI.W  #$B437,(A6)+
        CMPI.W  #$42,D3
        
        **** CMPI.L ****    
        CMPI.L  #$66766,-(A2)
                
        **** Invalid CMPI ****
        DC.W    %0000110011000010 * invalid size
        DC.W    %0000110010001001 * An can't be destination for CMPI        

        **** EOR.B ****
        EOR.B   D3,D5
        EOR.B   D2,$1533
        EOR.B   D6,$00014533
        
        **** EOR.W ****
        EOR.W   D6,(A3)+
        EOR.W   D4,-(A3)
        
        **** EOR.L ****
        EOR.L   D2,$42
        EOR.L   D6,D6

        **** NEG.B ****
        NEG.B   D4
        NEG.B   $524
        NEG.B   (A1)
        
        **** NEG.W ****
        NEG.W   (A2)
        NEG.W   (A4)+
        NEG.W   $0001FACE
        
        **** NEG.L ****
        NEG.L   $1234ABCD
        NEG.L   D7
        NEG.L   -(A3)
        
        **** BCLR.B ****
        BCLR.B  D4,$4532
        BCLR.B  D2,(A6)
        BCLR.B  D5,(A2)+
        BCLR.B  #$3,$4532
        BCLR.B  #$7,(A3)
        
        **** BCLR.L ****
        BCLR.L  D4,D4
        BCLR.L  D7,D6
        BCLR.L  #$AF56,D3

        **** RTS ****        
        RTS
        RTS
        RTS
        
        **** ROL.B ****
        ROL.B   #$3,D3
        ROL.B   D3,D4
        
        **** ROL.B ****        
        ROL.W   D6,D1
        ROL.W   #$7,D3

        **** ROL.B ****        
        ROL.L   #$2,D6
        ROL.L   D4,D4
        
        **** ROL ****
        ROL     (A4)
        ROL     $00045314
        
        **** ROR.B ****
        ROR.B   #$8,D2
        ROR.B   D3,D5
        
        **** ROR.B ****        
        ROR.W   D6,D6
        ROR.W   #$4,D3

        **** ROR.B ****        
        ROR.L   #$2,D6
        ROR.L   D1,D5
        
        **** ROR ****
        ROR     (A5)+
        ROR     $00015311

        **** ASL.B ****
        ASL.B   #$3,D3
        ASL.B   D3,D4
        
        **** ASL.B ****        
        ASL.W   D6,D1
        ASL.W   #$7,D3

        **** ASL.B ****        
        ASL.L   #$2,D6
        ASL.L   D4,D4
        
        **** ASL ****
        ASL     (A4)
        ASL     $00045314
        
        **** ASR.B ****
        ASR.B   #$8,D2
        ASR.B   D3,D5
        
        **** ASR.B ****        
        ASR.W   D6,D6
        ASR.W   #$4,D3

        **** ASR.B ****        
        ASR.L   #$2,D6
        ASR.L   D1,D5
        
        **** ASR ****
        ASR     (A5)+
        ASR     $00015311

        **** Invalid AS/LS/RO ****       
        DC.W    %1110000000010000      * bad op (variation of RO*/AS*/LS*)
        DC.W    %1110010011000000      * bad op (variation of RO*/AS*/LS*)
 
        **** MOVEM.B ****
        *MOVEM.B  D1-D3/A4-A6/A1,-(SP)
        *MOVEM.B  D4/A4/D3/D1/A2,-(SP)
        *MOVEM.B  D1/A3,-(SP)

        **** MOVEM.W ****
        MOVEM.W  D1-D3/A4-A6/A1,-(SP)
        MOVE.L  D1,D2
        MOVEM.W  D4/A4/D3/D1/A2,-(SP)
        MOVEM.W  D1/A3,-(SP)
        
        MOVEM.W  (SP)+,D1-D3/A4-A6/A1
        MOVEM.W  (SP)+,D4/A4/D3/D1/A2
        MOVEM.W  (SP)+,D1/A3
        
        **** MOVEM.L ****
        MOVEM.L  D1-D3/A4-A6/A1,-(SP)
        MOVEM.L  D4/A4/D3/D1/A2,-(SP)
        MOVEM.L  D1/A3,-(SP)       

        MOVEM.L  (SP)+,D1-D3/A4-A6/A1
        MOVEM.L  (SP)+,D4/A4/D3/D1/A2
        MOVEM.L  (SP)+,D1/A3      
        
* separate the labels by a word
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
