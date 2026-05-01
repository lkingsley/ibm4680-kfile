%ENVIRON C

INTEGER*1 DAY%, MONTH%, M%, J%, RECORDS.PER.BLOCK%, FOUND%, TRUE%
INTEGER*1 ARGS.COUNT%, INDEX%, SPACE.INDEX%, LENGTH%, Z%
INTEGER*2 BLOCK.SIZE%, KEY.LENGTH%, RECORD.SIZE%, YEAR%, FROM%, TO%, SHIFTED%
INTEGER*4 BITWISE.LIST%(1), BLOCKS.QTY%, RESULT%
INTEGER*4 FILE.SIZE%, I%, EXCLUDE%, EXPONENTS%(1)
STRING BLOCK$, CTRL.BLOCK.FMT$, EXCLUDE$, FILE$, FILE.CREATION.NAME$
STRING ARGS$(1), RECORD.FORMAT$, NOTKEYED$, KEY$, RECORD$
STRING C$, CMDTAIL$, LENGTH$, RESULT$, TYPE$, FIELD$, INVALID.FMT$

DIM ARGS$(10)
DIM BITWISE.LIST%(10)
DIM EXPONENTS%(4)

ARGS.COUNT% = 0
BLOCK.SIZE% = 512
CTRL.BLOCK.FMT$ = "C12 C18 I2 I1 I1 C6 I2 I4 I2 C6 I2 C456"
EXPONENTS%(1) = 1
EXPONENTS%(2) = 2^8
EXPONENTS%(3) = 2^16
EXPONENTS%(4) = 2^24
FROM% = 1
INVALID.FMT$ = "Invalid format specified: "
NOTKEYED$ = "Not keyed file or file is corrupted."
RESULT$ = ""
TRUE% = 1


!****************************************
! RETURN TRUE IF RECORD HAS A VALID KEY
!****************************************
FUNCTION HASKEY%(REC$, KEY.LENGTH%)
    INTEGER*1 KEY.LENGTH%, M%, DCODE%
    STRING REC$
    
    HASKEY% = 0
    FOR M% = 1 TO KEY.LENGTH%
        DCODE% = ASC(MID$(REC$, M%, 1))
        IF DCODE% <> 0 THEN \
            HASKEY% = TRUE% : EXIT FUNCTION
    NEXT M%
FEND


!****************************************************
! RETURN TRUE IF STRING CONTAINS ONLY NUMERIC DIGITS
!****************************************************
FUNCTION ISNUMERIC%(LENGTH$)
    STRING LENGTH$
    INTEGER*1 J%
    
    ISNUMERIC% = TRUE%
    FOR J% = 1 TO LEN(LENGTH$)
        C$ = MID$(LENGTH$, J%, 1)
        IF ASC(C$) < 48 OR ASC(C$) > 57 THEN \
            ISNUMERIC% = 0 : EXIT FUNCTION
    NEXT J%
FEND


CMDTAIL$ = COMMAND$

IF LEN(CMDTAIL$) = 0 THEN \
    PRINT "Usage: args [format] <file_name>" : STOP

SPACE.INDEX% = MATCH(" ", CMDTAIL$, FROM%)

ON ERROR GOTO ERRORTRAP

!***********************************************************
! FILE NAME PROVIDED AS AN ARGUMENT, BUT NO FORMAT STRING
!***********************************************************
IF SPACE.INDEX% = 0 AND LEN(CMDTAIL$) > 0 THEN \
    BEGIN
        ARGS.COUNT% = 1.
        !******************************************
        ! IF NOT FORMAT PROVIDED, DEFAULT PRINTS ALL FIELDS AS CHARACTERS
        !******************************************
        ARGS$(ARGS.COUNT%) = "D" 
        FILE$ = CMDTAIL$         
    ENDIF

!*******************************************************
! FILE NAME AND FORMAT STRING PROVIDED AS ARGUMENTS
!*******************************************************
WHILE SPACE.INDEX% > 0
    ARGS.COUNT% = ARGS.COUNT% + 1
    ARGS$(ARGS.COUNT%) = MID$(CMDTAIL$, FROM%, SPACE.INDEX% - 1)
    CMDTAIL$ = RIGHT$(CMDTAIL$, LEN(CMDTAIL$) - SPACE.INDEX%)

    SPACE.INDEX% = MATCH(" ", CMDTAIL$, FROM%)
    IF SPACE.INDEX% = 0 AND LEN(CMDTAIL$) > 0 THEN \
        FILE$ = CMDTAIL$
WEND

FILE.SIZE% = SIZE(FILE$)
IF FILE.SIZE% < BLOCK.SIZE% \
    OR MOD(FILE.SIZE%, BLOCK.SIZE%) <> 0 THEN PRINT NOTKEYED$ : STOP

!****************************
! READING CONTROL BLOCK
!****************************
OPEN FILE$ AS 10 BUFFSIZE FILE.SIZE%
READ FORM CTRL.BLOCK.FMT$; #10; EXCLUDE$, FILE.CREATION.NAME$, YEAR%, \
								MONTH%, DAY%, EXCLUDE$, EXCLUDE%, \
								BLOCKS.QTY%, RECORD.SIZE%, \
                            	EXCLUDE$, KEY.LENGTH%, EXCLUDE$

IF FILE.SIZE% <> (BLOCKS.QTY% * BLOCK.SIZE%) THEN \
    PRINT NOTKEYED$ : STOP

!***************************************************************
! IF DEFAULT FORMAT, PRINT ENTIRE RECORDS AS ASCII CHARACTERS
!***************************************************************
IF ARGS$(1) = "D" THEN \
    ARGS$(1) = "C"+STR$(RECORD.SIZE%) : GOTO PRINTSECTION

!*************************************************
! VALIDATING SIZE AND TYPE OF FORMAT FIELDS
!**************************************************
FOR I% = 1 TO ARGS.COUNT%
    TYPE$ = LEFT$(ARGS$(I%), 1)
    LENGTH$ = RIGHT$(ARGS$(I%), LEN(ARGS$(I%)) - 1)

    !********************************************
    ! VALIDATING DATA TYPE AND FIELD SIZE
    !********************************************
    IF TYPE$ <> "C" AND TYPE$ <> "P" AND TYPE$ <> "I" AND TYPE$ <> "E" THEN \
        PRINT INVALID.FMT$; ARGS$(I%) : STOP
 
    IF ISNUMERIC%(LENGTH$) <> TRUE% THEN \
        PRINT INVALID.FMT$; ARGS$(I%) : STOP

NEXT I%

!**************************************************************
! FORMAT VALIDATION FINISHED, NOW PROCESSING THE FILE.
! LOOP THROUGH EACH BLOCK AND PRINT ALL NOT EMPTY RECORDS
!**************************************************************

PRINTSECTION:
RECORDS.PER.BLOCK% = BLOCK.SIZE% / RECORD.SIZE%

FOR I% = 1 TO (BLOCKS.QTY% - 1)
    FROM% = 1
    TO% = RECORD.SIZE%
    READ FORM "C4 C508"; #10; EXCLUDE$, BLOCK$

    FOR J% = 1 TO RECORDS.PER.BLOCK%
        FOUND% = 0
		RECORD$ = MID$(BLOCK$, FROM%, TO%)
        FOUND% = HASKEY%(RECORD$, KEY.LENGTH%)

        !**************************************************************
        ! IF FOUND, PRINT FORMATTED TEXT
        !**************************************************************
        IF FOUND% = TRUE% THEN \
            BEGIN
            RESULT$ = ""

            FOR M% = 1 TO ARGS.COUNT%
                TYPE$ = LEFT$(ARGS$(M%), 1)
                LENGTH$ = RIGHT$(ARGS$(M%), LEN(ARGS$(M%)) - 1)

                IF TYPE$ = "E" THEN \
                    RECORD$ = RIGHT$(RECORD$, LEN(RECORD$) - VAL(LENGTH$)) \
                ELSE \
                IF TYPE$ = "P" THEN \
                    BEGIN
                        FIELD$ = LEFT$(RECORD$, VAL(LENGTH$))
                        RESULT$ = RESULT$ + "," + UNPACK$(FIELD$)
                        RECORD$ = RIGHT$(RECORD$, LEN(RECORD$) - VAL(LENGTH$))
                    ENDIF \
                ELSE \
                IF TYPE$ = "C" THEN \
                    BEGIN
                        RESULT$ = RESULT$ + "," + LEFT$(RECORD$, VAL(LENGTH$))
                        RECORD$ = RIGHT$(RECORD$, LEN(RECORD$) - VAL(LENGTH$))
                    ENDIF \
                ELSE \
                    BEGIN
                    !*****************************************************
                    ! HANDLING 1 TO 4 BYTES INTEGER FIELDS
                    !*****************************************************
                    RESULT% = 0
                    FIELD$ = LEFT$(RECORD$, VAL(LENGTH$))
                    RECORD$ = RIGHT$(RECORD$, LEN(RECORD$) - VAL(LENGTH$))

                    FOR Z% = 1 TO VAL(LENGTH$)
                        BITWISE.LIST%(Z%) = ASC(LEFT$(FIELD$, 1))
                        FIELD$ = RIGHT$(FIELD$, LEN(FIELD$) - 1)
                    NEXT Z%

                    !******************************************************
                    ! LEFT SHIFTING
                    !******************************************************
                    FOR Z% = VAL(LENGTH$) TO 1 STEP -1
                        RESULT% = RESULT% OR (BITWISE.LIST%(Z%) * EXPONENTS%(Z%))
                    NEXT Z%

                    RESULT$ = RESULT$ + "," + STR$(RESULT%)
                    ENDIF
            NEXT M%

            PRINT RIGHT$(RESULT$, LEN(RESULT$) - 1)
            ENDIF

        FROM% = FROM% + RECORD.SIZE%
        TO% = TO% + RECORD.SIZE%

	NEXT J%
NEXT I%

CLOSE 10
STOP

ERRORTRAP:
HX% = ERRN
ERRFX$ = ""

FOR S% = 28 TO 0 STEP -4
    SX% = SHIFT(HX%, S%)
    THE.SUM% = SX% AND 000FH

    IF THE.SUM% > 9 THEN    \
        THE.SUM% = THE.SUM% +55 \
    ELSE \
        THE.SUM% = THE.SUM% +48
    Z$ = CHR$(THE.SUM%)
    ERRFX$ = ERRFX$ + Z$
NEXT S%

IF ERRFX$ = "00000056" THEN \
    BEGIN
        PRINT NOTKEYED$
    ENDIF \
ELSE \
IF ERRFX$ = "00000052" THEN \
    BEGIN
        PRINT "File not found: ";FILE$
    ENDIF \
ELSE \
    BEGIN
        PRINT
        PRINT "A runtime error has occurred"
        PRINT
        PRINT "  ERR = ";ERR,"   ERRL = ";ERRL
        PRINT "  ERRF = ";ERRF%,"   ERRN = ";ERRFX$
        PRINT
    ENDIF
END
