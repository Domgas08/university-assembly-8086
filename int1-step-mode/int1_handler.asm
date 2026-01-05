.model small

.stack 100h

.data
    ; Pradinis praneimas
    PranPrad    db "INT 1 ADD komandos analize", 13, 10
                db "Autorius: Domas Grimalauskas", 13, 10
                db "Programa atpazista ADD r/m + betarpikas operandas", 13, 10, 10, "$"
    
    ; Pranesimai
    PranPertr   db "Zingsninio rezimo pertraukimas!", 13, 10, "$"
    PranAdr     db ":$"
    Tarpas      db "  $"
    PranAdd     db "ADD $"
	PranOr	 	db "OR $"
    PranReg     db "= $"
    KabSkliaust db "[$"
    SkliauUz    db "]$"
    Pliusas     db "+$"
    Kablelis    db ", $"
    Enteris     db 13, 10, "$"
    HRaidute    db "h$"
    
    ; Registru pavadinimai (8 bitu)
    RegPav8     db "al$"
                db "cl$"
                db "dl$"
                db "bl$"
                db "ah$"
                db "ch$"
                db "dh$"
                db "bh$"

    ; Registru pavadinimai (16 bitu)
    RegPav16    db "ax$"
                db "cx$"
                db "dx$"
                db "bx$"
                db "sp$"
                db "bp$"
                db "si$"
                db "di$"

    ; R/M pavadinimai (mod != 11)
    RMPav       db "bx+si$"
                db "bx+di$"
                db "bp+si$"
                db "bp+di$"
                db "si$$$$"
                db "di$$$$"
                db "bp$$$$"
                db "bx$$$$"
				
	arAdd  		db 1

    KomandLen   db 0
    WBit        db 0
    Sbit        db 0
    Modas       db 0
    RM          db 0
    ImmVal      dw 0
    Pos16       dw 0
    OPKodas     db 0
    AdresasSeg  dw 0
    AdresasOfs  dw 0

.code
  Pradzia:
    MOV ax, @data
    MOV ds, ax
    
    MOV ah, 9
    MOV dx, offset PranPrad
    INT 21h

    MOV ax, 0
    MOV es, ax
    
    PUSH es:[4]
    PUSH es:[6]
    
    MOV word ptr es:[4], offset ApdorokPertr
    MOV es:[6], cs

    PUSHF
    PUSHF
    POP ax
    OR ax, 0100h
    PUSH ax
    POPF
    NOP

    ; Testuojame ADD komandas

	ADD word ptr [bx+di], 10h
	ADD cx, 7Fh
	OR bx, 10h
	ADD ah, 12h
	ADD word ptr [bx+si+20h], 12h
	
    POPF
    
    POP es:[6]
    POP es:[4]

    MOV ah, 4Ch
    MOV al, 0
    INT 21h

;****************************************************************************
; Pertraukimo apdorojimo procedura
;****************************************************************************
PROC ApdorokPertr
    PUSH ax
    PUSH bx
    PUSH cx
    PUSH dx
    PUSH si
    PUSH di
    PUSH bp
    PUSH es
    PUSH ds

    MOV ax, @data
    MOV ds, ax

    MOV bp, sp
    ADD bp, 18
    MOV bx, [bp]
    MOV es, [bp+2]
    
    ;adresai
    MOV ax, [bp+2]
    MOV AdresasSeg, ax
    MOV ax, [bp]
    MOV AdresasOfs, ax
    
    ; OPK
    MOV al, [es:bx]
    MOV OPKodas, al
    
    ;Tikrinam ar add'as
    AND al, 0FCh             
    CMP al, 80h               
    JE Addas
    
    JMP NeAdd

NeAdd:
    JMP Pabaiga

Addas:
    MOV dx, OFFSET PranPertr
    CALL Spausdink
    
	;adresus spausdinam
    MOV ax, AdresasSeg
    CALL SpausdinkHexAX
    MOV dx, OFFSET PranAdr
    CALL Spausdink
    MOV ax, AdresasOfs
    CALL SpausdinkHexAX
    MOV dx, OFFSET Tarpas
    CALL Spausdink
    
	;OPK kodas
    MOV al, OPKodas
    MOV ah, 0
    CALL SpausdinkHexAX
    MOV dx, OFFSET Tarpas
    CALL Spausdink
    
		
	INC bx
	MOV dl, [es:bx]    ; dl = mod/rm byte
		
	; Mod+R/M 
	MOV al, dl
	MOV ah, 0
	CALL SpausdinkHexAX
	MOV dx, OFFSET Tarpas
	CALL Spausdink
	DEC bx            

	; gaunam S bita
	MOV al, OPKodas 
	AND al, 02h
	SHR al, 1
	MOV Sbit, al

	; gaunam W bita  
	MOV al, OPKodas   
	AND al, 01h
	MOV WBit, al

	INC bx             
	MOV dl, [es:bx]
		
	;gaunam mod
	MOV al, dl
	AND al, 0C0h
	SHR al, 6
	MOV Modas, al
	
	
	;patikrinam ar reg yra 000
	MOV al, dl
	AND al, 38h
	SHR al, 3
	CMP al, 000		
	mov arAdd, 1
	JE DarVisAdd
	
	CMP al, 1
	mov arAdd, 0
	JE DarVisAdd
	
	
	
	JMP Pabaiga
	
	DarVisAdd:
	MOV al, dl
	AND al, 07h
	MOV RM, al
		
;==================================================
; TIKRINIMAI
;==================================================

;==================================================
; Poslinkio nuskaitymas pagal Mod
;==================================================

    CMP Modas, 0
    JE arRM6         ; jei r/m=6
    CMP Modas, 1
    JE ModPos8
    CMP Modas, 2
    JE ModPos16
    JMP ToliauPos

arRM6:
    MOV al, RM
    CMP al, 6
    JNE ToliauPos       
    ; jeigu RM yra 6 tai reik nuskaityt 16 ilgio

ModPos16:
    INC bx
    MOV ax, es:[bx]
    MOV Pos16, ax
    
   
    PUSH ax
    MOV al, es:[bx]
    MOV ah, 0
    CALL SpausdinkHexAX
    MOV dx, OFFSET Tarpas
    CALL Spausdink
    POP ax
    
    ; spausdinam disp16 (vyresni byte)
    INC bx
    MOV al, es:[bx]
    MOV ah, 0
    CALL SpausdinkHexAX
    MOV dx, OFFSET Tarpas
    CALL Spausdink
    
    JMP ToliauPos

ModPos8:
    INC bx
    MOV al, es:[bx]
    
    ; spausdinam disp8
    PUSH ax
    MOV ah, 0
    CALL SpausdinkHexAX
    MOV dx, OFFSET Tarpas
    CALL Spausdink
    POP ax
    
    CBW
    MOV Pos16, ax
    JMP ToliauPos

ToliauPos:
    CMP WBit, 0
    JE W0
    CMP WBit, 1
    JE W1
    JMP Pabaiga

;=======================================
; W = 0: byte operacija
;=======================================
W0:
    INC bx
    MOV al, es:[bx]
    
    PUSH ax
    MOV ah, 0
    CALL SpausdinkHexAX
    MOV dx, OFFSET Tarpas
    CALL Spausdink
    POP ax
    
    MOV ah, 0
    MOV ImmVal, ax
    JMP ToliauImm

;=======================================
; W = 1: word operacija
;=======================================
W1:
    CMP Sbit, 0
    JE Imm16
    CMP Sbit, 1
    JE Imm8Sign
    JMP Pabaiga

Imm16:
    INC bx
    MOV ax, es:[bx]
    MOV ImmVal, ax
    
	
    PUSH ax
    MOV al, es:[bx]
    MOV ah, 0
    CALL SpausdinkHexAX
    MOV dx, OFFSET Tarpas
    CALL Spausdink
    POP ax
    
	;tarpu atskiriam jaunesni ir vyresni baitus
	
    INC bx
    MOV al, es:[bx]
    MOV ah, 0
    CALL SpausdinkHexAX
    MOV dx, OFFSET Tarpas
    CALL Spausdink
    
    JMP ToliauImm

Imm8Sign:
    INC bx
    MOV al, es:[bx]
    
    ;Ispausdinam betarpiska
    PUSH ax
    MOV ah, 0
    CALL SpausdinkHexAX
    MOV dx, OFFSET Tarpas
    CALL Spausdink
    POP ax
		
    CBW		;konvertuojam baita i zodi
    MOV ImmVal, ax
    JMP ToliauImm

ToliauImm:
    MOV dx, OFFSET Tarpas
    CALL Spausdink
    
    CMP Modas, 0
    JE Mod0
	JMP ne0

;=======================================
; mod = 0
;=======================================
Mod0:
    ;"ADD "
	cmp arAdd, 0
	JE printOr0
    MOV dx, OFFSET PranAdd
	JMP toliau00
	PrintOr0:
	MOV dx, OFFSET PranOr
	
	toliau00:
	
	
    CALL Spausdink

    ; "["
    MOV dx, OFFSET KabSkliaust
    CALL Spausdink

    ; Jeigu RM = 110
    MOV al, RM
    CMP al, 6
    JE Mod0_RM6
    
    MOV dl, 6
    MUL dl		;masyve kas 6 elementai vis ka reik spausdint
    MOV si, ax
    LEA dx, RMPav[si]
    CALL Spausdink
    JMP Mod0_skliaustas2

Mod0_RM6:
    ; For r/m=6, print the disp16 value
    MOV ax, Pos16
    CALL SpausdinkHexAX
    MOV dx, OFFSET HRaidute
    CALL Spausdink

Mod0_skliaustas2:
    ; "]"
    MOV dx, OFFSET SkliauUz
    CALL Spausdink

Mod0_SpauskImm:
    ; ", "
    MOV dx, OFFSET Kablelis
    CALL Spausdink

    MOV ax, ImmVal
    CALL SpausdinkHexAX
	
    MOV dx, OFFSET HRaidute
    CALL Spausdink

    MOV dx, OFFSET Enteris
    CALL Spausdink

    JMP Pabaiga



ne0:
    CMP Modas, 1
    JE Mod12
    CMP Modas, 2
    JE Mod12
	JMP ne12
	
    
;=======================================
; mod = 1 arba mod = 2
;=======================================
Mod12:
    ;"ADD "
	cmp arAdd, 0
	JE printOr12
    MOV dx, OFFSET PranAdd
	JMP toliau1212
	PrintOr12:
	MOV dx, OFFSET PranOr
	
	toliau1212:
	CALL Spausdink

    ; "["
    MOV dx, OFFSET KabSkliaust
    CALL Spausdink

    ;kas 6 masyve yra tinkamas
    MOV al, RM
    MOV dl, 6
    MUL dl
    MOV si, ax
    LEA dx, RMPav[si]
    CALL Spausdink

    ; "+" 
    MOV dx, OFFSET Pliusas
    CALL Spausdink

    ; Poslinkis
    MOV ax, Pos16
    CALL SpausdinkHexAX

    MOV dx, OFFSET HRaidute
    CALL Spausdink

    ; "]"
    MOV dx, OFFSET SkliauUz
    CALL Spausdink

Mod12_SpauskImm:
    ; ", "
    MOV dx, OFFSET Kablelis
    CALL Spausdink

    MOV ax, ImmVal
    CALL SpausdinkHexAX
	
	
    MOV dx, OFFSET HRaidute
    CALL Spausdink

   
    MOV dx, OFFSET Enteris
    CALL Spausdink

    JMP Pabaiga
	
	
	
	
ne12:
	CMP Modas, 3
    JE Mod3
    JMP Pabaiga


;=======================================
; mod = 3
;=======================================
Mod3:
    ; "ADD "
	cmp arAdd, 0
	JE printOr3
    MOV dx, OFFSET PranAdd
	JMP toliau33
	PrintOr3:
	MOV dx, OFFSET PranOr
	
	toliau33:
	
	CALL Spausdink

    ;pagal Wbit kuris stulpelis
    CMP WBit, 0
    JE Mod3_8
    JMP Mod3_16

Mod3_8:
    MOV al, RM
    MOV dl, 3
    MUL dl
    MOV si, ax
    LEA dx, RegPav8[si]
    CALL Spausdink
    JMP Mod3_SpauskImm

Mod3_16:
    MOV al, RM
    MOV dl, 3
    MUL dl
    MOV si, ax
    LEA dx, RegPav16[si]
    CALL Spausdink
    JMP Mod3_SpauskImm

Mod3_SpauskImm:
    ;", "
    MOV dx, OFFSET Kablelis
    CALL Spausdink

    MOV ax, ImmVal
    CALL SpausdinkHexAX
	
	
    MOV dx, OFFSET HRaidute
    CALL Spausdink
	
	
    MOV dx, OFFSET Enteris
    CALL Spausdink

    JMP Pabaiga

Pabaiga:
    POP ds
    POP es
    POP bp
    POP di
    POP si
    POP dx
    POP cx
    POP bx
    POP ax
    IRET

ApdorokPertr ENDP

;****************************************************************************
; AX kaip 4-digit hex
;****************************************************************************
SpausdinkHexAX PROC
    PUSH ax
    PUSH bx
    PUSH cx
    PUSH dx

    MOV bx, ax          ; Išsaugome AX
    MOV dh, 0           ; Flag: ar jau spausdiname (0=ne, 1=taip)
    
    ; 1 skaitmuo
    MOV ax, bx
    MOV cl, 12
    SHR ax, cl
    AND al, 0Fh
    MOV ch, 0           ; Ne paskutinis
    CALL PrintDigit
    
    ; 2 skaitmuo
    MOV ax, bx
    MOV cl, 8
    SHR ax, cl
    AND al, 0Fh
    MOV ch, 0
    CALL PrintDigit
    
    ;3 skaitmuo
    MOV ax, bx
    MOV cl, 4
    SHR ax, cl
    AND al, 0Fh
    MOV ch, 0
    CALL PrintDigit
    
    ; 4 skaitmuo
    MOV al, bl
    AND al, 0Fh
    MOV ch, 1           ; Paskutinis!
    CALL PrintDigit

    POP dx
    POP cx
    POP bx
    POP ax
    RET



PrintDigit:

    CMP al, 0
    JMP DoPrint		;cia pakeist i JMP jeigu su 0
    CMP dh, 1
    JE DoPrint
    CMP ch, 1
    JE DoPrint
    RET                 ; Praleidžiame priekinį nulį

DoPrint:
    MOV dh, 1           ; Dabar jau spausdiname
    ADD al, '0'
    CMP al, '9'
    JBE PrintOk
    ADD al, 7

PrintOk:
    PUSH ax
    MOV dl, al
    MOV ah, 02h
    INT 21h
    POP ax
    RET

SpausdinkHexAX ENDP






;****************************************************************************
; Spausdint DS:DX
;****************************************************************************
Spausdink PROC
    MOV ah, 09h
    INT 21h
    RET
Spausdink ENDP

END Pradzia
