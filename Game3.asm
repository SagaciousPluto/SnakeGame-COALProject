Title Snake Game (main.asm)
include Irvine32.inc

;-----------------------------------Snake Self-Collision Implemented----------------------------------------

;Snake is now continuous instead of being a set of disjointed segments
;Game Menu needs to be implemented
;Variable Length Increment Added

.data

    cursorInfo CONSOLE_CURSOR_INFO <>

    ; ground byte "-----------------------------------------------------------------------------------------------------------------------------------------------",0
    ground byte "----------------------------------------------------------------------",0
    brick byte '|'

    temp byte ?

    scoreMsg byte " Score: ",0
    score byte 0
    gameOverMsg byte "Game Over! Press any key to exit.",0

    sprintByte byte 0

    normalDelay byte 100
    sprintDelay byte 50

    delayTime byte 100

    snakeX byte 150 DUP(?)
    snakeY byte 150 DUP(?)
    character byte 219
    snakeLength byte 6

    foodXBoundary byte 35
    foodYBoundary byte 28
    lengthIncrement byte 2
    scoreIncrement byte 1

    xBoundary byte 70
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
        call BoundaryCollisionCheck
        call SelfCollisionCheck
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
        call SelfCollisionCheck
        jmp ContinueLoop
        
    MoveRight:
        call RemoveSnake
        call ShiftBody
        ; call IncreaseX
        add snakeX[0],1
        call SelfCollisionCheck
        jmp MoveRight2
        ; jmp ContinueLoop
        
    MoveDown:
        call RemoveSnake
        call ShiftBody
        ; call IncreaseY
        inc snakeY[0]
        call SelfCollisionCheck
        jmp ContinueLoop
        
    MoveLeft:
        call RemoveSnake
        call ShiftBody
        ; call DecreaseX
        sub snakeX[0],1
        call SelfCollisionCheck
        jmp MoveLeft2
        ; jmp ContinueLoop

    MoveLeft2:
        call RemoveSnake
        call ShiftBody
        sub snakeX[0],1
        call SelfCollisionCheck
        jmp ContinueLoop

    MoveRight2:
        call RemoveSnake
        call ShiftBody
        add snakeX[0],1
        call SelfCollisionCheck
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
    add al, lengthIncrement
    mov snakeLength, al

    mov al, score
    add al, scoreIncrement
    mov score, al
    
    ; New random X (1 to 76)

    RandomizeFood:
    movzx eax, foodXBoundary
    sub eax, 2
    call RandomRange
    inc eax
    shl eax, 1 ; Ensure food appears on even X coordinate (since snake moves in steps of 2)
    mov foodX, al        ; al = low byte of eax, fine here
    ; New random Y (2 to 2)
    movzx eax, foodYBoundary
    sub eax, 2
    call RandomRange
    add eax, 2 ; Ensure food appears within boundaries (2 to 27)
    mov foodY, al        ; same here
    
    movzx ecx, snakeLength
    mov esi, 0
    CheckCollisionX:
    mov al, snakeX[esi]
    cmp al, foodX
    je CheckCollisionY
    inc esi
    loop CheckCollisionX
    jmp NoCollision
    
    CheckCollisionY:
    mov al, snakeY[esi]
    cmp al, foodY
    je RandomizeFood ; If collision detected, generate new food position; If collision detected, generate new food position
    inc esi
    loop CheckCollisionX
    
    ; Draw food at new position immediately
    NoCollision:
    call DrawScore
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
        ; cmp cl, 1
        ; je DoneLeftWall
        mov dl, 0
        mov dh, cl
        call gotoxy
        mov al, brick
        call WriteChar
        loop LeftWallLoop
    
    ; Draw right wall
    DoneLeftWall:
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

BoundaryCollisionCheck proc
    ; Check for collision with walls
    mov eax, 0
    mov al, snakeX
    cmp al, 0
    jbe CollisionTrue
    cmp al, xBoundary
    jae Collision
    mov al, snakeY
    cmp al, 1
    jbe CollisionTrue
    cmp al, yBoundary
    jae CollisionTrue
    jmp NoCollision

CollisionTrue:
    call Collision

NoCollision:
    ret
BoundaryCollisionCheck endp

InitializeSnake proc
    mov snakeX[0], 30
    mov snakeY[0], 15
    mov snakeX[1], 29
    mov snakeY[1], 15
    mov snakeX[2], 28
    mov snakeY[2], 15
    mov snakeX[3], 27
    mov snakeY[3], 15
    mov snakeX[4], 26
    mov snakeY[4], 15
    mov snakeX[5], 25
    mov snakeY[5], 15

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
    ; call WriteChar
    inc esi
    loop DrawLoop
    ret
DrawSnake endp

ShiftBody proc
    movzx ecx, snakeLength
    mov dl, snakeX[ecx-1]
    mov dh, snakeY[ecx-1]
    call gotoxy
    mov al, ' '
    call WriteChar
    ; call WriteChar
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

SelfCollisionCheck proc
    ; Check for collision with self (starting from index 1 to skip head)
    movzx ecx, snakeLength
    dec ecx
    mov esi, 1

    CheckLoop:
    mov al, snakeX[0] ; head X
    cmp al, snakeX[esi]
    je CheckY
    jmp NextIter

    CheckY:
    mov al, snakeY[0] ; head Y
    cmp al, snakeY[esi]
    je Collision
    jmp NextIter

    NextIter:
    cmp ecx, 0
    je NoCollision
    inc esi
    dec ecx
    jmp CheckLoop
    
    call Collision

NoCollision:
    ret
SelfCollisionCheck endp

Collision proc
    call Clrscr
    mov dl, 70
    mov dh, 15
    call gotoxy
    mov edx, offset scoreMsg
    call WriteString
    movzx eax, score
    call WriteDec
    call Crlf
    mov dl, 71
    mov dh, 17
    call gotoxy
    mov edx, offset gameOverMsg
    call WriteString
    call ReadChar
    exit

Collision endp


end main