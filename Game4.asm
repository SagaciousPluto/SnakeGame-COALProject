.386  ; Enables extended jump ranges
Title Snake Game (main.asm)
include Irvine32.inc
; include Menu.asm

;-----------------------------------Snake Self-Collision Implemented----------------------------------------

;Snake is now continuous instead of being a set of disjointed segments
;Game Menu needs to be implemented
;Variable Length Increment Added

.data

    cursorInfo CONSOLE_CURSOR_INFO <>

    groundLarge byte "-----------------------------------------------------------------------------------------------------------------------------------------------",0
    groundSmall byte "--------------------------------------------------------------------",0
    brick byte '|'

    colorByte byte 1 ; 1=green,2=red,3=yellow,4=blue,5=magenta,6=cyan
    
    isStriped byte 0;

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

    ; playerNameInput byte "Pluto",0

    ; playGameMsg byte "Press any key to play the game...",0
    playerNameInputPrompt byte "Enter your name : ",0
    nameEraser byte "                              ",0 ; Buffer for erasing previous name input
    playerNameInput byte 30 dup(0) ; Buffer for player name input

    mapSizePrompt byte "Map Size",0
    mapSizeOptions byte "1. Small 2. Large",0
    mapPromptEraser byte "          ",0
    mapOptionsEraser byte "                         ",0
    mapSizeInput byte ?

    colorPrompt byte "Select Color of Snake",0
    colorGreen byte "1. Green",0
    colorRed byte "2. Red", 0
    colorYellow byte "3. Yellow", 0
    colorViolet byte "4. Violet",0
    colorMagenta byte "5. Magenta", 0
    colorBlue byte "6. Blue",0
    colorInput byte ?
    colorOptionsEraser byte "                     ",0
    colorPromptEraser byte "                       ",0
    eraser byte "            ",0

    difficultyPrompt byte "Select Difficulty", 0
    difficultyLow byte "1. Low",0
    difficultyHigh byte "2. High",0
    difficultyInput byte ?

    
    
    ; For now the snake will be represented as a single character, but we can expand this later to an array to represent the body segments.
.code

public Game
Game proc
    call Menu
    call Settings
    


    Continue:
    call Randomize
    call Clrscr
    call HideCursor
    call DrawGround
    call DrawCeiling
    call DrawWalls
    call DrawName
    call DrawScore
    call InitializeSnake
    call DrawFood
    gameLoop:    
        ; Get input and move based on direction
        ; mov eax, (black*16) + white
        ; call setTextColor
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
Game endp

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
    mov eax, (black*16) + blue
    call setTextColor
    mov dl, 0
    mov dh, 0
    call gotoxy
    mov edx, offset scoreMsg
    call WriteString
    movzx eax, score    ; Zero-extend score to 32-bit (fixes display issue)
    call WriteDec
    mov eax, (black*16) + white
    call setTextColor
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
    mov eax, (black*16) + green
    call setTextColor
    mov dl, foodX
    mov dh, foodY
    call gotoxy
    mov al, '*'
    call WriteChar
    mov eax, (black*16) + white
    call setTextColor
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
    mov al, xBoundary
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
    mov eax, (black*16) + red
    call setTextColor
    mov dl, 0
    mov dh, 28
    call gotoxy
    mov al, mapSizeInput
    cmp al, "2"
    je DrawLargeGround
    mov edx, offset groundSmall
    call WriteString
    jmp continue

    DrawLargeGround:
    mov edx, offset groundLarge
    call WriteString
    continue:
    mov eax, (black*16) + white
    call setTextColor
    ret
DrawGround endp

DrawCeiling proc
    mov eax, (black*16) + red
    call setTextColor
    mov dl, 0
    mov dh, 1
    call gotoxy
    mov al, mapSizeInput
    cmp al, "2"
    je DrawLargeGround
    mov edx, offset groundSmall
    call WriteString
    jmp continue
    
    DrawLargeGround:
    mov edx, offset groundLarge
    call WriteString
    
    continue:
    mov eax, (black*16) + white
    call setTextColor
    ret
DrawCeiling endp

DrawWalls proc
    ; Draw left wall
    mov eax, (black*16) + red
    call setTextColor
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
    mov eax, (black*16) + white
    call setTextColor
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

    ; mov al, isStriped
    ; cmp al, 0
    ; jne StripedSnake
    call DrawPlainSnake
    ret
    


    ; StripedSnake:
    ; call DrawGaySnake
    ; ret
DrawSnake endp

DrawGaySnake proc
;   ; Placeholder for future pride snake implementation
    ; Could cycle through colors for each segment or use a pattern
    ret
DrawGaySnake endp

DrawPlainSnake proc
    movzx ecx, snakeLength
    mov esi, 0
    cmp colorByte, 1
    je SetGreen
    cmp colorByte, 2
    je SetRed
    cmp colorByte, 3
    je SetYellow
    cmp colorByte, 4
    je SetBlue
    cmp colorByte, 5
    je SetMagenta
    cmp colorByte, 6
    je SetCyan
    mov eax, (black*16) + white
    call SetTextColor
    mov colorByte, 1
    DrawLoop:
    mov dl, snakeX[esi]
    mov dh, snakeY[esi]
    call gotoxy
    mov al, character
    call WriteChar
    inc esi
    loop DrawLoop
    mov eax, (black*16) + white
    call SetTextColor
    ret

    SetGreen:
    mov eax, (black*16) + green
    call setTextColor
    jmp DrawLoop

    SetRed:
    mov eax, (black*16) + red
    call setTextColor
    jmp DrawLoop

    SetYellow:
    mov eax, (black*16) + yellow
    call setTextColor
    jmp DrawLoop

    SetBlue:
    mov eax, (black*16) + blue
    call setTextColor
    jmp DrawLoop

    SetMagenta:
    mov eax, (black*16) + magenta
    call setTextColor
    jmp DrawLoop

    SetCyan:
    mov eax, (black*16) + cyan
    call setTextColor
    jmp DrawLoop
DrawPlainSnake endp

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

DrawName proc
    mov eax, (black*16) + cyan
    call setTextColor

    mov al, mapSizeInput
    cmp al, "2"
    je DrawLarge
    mov dl, 30
    mov dh, 0
    call gotoxy
    jmp Render

    DrawLarge:
    mov dl, 70
    mov dh, 0
    call gotoxy

    Render:
    mov edx, offset playerNameInput
    call WriteString
    mov eax, (black*16) + white
    call setTextColor
    ret
DrawName endp

Menu proc
call Clrscr
    call HideCursor
    mov dl, 62
    mov dh, 12
    ; mov eax, (white*16) + black
    ; call SetTextColor
    call gotoxy
    mov edx, offset playerNameInputPrompt
    call WriteString
    mov edx, offset playerNameInput
    mov ecx, 30
    call ReadString ; read the user name into playerNameInput
    mov eax, (black*16) + white
    ; call SetTextColor
    mov dl, 60
    mov dh, 12
    call gotoxy
    mov edx, offset nameEraser
    call WriteString ; Erase the prompt and input
    mov dl, 68
    mov dh, 12
    call gotoxy
    ; mov eax, (white*16) + black
    mov edx, offset mapSizePrompt
    call WriteString
    call crlf
    mov dl, 64
    mov dh, 14
    call gotoxy
    mov edx, offset mapSizeOptions
    call WriteString
    call ReadChar
    mov mapSizeInput, al
    mov dl, 65
    mov dh, 12
    call gotoxy
    mov edx, offset mapPromptEraser
    call WriteString
    mov dl, 61
    mov dh, 14
    call gotoxy
    mov edx, offset mapOptionsEraser
    call WriteString
    mov dl, 65
    mov dh, 12
    call gotoxy
    mov edx, offset colorPrompt
    call WriteString
    ; Erase color prompt after selection
    ; Print color options one by one
    mov dl, 68
    mov dh, 14
    call gotoxy
    mov edx, offset colorGreen
    call WriteString
    mov dl, 68
    mov dh, 15
    call gotoxy
    mov edx, offset colorRed
    call WriteString
    mov dl, 68
    mov dh, 16
    call gotoxy
    mov edx, offset colorYellow
    call WriteString
    mov dl, 68
    mov dh, 17
    call gotoxy
    mov edx, offset colorViolet
    call WriteString
    mov dl, 68
    mov dh, 18
    call gotoxy
    mov edx, offset colorMagenta
    call WriteString
    mov dl, 68
    mov dh, 19
    call gotoxy
    mov edx, offset colorBlue
    call WriteString
    mov dl, 68
    mov dh, 20
    call gotoxy
    call ReadChar
    mov colorInput, al
    ; Erase color options
    mov dl, 65
    mov dh, 12
    call gotoxy
    mov edx, offset mapOptionsEraser
    call writeString
    mov dl, 68
    mov dh, 14
    call gotoxy
    mov edx, offset colorOptionsEraser
    call WriteString
    mov dl, 68
    mov dh, 15
    call gotoxy
    mov edx, offset colorOptionsEraser
    call WriteString
    mov dl, 68
    mov dh, 16
    call gotoxy
    mov edx, offset colorOptionsEraser
    call WriteString
    mov dl, 68
    mov dh, 17
    call gotoxy
    mov edx, offset colorOptionsEraser
    call WriteString
    mov dl, 68
    mov dh, 18
    call gotoxy
    mov edx, offset colorOptionsEraser
    call WriteString
    mov dl, 68
    mov dh, 19
    call gotoxy
    mov edx, offset colorOptionsEraser
    call WriteString
    mov dl, 68
    mov dh, 20
    call gotoxy
    mov edx, offset colorOptionsEraser
    call WriteString
    mov dl, 66
    mov dh, 12
    call gotoxy
    mov edx, offset difficultyPrompt
    call WriteString
    mov dl, 70
    mov dh, 14
    call gotoxy
    mov edx, offset difficultyLow
    call WriteString
    mov dl, 70
    mov dh, 15
    call gotoxy
    mov edx, offset difficultyHigh
    call WriteString
    call ReadChar
    mov difficultyInput, al
    mov dl, 66
    mov dh,12
    call gotoxy
    mov edx, offset eraser
    call WriteString
    call WriteString
    mov dl, 70
    mov dh, 14
    call gotoxy
    mov edx, offset eraser
    call WriteString
    mov dl, 70
    mov dh, 15
    call gotoxy
    mov edx, offset eraser
    call WriteString
    ret
Menu endp

Settings proc
    mov al, mapSizeInput
    cmp al, "2"
    je SetLarge
    mov xBoundary, 70
    jmp SetHard

SetLarge:
    mov xBoundary, 140

    mov al, difficultyInput
    cmp al, "2"
    je SetHard
    mov normalDelay, 110
    mov sprintDelay, 55
    jmp SetColor

SetHard:
    mov normalDelay, 65
    mov sprintDelay, 35

SetColor:
    mov al, colorInput
    cmp al, "1"
    je SetColor1
    cmp al, "2"
    je SetColor2
    cmp al, "3"
    je SetColor3
    cmp al, "4"
    je SetColor4
    cmp al, "5"
    je SetColor5
    cmp al, "6"
    je SetColor6
    mov colorByte, 1
    jmp SettingsDone

SetColor1:
    mov colorByte, 1
    jmp SettingsDone
SetColor2:
    mov colorByte, 2
    jmp SettingsDone
SetColor3:
    mov colorByte, 3
    jmp SettingsDone
SetColor4:
    mov colorByte, 4
    jmp SettingsDone
SetColor5:
    mov colorByte, 5
    jmp SettingsDone
SetColor6:
    mov colorByte, 6

SettingsDone:
    ret
Settings endp

end Game
end main