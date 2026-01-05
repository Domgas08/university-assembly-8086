;***************************************************************
; Programa atidaranti faila duom.txt, pakeicianti mazasias raides didziosiomis ir rezultata irasanti i faila rez.txt
;***************************************************************
.model small
skBufDydis	EQU 20			;konstanta skBufDydis (lygi 20) - skaitymo buferio dydis
raBufDydis	EQU 20			;konstanta raBufDydis (lygi 20) - rasyymo buferio dydis 
maxFileSize	EQU 10

.stack 100h
.data
	duom db maxFileSize dup (0)
	rez db maxFileSize dup (0)
	skBuf	db skBufDydis dup (?)	;skaitymo buferis                                                        	
	raBuf	db raBufDydis dup (?)	;rasyymo buferis 
	dFail	dw ?			;vieta, skirta saugoti duomenu failo deskriptoriaus numeri ("handle")
	rFail	dw ?			;vieta, skirta saugoti rezultato failo deskriptoriaus numeri  
	mapas   db      256 dup (0)  
	counter dw ? 	
	bgood db 1	;bool good ar viskas ok (ar nebuvo klaidu)
	good	db "Programa sekminga!$"
	help db "Klaida: ", ?, 10, 13, \
		  "-------------", 10, 13, \
          "0: info", 10, 13, \
          "1: atidarant skaitymui", 10, 13, \
          "2: atidarant rasymui", 10, 13, \	
          "3: uzdarant rasymui", 10, 13, \
          "4: uzdarant skaitymui", 10, 13, \
          "5: skaitant", 10, 13, \
          "6: dalinis rasymas", 10, 13, \
          "7: rasant", 10, 13, \
          "8: nurodant parametrus", 10, 13, '$'
		  
		  
.code
  pradzia:
  
	MOV	ax, @data		;reikalinga kiekvienos programos pradzioj
	MOV	ds, ax			;reikalinga kiekvienos programos pradzioj 
	
	mov bx, 0
	mov si, 0
	
	CALL    SurastFailuVardus		;susirandam failo vardus
	
;*****************************************************
;Duomenu failo atidarymas skaitymui
;*****************************************************
	MOV	ah, 3Dh				;21h pertraukimo failo atidarymo funkcijos numeris
	MOV	al, 00				;00 - failas atidaromas skaitymui
	MOV	dx, offset duom			;vieta, kur nurodomas failo pavadinimas, pasibaigiantis nuliniu simboliu
	INT	21h				;failas atidaromas skaitymui
	JC	klaidaAtidarantSkaitymui	;jei atidarant faila skaitymui ivyksta klaida, nustatomas carry flag
	MOV	dFail, ax			;atmintyje issisaugom duomenu failo deskriptoriaus numeri

;*****************************************************
;Rezultato failo sukûrimas ir atidarymas rasymui
;*****************************************************
	MOV	ah, 3Ch				;21h pertraukimo failo sukûrimo funkcijos numeris
	MOV	cx, 0				;kuriamo failo atributai
	MOV	dx, offset rez			;vieta, kur nurodomas failo pavadinimas, pasibaigiantis nuliniu simboliu
	INT	21h				;sukuriamas failas; jei failas jau egzistuoja, visa jo informacija istrinama
	JC	klaidaAtidarantRasymui		;jei kuriant faila skaitymui ivyksta klaida, nustatomas carry flag
	MOV	rFail, ax			;atmintyje issisaugom rezultato failo deskriptoriaus numeri

;*****************************************************
;Duomenu nuskaitymas is failo
;*****************************************************
  skaityk:
	MOV	bx, dFail			;i bx irasom duomenu failo deskriptoriaus numeri
	CALL	SkaitykBuf			;iskvieciame skaitymo is failo procedura
	CMP	ax, 0				;ax irasoma, kiek baitu buvo nuskaityta, jeigu 0 - pasiekta failo pabaiga
	JE	uzdarytiRasymui

;*****************************************************
;Darbas su nuskaityta informacija
;*****************************************************
	MOV	cx, ax
	MOV	si, offset skBuf
	;cx yra kiek nuskaitytu simboliu 
	;ax yra nelieciamas, nes nezinosim ar dar reik skaityt
	;surasom i map'a reiksmes
	
	dirbk:
        MOV	dl, [si] 	
    	MOV dh, 0
    	MOV di, dx		;mapo principu
    	INC mapas[di]  
    	INC	si
    LOOP	dirbk
	
	CMP	ax, skBufDydis			;jeigu vyko darbas su pilnu buferiu -> is duomenu failo buvo nuskaitytas pilnas buferis ->
    JE	skaityk					;-> reikia skaityti toliau	
	
	CALL Darbas_su_mapu

;*****************************************************
;Rezultato failo uzdarymas
;*****************************************************
  uzdarytiRasymui:
	MOV	ah, 3Eh				;21h pertraukimo failo uzdarymo funkcijos numeris
	MOV	bx, rFail			;i bx irasom rezultato failo deskriptoriaus numeri
	INT	21h				;failo uzdarymas
	JC	klaidaUzdarantRasymui		;jei uzdarant faila ivyksta klaida, nustatomas carry flag
	
;*****************************************************
;Duomenu failo uzdarymas
;*****************************************************
  uzdarytiSkaitymui:
	MOV	ah, 3Eh				;21h pertraukimo failo uzdarymo funkcijos numeris
	MOV	bx, dFail			;i bx irasom duomenu failo deskriptoriaus numeri
	INT	21h				;failo uzdarymas
	JC	klaidaUzdarantSkaitymui		;jei uzdarant faila ivyksta klaida, nustatomas carry flag

  pabaiga:
  
  
	CMP bgood, 0
	JE ne_ok
  
	MOV ah, 09
	MOV dx, offset good
	int 21h
	
	ne_ok:
	
	MOV	ah, 4Ch				;reikalinga kiekvienos programos pabaigoj
	MOV	al, 0				;reikalinga kiekvienos programos pabaigoj
	INT	21h				;reikalinga kiekvienos programos pabaigoj

;*****************************************************
;Klaidu apdorojimas
;*****************************************************
  klaidaAtidarantSkaitymui:
	;<klaidos pranesimo isveddosimo kodas>
	MOV ax, 1
	CALL Help_kvietimas
	JMP	pabaiga
	
  klaidaAtidarantRasymui:
	;<klaidos pranesimo isvedimo kodas>
	MOV ax, 2
	CALL Help_kvietimas
	JMP	uzdarytiSkaitymui
	
  klaidaUzdarantRasymui:
	;<klaidos pranesimo isvedimo kodas>
	MOV ax, 3
	CALL Help_kvietimas
	JMP	uzdarytiSkaitymui
	
	
  klaidaUzdarantSkaitymui:
	;<klaidos pranesimo isvedimo kodas>
	MOV ax, 4
	CALL Help_kvietimas
	JMP	pabaiga

;*****************************************************  
;Procedura nuskaitanti informacija is failo
;*****************************************************
PROC SkaitykBuf
;i BX paduodamas failo deskriptoriaus numeris
;i AX bus grazinta, kiek simboliu nuskaityta
	PUSH	cx
	PUSH	dx
	
	MOV	ah, 3Fh			;21h pertraukimo duomenu nuskaitymo funkcijos numeris
	MOV	cx, skBufDydis		;cx - kiek baitu reikia nuskaityti is failo
	MOV	dx, offset skBuf	;vieta, i kuria irasoma nuskaityta informacija
	INT	21h			;skaitymas is failo
	JC	klaidaSkaitant		;jei skaitant is failo ivyksta klaida, nustatomas carry flag

  SkaitykBufPabaiga:
	POP	dx
	POP	cx
	RET

  klaidaSkaitant:
	;<klaidos pranesimo isvedimo kodas>
	MOV ax, 5
	CALL Help_kvietimas
	MOV ax, 0			;Pazymime registre ax, kad nebuvo nuskaityta ne vieno simbolio
	JMP	SkaitykBufPabaiga
SkaitykBuf ENDP

;*****************************************************
;Procedura, irasanti buferi i faila
;*****************************************************
PROC RasykBuf
;i BX paduodamas failo deskriptoriaus numeris
;i CX - kiek baitu irasyti
;i AX bus grazinta, kiek baitu buvo irasyta
	PUSH	dx
	
	MOV	ah, 40h			;21h pertraukimo duomenu irasymo funkcijos numeris
	MOV	dx, offset raBuf	;vieta, is kurios rasom i faila
	INT	21h			;rasyymas i faila
	JC	klaidaRasant		;jei rasant i faila ivyksta klaida, nustatomas carry flag
	CMP	cx, ax			;jei cx nelygus ax, vadinasi buvo irasyta tik dalis informacijos
	JNE	dalinisIrasymas

  RasykBufPabaiga:
	POP	dx
	RET

  dalinisIrasymas:
	;<klaidos pranesimo isvedimo kodas>
	MOV ax, 6
	CALL Help_kvietimas
	JMP	RasykBufPabaiga
  klaidaRasant:
	;<klaidos pranesimo isvedimo kodas>
	MOV ax, 7
	CALL Help_kvietimas
	MOV	ax, 0			;Pazymime registre ax, kad nebuvo irasytas ne vienas simbolis
	JMP	RasykBufPabaiga
RasykBuf ENDP


PROC IraBufDetSk		;i raBuf ideda skaicius 
    ;al turim skaiciu 
    PUSH cx 
    MOV ah, 0 
    MOV cx, 0
    
    mazinam:				;loop'as kuris suraso skaicius po viena skaitmeni
        	MOV dl, 10			
        	DIV dl			;atlieka veiksmus su ax		al=ax/dl	ah = ax % dl   
        	
        	MOV dx, ax      ;issaugom kas kokia reiksme gavos cx
        	
        	MOV dl, dh      ;ch yra liekana kurios reik, mum reik kad ispopinus butu dl ta liekana
        	MOV dh, 0       ;isvalom dh
        	PUSH dx
        	
        	INC cx 				;counteris kiek i stack'a irasem
			
        	MOV ah, 0		;lygina
        	CMP al, 0
                                              
        	
      JNE mazinam    		 ;for'as  
          
       
     MOV di, 0
     isSteko:			;cx yra counteris kiek irasem i stacka
        
        POP dx     
        ADD dl, 30h
        mov raBuf[di], dl	;idedam i rasymo bufferi
        inc di
     
     LOOP isSteko
    
    POP cx   ;grazinam cx orginalia reiksme
    
    RET
    
IraBufDetSk ENDP



PROC Darbas_su_mapu
	
		
;masyve mapas turim visus, reik spausdint
	MOV cx, 256    ;praeinam pro visus map'o elementus
	MOV si, 0  		;indeksavimui
	irasymo_buf:  
	           
	    MOV counter, cx       	;counteris turi kiek suksim loop'a
		
	    CMP mapas[si], 0
	    JE ner_simbolio 			;jeigu tokio simbolio nera (0 kartu pasikartojo), tai mes su juo nedirbam	
		
	    MOV dx, si 
	    MOV dh, 0          ;spausdinam simboli  
	    CALL IraBufDetChar
		
	    MOV raBuf[2], ' '
	    MOV	cx, 3				;ir tarpa
	    MOV	bx, rFail			
	    CALL	RasykBuf  
		
		
	    MOV al, mapas[si]
	    CALL IraBufDetSk   ;di kiek skaiciu gavos (keliaskiemenis)
	    MOV cx, di
	    MOV ch, 0 
	    MOV bx, rFail
	    CALL    RasykBuf
		
	    MOV cx, 1              ;endline'as
	    MOV bx, rFail
	    MOV raBuf[0], 10
		;MOV raBuf[1], 13
	    CALL    Rasykbuf
		
	    ner_simbolio:  
	    INC si
	    
	    MOV cx, counter   

    LOOP irasymo_buf

	RET
	
Darbas_su_mapu ENDP


PROC IraBufDetChar
    
    ;dl turim ta char
    
    MOV al, dl
    MOV ah, 0
    MOV bl, 16	;hex sistema
    DIV bl      ;ah liekana         al pirmiau
 
    CMP al, 9	;tikrinam ar tas simbolis 1-zenklis [ascii] (16tainej sistemoj)
    JA raide1	;jeigu daugiau 9 reiskia reikes raidziu
    
    ADD al, 30h
    JMP ipabaiga1		;jeigu vienzenklis sokam i pabaiga   
    
    raide1:
    ADD al, 55		;pridedam kad 10 -> A ir t.t.
	
    ipabaiga1:     
    MOV raBuf[0], al
	
	;------antras simbolis------
    CMP ah, 9
    JA raide2
	
    ADD ah, 30h
    
    JMP ipabaiga2  
    
    raide2:

    ADD ah, 55
    
    ipabaiga2:      
    MOV raBuf[1], ah    
    RET

IraBufDetChar   ENDP 




PROC SurastFailuVardus 
    
    
    PUSH ax
    
    MOV cl, [es:0080h]    ;kiek yra elementu	
    MOV ch, 0
    cmp cx, 0 
    JE netinka 

    
    cmp cx, 3
    JE pagalbos_simbolis 	;jeigu tik vienas simbolis reiskia tai yra pagalbos simbolis
    
    MOV bx, 0082h
	
		MOV dl, [es:bx]
        CMP dl, 'a'    ;tikrinam ar komanda yra 'antra'
        JNE netinka
        INC bx		

        
        MOV dl, [es:bx]
        CMP dl, 'n'
        JNE netinka
        INC bx


        MOV dl, [es:bx]
        CMP dl, 't'
        JNE netinka
        INC bx
       
		
        MOV dl, [es:bx]
        CMP dl, 'r'
        JNE netinka
        INC bx
		

        MOV dl, [es:bx]
        CMP dl, 'a'
        JNE netinka
        INC bx
   
	  
        MOV dl, [es:bx]
        CMP dl, ' '
        JNE  netinka    
        
                     
    MOV di, 0     
    INC bx
	SUB cx, 7	;7 raides nes ' antra '
    
    duomenuF:
	DEC cx
        MOV al, [es:bx]
        MOV duom[di], al	;di indeksuojam. Dedam i duom[] is parametru
        
		INC di
        INC bx
        
		MOV dl, [es:bx]
        CMP dl, ' '
        JE  irasem_duom 		;iki tarpo tarpo skaitom duomenu failo pavadinima
        
        CMP cx, 0              ;netinkama, nes reiskia ner tarpo
        JE netinka
            
    JMP duomenuF  
    
    irasem_duom:
    
    MOV di, 0
    INC bx
	DEC cx		;nenorim skaityt gale parametru 0Dh

    rezultatuF:
       
		MOV al, [es:bx]		;dedam i rez[] is parametru
		MOV rez[di], al
		
		INC bx
		INC di
		MOV dl, [es:bx]
		CMP dl, 0
		LOOP rezultatuF		;iki galo nuskaitom (cx turi kiek simboliu sudaro parametrai)
    
	JMP SurastFailuVardus_pab
    
    netinka:
    ;<netinka parametru> 
	MOV ax, 8
	CALL Help_kvietimas
	
	MOV	ah, 4Ch				;baigiam
	MOV	al, 0				
	INT	21h		
	
    SurastFailuVardus_pab:
    POP ax
    RET 
    
    
    pagalbos_simbolis:	
    CMP	[es:0082h], '?/'	;nes little endian
    
    JNE pagalbos_simbolis_galas
    ;<pagalbos zinute /?> 
    MOV ax, 0
	CALL Help_kvietimas
	
	MOV	ah, 4Ch				;baigiam
	MOV	al, 0				
	INT	21h	
	
    pagalbos_simbolis_galas: 
    POP ax
    RET
    
    
SurastFailuVardus ENDP

PROC Help_kvietimas
	
	;I AX ATEINA KLAIDOS KODAS
	CMP ax, 0
	JE info
	
	mov bgood, 0
	
	info:
	
	ADD ax, 30h
	MOV help[8], al
	
	MOV ah, 09
	MOV dx, offset help
	INT 21h
	
	RET

Help_kvietimas ENDP

    
END pradzia



