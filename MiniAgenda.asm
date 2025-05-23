.model small
.stack 100h

.data
MAX_CONTACTS db 5
CONTACT_SIZE dw 40 ; 30 bytes para nombre, 10 para numero
CONTACT_COUNT db 0

; Estructura: [Nombre (30 bytes)] + [Numero (10 bytes)]
contacts db 200 dup('$') ; 5 contactos de 40 bytes

menu db 13,10,"--- MINI AGENDA ---",13,10
     db "1. Anadir contacto",13,10
     db "2. Buscar contacto por nombre",13,10
     db "3. Listar contactos",13,10
     db "4. Salir",13,10,"Seleccione una opcion: $"

newline db 13,10,"$"

name_prompt db 13,10,"Ingrese nombre (max 30 caracteres): $"
number_prompt db 13,10,"Ingrese numero (max 10 digitos): $"
found_msg db 13,10,"Nombre: $"
not_found_msg db 13,10,"Contacto no encontrado.$"
list_msg db 13,10,"--- LISTA DE CONTACTOS ---",13,10,"$"
full_msg db 13,10,"Agenda llena, no se pueden agregar mas contactos.$"

input_buffer db 40 dup('$')
number_buffer db 10 dup('$')

number_label db "Numero: $"
pause_msg db 13,10,"Presione Enter para regresar al menu...$"

.code
mov ax, @data
mov ds, ax
mov es, ax

main_menu:
    mov ah, 09h
    mov dx, offset menu
    int 21h

    call read_char
    cmp al, '1'
    je add_contact
    cmp al, '2'
    je search_contact
    cmp al, '3'
    je list_contacts
    cmp al, '4'
    je exit
    jmp main_menu

; -------------------------------------
add_contact:
    mov al, CONTACT_COUNT
    cmp al, MAX_CONTACTS
    jae agenda_llena

    mov ah, 09h
    mov dx, offset name_prompt
    int 21h

    lea di, input_buffer
    call read_string

    mov ah, 09h
    mov dx, offset number_prompt
    int 21h

    lea di, number_buffer
    call read_string

    mov al, CONTACT_COUNT
    cbw
    mov bx, ax
    mov ax, 40
    mul bx
    mov di, offset contacts
    add di, ax

    lea si, input_buffer
    mov cx, 30
copy_name:
    lodsb
    stosb
    loop copy_name

    lea si, number_buffer
    mov cx, 10
copy_number:
    lodsb
    stosb
    loop copy_number

    inc CONTACT_COUNT
    jmp main_menu

agenda_llena:
    mov ah, 09h
    mov dx, offset full_msg
    int 21h
    jmp main_menu

; -------------------------------------
search_contact:
    mov ah, 09h
    mov dx, offset name_prompt
    int 21h

    lea di, input_buffer
    call read_string

    mov cx, CONTACT_COUNT
    cmp cx, 0
    je contacto_no_encontrado

    xor bx, bx
buscar_loop:
    mov ax, 40
    mul bx
    mov si, offset contacts
    add si, ax

    lea di, input_buffer
    push cx
    mov cx, 30
    repe cmpsb
    pop cx
    je mostrar_contacto

    inc bx
    loop buscar_loop

contacto_no_encontrado:
    mov ah, 09h
    mov dx, offset not_found_msg
    int 21h
    jmp main_menu

mostrar_contacto:
    ; Mostrar etiqueta Nombre:
    mov ah, 09h
    mov dx, offset found_msg
    int 21h

    ; Calcular direccion del contacto
    mov ax, 40
    mul bx
    mov si, offset contacts
    add si, ax

    mov cx, 30
print_name:
    lodsb
    cmp al, '$'
    je skip_name
    mov dl, al
    mov ah, 02h
    int 21h
    loop print_name
skip_name:

    ; Nueva linea
    mov ah, 09h
    mov dx, offset newline
    int 21h

    ; Mostrar etiqueta Numero:
    mov ah, 09h
    mov dx, offset number_label
    int 21h

    ; Volver a direccion del contacto + 30
    mov ax, 40
    mul bx
    mov si, offset contacts
    add si, ax
    add si, 30

    mov cx, 10
print_number:
    lodsb
    cmp al, '$'
    je done_print
    mov dl, al
    mov ah, 02h
    int 21h
    loop print_number

done_print:
    mov ah, 09h
    mov dx, offset newline
    int 21h
    jmp main_menu

; -------------------------------------
list_contacts:
    mov cl, CONTACT_COUNT
    cmp cl, 0
    je main_menu

    mov ah, 09h
    mov dx, offset list_msg
    int 21h

    xor bx, bx
list_loop:
    mov ax, 40
    mul bx
    mov si, offset contacts
    add si, ax

    ; Mostrar etiqueta Nombre:
    mov ah, 09h
    mov dx, offset found_msg
    int 21h

    ; Imprimir nombre
    mov cx, 30
print_list_name:
    lodsb
    cmp al, '$'
    je skip_list_name
    mov dl, al
    mov ah, 02h
    int 21h
    loop print_list_name
skip_list_name:

    ; Nueva linea
    mov ah, 09h
    mov dx, offset newline
    int 21h

    ; Mostrar etiqueta Numero:
    mov ah, 09h
    mov dx, offset number_label
    int 21h

    ; Calcular direccion + 30
    mov ax, 40
    mul bx
    mov si, offset contacts
    add si, ax
    add si, 30

    ; Imprimir numero
    mov cx, 10
print_list_number:
    lodsb
    cmp al, '$'
    je done_list_number
    mov dl, al
    mov ah, 02h
    int 21h
    loop print_list_number

done_list_number:
    ; Nueva linea
    mov ah, 09h
    mov dx, offset newline
    int 21h

    inc bx
    mov cl, CONTACT_COUNT
    cmp bl, cl
    jl list_loop

    mov ah, 09h
    mov dx, offset pause_msg
    int 21h
    call read_char
    jmp main_menu

; -------------------------------------
exit:
    mov ah, 4Ch
    int 21h

; -------------------------------------
; Leer un caracter
read_char:
    mov ah, 01h
    int 21h
    ret

; Leer cadena terminada en ENTER
read_string:
    mov cx, 0
.next_char:
    mov ah, 01h
    int 21h
    cmp al, 13
    je .done
    stosb
    inc cx
    cmp cx, 39
    je .done
    jmp .next_char
.done:
    mov al, '$'
    stosb
    ret

end
