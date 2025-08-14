; =============================================================================
; OpenGL Triangle Demo with GLFW
;
; Simple OpenGL program that renders a colored triangle
; Press ESC to exit
;
;
;
; TODO: Make usage of `x86inc.asm`, an abstraction layer provided by x264 project
; TODO: Implement `Struct Directive`
;
; PLATFORM: x86-64 (amd64)
;
; DEPENDENCIES:
;     GLFW - Window management and input handling (https://www.glfw.org/)
;
; AUTHORS: SOHNE, Leandro Peres <leandro@peres.dev>
; LICENSE: zlib/libpng
;
; Copyright (c) 2025 SOHNE (@sohne) and contributors
;
; This software is provided "as-is", without any express or implied warranty. In no event
; will the authors be held liable for any damages arising from the use of this software.
;
; Permission is granted to anyone to use this software for any purpose, including commercial
; applications, and to alter it and redistribute it freely, subject to the following restrictions:
;
;   1. The origin of this software must not be misrepresented; you must not claim that you
;   wrote the original software. If you use this software in a product, an acknowledgment
;   in the product documentation would be appreciated but is not required.
;
;   2. Altered source versions must be plainly marked as such, and must not be misrepresented
;   as being the original software.
;
;   3. This notice may not be removed or altered from any source distribution.
;
; =============================================================================

default rel  ; Make all memory references RIP-relative by default

; =============================================================================
; Macros
; =============================================================================

; Define symbol mangling based on platform
%ifidn __OUTPUT_FORMAT__, macho64
    %define mangle(x) _ %+ x
%elifidn __OUTPUT_FORMAT__, macho32
    %define mangle(x) _ %+ x
%elifidn __OUTPUT_FORMAT__, win32
    %define mangle(x) x
%elifidn __OUTPUT_FORMAT__, win64
    %define mangle(x) x
%else
    %define mangle(x) x
%endif

; Main entry point symbol
%define MAIN mangle(main)

; Call mangled function
; Usage: mcall glfwCreateWindow
;        mcall glColor3f
%macro mcall 1
    call mangle(%1)
%endmacro

; Declare one-or-more extern symbols
; Usage: mextern foo, bar, ...
%macro mextern 1-*
%rep %0
    extern mangle(%1)
    %rotate 1
%endrep
%endmacro

; Load float constants into the given register
; Uses immediate values or memory references as appropriate
;
; Parameters:
; %1 - XMM register to load into (e.g., xmm0, xmm1)
; %2 - Numeric constant or memory label
;
; Usage: loadf xmm0, 1.0        ; loads 1.0
;        loadf xmm1, 1          ; loads 1 as 1.0 (auto-converts int to float)
;        loadf xmm2, 0.0        ; loads 0.0 by zeroing register
;        loadf xmm3, float_val  ; loads from memory label
%macro loadf 2
    %ifstr %2
        ; If second parameter is a string (label), load from memory
        movss %1, [%2]
    %else
        ; Handle numeric constants
        %if %2 == 0
            ; Zero the register
            xorps %1, %1
        %else
            ; Load any numeric constant
            mov eax, __float32__(%2.0)
            movd %1, eax
        %endif
    %endif
%endmacro

; Load multiple float values into consecutive XMM registers
;
; Parameters:
; %1-%15 - Numeric constants or memory labels
;
; Usage: loadf_xmms 1.0, 2.0, 3.0, 4.0 ; Loads into xmm0, xmm1, xmm2, xmm3
%macro loadf_xmms 1-15
    %assign idx 0
    %rep %0
        %xdefine reg xmm%+idx
        loadf reg, %1
        %assign idx idx+1
        %rotate 1
    %endrep
%endmacro

; Load 2D vertex coordinates
;
; Parameters:
; %1 - X coordinate
; %2 - Y coordinate
;
; Usage: vertex2f -1.0, -1.0
%macro vertex2f 2
    loadf_xmms %1, %2
    mcall glVertex2f
%endmacro

; Set RGB color (normalized)
;
; Parameters:
; %1 - Red component (0.0 to 1.0)
; %2 - Green component (0.0 to 1.0)
; %3 - Blue component (0.0 to 1.0)
;
; Usage: color3f 1, 0, 0  ; Red color
%macro color3f 3
    loadf_xmms %1, %2, %3
    mcall glColor3f
%endmacro

; Set clear color (normalized)
;
; Parameters:
; %1 - Red component (0.0 to 1.0)
; %2 - Green component (0.0 to 1.0)
; %3 - Blue component (0.0 to 1.0)
;
; Usage: clear_color 0, 0, 0, 1  ; Black background
%macro clear_color 4
    loadf_xmms %1, %2, %3, %4
    mcall glClearColor
%endmacro

; -----------------------------------------------------------------------------
; Get a value from a struct
;
; Parameters:
; %1 - Destination operand
; %2 - Struct name ("struc_<name>")
; %3 - Field name ("<name>.<field>")
%macro SGET 3
    mov %1, [struc_%2 + %2.%3]
%endmacro

; -----------------------------------------------------------------------------
; Set a value in a struct
;
; Parameters:
; %1 - Struct name ("struc_<name>")
; %2 - Field name ("<name>.<field>")
; %3 - Source operand
%macro SSET 3
    mov [struc_%1 + %1.%2], %3
%endmacro

; -----------------------------------------------------------------------------
; Get address of a field in a struct
;
; Parameters:
; %1 - Destination register
; %2 - Struct name ("struc_<name>")
; %3 - Field name ("<name>.<field>")
%macro SADDR 3
    lea %1, [struc_%2 + %2.%3]
%endmacro

; =============================================================================
; Struct Definitions
; =============================================================================

; Define a struct for platform
struc state
    .window_handle: resq 1  ; Window handle (64-bit)
endstruc

; =============================================================================
; External OpenGL and GLFW Functions
; =============================================================================

; GLFW
; -----------------------------------------------------------------------------
mextern glfwInit, glfwTerminate
mextern glfwCreateWindow, glfwMakeContextCurrent, glfwSwapBuffers
mextern glfwWindowShouldClose, glfwSetWindowShouldClose, glfwGetFramebufferSize
mextern glfwSetKeyCallback, glfwSetFramebufferSizeCallback
mextern glfwPollEvents

; OpenGL
; -----------------------------------------------------------------------------
mextern glClearColor, glClear, glViewport
mextern glBegin, glEnd, glFlush
mextern glColor3f, glVertex2f

; =============================================================================
; Data Section
; =============================================================================
section .data
    window_title    db "GLFW + OpenGL + x64-NASM", 0
    window_title_len equ $ - window_title

    ; OpenGL constants
    GL_COLOR_BUFFER_BIT equ 0x00004000
    GL_TRIANGLES        equ 0x0004

    ; GLFW constants
    GLFW_KEY_ESCAPE     equ 256
    GLFW_RELEASE        equ 0

    GLFW_TRUE           equ 1

    ; Window dimensions
    WINDOW_WIDTH        equ 800
    WINDOW_HEIGHT       equ 600

struc_state:
    istruc state
        at .window_handle, dq 0  ; NULL
    iend

; =============================================================================
; Uninitialized Data
; =============================================================================
section .bss
    width       resd 1          ; Framebuffer width
    height      resd 1          ; Framebuffer height

; =============================================================================
; Code Section
; =============================================================================
section .text
global MAIN

; -----------------------------------------------------------------------------
; Key Callback Function
; -----------------------------------------------------------------------------
; Parameters: rdi=window, rsi=key, rdx=scancode, rcx=action, r8=mods
; -----------------------------------------------------------------------------
key_callback:
    push rbp
    mov rbp, rsp                ; Set up stack frame

    ; Check if ESC key was pressed
    cmp rsi, GLFW_KEY_ESCAPE
    jne .exit
    cmp rcx, GLFW_RELEASE
    je .exit

    ; Set window should close flag
    mov rsi, GLFW_TRUE
    mcall glfwSetWindowShouldClose

.exit:
    pop rbp                     ; Restore stack frame
    ret

; -----------------------------------------------------------------------------
; Window Resize Callback
; Update viewport to match framebuffer size
; -----------------------------------------------------------------------------
; Parameters: rdi=window, rsi=width, rdx=height
; -----------------------------------------------------------------------------
window_resize_callback:
    push rbp
    mov rbp, rsp                ; Set up stack frame

    ; On window minimization, width and height can be zero
    cmp rsi, 0
    jle .exit
    cmp rdx, 0
    jle .exit

    ; Store new width and height
    lea rsi, [width]
    lea rdx, [height]
    mcall glfwGetFramebufferSize

    ; Setup OpenGL viewport
    xor rdi, rdi                ; x = 0
    xor rsi, rsi                ; y = 0
    mov edx, [width]            ; width
    mov ecx, [height]           ; height
    mcall glViewport

.exit:
    pop rbp                     ; Restore stack frame
    ret

; -----------------------------------------------------------------------------
; Main Program Entry Point
; -----------------------------------------------------------------------------
MAIN:
    push rbp
    mov rbp, rsp
    sub rsp, 16                 ; Align stack and reserve space

    ; Initialize GLFW
    ; -------------------------------------------------------------------------
    mcall glfwInit
    test rax, rax
    jz .cleanup                 ; Initialization failed

    ; Create Window
    ; -------------------------------------------------------------------------
    mov rdi, WINDOW_WIDTH
    mov rsi, WINDOW_HEIGHT
    lea rdx, [window_title]
    xor rcx, rcx                ; NULL monitor (windowed mode)
    xor r8, r8                  ; NULL share context
    mcall glfwCreateWindow
    test rax, rax
    jz .cleanup                 ; Exit if window creation failed
    SSET state, window_handle, rax

    ; Setup OpenGL Context
    ; -------------------------------------------------------------------------
    SGET rdi, state, window_handle
    mcall glfwMakeContextCurrent

    ; Set keyboard callback
    SGET rdi, state, window_handle
    lea rsi, [key_callback]
    mcall glfwSetKeyCallback

    ; Set window resize callback
    SGET rdi, state, window_handle
    lea rsi, [window_resize_callback]
    mcall glfwSetFramebufferSizeCallback

    ; Set clear color
    clear_color 0, 0, 0, 1      ; Black background (RGBA)

; -----------------------------------------------------------------------------
; Main Render Loop
; -----------------------------------------------------------------------------
.main_loop:
    ; Clear the screen
    ; -------------------------------------------------------------------------
    mov rdi, GL_COLOR_BUFFER_BIT
    mcall glClear

    ; Render Triangle
    ; -------------------------------------------------------------------------
    ; Begin Drawing
    mov rdi, GL_TRIANGLES
    mcall glBegin

    ; 1st vertex - bottom left
    color3f 1, 0, 0             ; Red color
    vertex2f -1, -1             ; Bottom left position

    ; 2nd vertex - bottom right
    color3f 0, 0, 1             ; Blue color
    vertex2f 1, -1              ; Bottom right position

    ; 3rd vertex - top center
    color3f 0, 1, 0             ; Green color
    vertex2f 0, 1               ; Top center position

    ; End Drawing
    mcall glEnd

    ; Present frame
    ; -------------------------------------------------------------------------
    SGET rdi, state, window_handle
    mcall glfwSwapBuffers

    ; Poll for events
    ; -------------------------------------------------------------------------
    mcall glfwPollEvents

    ; Check if window should close
    ; -------------------------------------------------------------------------
    SGET rdi, state, window_handle
    mcall glfwWindowShouldClose
    test rax, rax
    jz .main_loop               ; Should stay open?

; -----------------------------------------------------------------------------
; Cleanup and Exit
; -----------------------------------------------------------------------------
.cleanup:
    mcall glfwTerminate

    ; Handle platform-specific exit
    ; TODO: Make this more robust and cross-platform
%ifidn __OUTPUT_FORMAT__, macho64
    mov rax, 0x2000001          ; sys_exit on macOS
    xor rdi, rdi                ; Exit code 0
    syscall
%else
    xor eax, eax                ; Return 0
    add rsp, 32
    pop rbp
    ret
%endif

; vim:ft=nasm

