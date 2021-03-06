;
;			 XDIR.ASM
;		     Revised 6/28/80
;
;	    EXTENDED (SORTED) DIRECTORY PROGRAM
;		by Keith Petersen, W8SDZ
;
;PRINTS A 3-WIDE DIRECTORY, SORTED ALPHABETICALLY,
;SHOWING EXTENT NUMBERS AND EXTENT SIZE.  BASED ON
;'FMAP' BY WARD CHRISTENSEN AND XDIR BY B. RATOFF.
;
;XDIR FILENAME.FILETYPE or just XDIR
;ALLOWS '*' OR '?' TYPE SPECIFICATIONS
;DRIVE NAME MAY ALSO BE SPECIFIED
;
;07/31/79 CORRECTED ERROR IN CONSTAT TEST
;	  FOR ABORTING PRINT.  (KBP)
;
;08/16/79 ADD CONDITIONAL ASSEMBLY FOR CP/M
;	  ON H8 OR TRS-80.  (KBP)
;
;05/21/80 ADD ANI 7FH TO REMOVE FILE ATTRIBUTES
;	  TO MAKE COMPATIBLE WITH CPM-2. (KBP)
;
;06/28/80 FIX ERROR IN FILE SIZE PRINTOUTS. (KBP)
;
FALSE	EQU	0
TRUE	EQU	NOT FALSE
;
BASE	SET	0
;
ALTCPM	EQU	FALSE	;PUT TRUE HERE FOR H8 OR TRS-80 CP/M
;
	IF	ALTCPM
BASE	SET	4200H
	ENDIF
;
FCB	EQU	BASE+5CH ;SYSTEM FCB
EXTENT	EQU	BASE+68H ;FCB EXTENT BYTE
NPL	EQU	3	;NUMBER OF NAMES PER LINE
DELIM	EQU	7CH	;FENCE (DELIMITER) CHARACTER
;
	ORG	BASE+100H
;
	JMP	START	;JMP AROUND I.D.
	DB	'XDIR.COM 6/27/80 '
;
;SAVE THE STACK
START	LXI	H,0
	DAD	SP	;H=STACK
	SHLD	STACK	;SAVE IT
	LXI	SP,STACK ;GET NEW STACK
;NO FCB SPECIFIED?
	LXI	H,FCB+1
	MOV	A,M
	CPI	' '
	JNZ	GOTFCB
;NO FCB - MAKE FCB ALL '?'
	MVI	B,11	;FN+FT COUNT
QLOOP	MVI	M,'?'	;STORE '?' IN FCB
	INX	H
	DCR	B
	JNZ	QLOOP
;LOOK UP THE FCB IN THE DIRECTORY
GOTFCB	MVI	A,'?'	;MATCH ALL EXTENTS
	STA	EXTENT
	MVI	C,FSRCHF ;GET 'SEARCH FIRST' FNC
	LXI	D,FCB
	CALL	BDOS	;READ FIRST
	INR	A	;WERE THERE ANY?
	JNZ	SOME	;GOT SOME
	CALL	ERXIT
	DB	'++NOT FOUND$'
;
;READ MORE DIRECTORY ENTRIES
MOREDIR	MVI	C,FSRCHN ;SEARCH NEXT
	LXI	D,FCB
	CALL	BDOS	;READ DIR ENTRY
	INR	A	;CHECK FOR END (0FFH)
	JZ	SPRINT	;NO MORE - SORT & PRINT
;POINT TO DIRECTORY ENTRY 
SOME	DCR	A	;UNDO PREV 'INR A'
	ANI	3	;MAKE MODULUS 4
	ADD	A	;MULTIPLY...
	ADD	A	;..BY 32 BECAUSE
	ADD	A	;..EACH DIRECTORY
	ADD	A	;..ENTRY IS 32
	ADD	A	;..BYTES LONG
	LXI	H,BASE+81H ;POINT TO BUFFER
			;(SKIP TO FN/FT)
	ADD	L	;POINT TO ENTRY
	MOV	L,A	;SAVE (CAN'T CARRY TO H)
;MOVE ENTRY TO TABLE
	XCHG		;ENTRY TO DE
	LHLD	NEXTT	;NEXT TABLE ENTRY TO HL
	MVI	B,11	;LENGTH OF NAME
;
TMOVE	LDAX	D	;GET ENTRY CHAR
	ANI	7FH	;REMOVE ATTRIBUTES
	MOV	M,A	;STORE IN TABLE
	INX	D
	INX	H
	DCR	B	;MORE?
	JNZ	TMOVE
	MVI	B,20	;LENGTH OF REST OF ENTRY
;
TMOVE2	LDAX	D	;GET ENTRY CHARACTER
	MOV	M,A	;STORE IN TABLE
	INX	D
	INX	H
	DCR	B	;MORE?
	JNZ	TMOVE2
	SHLD	NEXTT	;SAVE UPDATED TABLE ADDR
	LDA	COUNT	;GET PREV COUNT
	INR	A
	STA	COUNT
	JMP	MOREDIR
;
;SORT AND PRINT
SPRINT	LDA	COUNT	;INIT THE ORDER TABLE
	LXI	H,ORDER
	LXI	D,TABLE
	LXI	B,31	;ENTRY LENGTH
;
BLDORD	MOV	M,E	;SAVE LO ORD ADDR
	INX	H
	MOV	M,D	;SAVE HI ORD ADDR
	INX	H
	XCHG		;TABLE ADDR TO HL
	DAD	B	;POINT TO NEXT ENTRY
	XCHG
	DCR	A	;MORE?
	JNZ	BLDORD	;..YES
	LDA	COUNT	;GET COUNT
	STA	SCOUNT	;SAVE AS # TO SORT
	DCR	A	;ONLY 1 ENTRY?
	JZ	DONE	;..YES, SO SKIP SORT
;
SORT	XRA	A	;GET A ZERO
	STA	SWITCH	;SHOW NONE SWITCHED
	LDA	SCOUNT	;GET COUNT
	DCR	A	;USE 1 LESS
	STA	TEMP	;SAVE # TO COMPARE
	STA	SCOUNT	;SAVE HIGHEST ENTRY
	JZ	DONE	;EXIT IF NO MORE
	LXI	H,ORDER ;POINT TO ORDER TABLE
;
SORTLP	CALL	COMPR	;COMPARE 2 ENTRIES
	CM	SWAP	;SWAP IF NOT IN ORDER
	INX	H	;BUMP ORDER
	INX	H	;..TABLE POINTER
	LDA	TEMP	;GET COUNT
	DCR	A
	STA	TEMP
	JNZ	SORTLP	;CONTINUE
;ONE PASS OF SORT DONE
	LDA	SWITCH	;ANY SWAPS DONE?
	ORA	A
	JNZ	SORT
;SORT IS ALL DONE - PRINT ENTRIES
DONE	LXI	H,ORDER
	SHLD	NEXTT
;
;PRINT AN ENTRY
	MVI	C,NPL	;NR. OF NAMES PER LINE
;
ENTRY:	PUSH	B
	MVI	C,CONST	;CK STATUS OF KB
	CALL	BDOS	;ANY KEY PRESSED?
	POP	B
	ORA	A
	JNZ	ABORT	;YES, ABORT
	LHLD	NEXTT	;GET ORDER TABLE POINTER
	MOV	E,M	;GET LO ADDR
	INX	H
	MOV	D,M	;GET HI ADDR
	INX	H
	SHLD	NEXTT	;SAVE UPDATED TABLE POINTER
	XCHG		;TABLE ENTRY TO HL
	MVI	B,8	;FILE NAME LENGTH
	CALL	TYPEIT	;TYPE FILENAME
	CALL	PERIOD	;PERIOD AFTER FN
	MVI	B,3	;GET THE FILETYPE
	CALL	TYPEIT
	MOV	A,M	;GET EXTENT NUMBER
	ADI	'0'	;CONVERT TO ASCII
	CPI	':'	;ABOVE ASCII '9' ?
	JC	ENTRY2
	ADI	7
;
ENTRY2	CPI	'0'	;IS EXTENT NUMBER ZERO?
	JNZ	ENTRY3	;NO, PRINT '+' THEN NUMBER
	CALL	TWOSPCE	;IT'S ZERO - PRINT 2 SPACES
	JMP	ENTRY4	;THEN PRINT SIZE
;
ENTRY3	PUSH	PSW	;SAVE EXTENT NUMBER
	MVI	A,'+'
	CALL	TYPE	;PRINT '+'
	POP	PSW	;GET EXTENT NUMBER
	CALL	TYPE	;PRINT IT
;
ENTRY4	CALL	SPACE	;SPACE OVER ONE
	INX	H
	INX	H
	INX	H
	MOV	A,M	;GET EXTENT SIZE
	PUSH	B
	CALL	PDEC	;PRINT IT
	POP	B
	DCR	C	;ONE LESS ON THIS LINE
	PUSH	PSW
	CNZ	FENCE	;NO CR-LF NEEDED, DO FENCE
	POP	PSW
	CZ	CR	;CR-LF NEEDED
;SEE IF MORE ENTRIES
	LDA	COUNT
	DCR	A
	STA	COUNT
	JNZ	ENTRY	;YES, MORE
	JMP	EXIT
;
;PRINT VALUE IN A IN UNSIGNED DECIMAL FORMAT
;
PDEC:	STA	DTEMP	;SAVE THE NUMBER
	MVI	A,100
	STA	Q
	XRA	A	;CLEAR LEADING ZERO FLAG
	STA	LEAD0FL
; 
;DIVIDE A BY Q
;
PDEC2:	LDA	DTEMP
	MOV	C,A
	LDA	Q
	MOV	D,A
	CALL	BDIV
	MOV	A,B
	STA	DTEMP	;SAVE REMAINDER
	MOV	A,C
	ADI	0
	JNZ	PDEC3
	LDA	LEAD0FL
	ADI	0
	JZ	PDEC4
; 
PDEC3:	MOV	A,C
	ADI	'0'	;CONVERT TO ASCII
	CALL	TYPE	;PRINT QUOTIENT
	MVI	A,1	;STOP SUPRESSING ZEROS
	STA	LEAD0FL
	JMP	PDEC5
; 
PDEC4:	CALL	SPACE
; 
PDEC5:	LDA	Q
	MOV	C,A
	MVI	D,10
	CALL	BDIV	;DIVIDE Q BY 10
	MOV	A,C
	STA	Q
	LDA	Q
	CPI	1
	JNZ	PDEC2
	LDA	DTEMP
	ADI	'0'	;CONVERT TO ASCII
	JMP	TYPE	;PRINT IT THEN RETURN
; 
;BYTE DIVISION ROUTINE
;
BDIV:	MVI	B,0
	MVI	L,8
; 
BDIVLP:	STC
	CMC
	MOV	A,C
	RAL
	MOV	C,A
	MOV	A,B
	RAL
	MOV	B,A
	MOV	A,B
	SUB	D
	JM	BDIV2
	MOV	B,A
	MOV	A,C
	ORI	1
	MOV	C,A
; 
BDIV2:	DCR	L
	JNZ	BDIVLP
	RET
;
PERIOD	MVI	A,'.'
	JMP	TYPE
;
FENCE	CALL	SPACE
	MVI	A,DELIM	;FENCE CHARACTER
	CALL	TYPE
;
TWOSPCE	CALL	SPACE
;
SPACE	MVI	A,' '
;
;TYPE CHAR IN A
TYPE	PUSH	B
	PUSH	D
	PUSH	H
	ANI	7FH	;REMOVE ATTRIBUTES
	MOV	E,A
	MVI	C,WRCHR
	CALL	BDOS
	POP	H
	POP 	D
	POP	B
	RET
;
WRCON	MVI	C,PRINT
	JMP	BDOS
;
TYPEIT	MOV	A,M
	CALL	TYPE
	INX	H
	DCR	B
	JNZ	TYPEIT
	RET
;
CR	MVI	E,13	;PRINT
	MVI	C,2	;C/R
	CALL	BDOS
	MVI	E,10	;LF
	MVI	C,2
	CALL	BDOS
	MVI	C,NPL	;NUMBER OF NAMES PER LINE
	RET
;
;COMPARE ROUTINE FOR SORT
COMPR	PUSH	H	;SAVE TABLE ADDR
	MOV	E,M	;LOAD LO
	INX	H
	MOV	D,M	;LOAD HI
	INX	H
	MOV	C,M
	INX	H
	MOV	B,M
;BC, DE NOW POINT TO ENTRIES TO BE COMPARED
	XCHG
CMPLP	LDAX	B
	CMP	M
	INX	H
	INX	B
	JZ	CMPLP
	POP	H
	RET		;COND CODE TELLS ALL
;
;SWAP ENTRIES IN THE ORDER TABLE
SWAP	MVI	A,1
	STA	SWITCH	;SHOW A SWAP WAS MADE
	MOV	C,M
	INX	H
	PUSH	H	;SAVE TABLE ADDR+1
	MOV	B,M
	INX	H
	MOV	E,M
	MOV	M,C
	INX	H
	MOV	D,M
	MOV	M,B
	POP	H
	MOV	M,D
	DCX	H	;BACK POINTER TO CORRECT LOC'N
	MOV	M,E
	RET
;
;ERROR EXIT
ERXIT	POP	D	;GET MSG
	MVI	C,PRINT
	JMP	CALLB	;PRINT MSG, EXIT
;
;ABORT - READ CHAR ENTERED
ABORT	MVI	C,RDCHR
CALLB	CALL	BDOS	;DELETE THE CHAR
;
;FALL INTO EXIT
;EXIT - ALL DONE , RESTORE STACK
EXIT	LHLD	STACK	;GET OLD STACK
	SPHL		;MOVE TO STACK
	RET		;..AND RETURN
;
NEXTT	DW	TABLE	;NEXT TABLE ENTRY
COUNT	DB	0	;ENTRY COUNT
SCOUNT	DB	0	;# TO SORT
SWITCH	DB	0	;SWAP SWITCH FOR SORT
BUFAD	DW	BASE+80H ;OUTPUT ADDR
ORDER	DS	256	;ORDER TABLE (ROOM FOR 128 NAMES)
	DS	60	;STACK AREA
STACK	DS	2	;SAVE OLD STACK HERE
Q	DS	1	;FOR DIVIDER ROUTINE
DTEMP	DS	1	;FOR DIVIDER ROUTINE
LEAD0FL	DS	1	;LEADING ZERO FLAG
TEMP	DS	1	;SAVE DIR ENTRY
TABLE	EQU	$	;READ ENTRIES IN HERE
;
; BDOS EQUATES
;
RDCHR	EQU	1	;READ CHAR FROM CONSOLE
WRCHR	EQU	2	;WRITE CHR TO CONSOLE
PRINT	EQU	9	;PRINT CONSOLE BUFF
CONST	EQU	11	;CHECK CONS STAT
FOPEN	EQU	15	;0FFH=NOT FOUND
FCLOSE	EQU	16	;   "	"
FSRCHF	EQU	17	;   "	"
FSRCHN	EQU	18	;   "	"
ERASE	EQU	19	;NO RET CODE
FREAD	EQU	20	;0=OK, 1=EOF
FWRTE	EQU	21	;0=OK, 1=ERR, 2=?, 255=NO DIR SPC
FMAKE	EQU	22	;255=BAD
FREN	EQU	23	;255=BAD
FDMA	EQU	26
BDOS	EQU	BASE+5
REBOOT	EQU	BASE+0
;
	END
RR, 2=?, 255=NO DIR SPC
FMAKE	EQU	22	;255=BAD
FREN	EQU	23	;255=BAD
FDMA	EQU