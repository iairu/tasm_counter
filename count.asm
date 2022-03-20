; The whole program supplied as an external procedure, separately compiled and then linked.
; See / use compile.bat for compilation and linking.
; Ondrej Spanik 2022 iairu.com

PUBLIC count

_ZAS   SEGMENT STACK
        DW      8 DUP(?)       ;8 WORDs
_ZAS   ENDS

_DATA    SEGMENT

    ; Help contents printed using -h argument
    help   db   'Pomocnik pre SPAASM Z1:', 13, 10, \
                'Ondrej Spanik 2022 (c) iairu.com', 13, 10, \
                'Program vypise pocty cislic, malych pismen, velkych pismen', 13, 10, \
                'a ostatnych znakov pre kazdy riadok aj pre cely vstup.', 13, 10, \
                13, 10, \
                'Mozne argumenty:', 13, 10, \
                '[subor] - Vstup programu', 13, 10, \
                '-h - Vypis pomocnika', 13, 10, \
                '-s - Prepnutie na ciste sumarny vypis (viac krat -> ON, OFF, ON, ...)', 13, 10, \
                '-c - Precistenie obrazovky a kurzor v lavy-horny roh', 13, 10, \
                13, 10, \
                'Na kombinacii argumentov nezalezi.', 13, 10, \
                'Kazdy argument je vzdy spracovany zvlast v poradi zadania.', 13, 10, \
                'Sucty pretecu kazdych 64kB kedze je pouzity typ WORD vo forme cisla.', 13, 10, \
                'Spracovanie funguje pre subory >64kB.$' ; 13, 10 je CRLF (windows \r\n line ending)

    ; Error and information messages for the user.
    errnofile   db 'Zadany argument nie je pristupny ako subor. Ignorujem.$'
    errlongarg  db 'Zadany argument je prilis dlhy. Ukoncujem.$'
    errnoarg    db 'Nebol zadany ziadny argument. Odporucam -h pre pomoc. Ukoncujem.$'
    errok       db 'Koniec.$'
    sodescon    db 'Bol zapnuty ciste sumarny vypis.$'
    sodescoff   db 'Bol vypnuty ciste sumarny vypis.$'

    ; Argument buffers, flag, special -h -s -c arguments for CMPS comparison
    abufdesc    db 'Argument: $' ; info to be shown to the user on each argument
    abuf        db 128 dup(0)    ; argument buffer (contains a single argument and NULL)
    aflg        db 0             ; 1 if last argument else 0 (for jumps)
    ahelp       db '-h',0        ; special -h -s -c arguments for CMPS comparison
    asumonly    db '-s',0        ; /\
    aclear      db '-c',0        ; /\

    sumdesc     db 'Spolu: $'   ; info to be shown to the user on summary additions
    sumonly     db 0            ; user-flag only for summary printing (>0 = won't print per line counts)

    fptr        dw 0            ; pointer within the file (saved for reuse after buffer ends)
    fbuf        db 128 dup(0)   ; file content buffer (used in processing, up to 127 characters and NULL)
    fbufptr     dw 0            ; pointer within the buffer (used in processing character by character)

    flag    db 0        ; 0 if end of file else 1 (for continuation jump)
    i       dw 0        ; counter when numbers are processed into characters for MS-DOS output
    jmin    dw 0        ; Min variable offset
    j       dw 0        ; Max variable offset + iterator !!DON'T MOVE!! variables below are accessed by j + offset
    ine     dw 0        ; /\ These variables are accessed "while ((*j) > (*jmin)) {print *(j+(*j)); (*j)--;}" style
    velke   dw 0        ; /\
    male    dw 0        ; /\
    cisla   dw 0        ; /\
    all_ine     dw 0    ; /\ Same for these when (*j) is between <8;4> and (*jmin) is 4
    all_velke   dw 0    ; /\
    all_male    dw 0    ; /\
    all_cisla   dw 0    ; /\
    ; 8 variables above are used for counting, last 4 summary per file, first 4 per line

    ; External procedures and macros
    INCLUDE cpm.inc ; Name implies: c count p procedures m macros => cpm

_DATA    ENDS

_CODE SEGMENT 
    assume cs:_code, ds:_data, ss:_zas
    .386 ; allows for larger gaps between labels (necessary because there are some large jumps)

count:
    mov ax, seg _data    ; sets DS to data segment (otherwise offset would be wrong)
    mov ds, ax           ; /\
    ; Program segment prefix is still pointed to by ES (extra data segment register) and will be used later

    ; ----------------------------------------------------
    ; ARGUMENTS
    ; ----------------------------------------------------
    mov cl, es:[80h]        ; loads the arguments length to CX
    cmp cx, 0               ; if there are no arguments (their length == 0)
    jz end_no_arg           ; then end (and show appropriate error message to user)
    mov si, 82h             ; save offset to the first char of arguments (second really, because the first one is a space) to SI (memory address register)
    dec cx                  ; decrement the given space from arguments length (CX will be used to determine whether all arguments have been processed)

    obtain_arg:
        lea di, abuf        ; retreive/reset pointer to abuf in DI register (DI will move as individual characters are added to the buffer)
        xor ah, ah          ; reset AH for abuf length counter (will increment until length(abuf) except last character (for termination) is reached)
        @loop:
            cmp ah, 127                 ; max allowed length
            je end_arg_too_long         ; implies the argument is too long to fit abuf (handled as a fatal error, inform user)
            cmp cx, 0                   ; reached the end of arguments
            je process_abuf_last        ; process the argument as the last one (set appropriate flags so no more will try to be processed)
            ; otherwise load another character within the arguments
            mov al, es:[si]             ; loads the character using ES (pointing to program segment prefix) and SI (pointing to offset within arguments)
            cmp al, ' '                 ; if the loaded character is a space then the argument ends
            je process_abuf             ; argument ended, process it and come back later for more
            mov byte ptr [di], al       ; otherwise if the argument continues, save the character to abuf (argument buffer)
            inc ah                      ; + increment used length (for allowed length check)
            inc di                      ; + move the pointer within abuf (argument buffer)
            inc si                      ; + move the pointer within program segment prefix arguments
            dec cx                      ; + decrease the length of remaining psp argument characters
            jmp @loop                   ; and continue loading more characters of the given argument until a space or end of arguments is reached

    process_abuf_last:
        mov aflg, 1         ; process the argument as the last one (set appropriate flags so no more will try to be processed)
    process_abuf:
        inc si              ; move past the space character for later argument loading (otherwise it would get stuck on cmp al, ' ' above)
        dec cx              ; + decrease the length of remaining psp argument characters (because we moved)
        push si             ; obtain_arg requires si
        push cx             ; obtain_arg requires cx (ah, di not needed)
        push es             ; obtain_arg requires es (but cmps will be used, so it needs to be saved)
        mov al, 0           ; save NULL to abuf after the argument (implies the end of the argument during later processing)
        mov byte ptr [di], al ; /\

        write_abuf              ; write the "Argument: <argument>" to user incl. color

        mov ax, seg _data       ; direct addressing of ES within CMPS because of disallowed override (had an issue with this)
        mov es, ax              ; /\

        ; if
        cld                     ; CMPS will scan in forward direction
        mov cx, 3               ; 3 => compare first three characters in abuf whether they're "-h0" where 0 is NULL (for repe)
        lea si, abuf            ; address of argument buffer
        lea di, ahelp           ; address of argument we're looking for "-h0"
        repe cmps byte ptr ds:[si], byte ptr es:[di]   ; comparison of buffer with "-h0" using CMPS repetition (repe)
        je write_help_and_next  ; write help to user and continue by loading the next argument

        ; elif
        cld                     ; CMPS will scan in forward direction
        mov cx, 3               ; 3 => compare first three characters in abuf whether they're "-s0" where 0 is NULL (for repe)
        lea si, abuf            ; address of argument buffer
        lea di, asumonly        ; address of argument we're looking for "-s0"
        repe cmps byte ptr ds:[si], byte ptr es:[di]   ; comparison of buffer with "-s0" using CMPS repetition (repe)
        je sumonly_and_next     ; switch sumonly flag and continue by loading the next argument

        ; elif
        cld                     ; CMPS will scan in forward direction
        mov cx, 3               ; 3 => compare first three characters in abuf whether they're "-c0" where 0 is NULL (for repe)
        lea si, abuf            ; address of argument buffer
        lea di, aclear          ; address of argument we're looking for "-c0"
        repe cmps byte ptr ds:[si], byte ptr es:[di]   ; comparison of buffer with "-c0" using CMPS repetition (repe)
        je clear_and_next       ; clear the screen and continue by loading the next argument

        ; else
        jmp process_file        ; process argument as a file path (incl. checks), do all the stuff and continue by loading the next argument

    write_help_and_next:
        write_color 09h         ; switch color to light blue
        write_string help       ; write the <help> string
        write_color 07h         ; switch back to greyish
        jmp obtain_next_arg     ; continue with next argument

    sumonly_and_next:
        write_color 09h         ; switch color to light blue
        mov al, sumonly         ; grab the exiting <sumonly> flag value
        cmp al, 1               ; if sumonly == 1
        je sumonly_off          ; jump: then set it to 0 + inform user
        mov sumonly, 1          ; otherwise set it to 1
        write_string sodescon   ; inform user that summary-only output is enabled
        write_color 07h         ; switch back to greyish
        jmp obtain_next_arg     ; continue with next argument

    sumonly_off:
        mov sumonly, 0          ; set sumflag to 1
        write_string sodescoff  ; inform user that summary-only output is disabled
        write_color 07h         ; switch back to greyish
        jmp obtain_next_arg     ; continue with next argument

    clear_and_next:
        call clear_screen       ; clear the screen using external procedure and continue with next argument (directly below)

    obtain_next_arg:
        mov al, aflg        ; check the argument flag for whether there is any more arguments to be obtained
        cmp al, 1           ; if aflg == 1
        je koniec_ok        ; then end successfully (inform user)
        ; otherwise once again obtain an argument like before
        ; but continue with saved register values from stack
        pop es              ; obtain_arg requires es (naspat na program segment prefixe)
        pop cx              ; obtain_arg requires cx
        pop si              ; obtain_arg requires si
        jmp obtain_arg      ; do the obtaining


    ; ----------------------------------------------------
    ; OPENING + LOADING OF A FILE TO BUFFER (abuf => fbuf)
    ; ----------------------------------------------------
    process_file:
        ; open the file using an MS-DOS service
        mov dx, offset abuf     ; ds:dx path to file
        mov al, 0               ; read-only access
        mov ah, 3Dh             ; MS-DOS service
        int 21h                 ; MS-DOS interrupt
        ; AX is now the file descriptor and, C (carry flag) implies error
        jc error_file_inaccessible      ; if carry flag: error file inaccessible, inform user
        mov fptr, ax                    ; save the file descriptor (will be used later during buffer refilling)
        jmp load_and_process_fbuf       ; skip reset and EOF check on first load

    load_and_process_next_fbuf:
        ; check the end of file (fbufptr - offset fbuf = buffer length)
        mov ax, fbufptr
        mov bx, offset fbuf
        sub ax, bx          ; subtract (ax = fbufptr - offset fbuf)
        cmp ax, 127         ; compare buffer length with max buffer length
        jl write_stats_last ; if less chars than max buffer length => EOF reached, end processing this file after stats written to user

        ; reset fbuf buffer to DUP(0) so that NULL implies the end of buffer content (this could be done more simply by appending in the future)
        lea si, fbuf        ; get the buffer address to SI
        mov cx, 127         ; load the buffer max length to CX
        @fbuf_loop:
            mov byte ptr [si], 0    ; reset the character pointed to by SI
            inc si                  ; move SI to the next character address
            dec cx                  ; decrement CX
            jnz @fbuf_loop          ; loop until CX reaches 0 (end of buffer)
    load_and_process_fbuf:
        ; load a part of the file into the buffer
        mov dx, offset fbuf     ; ds:dx output from file to this buffer
        mov bx, fptr            ; file descriptor
        mov cx, 127             ; we want 127 bytes at most
        mov ah, 3Fh             ; MS-DOS service to read from an open file
        int 21h                 ; MS-DOS interrupt

        ; write_fbuf              ; write buffer to user (commented out because with larger files: super slow and unoptimized (beep sounds & stuff))

        ; get ready to process a character
        mov ax, offset fbuf     ; save fbuf pointer that will move
        mov fbufptr, ax         ; save the beginning of fbuf for later (this could be optimized to only be used on newlines and use a register instead)
        jmp process_char        ; process the character in a loop then write stats or load more buffer content

    move_fbufptr:
        mov ax, fbufptr         ; increment the fbuf pointer (as variable) to the next character
        inc ax                  ; /\
        mov fbufptr, ax         ; /\
        jmp process_char        ; process the next character

    close_file:
        mov bx, fptr            ; get the file descriptor
        mov ah, 3Eh             ; MS-DOS service to close the file
        int 21h                 ; MS-DOS interrupt
        jmp obtain_next_arg     ; continue with the next argument

    error_file_inaccessible:
        write_error_string errnofile    ; inform user
        jmp obtain_next_arg

    ; ----------------------------------------------------
    ; PROCESS CHARACTERS = SAVE STATISTICS (input: ax, fbufptr pointing within fbuf)
    ; ----------------------------------------------------
    process_char:
        mov si, ax              ; use the fbuf pointer within ax for addressing
        mov dx, [si]            ; resolve the contents of the fbuf pointer's address (get the chars at given position to DX)

        ; special characters: new line and NULL
        cmp dl, 0                       ; is NULL char?
        je load_and_process_next_fbuf   ; reset fbuf, load more content into it and continue processing
        cmp dl, 13                      ; is newline (LF) ?
        je write_stats                  ; end of line reached: write stats for given line
        cmp dl, 10                      ; is newline (CR) ?
        je move_fbufptr                 ; ignore CR in CRLF: go to next char

        ; locate the position of the character within ASCII table to group it into a given stat type
        cmp dl, '0'
        jl pc_other       ; < 0
        cmp dl, '9'
        jle pc_num    ; >= 0 && <= 9
        cmp dl, 'A'
        jl pc_other       ; > 9 && < A
        cmp dl, 'Z'
        jle pc_big    ; >= A && <= Z
        cmp dl, 'a'
        jl pc_other       ; > Z && < a
        cmp dl, 'z'
        jle pc_small     ; >= a && <= z
        jmp pc_other      ; > z

    ; increment the respective counter, summary counter and move pointer to the next fbuf character
    pc_other:
        add ine, 1
        add all_ine, 1
        jmp move_fbufptr
    pc_num:
        add cisla, 1
        add all_cisla, 1
        jmp move_fbufptr
    pc_big:
        add velke, 1
        add all_velke, 1
        jmp move_fbufptr
    pc_small:
        add male, 1
        add all_male, 1
        jmp move_fbufptr

    ; ----------------------------------------------------
    ; STATISTICS OUTPUT (Super ineffective due to variable usage, could be improved)
    ; ----------------------------------------------------
    write_stats_sum:
        mov flag, 0     ; last flag (afterwards jump to end)
        mov jmin, 4     ; variable offset from j for summary (first variable)
        mov j, 8        ; /\ (last variable)
        write_string sumdesc    ; inform user that this is the summary stat and not just another line
        jmp write_stats_next    ; prepare for number output using MS-DOS char output service

    write_stats_last:
        mov flag, 0     ; last flag (afterwards jump to end)
        mov jmin, 0     ; variable offset from j for summary (first variable)
        mov j, 4        ; /\ (last variable): 4x run, and lower the pointer by 2 each time (see ws_next)
        jmp write_stats_flagcheck   ; check whether the user wants non-summary output (-s flag check)

    write_stats:
        mov flag, 1     ; not last flag (afterwards return to move_fbufptr)
        mov jmin, 0     ; same as before
        mov j, 4        
        ; check whether the user wants non-summary output (-s flag check)
    write_stats_flagcheck:
        mov al, sumonly
        cmp al, 0
        jnz ws_end      ; only summary stats will be written (if flag on: jump to end => skip conversion and output)
    write_stats_next:
        ; PREPARATION FOR number output using MS-DOS char output service
        mov i, 0        ; reset i (was used before, otherwise the output would overflow)
        mov cx, 10      ; divisor for modulo
        jmp ws_next     ; load the appropriate variable for output after j using value in j as offset
    ws_process:
        ; CONVERSION FOR number output using MS-DOS char output service
        mov dx, 0       ; space for modulo output (one int character)
        div cx          ; ax /= 10, dx = ax % 10
        add dx, '0'     ; one int character to ascii conversion
        push dx         ; save the character for output into the stack (because we're processing them in reverse order)
        add i, 1        ; increment the personal stack counter related to conversion
        cmp ax, 0       ; check if anything left for processing
        jnz ws_process  ; if so, then continue processing
    ws_output:
        ; THE ACTUAL number output using MS-DOS char output service
        ; while (i > 0) where i is the stack counter
        mov bx, i           ; load i
        cmp bx, 0           ; compare it with 0
        jz ws_next_space    ; jump if i == 0
        dec bx              ; i--
        mov i, bx           ; save i
        pop dx              ; character to be output from stack (now in the right order)
        mov ah, 2           ; MS-DOS service for output from DL
        int 21h             ; MS-DOS interrupt
        jmp ws_output       ; continue the output while i > 0
    ws_next_space:
        call write_space    ; output space and continue with the next variable
    ws_next:
        ; this approach may be a little bit stupid and unnecessarily complicated, there is likely a better way to do this in the future
        mov ax, j           ; j is the number of DW variables (after each other, from end) to be written as numbers
        mov bx, jmin
        cmp ax, bx          ; if j == jmin 
        je ws_output_end    ; then all have been written already: end the output
        sub j, 1        ; j-- through bx (last value will be used once more)
        mov bx, 2       ; DW means that offset is 2
        mul bx          ; ax *= 2, ax is now the offset from j to the next variable (from end) for output
        lea bx, j       ; we take the j address
        add bx, ax      ; and move it by the calculated offset
        mov ax, [bx]    ; then dereference it -> ax will contain the appropriate variable's value
        jmp ws_process  ; do the processing over the given value
    ws_output_end:
        call write_crlf ; new line on output finish and continue with ws_end
    ws_end:
        ; reset stats for next line (incl. first line of potential next file)
        mov ine, 0
        mov velke, 0
        mov male, 0
        mov cisla, 0
        ; depending on flag: end of file or move to next char within buffer
        mov al, flag
        cmp al, 0
        je ws_end_file
        jmp move_fbufptr
    ws_end_file:
        ; summary stats output (jmin check to prevent encyclement)
        mov ax, jmin
        cmp ax, 0
        je write_stats_sum
        ; reset stats for the next file
        mov all_ine, 0
        mov all_velke, 0
        mov all_male, 0
        mov all_cisla, 0
        jmp close_file      ; close this file (and continue with the next one if in arguments)

    ; ----------------------------------------------------
    ; COMPLETE END
    ; ----------------------------------------------------
    end_arg_too_long:
        write_error_string errlongarg   ; inform user (fatal error)
        jmp koniec
    end_no_arg:
        write_error_string errnoarg     ; inform user (fatal error)
        jmp koniec
    koniec_ok:
        write_color 0Ah
        write_string errok              ; light green "success" output before successful end
        write_color 07h
    koniec:
        ; MS-DOS exit
        mov ah, 4ch
        int 21h

_CODE ENDS
    END
