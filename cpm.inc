; Internal procedures and macros referenced in count.asm
; Some of these procedures have not been cleaned up of variables in count.asm, others use parameters
; Ondrej Spanik 2022 iairu.com

clear_screen    proc far
    mov ah, 0Fh     ; Obtain the video-mode from BIOS into AL
    int 10h         ; BIOS interrupt
    mov ah, 00h     ; Change the video-mode using AL (to the same) with BIOS, which means screen clear
    int 10h         ; BIOS interrupt
    ret             ; Return from procedure
clear_screen    endp

write_space  proc far
    mov dl, ' '     ; Set DL for MS-DOS character output to a space character
    mov ah, 2       ; MS-DOS char output service
    int 21h         ; MS-DOS interrupt
    ret             ; Return from procedure
write_space  endp

write_crlf  proc far
    ; New-line in DL (DOS/Windows uses two characters: CR and LF)
    mov dl, 13  ; "\r" CR
    mov ah, 2   ; MS-DOS char output service
    int 21h     ; MS-DOS interrupt
    mov dl, 10  ; "\n" LF
    mov ah, 2   ; MS-DOS char output service
    int 21h     ; MS-DOS interrupt
    ret         ; Return from procedure
write_crlf  endp

write_color macro color
    mov ah, 09h     ; BIOS service to write the characters in color
    mov al, ' '     ; use space when there is background without text (without that it would output bl as a character too)
    mov bl, color   ; hint: usable colors https://en.wikipedia.org/wiki/BIOS_color_attributes
                    ; first digit is background color, second text color
    mov cx, 2000    ; max. character count of the given color (could be larger but i found no use for more right now)
    int 10h         ; BIOS interrupt
endm

write_abuf	macro
    LOCAL @@loop, @@endl    ; jumps must be local, didn't work within a far procedure for some reason

    write_color 0Ah         ; light-green text color

    ; write helpful description
    mov dx, offset abufdesc ; "Argument: "
    mov ah, 9
    int 21h

    ; write abuf from DS:DX even though it ends with NULL
    mov dx, offset abuf     ; "<argument>"
    mov si, dx
    @@loop: ; looking for last NULL
        cmp byte ptr [si], 0
        je @@endl
        inc si
        jmp @@loop
    @@endl:
    mov byte ptr [si], '$'  ; temporary change to '$' for MS-DOS string output
    mov ah, 9               ; MS-DOS string output service
    int 21h                 ; MS-DOS interrupt
    mov byte ptr [si], 0    ; undo the change

    ; write new line
    call write_crlf         ; "\r\n"

    ; set the text color back to default grey-ish
    write_color 07h
endm

write_fbuf macro
    ; slightly darker grey
    write_color 08h

    ; write fbuf from DS:DX even though it ends with NULL
    mov dx, offset fbuf     ; "<buffer>"
    mov si, dx
    @@loop: ; looking for last NULL
        cmp byte ptr [si], 0
        je @@endl
        inc si
        jmp @@loop
    @@endl:
    mov byte ptr [si], '$'  ; temporary change to '$' for MS-DOS string output
    mov ah, 9               ; MS-DOS string output service
    int 21h                 ; MS-DOS interrupt
    mov byte ptr [si], 0    ; undo the change

    ; write new line
    call write_crlf         ; "\r\n"

    ; set the text color back to default grey-ish
    write_color 07h
endm

write_string macro place
    mov dx, offset place    ; DS:DX set to the variable to be output until '$' reached
    mov ah, 9               ; MS-DOS string output service
    int 21h                 ; MS-DOS interrupt
    call write_crlf         ; write new line
endm

write_error_string macro place
    write_color 0Ch         ; set light-red text color
    write_string place      ; use the write_string macro
    write_color 07h         ; set the text color back to default grey-ish
endm
