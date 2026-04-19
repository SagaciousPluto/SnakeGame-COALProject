Title Snake Game (main.asm)
include Irvine32.inc

.data

    cursorInfo CONSOLE_CURSOR_INFO <>

    ground byte "-----------------------------------------------------------------------------------------------------------------------------------------------",0
    brick byte '|'

    temp byte ?

    scoreMsg byte "Score: ",0
    score byte 0
    gameOverMsg byte "Game Over! Press any key to exit.",0

    sprintByte byte 0

    normalDelay byte 100
    sprintDelay byte 50

    delayTime byte 100

    snakeX byte 100 DUP(?)
    snakeY byte 100 DUP(?)
    character byte 219
    snakeLength byte 3

    xBoundary byte 142
    yBoundary byte 28

    direction byte 1 ; 0=up,1=right,2=down,3=left

    foodX byte 50
    foodY byte 15
    
    
    ; For now the snake will be represented as a single character, but we can expand this later to an array to represent the body segments.
.code
main proc
    call Randomize
    call Clrscr
    call HideCursor
    call DrawGround
    call DrawCeiling
    call DrawWalls
    call DrawScore
    call InitializeSnake
    call DrawFood
    gameLoop:    
        ; Get input and move based on direction
        call GetInput
        call CollisionCheck
        call EatingCheck
        cmp direction, 0
        je MoveUp
        cmp direction, 1
        je MoveRight
        cmp direction, 2
        je MoveDown
        cmp direction, 3
        je MoveLeft
        cmp sprintByte, 1
        je IncreaseSpeed
        mov al, normalDelay
        mov delayTime, al
        
    MoveUp:
        call RemoveSnake
        call ShiftBody
        ; call DecreaseY
        dec snakeY[0]
        jmp ContinueLoop
        
    MoveRight:
        call RemoveSnake
        call ShiftBody
        ; call IncreaseX
        add snakeX[0],2
        jmp ContinueLoop
        
    MoveDown:
        call RemoveSnake
        call ShiftBody
        ; call IncreaseY
        inc snakeY[0]
        jmp ContinueLoop
        
    MoveLeft:
        call RemoveSnake
        call ShiftBody
        ; call DecreaseX
        sub snakeX[0],2
        jmp ContinueLoop
    
    IncreaseSpeed:
        mov al, sprintDelay
        mov delayTime, al
        jmp gameLoop
        


    ContinueLoop:
        ; Redraw the snake at new position
        call DrawSnake
        cmp sprintByte, 1
        je FastMove
        movzx eax, normalDelay
        jmp Move

        FastMove:
        movzx eax, sprintDelay

        Move:
        call Delay
        jmp gameLoop
    exit  
main endp

RemoveSnake proc
    ; Clear the current position of the snake (replace with space)
    mov dl, snakeX
    mov dh, snakeY
    call gotoxy
    mov al, ' '
    call WriteChar
    ret
RemoveSnake endp

DrawScore proc
    mov dl, 0
    mov dh, 0
    call gotoxy
    mov edx, offset scoreMsg
    call WriteString
    movzx eax, score    ; Zero-extend score to 32-bit (fixes display issue)
    call WriteDec
    ret
DrawScore endp

GetInput proc
    ; Use Irvine32's ReadKey for input (non-blocking check)
    call ReadKey
    jz NoKey ; if no key pressed, ZF=1, jump to NoKey
    
    ; Check for W/A/S/D keys
    cmp al, 'w'
    je SetUp
    cmp al, 'd'
    je SetRight
    cmp al, 's'
    je SetDown
    cmp al, 'a'
    je SetLeft
    cmp al, ' '
    je SetSprint
    jmp NoKey
    
SetUp:
    cmp direction, 2
    je NoKey
    mov direction, 0
    jmp NoKey
SetRight:
    cmp direction, 3
    je NoKey
    mov direction, 1
    jmp NoKey
SetDown:
    cmp direction, 0
    je NoKey
    mov direction, 2
    jmp NoKey
SetLeft:
    cmp direction, 1
    je NoKey
    mov direction, 3
    jmp NoKey

SetSprint:
    cmp sprintByte, 0
    je EnableSprint
    mov sprintByte, 0
    jmp NoKey

EnableSprint:
    mov sprintByte, 1
    
    
NoKey:
    ret
GetInput endp



DrawFood proc
    mov dl, foodX
    mov dh, foodY
    call gotoxy
    mov al, '*'
    call WriteChar
    ret
DrawFood endp


EatingCheck proc
    mov al, snakeX[0]
    cmp al, foodX
    jne NotEating
    mov al, snakeY[0]
    cmp al, foodY
    jne NotEating
    
    ; Clear old food position
    mov dl, foodX
    mov dh, foodY
    call gotoxy
    mov al, ' '
    call WriteChar
    
    ; Increment score

    mov al, snakeLength
    inc al
    mov snakeLength, al

    mov al, score
    inc al
    mov score, al
    call DrawScore
    
    ; New random X (1 to 76)
    mov eax, 65
    call RandomRange
    inc eax ; Range : 1 - 76
    shl eax, 1 ; Ensure food appears on even X coordinate (since snake moves in steps of 2)
    call WriteInt
    mov foodX, al        ; al = low byte of eax, fine here
    
    ; New random Y (1 to 26)
    mov eax, 26
    call RandomRange
    add eax,2
    mov foodY, al        ; same here
    
    ; Draw food at new position immediately
    call DrawFood
    
    NotEating:
    ret
EatingCheck endp

HideCursor proc
    pushad

    ; get stdout handle (STD_OUTPUT_HANDLE = -11)
    push -11
    call GetStdHandle
    mov ebx, eax

    ; set cursor info
    mov cursorInfo.dwSize, 1
    mov cursorInfo.bVisible, 0

    push offset cursorInfo
    push ebx
    call SetConsoleCursorInfo

    popad
    ret
HideCursor endp



DrawGround proc
    mov dl, 0
    mov dh, 28
    call gotoxy
    mov edx, offset ground
    call WriteString
    ret
DrawGround endp

DrawCeiling proc
    mov dl, 0
    mov dh, 1
    call gotoxy
    mov edx, offset ground
    call WriteString
    ret
DrawCeiling endp

DrawWalls proc
    ; Draw left wall
    mov ecx, 0
    mov cl, 27 ; Number of rows for walls
    LeftWallLoop:
        mov dl, 0
        mov dh, cl
        call gotoxy
        mov al, brick
        call WriteChar
        loop LeftWallLoop
    
    ; Draw right wall
    mov ecx, 0
    mov cl, 28
    RightWallLoop:
        mov dl, xBoundary
        mov dh, cl
        call gotoxy
        mov al, brick
        call WriteChar
        loop RightWallLoop
    
    ret
DrawWalls endp

CollisionCheck proc
    ; Check for collision with walls
    mov eax, 0
    mov al, snakeX
    cmp al, 0
    jbe Collision
    cmp al, xBoundary
    jae Collision
    mov al, snakeY
    cmp al, 1
    jbe Collision
    cmp al, yBoundary
    jae Collision
    jmp NoCollision

Collision:
    ; Game over logic here (for now just exit)
    call Clrscr
    mov edx, offset scoreMsg
    call WriteString
    movzx eax, score
    call WriteDec
    call Crlf
    mov edx, offset gameOverMsg
    call WriteString
    call ReadChar
    exit

NoCollision:
    ret
CollisionCheck endp

InitializeSnake proc
    mov snakeX[0], 30
    mov snakeY[0], 15
    mov snakeX[1], 28
    mov snakeY[1], 15
    mov snakeX[2], 26
    mov snakeY[2], 15
    call DrawSnake
    ret
InitializeSnake endp

DrawSnake proc
    movzx ecx, snakeLength
    mov esi, 0
    DrawLoop:
    mov dl, snakeX[esi]
    mov dh, snakeY[esi]
    call gotoxy
    mov al, character
    call WriteChar
    inc esi
    loop DrawLoop
    ret
DrawSnake endp

DecreaseX proc
    movzx ecx, snakeLength
    mov dl, snakeX[ecx-1]
    mov dh, snakeY[ecx-1]
    call gotoxy
    mov al, ' '
    call WriteChar
    dec ecx                 
ShiftLoop:
    mov al, snakeX[ecx-1]
    mov snakeX[ecx], al
    mov al, snakeY[ecx-1]
    mov snakeY[ecx], al
    dec ecx
    jnz ShiftLoop

    sub snakeX[0], 2
    ret
DecreaseX endp

IncreaseX proc
    movzx ecx, snakeLength
    mov dl, snakeX[ecx-1]
    mov dh, snakeY[ecx-1]
    call gotoxy
    mov al, ' '
    call WriteChar
    dec ecx                 
ShiftLoop:
    mov al, snakeX[ecx-1]
    mov snakeX[ecx], al
    mov al, snakeY[ecx-1]
    mov snakeY[ecx], al
    dec ecx
    jnz ShiftLoop

    add snakeX[0], 2
    ret
IncreaseX endp

DecreaseY proc

    movzx ecx, snakeLength
    mov dl, snakeX[ecx-1]
    mov dh, snakeY[ecx-1]
    call gotoxy
    mov al, ' '
    call WriteChar
    dec ecx                  ; last index

ShiftLoop:
    mov al, snakeX[ecx-1]
    mov snakeX[ecx], al

    mov al, snakeY[ecx-1]
    mov snakeY[ecx], al

    dec ecx
    jnz ShiftLoop

    ; move head up
    dec snakeY[0]

    ret
DecreaseY endp

IncreaseY proc
    movzx ecx, snakeLength
    mov dl, snakeX[ecx-1]
    mov dh, snakeY[ecx-1]
    call gotoxy
    mov al, ' '
    call WriteChar
    dec ecx                  ; last index

ShiftLoop:
    mov al, snakeX[ecx-1]
    mov snakeX[ecx], al

    mov al, snakeY[ecx-1]
    mov snakeY[ecx], al

    dec ecx
    jnz ShiftLoop

    ; move head up
    inc snakeY[0]

    ret
IncreaseY endp

ShiftBody proc
    movzx ecx, snakeLength
    mov dl, snakeX[ecx-1]
    mov dh, snakeY[ecx-1]
    call gotoxy
    mov al, ' '
    call WriteChar
    dec ecx                  ; last index

ShiftLoop:
    mov al, snakeX[ecx-1]
    mov snakeX[ecx], al

    mov al, snakeY[ecx-1]
    mov snakeY[ecx], al

    dec ecx
    jnz ShiftLoop
    ret
ShiftBody endp


end main