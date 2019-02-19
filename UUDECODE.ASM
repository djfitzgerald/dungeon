;----------------------------------------------------------------------------
; UUDECODE program, version 1.1
;
; Copyright 1995, David S. Peterson
;
; This program may be used and distributed freely as long as this copyright
; notice is not removed.  Feel free to use sections of code from this program
; as part of your own programs, but please leave this file intact.  I am
; reasonably certain that this program doesn't have any major bugs, but its
; use is at your own risk.  If you find any bugs in this program, or have any
; questions or comments, please feel free to send me some email or write me a
; letter.  My email address is:
;
;    dspeter1@eos.ncsu.edu
;
; and my mailing address is:
;
;    David S. Peterson
;    3717 Williamsborough Ct.
;    Raleigh, NC 27609
;    USA
;
; If you like this program, feel free to send me a postcard from your home
; town.
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Changes in Version 1.1:
;
;    No changes made to content of program.  Copyright message changed.
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Program should be linked to produce a COM file.
;
; Usage: uudecode PATH1 [PATH2 ...]
;
; PATH1, PATH2, etc. can contain wildcard characters such as * and ?
;----------------------------------------------------------------------------

TAB           EQU       09h
SPACE         EQU       20h
CR            EQU       0Dh
LF            EQU       0Ah
IBUF_SIZE     EQU       30720               ;file input buffer size  (30 k)
OBUF_SIZE     EQU       30720               ;file output buffer size (30 k)

fileinfo      STRUC
 f_reserved   DB        21        DUP (?)
 f_attribute  DB        ?
 f_filetime   DW        ?
 f_filedate   DW        ?
 f_size       DD        ?
 f_filename   DB        13        DUP (?)
fileinfo      ENDS

uudecode      SEGMENT   PARA      'CODE'

              ORG       80h
args          DB        128       DUP (?)   ;command line args in PSP

              ORG       100h
              ASSUME    CS: uudecode, DS: uudecode
              ASSUME    ES: uudecode, SS: uudecode

start:        CALL      parse_args          ;parse command line args
              MOV       AH, 1Ah
              LEA       DX, dta
              INT       21h                 ;set DTA for file find functions
              CMP       BYTE PTR argc, 0
              JNE       process_args        ;disp usage msg if no args
              MOV       AH, 09h
              LEA       DX, usage
              INT       21h
              MOV       BYTE PTR ret_val, 1 ;exit code
              JMP       SHORT exit
process_args: XOR       SI, SI              ;SI is array index for argv
              MOV       BX, SI
              MOV       BL, argc
              SHL       BL, 1               ;value to compare with SI in loop
              MOV       ret_val, BH
find_first:   MOV       AH, 4Eh
              MOV       CX, 21h             ;include read only and archive
              MOV       DX, argv[SI]        ;DX points to arg in PSP
              INT       21h                 ;find first matching filename
              PUSH      argv[SI]            ;arg for disp_error or getpath
              JNC       do_path             ;jump on success (file found)
              CMP       AL, 03h
              JE        set_errno
              MOV       AL, 02h             ;file not found
set_errno:    MOV       BYTE PTR errno, AL
              CALL      disp_error          ;disp error msg
              JMP       SHORT arg_done      ;process next arg
do_path:      CALL      getpath             ;combine dir path with filename
do_decode:    CALL      decode              ;decode file (name in filepath)
              OR        ret_val, AL         ;ret val from decode in AL
find_next:    MOV       AH, 4Fh
              INT       21h                 ;find next file
              JC        arg_done            ;do next arg if file not found
              CALL      decode              ;decode file (name in filepath)
              OR        ret_val, AL         ;ret val from decode in AL
              JMP       SHORT find_next
arg_done:     ADD       SI, 2
              CMP       SI, BX
              JB        find_first
exit:         MOV       AH, 4Ch
              MOV       AL, ret_val
              INT       21h                 ;terminate program

;----------------------------------------------------------------------------
; PROC decode:
;
; decode file
;
; parameters: filename to decode gets passed in global variable filepath
;
; local variables on stack:
;
;    misc: used to temporarily hold return value for subroutine
;
; global variables used:
;
;    filepath   : contains filename to decode
;    outfilename: used to store output filename
;    if_handle  : stores handle for input file
;    of_handle  : stores handle for output file
;    obuf       : output file buffer
;    ibuf_n     : # of chars in ibuf (file input buffer)
;    line_ptr   : ptr to lines read from input file
;    errno      : contains error codes
;
; return value: in AL: 1 if error occurred or 0 if no error
;----------------------------------------------------------------------------

decode        PROC      NEAR

              LOCAL     misc: BYTE = LOC_N

              LOCALS    @@

              PUSH      BP
              MOV       BP, SP
              SUB       SP, LOC_N
              PUSH      BX
              PUSH      CX
              PUSH      DX
              PUSH      SI
              PUSH      DI
              PUSH      AX

              MOV       BYTE PTR errno, 0   ;no system errors yet
              MOV       AX, 3D00h
              LEA       DX, filepath
              INT       21h                 ;open input file for reading
              JNC       @@op_success
              LEA       SI, filepath        ;filename for error msg
              MOV       BYTE PTR errno, AL
              XOR       CX, CX              ;no files to close
              JMP       @@rtn_error         ;return with error msg
@@op_success: MOV       if_handle, AX       ;save file handle
              MOV       WORD PTR ibuf_n, 0  ;clear input file buffer
              CALL      find_begin          ;find begin line
              LEA       SI, filepath        ;filename for error msg
              CMP       AL, -2
              JE        @@here              ;jump if disk error
              CMP       AL, -1
              JNE       @@test_fmt
@@here:       MOV       CX, 0100h
              JMP       @@rtn_error
@@test_fmt:   CMP       AL, -2
              JNE       @@cr_outfile
              MOV       CX, 0101h           ;close input file, unknown format
              JMP       @@rtn_error
@@cr_outfile: MOV       AH, 5Bh
              MOV       CX, 0020h           ;mode = archive
              LEA       DX, outfilename
              INT       21h                 ;create output file (new file)
              JNC       @@cr_success
              LEA       SI, outfilename     ;filename for error msg
              MOV       BYTE PTR errno, AL
              MOV       CX, 0100h           ;close input file
              JMP       @@rtn_error         ;error opening output file
@@cr_success: MOV       of_handle, AX       ;save file handle
              XOR       DX, DX              ;0 chars in obuf
              LEA       DI, obuf            ;[DI] = next position in obuf
@@get_line:   CALL      readline            ;start of outer loop
              CMP       AH, -1
              JNE       @@test_err
              LEA       SI, filepath        ;filename for error msg
              MOV       CX, 0301h           ;close both files, unknown format
              JMP       @@rtn_error
@@test_err:   CMP       AH, -2
              JNE       @@test_eof
              LEA       SI, filepath
              MOV       CX, 0300h
              JMP       @@rtn_error
@@test_eof:   CMP       AL, 0
              JE        @@do_flush
              LEA       SI, filepath        ;filename for error msg
              MOV       CX, 0302h           ;close both files, short file
              JMP       @@rtn_error
@@long_jmp_1: JMP       @@flush_err         ;JMP is > 127 bytes forward
@@long_jmp_2: JMP       @@flush             ; "           "           "
@@do_flush:   CMP       DX, OBUF_SIZE - 60  ;flush obuf if not enough room
              JBE       @@load_SI           ;for at least 60 more chars
              CALL      flush_obuf
              CMP       CH, 0
              JNE       @@long_jmp_1        ;flush error
@@load_SI:    MOV       SI, line_ptr        ;SI will index line from readline
              CLD                           ;DF stays clear during inner loop
              LODSB                         ;get 1st char in line
              SUB       AL, SPACE           ;compute DEC(AL) ...
              AND       AL, 77o             ;...
              CMP       AL, 0               ;treat AL as signed value
              JLE       @@long_jmp_2        ;exit outer loop if AL < 0
              MOV       BL, AL              ;BL stores n (loop counter)
              CMP       BL, 3
              JL        @@below_3           ;treat BL as signed value
@@inner_loop: LODSW
              SUB       AL, SPACE
              AND       AL, 77o
              SHL       AL, 1
              SHL       AL, 1
              SUB       AH, SPACE
              AND       AH, 77o
              MOV       CL, AH
              SHR       AH, 1
              SHR       AH, 1
              SHR       AH, 1
              SHR       AH, 1
              OR        AL, AH
              STOSB
              LODSW
              SHL       CL, 1
              SHL       CL, 1
              SHL       CL, 1
              SHL       CL, 1
              SUB       AL, SPACE
              AND       AL, 77o
              MOV       BH, AL
              SHR       AL, 1
              SHR       AL, 1
              OR        AL, CL
              STOSB
              EVEN
              SHL       BH, 1
              SHL       BH, 1
              SHL       BH, 1
              SHL       BH, 1
              SHL       BH, 1
              SHL       BH, 1
              SUB       AH, SPACE
              AND       AH, 77o
              OR        AH, BH
              MOV       AL, AH
              STOSB
              ADD       DX, 3
              SUB       BL, 3
              CMP       BL, 3
              JGE       @@inner_loop        ;repeat inner loop if BL >= 3
@@below_3:    CMP       BL, 1
              JL        @@long_jmp_3        ;repeat outer loop if BL < 1
@@next:       LODSW
              EVEN
              SUB       AL, SPACE
              AND       AL, 77o
              SHL       AL, 1
              SHL       AL, 1
              SUB       AH, SPACE
              AND       AH, 77o
              MOV       CL, AH
              SHR       AH, 1
              SHR       AH, 1
              SHR       AH, 1
              SHR       AH, 1
              OR        AL, AH
              STOSB
              INC       DX
              CMP       BL, 2
              JL        @@long_jmp_3        ;repeat outer loop if BL < 2
              LODSB
              EVEN
              SHL       CL, 1
              SHL       CL, 1
              SHL       CL, 1
              SHL       CL, 1
              SUB       AL, SPACE
              AND       AL, 77o
              SHR       AL, 1
              SHR       AL, 1
              OR        AL, CL
              STOSB
              INC       DX
              JMP       @@get_line          ;do outer loop again
@@long_jmp_3: JMP       @@get_line          ;JMP is > 127 bytes backward
@@flush:      CALL      flush_obuf          ;write any remaining chars
              CMP       CH, 0
              JE        @@find_end
@@flush_err:  MOV       BYTE PTR misc, 1    ;return value in misc
              MOV       CX, 0300h           ;close both files
              JMP       SHORT @@cl_files    ;close files and return
@@find_end:   CALL      readline            ;read line from input file
              MOV       SI, line_ptr        ;SI will index line from readline
              CMP       AH, -2
              JNE       @@cmp_line
              LEA       SI, filepath
              MOV       CX, 0300h
              JMP       SHORT @@rtn_error
@@cmp_line:   LEA       DI, endline
              MOV       CX, 3
              CLD
        REPE  CMPSB
              JNE       @@no_end
              CMP       AH, 3
              JB        @@no_end
              JE        @@rtn_good
              LODSB                         ;make sure next char is CR or ...
              CMP       AL, CR              ;
              JE        @@rtn_good          ;
              CMP       AL, SPACE           ;
              JE        @@rtn_good          ;
              CMP       AL, TAB             ;
              JE        @@rtn_good          ;... whitespace
@@no_end:     LEA       SI, filepath        ;filename for error msg
              MOV       CX, 0303h           ;close both files, no end line
              JMP       SHORT @@rtn_error
@@rtn_good:   MOV       BYTE PTR misc, 0    ;return value in misc
              MOV       CX, 0304h           ;close both, disp msg on error
              JMP       SHORT @@cl_files    ;close files and return
@@rtn_error:  MOV       BYTE PTR misc, 1    ;return value in misc
              PUSH      SI
              CALL      disp_error          ;display error msg
              CMP       BYTE PTR errno, 0
              JNE       @@cl_files          ;done if system msg was displayed
              MOV       AH, 09h
              XOR       BH, BH
              MOV       BL, CL
              MOV       DX, msgs[BX]        ;[DX] = rest of error msg
              INT       21h                 ;display rest of error msg
@@cl_files:   MOV       AL, CH
              AND       AL, 01h
              JZ        @@test_outf
              MOV       AH, 3Eh
              MOV       BX, if_handle
              INT       21h                 ;close input file
@@test_outf:  MOV       AL, CH
              AND       AL, 02h
              JZ        @@rtn
              MOV       AH, 3Eh
              MOV       BX, of_handle
              INT       21h                 ;close output file
              JNC       @@rtn
              CMP       CL, 04h
              JNE       @@rtn               ;skip if msg already displayed
              MOV       BYTE PTR errno, AL
              LEA       BX, outfilename
              PUSH      BX
              CALL      disp_error          ;error closing output file

@@rtn:        POP       AX
              MOV       AL, BYTE PTR misc
              POP       DI
              POP       SI
              POP       DX
              POP       CX
              POP       BX
              ADD       SP, LOC_N
              POP       BP
              RET

decode        ENDP

;----------------------------------------------------------------------------
; end PROC decode
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; PROC flush_obuf:
;
; flush file output buffer; called from subroutine 'decode'
;
; parameters:
;
;    DX: # of chars in output buffer
;    DI: points to next available position in obuf
;
; global variables used:
;
;    outfilename: stores output filename
;    of_handle  : file handle of output file
;    obuf       : output file buffer
;    errno      : stores error codes
;
; return value: in CH: 0 on success, 1 on error
;----------------------------------------------------------------------------

flush_obuf    PROC      NEAR

              LOCALS    @@

              PUSH      AX
              PUSH      BX
              PUSH      CX

              MOV       AH, 40h
              MOV       BX, of_handle
              MOV       CX, DX
              LEA       DX, obuf
              INT       21h                 ;write buffer to disk
              JNC       @@test_full
              MOV       BYTE PTR errno, AL  ;error writing data to disk
@@disp_msg:   LEA       BX, outfilename
              PUSH      BX
              CALL      disp_error          ;display error msg
              MOV       AL, 1               ;return 1 (error)
              JMP       SHORT @@rtn
@@test_full:  CMP       AX, CX
              JE        @@set_vars
              MOV       BYTE PTR errno, 27h ;disk full
              JMP       SHORT @@disp_msg
@@set_vars:   XOR       DX, DX              ;0 chars in obuf
              LEA       DI, obuf            ;[DI] = start of obuf
              MOV       AL, DL              ;return 0 (success)

@@rtn:        POP       CX
              MOV       CH, AL
              POP       BX
              POP       AX
              RET

flush_obuf    ENDP

;----------------------------------------------------------------------------
; end PROC flush_obuf
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; PROC find_begin:
;
; find begin line; pass back output filename in outfilename
;
; global variables used:
;
;    outfilename: used to store output filename (taken from begin line)
;    line_ptr   : ptr to lines read from input file
;
; return value: in AL: 0 on success, -1 on 'no begin line', -2 on 'unknown
;                      file format', -3 on error reading from disk; if
;                      subroutine returns -3, errno will contain the proper
;                      error code on exit
;----------------------------------------------------------------------------

find_begin    PROC      NEAR

              LOCALS    @@

              PUSH      CX
              PUSH      DX
              PUSH      SI
              PUSH      DI
              PUSH      AX

@@getline:    CALL      readline            ;get line from input file
              CMP       AH, -2
              JNE       @@test_lngth
              MOV       DL, -3
              JMP       @@rtn
@@test_lngth: CMP       AH, -1
              JE        @@getline
              CMP       AH, 0
              JNE       @@not_eof
              CMP       AL, 0
              JE        @@not_eof
              MOV       DL, -1              ;return value
              JMP       SHORT @@rtn         ;no begin line
@@not_eof:    CMP       AH, 5               ;
              JB        @@getline           ;line too short for 'begin'
@@find_beg:   MOV       SI, line_ptr
              LEA       DI, beg             ;string containing 'begin'
              MOV       CX, 5
              CLD                           ;clear DF for rest of subroutine
        REPE  CMPSB
              JNE       @@getline           ;loop if 1st 5 chars not 'begin'
              XOR       CH, CH              ;CX = # chars left in line ...
              MOV       CL, AH              ;
              SUB       CX, 5               ;... to scan
              MOV       DI, CX
              DEC       DI
@@scan_ws_1:  LODSB                         ;loop discards whitespace, and
              CMP       AL, SPACE           ;ends when a non-whitespace char
              LAHF                          ;has been found or the entire
              MOV       DH, AH              ;line has been scanned
              CMP       AL, TAB
              LAHF
              OR        DH, AH
              AND       DH, 40h
              LOOPNZ    @@scan_ws_1
              JNZ       @@rtn_neg_2         ;rest of line is whitespace
              JCXZ      @@rtn_neg_2         ;only 1 more non-whitespace char
              CMP       CX, DI
              JE        @@rtn_neg_2         ;no whitespace after 'begin'
              MOV       DI, CX
@@scan_mode:  CMP       AL, '0'             ;loop discards mode (digits 0-7)
              JB        @@check_num
              CMP       AL, '7'
              JA        @@check_num
              LODSB
              LOOP      @@scan_mode
              JMP       SHORT @@rtn_neg_2   ;entire line scanned
@@check_num:  CMP       CX, DI
              JE        @@rtn_neg_2         ;first char was not in (0-7)
              CMP       AL, SPACE
              JE        @@scan_ws_2
              CMP       AL, TAB
              JNE       @@rtn_neg_2         ;mode not followed by whitespace
@@scan_ws_2:  LODSB                         ;loop discards whitespace after
              CMP       AL, SPACE           ;mode digits; loop ends when non-
              LAHF                          ;whitespace char found or entire
              MOV       DH, AH              ;line scanned
              CMP       AL, TAB
              LAHF
              OR        DH, AH
              AND       DH, 40h
              LOOPNZ    @@scan_ws_2
              JZ        @@get_fname         ;rest of line not whitespace
@@rtn_neg_2:  MOV       DL, -2
              JMP       SHORT @@rtn
@@get_fname:  LEA       DI, outfilename
              STOSB                         ;store 1st char of outfilename
              JCXZ      @@add_null          ;entire line scanned
@@next_char:  LODSB                         ;loop gets rest of outfilename,
              CMP       AL, SPACE           ;and terminates when whitespace
              JE        @@add_NULL          ;char found or entire line
              CMP       AL, TAB             ;scanned
              JE        @@add_NULL
              STOSB
              LOOP      @@next_char
@@add_NULL:   XOR       AL, AL
              STOSB                         ;add terminating NULL char
              MOV       DL, AL              ;return value of 0 in DL

@@rtn:        POP       AX
              MOV       AL, DL
              POP       DI
              POP       SI
              POP       DX
              POP       CX
              RET

find_begin    ENDP

;----------------------------------------------------------------------------
; end PROC find_begin
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; PROC readline:
;
; attempt to read a line (80 chars max) from input file; pointer to line
; (located in ibuf) is passed back in global variable line_ptr and on return,
; AL indicates whether line terminates due to EOF; in AH, function returns
; length of line which was read, or -1 if line had to be truncated to keep
; from exceeding 80 char maximum; although line is not moved from ibuf,
; ibuf_p is advanced past last char in line, and length of line is subtracted
; from ibuf_n; no terminating NULL char is added to end of line, because
; doing so could overwrite next char in ibuf
;
; global variables used:
;
;    line_ptr : on return, points to line in ibuf
;    if_handle: file handle of input file
;    ibuf     : input file buffer
;    ibuf_n   : # of chars in ibuf
;    ibuf_p   : ptr to next char in ibuf
;    errno    : stores error codes
;
; return value: in AX:
;
;                  AH: -1 if line was truncated to keep from exceeding 80
;                      char maximum; -2 if error occurred while trying to
;                      fill ibuf; else, # of chars in line; if AH = -2, errno
;                      will contain the proper error code
;                  AL: 1 if line terminated due to EOF; 0 otherwise
;----------------------------------------------------------------------------

readline      PROC      NEAR

              LOCALS    @@

              PUSH      BX
              PUSH      CX
              PUSH      DX
              PUSH      SI
              PUSH      DI

              CLD                           ;clear DF for entire subroutine
              MOV       SI, ibuf_p          ;register variable
              MOV       BX, ibuf_n          ;register variable
              CMP       BX, 82
              JAE       @@ibuf_ready        ;jump if ibuf has enough chars
              LEA       DI, ibuf
              MOV       CX, BX
        REP   MOVSB                         ;move chars to start of ibuf
              MOV       DX, DI              ;[DX] = first empty place in ibuf
              MOV       DI, BX              ;save value in BX
              MOV       AH, 3Fh
              MOV       BX, if_handle
              MOV       CX, IBUF_SIZE
              SUB       CX, DI              ;CX = # chars to read from file
              INT       21h                 ;attempt to fill ibuf
              JNC       @@rd_success
              MOV       BYTE PTR errno, AL  ;save error code
              MOV       AX, 0FE00h          ;AH = -2, AL = 0
              JMP       SHORT @@rtn         ;error reading from file
@@rd_success: MOV       BX, AX              ;# chars read in BX (ibuf_n)
              ADD       BX, DI              ;add chars already in ibuf
              LEA       SI, ibuf            ;ibuf_p points to start of ibuf
@@ibuf_ready: MOV       CX, BX
              MOV       DI, SI              ;ibuf_p in DI
              CMP       CX, 82
              JB        @@dec_CX
              MOV       CX, 82
@@dec_CX:     DEC       CX
              MOV       DX, CX              ;save value in CX
              CMP       CX, 1               ;if CX < 1, then no CR, LF
              JGE       @@here              ;signed comparison (CX may be -1)
              INC       DX                  ;DX = # chars in line (0 or 1)
              XOR       AL, AL              ;no CR, LF to strip from ibuf
              MOV       AH, DL              ;in AH, return # chars in line
              JMP       SHORT @@calc_eof
@@here:       INC       DI
@@find_CR:    DEC       DI                  ;start of loop to find CR
              MOV       AL, CR
        REPNE SCASB                         ;look for CR
              JE        @@CR_found
              INC       DX
              MOV       AH, DL              ;in AH, return # chars in line
              CMP       DX, 80              ;
              JBE       @@clear_AL          ;
              MOV       DX, 80              ;DX is 81 or 82, so set DX to 80
              MOV       AH, -1              ;ret -1 in AH: line truncated
@@clear_AL:   XOR       AL, AL              ;no CR, LF to strip from ibuf
              JMP       SHORT @@calc_eof    ;
@@CR_found:   MOV       AL, LF              ;CR found, ...
              SCASB                         ;... look for LF
              JNE       @@find_CR           ;repeat loop if LF not found
              MOV       AL, 1               ;CR, LF need to be stripped
              SUB       DX, CX
              DEC       DX                  ;DX = # chars in line (80 max)
              MOV       AH, DL              ;in AH, return # chars in line
@@calc_eof:   CMP       DX, 80              ;set LSB of DL if DX < 80 ...
              RCL       CL, 1               ;... (DX treated as unsigned)
              CMP       AL, 1               ;set LSB of CH ...
              RCL       CH, 1               ;... if AL == 0
              AND       CL, CH              ;CL = 1 if line ends due to ...
              AND       CL, 01h             ;... EOF, or 0 otherwise
              MOV       line_ptr, SI        ;[line_ptr] = 1st char in line
              ADD       SI, DX              ;update ibuf_p
              SUB       BX, DX              ;update ibuf_n
              CMP       AL, 0
              JE        @@set_AL
              ADD       SI, 2               ;strip CR, LF ...
              SUB       BX, 2               ;... from ibuf
@@set_AL:     MOV       AL, CL
              MOV       ibuf_p, SI          ;save new value for ibuf_p
              MOV       ibuf_n, BX          ;save new value for ibuf_n

@@rtn:        POP       DI
              POP       SI
              POP       DX
              POP       CX
              POP       BX
              RET

readline      ENDP

;----------------------------------------------------------------------------
; end PROC readline
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; PROC parse_args:
;
; parse command line argument string in PSP, first converting any tabs to
; spaces and any lowercase letters to uppercase; add NULL char (ASCII value
; 0) to end of each arg; store pointers to args in array argv and store # of
; args in argc
;
; NOTE: there is no need to save and restore registers, since this will
;       always be the first subroutine that gets called
;
; parameters: none
;
; global variables used:
;
;    args: section of PSP containing command line argument string
;    argc: on exit, will equal # of args found
;    argv: on exit, will contain array of pointers to args in PSP
;----------------------------------------------------------------------------

parse_args    PROC      NEAR

              LOCALS    @@

              CLD                           ;clear DF for entire subroutine
              LEA       DI, args            ;[DI] = length byte for args str.
              XOR       CH, CH
              MOV       CL, [DI]            ;CX = # chars in args string
              JCXZ      @@clear_BX
              INC       DI                  ;[DI] = first char in args string
              MOV       SI, DI
              MOV       BX, CX              ;save CX
              MOV       DX, DI              ;save DI
@@convert:    LODSB
              CMP       AL, 'a'
              JB        @@do_tabs
              CMP       AL, 'z'
              JA        @@do_tabs
              SUB       AL, 20h             ;convert to uppercase
@@do_tabs:    CMP       AL, TAB
              JNE       @@put_char
              MOV       AL, SPACE           ;convert TAB to SPACE
@@put_char:   STOSB
              LOOP      @@convert
              MOV       DI, DX              ;restore DI
              MOV       AL, TAB
              MOV       DL, SPACE
              XCHG      AX, DX              ;SPACE in AL
              MOV       CX, BX              ;restore CX
              INC       CX
@@clear_BX:   XOR       BX, BX              ;use BX to index argv array
              MOV       DL, BL              ;NULL char in DL
@@lp:   REPE  SCASB                         ;look for next nonspace char
              JCXZ      @@lp_done           ;jump if no more nonspace chars
              DEC       DI
              MOV       argv[BX], DI        ;ptr to arg in argv
              INC       DI
              ADD       BX, 2
        REPNE SCASB                         ;look for next SPACE char
              DEC       DI
              XCHG      AX, DX              ;NULL char in AL
              STOSB                         ;add treminating NULL char
              XCHG      AX, DX              ;SPACE in AL
              JCXZ      @@lp_done           ;jump if no more space chars
              JMP       SHORT @@lp          ;continue parsing args
@@lp_done:    SHR       BL, 1
              MOV       argc, BL            ;# args found in argc
              RET

parse_args    ENDP

;----------------------------------------------------------------------------
; end PROC parse_args
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; PROC getpath:
;
; get path from path string pointed to by parameter pathstring, combine with
; filename in DTA, and store in global variable filepath
;
; parameters on stack:
;
;    pathstring: pointer to ASCIIZ string containing path string
;
; global variables used:
;
;    dta     : DTA, which contains data about last file found
;    filepath: dir path from pathstring gets stored here
;----------------------------------------------------------------------------

getpath       PROC      NEAR

              ARG       pathstring: WORD = ARG_N

              LOCALS    @@

              PUSH      BP
              MOV       BP, SP
              PUSH      AX
              PUSH      BX
              PUSH      CX
              PUSH      DX
              PUSH      SI
              PUSH      DI

              XOR       AL, AL
              MOV       DI, pathstring
              MOV       BX, DI              ;save ptr to pathstring
              MOV       CX, 128
              CLD
        REPNE SCASB                         ;look for terminating null char
              SUB       DI, 2               ;[DI] = last char in dir path
              MOV       SI, DI
              SUB       CX, 128
              NEG       CX                  ;CX = length of pathstring + 1
              STD                           ;scan backwards from end
@@find_char:  LODSB                         ;loop searches for ':' or '\',
              CMP       AL, '\'             ;which will be last char in dir
              LAHF                          ;path; when loop exits, CX will
              MOV       DH, AH              ;equal the # of chars in dir path
              CMP       AL, ':'
              LAHF
              OR        DH, AH
              AND       DH, 40h
              LOOPZ     @@find_char
              MOV       SI, BX              ;[SI] = 1st char in pathstring
              LEA       DI, filepath
              CLD
        REP   MOVSB                         ;copy dir path into filepath
@@get_fname:  LEA       SI, dta.f_filename
              MOV       CX, 13
        REP   MOVSB                         ;copy filename into filepath

              POP       DI
              POP       SI
              POP       DX
              POP       CX
              POP       BX
              POP       AX
              POP       BP
              RET       ARG_N

getpath       ENDP

;----------------------------------------------------------------------------
; end PROC getpath
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; PROC disp_error:
;
; display error message for file find
;
; NOTE: Since the path name which just failed is an ASCIIZ (NULL terminated)
;       string, we can't print it with function 09h of INT 21h.  This is
;       because the function expects a $ terminated string and the pathname
;       might have a $ in it.  Therefore, the string is printed by repeatedly
;       calling function 02h of INT 21h (display char).  This isn't very
;       efficient, but who cares, since all we are printing is one string.
;
; parameters on stack:
;
;    pathname: pointer to ASCIIZ string containing pathname
;
; global variables used:
;
;    errno: error code passed in this variable
;----------------------------------------------------------------------------

disp_error    PROC      NEAR

              ARG       pathname: WORD = ARG_N

              LOCALS    @@

              PUSH      BP
              MOV       BP, SP
              PUSH      AX
              PUSH      BX
              PUSH      DX

              MOV       AH, 09h
              LEA       DX, uu
              INT       21h                 ;display 'uudecode: '
              MOV       BX, pathname        ;[BX] = path string
@@do_char:    MOV       DL, [BX]            ;get char from path string
              CMP       DL, 0
              JE        @@disp_err          ;exit loop if NULL char
              MOV       AH, 02h
              INT       21h                 ;display char
              INC       BX                  ;[BX] = next char in path string
              JMP       SHORT @@do_char
@@disp_err:   MOV       AH, 09h
              XOR       BH, BH
              MOV       BL, errno
              SHL       BL, 1
              MOV       DX, errors[BX]
              INT       21h                 ;disp error msg string

              POP       DX
              POP       BX
              POP       AX
              POP       BP
              RET       ARG_N

disp_error    ENDP

;----------------------------------------------------------------------------
; end PROC disp_error
;----------------------------------------------------------------------------

usage         DB        'Usage: uudecode PATH1 [PATH2 ...]$'
uu            DB        'uudecode: $'
beg           DB        'begin'
endline       DB        'end'

no_beg        DB        ': no "begin" line', CR, LF, '$'
bad_format    DB        ': unknown file format', CR, LF, '$'
short_file    DB        ': short file', CR, LF, '$'
no_end        DB        ': no "end" line', CR, LF, '$'
msgs          DW        no_beg, bad_format, short_file, no_end

error_00h     DB        '$'
error_01h     DB        ': Invalid function code', CR, LF, '$'
error_02h     DB        ': File not found', CR, LF, '$'
error_03h     DB        ': Path not found', CR, LF, '$'
error_04h     DB        ': Too many open files', CR, LF, '$'
error_05h     DB        ': Access denied', CR, LF, '$'
error_08h     DB        ': Out of memory', CR, LF, '$'
error_0Fh     DB        ': Invalid drive', CR, LF, '$'
error_13h     DB        ': Disk is write protected', CR, LF, '$'
error_14h     DB        ': Bad disk unit', CR, LF, '$'
error_15h     DB        ': Drive not ready', CR, LF, '$'
error_17h     DB        ': CRC error', CR, LF, '$'
error_19h     DB        ': Seek error', CR, LF, '$'
error_1Ah     DB        ': Not a DOS disk', CR, LF, '$'
error_1Bh     DB        ': Sector not found', CR, LF, '$'
error_1Fh     DB        ': General failure', CR, LF, '$'
error_27h     DB        ': Disk is full', CR, LF, '$'
error_50h     DB        ': File already exists', CR, LF, '$'
error_52h     DB        ': Cannot make directory entry', CR, LF, '$'
error_54h     DB        ': Out of structures', CR, LF, '$'
errors        DW        error_00h, error_01h, error_02h, error_03h, error_04h
              DW        error_05h, error_00h, error_00h, error_08h, error_00h
              DW        error_00h, error_00h, error_00h, error_00h, error_00h
              DW        error_0Fh, error_00h, error_00h, error_00h, error_13h
              DW        error_14h, error_15h, error_00h, error_17h, error_00h
              DW        error_19h, error_1Ah, error_1Bh, error_00h, error_00h
              DW        error_00h, error_1Fh, error_00h, error_00h, error_00h
              DW        error_00h, error_00h, error_00h, error_00h, error_27h
              DW        error_00h, error_00h, error_00h, error_00h, error_00h
              DW        error_00h, error_00h, error_00h, error_00h, error_00h
              DW        error_00h, error_00h, error_00h, error_00h, error_00h
              DW        error_00h, error_00h, error_00h, error_00h, error_00h
              DW        error_00h, error_00h, error_00h, error_00h, error_00h
              DW        error_00h, error_00h, error_00h, error_00h, error_00h
              DW        error_00h, error_00h, error_00h, error_00h, error_00h
              DW        error_00h, error_00h, error_00h, error_00h, error_00h
              DW        error_50h, error_00h, error_52h, error_00h, error_54h
version       DB        ' uudecode version 1.1 ', CR, LF
copyright     DB        ' Copyright 1995, David S. Peterson'

              EVENDATA
errno         DB        ?                   ;keeps track of error codes
ret_val       DB        ?                   ;exit code
argc          DB        ?                   ;# of command line args
argv          DW        64        DUP (?)   ;array of pointers to args in PSP
dta           fileinfo  ?                   ;DTA to hold FILEINFO struct
filepath      DB        138       DUP (?)   ;holds dir path of file in DTA
outfilename   DB        81        DUP (?)   ;holds filename of output file
              EVENDATA
line_ptr      DW        ?                   ;ptr to line found by readline
if_handle     DW        ?                   ;input file handle
of_handle     DW        ?                   ;output file handle
ibuf          DB        IBUF_SIZE DUP (?)   ;file input buffer
              EVENDATA
obuf          DB        OBUF_SIZE DUP (?)   ;file output buffer
              EVENDATA
ibuf_n        DW        ?                   ;# chars in ibuf
ibuf_p        DW        ?                   ;ptr to next char in ibuf

uudecode      ENDS
              END       start