STACK SEGMENT PARA STACK
          DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'

    WINDOW_WIDTH                DW 140h                                ;HEX for 320 - width size
    WINDOW_HEIGHT               DW 0C8h                                ;HEX for 200 - height size
    WINDOW_BOUNDS               DW 6                                   ;variable to check collision early

    TIME_AUX                    DB 0                                   ;variable for checking if the time changed
    GAME_ACTIVE                 DB 1                                   ;the game is active (1 - true, 0 - false)
    WINNER_INDEX                DB 0                                   ;the index of the winner (1 - P1, 2 - P2)
    CURRENT_SCENE               DB 0                                   ;the index of the current scene (0 - main menu, 1 - game)
    EXITING_GAME                DB 0

    TEXT_POINTS_PLAYER_ONE      DB '0','$'                             ;text with the players points
    TEXT_POINTS_PLAYER_TWO      DB '0','$'
    TEXT_GAME_OVER_TITLE        DB 'GAME OVER','$'                     ;GAME OVER menu title
    TEXT_GAME_OVER_WINNER       DB 'PLAYER 0 WON','$'                  ;TEXT with the WINNER
    TEXT_GAME_OVER_PLAY_AGAIN   DB 'Press R to play again','$'         ;text with play again
    TEXT_GAME_OVER_MAIN_MENU    DB 'Press E to exit to menu', '$'      ;message to go to main menu
    TEXT_GAME_OVER_SINGLEWIN    DB "YOU WON!", '$'                     ;message for WIN SINGLEPLAYER
    TEXT_GAME_OVER_COMWIN       DB "YOU LOSE.", '$'                    ;message for LOSE SINGLEPLAYER
    TEXT_GAME_OVER_EZWIN        DB "Good job, but quite easy.", '$'    ;text under WIN, for EASY MODE
    TEXT_GAME_OVER_HDWIN        DB "That was impressive!", '$'         ;text under WIN, for HARD MODE

    TEXT_MAIN_MENU_TITLE        DB 'PONG','$'                          ;text with the main menu title
    TEXT_MAIN_MENU_SINGLEPLAYER DB '1 PLAYER - 1 KEY', '$'             ;text with singleplayer
    TEXT_MAIN_MENU_MULTIPLAYER  DB '2 PLAYERS - 2 KEY', '$'            ;text with multiplayer
    TEXT_MAIN_MENU_EXIT         DB 'EXIT GAME - E', '$'                ;text with exit
    TEXT_MAIN_MENU_MADE         DB 'razandtim', '$'

    BALL_ORIGIN_X               DW 0A0h                                ;HEX for 160, initial position for ball
    BALL_ORIGIN_Y               DW 64h                                 ;HEX for 100, initial position for ball

    BALL_X                      DW 0A0h                                ;X position
    BALL_Y                      DW 64h                                 ;Y position
    BALL_SIZE                   DW 04h                                 ;Size of 4 pixels (in width and height)
    BALL_VELOCITY_X             DW 05h                                 ;X (horizontal) velocity of the ball
    BALL_VELOCITY_Y             DW 02h                                 ;Y (vertical) velocity of the ball

    PADDLE_LEFT_X               DW 0Ah
    PADDLE_LEFT_Y               DW 55h
    PLAYER_ONE_POINTS           DB 0                                   ;current points for left player (P1)
    COMPUTER_CONTROLLED         DB 0                                   ;is the right paddle controlled by the COM? (0 - false, 1 - true)

    PADDLE_RIGHT_X              DW 130h
    PADDLE_RIGHT_Y              DW 55h
    PLAYER_TWO_POINTS           DB 0                                   ;current points for right player (P2)

    PADDLE_WIDTH                DW 05h                                 ;default paddle width
    PADDLE_HEIGHT               DW 1Fh                                 ;default paddle height
    PADDLE_VELOCITY             DW 0Fh                                 ;default paddle velocity

DATA ENDS

CODE SEGMENT PARA 'CODE'
   
MAIN PROC FAR
                                     ASSUME CS:CODE, DS:DATA, SS:STACK          ; assume as code, data, stack respective registers
                                     PUSH   DS                                  ; push datasegment to the stack
                                     SUB    AX,AX                               ; clean the AX register
                                     PUSH   AX                                  ; push AX to the stack
                                     MOV    AX,DATA                             ; save on the AX register
                                     MOV    DS,AX                               ; save on the DS register
                                     POP    AX                                  ; release the top item from the stack to AX register
                                     POP    AX
                
                                     CALL   CLEAR_SCREEN
    ;MOV    AH,00h                        ; set video mode
    ;MOV    AL,13h                        ; 13 320x200 256 color (VGA)
    ;INT    10h                           ; INT 10h provides video services, to draw the pixel

    ;MOV    AH,08h                        ;set config
    ;MOV    BH,00h                        ;to the background color
    ;MOV    BL,00h                        ;Black as background 08h - dark gray
    ;INT    10h

    CHECK_TIME:                                                                 ;time checked loop
    ;if pressed exit, exit the game
                                     CMP    EXITING_GAME,01h
                                     JE     START_EXIT_PROCESS
    ;show main menu
                                     CMP    CURRENT_SCENE,00h
                                     JE     SHOW_MAIN_MENU
    ;check if the game is active, time checking loop
                                     CMP    GAME_ACTIVE,00h
                                     JE     SHOW_GAME_OVER

    ;set the system time
                                     MOV    AH,2Ch                              ;get system time
                                     INT    21h                                 ;INT 21h provides MS-DOS services
    ;CH = hour CL = minute DH = second DL = 1/100 seconds

    ;is the current time equal to the previous one? (TIME_AUX)
                                     CMP    DL,TIME_AUX
                                     JE     CHECK_TIME                          ;if is the same, check again

    ;if it's different, then draw/move/etc.
                                     MOV    TIME_AUX,DL                         ;save the current time

                                     CALL   CLEAR_SCREEN

                                     CALL   MOVE_BALL
                                     CALL   DRAW_BALL

                                     CALL   MOVE_PADDLES
                                     CALL   DRAW_PADDLES

                                     CALL   DRAW_UI                             ;draw the User Interface

                                     JMP    CHECK_TIME                          ;check time again

    SHOW_GAME_OVER:                  
                                     CALL   DRAW_GAME_OVER_MENU
                                     JMP    CHECK_TIME

    SHOW_MAIN_MENU:                  
                                     CALL   DRAW_MAIN_MENU
                                     JMP    CHECK_TIME

    START_EXIT_PROCESS:              
                                     CALL   CONCLUDE_EXIT_GAME

                                     RET
MAIN ENDP

MOVE_BALL PROC NEAR
    ;moving the ball, first we move the register
                                     MOV    AX,BALL_VELOCITY_X
                                     ADD    BALL_X,AX                           ;moving ball horizontally

    ;check if the ball has passed the left boundary
                                     MOV    AX,WINDOW_BOUNDS
                                     CMP    BALL_X,AX
                                     JL     POINT_PLAYER_TWO                    ;BALL_X < WINDOW_BOUNDS(Y -> collided) - Give one point to P2 and reset possition

    ;check if the ball has passed the right boundary
                                     MOV    AX,WINDOW_WIDTH
                                     SUB    AX,BALL_SIZE
                                     SUB    AX,WINDOW_BOUNDS
                                     CMP    BALL_X,AX                           ;BALL_X > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS (Y -> collided)
                                     JG     POINT_PLAYER_ONE                    ;Give one point to P1 and reset possition
                                     JMP    MOVE_BALL_VERTICALLY

    POINT_PLAYER_ONE:                
                                     INC    PLAYER_ONE_POINTS                   ;increase a point for P1
                                     CALL   RESET_BALL_POSITION                 ;resets BALL possition to the center

                                     CALL   UPDATE_TEXT_PLAYER_ONE_POINTS       ;update the text for P1 Points
    ;check if player reached 5 points
                                     CMP    PLAYER_ONE_POINTS,05h
                                     JGE    GAME_OVER
                                     RET
    POINT_PLAYER_TWO:                
                                     INC    PLAYER_TWO_POINTS                   ;increase a point for P2
                                     CALL   RESET_BALL_POSITION                 ;resets BALL possition to the center

                                     CALL   UPDATE_TEXT_PLAYER_TWO_POINTS       ;update the text for P2 Points
    ;check if player reached 5 points
                                     CMP    PLAYER_TWO_POINTS,05h
                                     JGE    GAME_OVER
                                     RET

    GAME_OVER:                       
    ;When a player reached 5 points, is Game Over and it restarts the points of the players
                                     CMP    PLAYER_ONE_POINTS,05h               ;check which one has 5 points
                                     JNL    WINNER_IS_PLAYER_ONE
                                     JMP    WINNER_IS_PLAYER_TWO

    WINNER_IS_PLAYER_ONE:            
                                     MOV    WINNER_INDEX,01h                    ;update the index with P1
                                     JMP    CONTINUE_GAME_OVER
    WINNER_IS_PLAYER_TWO:            
                                     MOV    WINNER_INDEX,02h                    ;update the index with P2
                                     JMP    CONTINUE_GAME_OVER

    CONTINUE_GAME_OVER:              
                                     MOV    PLAYER_ONE_POINTS,00h
                                     MOV    PLAYER_TWO_POINTS,00h

                                     CALL   UPDATE_TEXT_PLAYER_ONE_POINTS
                                     CALL   UPDATE_TEXT_PLAYER_TWO_POINTS

                                     MOV    GAME_ACTIVE,00h                     ;stops the game
                                     RET

    MOVE_BALL_VERTICALLY:            
    ;moving ball vertically
                                     MOV    AX,BALL_VELOCITY_Y
                                     ADD    BALL_Y,AX

                                     MOV    AX,WINDOW_BOUNDS
                                     CMP    BALL_Y,AX
                                     JL     NEG_VELOCITY_Y                      ;BALL_Y < WINDOW_BOUNDS (Y -> collided)

                                     MOV    AX,WINDOW_HEIGHT
                                     SUB    AX,BALL_SIZE
                                     SUB    AX,WINDOW_BOUNDS
                                     CMP    BALL_Y,AX                           ;BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS (Y -> collided)
                                     JG     NEG_VELOCITY_Y

    ;check if the ball is colliding with the right paddle (AABBs)
    ;maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
    ; BALL_X + BALL_SIZE > PADDLE_RIGHT_X && BALL_X < PADDLE_RIGHT_X + PADDLE_WIDTH &&
    ; BALL_Y + BALL_SIZE > PADDLE_RIGHT_Y && BALL_Y < PADDLE_RIGHT_Y + PADDLE_HEIGHT

                                     MOV    AX,BALL_X
                                     ADD    AX,BALL_SIZE
                                     CMP    AX,PADDLE_RIGHT_X
                                     JNG    CHECK_COLLISION_PADDLE_LEFT         ;if there is not collision check for the left paddle collision

                                     MOV    AX,PADDLE_RIGHT_X
                                     ADD    AX,PADDLE_WIDTH
                                     CMP    BALL_X,AX
                                     JNL    CHECK_COLLISION_PADDLE_LEFT         ;if there is not collision check for the left paddle collision

                                     MOV    AX,BALL_Y
                                     ADD    AX,BALL_SIZE
                                     CMP    AX,PADDLE_RIGHT_Y
                                     JNG    CHECK_COLLISION_PADDLE_LEFT         ;if there is not collision check for the left paddle collision

                                     MOV    AX,PADDLE_RIGHT_Y
                                     ADD    AX,PADDLE_HEIGHT
                                     CMP    BALL_Y,AX
                                     JNL    CHECK_COLLISION_PADDLE_LEFT         ;if there is not collision check for the left paddle collision

    ;if reaches the point, the ball collides with the right paddle
                                     JMP    NEG_VELOCITY_X

    ;check if the ball is colliding with the left paddle
    CHECK_COLLISION_PADDLE_LEFT:     
    ;maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
    ; BALL_X + BALL_SIZE > PADDLE_LEFT_X && BALL_X < PADDLE_LEFT_X + PADDLE_WIDTH &&
    ; BALL_Y + BALL_SIZE > PADDLE_LEFT_Y && BALL_Y < PADDLE_LEFT_Y + PADDLE_HEIGHT

                                     MOV    AX,BALL_X
                                     ADD    AX,BALL_SIZE
                                     CMP    AX,PADDLE_LEFT_X
                                     JNG    EXIT_COLLISION_CHECK                ;if there is not collision exit

                                     MOV    AX,PADDLE_LEFT_X
                                     ADD    AX,PADDLE_WIDTH
                                     CMP    BALL_X,AX
                                     JNL    EXIT_COLLISION_CHECK                ;if there is not collision exit

                                     MOV    AX,BALL_Y
                                     ADD    AX,BALL_SIZE
                                     CMP    AX,PADDLE_LEFT_Y
                                     JNG    EXIT_COLLISION_CHECK                ;if there is not collision exit

                                     MOV    AX,PADDLE_LEFT_Y
                                     ADD    AX,PADDLE_HEIGHT
                                     CMP    BALL_Y,AX
                                     JNL    EXIT_COLLISION_CHECK                ;if there is not collision exit

    ;if reaches the point, the ball collides with the left paddle
                                     JMP    NEG_VELOCITY_X
                                     
    NEG_VELOCITY_Y:                  
                                     NEG    BALL_VELOCITY_Y                     ;BALL_VELOCITY_Y = - BALL_VELOCITY_Y
                                     RET
    NEG_VELOCITY_X:                  
                                     NEG    BALL_VELOCITY_X                     ;reverses the horizontal velocity of the ball
                                     RET                                        ;exit the procedure (because there's no collision with the right paddle)
    EXIT_COLLISION_CHECK:            
                                     RET
                        
MOVE_BALL ENDP

MOVE_PADDLES PROC NEAR
    ;Using INT 16 - Keyboard BIOS Services

    ;left paddle movement
    ;check if any key is pressed, if not check the other procedure
                                     MOV    AH,01h
                                     INT    16h
                                     JZ     CHECK_PADDLE_RIGHT_MOVE             ;ZF = 1, JZ -> Jump if zero

    ;check which key is pressed (AL = ASCII Char)
                                     MOV    AH,00h
                                     INT    16h

    ;if it's "W"/"w" move up
                                     CMP    AL,77h                              ;"w"
                                     JE     MOVE_PADDLE_LEFT_UP
                                     CMP    AL,57h                              ;"W"
                                     JE     MOVE_PADDLE_LEFT_UP
                                 
    ;if it's "S"/"s" move down
                                     CMP    AL,73h                              ;"s"
                                     JE     MOVE_PADDLE_LEFT_DOWN
                                     CMP    AL,53h                              ;"S"
                                     JE     MOVE_PADDLE_LEFT_DOWN
                                     JMP    CHECK_PADDLE_RIGHT_MOVE


    MOVE_PADDLE_LEFT_UP:             
                                     MOV    AX,PADDLE_VELOCITY
                                     SUB    PADDLE_LEFT_Y,AX

                                     MOV    AX,WINDOW_BOUNDS
                                     CMP    PADDLE_LEFT_Y,AX
                                     JL     FIX_PADDLE_LEFT_TOP_POSITION
                                     JMP    CHECK_PADDLE_RIGHT_MOVE

    FIX_PADDLE_LEFT_TOP_POSITION:    
                                     MOV    PADDLE_LEFT_Y,AX
                                     JMP    CHECK_PADDLE_RIGHT_MOVE

    MOVE_PADDLE_LEFT_DOWN:           
                                     MOV    AX,PADDLE_VELOCITY
                                     ADD    PADDLE_LEFT_Y,AX

                                     MOV    AX,WINDOW_HEIGHT
                                     SUB    AX,WINDOW_BOUNDS
                                     SUB    AX,PADDLE_HEIGHT
                                     CMP    PADDLE_LEFT_Y,AX
                                     JG     FIX_PADDLE_LEFT_BOTTOM_POSITION

                                     JMP    CHECK_PADDLE_RIGHT_MOVE

    FIX_PADDLE_LEFT_BOTTOM_POSITION: 
                                     MOV    PADDLE_LEFT_Y,AX
                                     JMP    CHECK_PADDLE_RIGHT_MOVE


    ;right paddle movement
    CHECK_PADDLE_RIGHT_MOVE:         

                                     CMP    COMPUTER_CONTROLLED,01h
                                     JE     CONTROL_BY_COM

    ;when the paddle is used by PLAYER 2
    CHECK_FOR_KEYS:                  
    ;check if any key is pressed, if not, exit  **no need to put it 2 times*
    ;                          MOV    AH,01h
    ;                         INT    16h
    ;                        JZ     EXIT_PADDLE_MOVEMENT                ;ZF = 1, JZ -> Jump if zero
    ;check which key is pressed

    ;                             MOV    AH,00h
    ;                                INT    16h

    ;if it's "O"/"o" move up
                                     CMP    AL,6Fh                              ;"o"
                                     JE     MOVE_PADDLE_RIGHT_UP
                                     CMP    AL,4Fh                              ;"O"
                                     JE     MOVE_PADDLE_RIGHT_UP
                                 
    ;if it's "L"/"l" move down
                                     CMP    AL,6Ch                              ;"l"
                                     JE     MOVE_PADDLE_RIGHT_DOWN
                                     CMP    AL,4Ch                              ;"L"
                                     JE     MOVE_PADDLE_RIGHT_DOWN
                                     JMP    EXIT_PADDLE_MOVEMENT


    ;when the paddle is used by COMPUTER
    CONTROL_BY_COM:                  
    ;check if the ball is above the paddle (BALL_Y + BALL_SIZE < PADDLE_RIGHT_Y) - if it is, move the paddle up
                                     MOV    AX,BALL_Y
                                     ADD    AX,BALL_SIZE
                                     CMP    AX,PADDLE_RIGHT_Y
                                     JL     MOVE_PADDLE_RIGHT_UP

    ;check if the ball is below the paddle (BALL_Y > PADDLE_RIGHT_Y + PADDLE_HEIGHT) - if it is, move the paddle down
                                     MOV    AX,PADDLE_RIGHT_Y
                                     ADD    AX,PADDLE_HEIGHT
                                     CMP    AX,BALL_Y
                                     JL     MOVE_PADDLE_RIGHT_DOWN

    ;if none, then don't move (exit paddle movement)
                                     JMP    EXIT_PADDLE_MOVEMENT



    MOVE_PADDLE_RIGHT_UP:            
                                     MOV    AX,PADDLE_VELOCITY
                                     SUB    PADDLE_RIGHT_Y,AX

                                     MOV    AX,WINDOW_BOUNDS
                                     CMP    PADDLE_RIGHT_Y,AX
                                     JL     FIX_PADDLE_RIGHT_TOP_POSITION
                                     JMP    EXIT_PADDLE_MOVEMENT
    FIX_PADDLE_RIGHT_TOP_POSITION:   
                                     MOV    PADDLE_RIGHT_Y,AX
                                     JMP    EXIT_PADDLE_MOVEMENT

    MOVE_PADDLE_RIGHT_DOWN:          
                                     MOV    AX,PADDLE_VELOCITY
                                     ADD    PADDLE_RIGHT_Y,AX

                                     MOV    AX,WINDOW_HEIGHT
                                     SUB    AX,WINDOW_BOUNDS
                                     SUB    AX,PADDLE_HEIGHT
                                     CMP    PADDLE_RIGHT_Y,AX
                                     JG     FIX_PADDLE_RIGHT_BOTTOM_POSITION

                                     JMP    EXIT_PADDLE_MOVEMENT
    FIX_PADDLE_RIGHT_BOTTOM_POSITION:
                                     MOV    PADDLE_RIGHT_Y,AX
                                     JMP    EXIT_PADDLE_MOVEMENT

    EXIT_PADDLE_MOVEMENT:            

                                     RET
MOVE_PADDLES ENDP

RESET_BALL_POSITION PROC NEAR
    ;resetting the ball position to the start position
                                     MOV    AX,BALL_ORIGIN_X
                                     MOV    BALL_X,AX

                                     MOV    AX,BALL_ORIGIN_Y
                                     MOV    BALL_Y,AX

                                     NEG    BALL_VELOCITY_X
                                     NEG    BALL_VELOCITY_Y

                                     RET
RESET_BALL_POSITION ENDP

DRAW_BALL PROC NEAR

                                     MOV    CX,BALL_X                           ;set the initial column X
                                     MOV    DX,BALL_Y                           ;set the initial line Y

    DRAW_BALL_HORIZONTAL:            
                                     MOV    AH,0Ch                              ;write a pixel
                                     MOV    AL,0Fh                              ;color of the pixel F - White
                                     MOV    BH,00h                              ;page 0
                                     INT    10h

                                     INC    CX                                  ;CX = CX + 1
                                     MOV    AX,CX                               ;CX - BALL_X > BALL_SIZE (Y -> We go to the next line, N -> We go to the next column)
                                     SUB    AX,BALL_X
                                     CMP    AX,BALL_SIZE
                                     JNG    DRAW_BALL_HORIZONTAL

                                     MOV    CX,BALL_X                           ;the CX goes back to initial
                                     INC    DX                                  ;we advance one line
                        
                                     MOV    AX,DX                               ;DX - BALL_Y > BALL_SIZE (Y -> We exit, N -> We continue to the next line)
                                     SUB    AX,BALL_Y
                                     CMP    AX,BALL_SIZE
                                     JNG    DRAW_BALL_HORIZONTAL

                                     RET
DRAW_BALL ENDP

DRAW_PADDLES PROC NEAR
    ;drawing the paddles
                                     MOV    CX,PADDLE_LEFT_X                    ;set the initial column X
                                     MOV    DX,PADDLE_LEFT_Y                    ;set the initial line Y

    DRAW_PADDLE_LEFT_HORIZONTAL:     
                                     MOV    AH,0Ch                              ;write a pixel
                                     MOV    AL,0Fh                              ;color of the pixel F - White
                                     MOV    BH,00h                              ;page 0
                                     INT    10h

                                     INC    CX                                  ;CX = CX + 1
                                     MOV    AX,CX                               ;CX - PADDLE_LEFT > PADDLE_WIDTH (Y -> We go to the next line, N -> We go to the next column)
                                     SUB    AX,PADDLE_LEFT_X
                                     CMP    AX,PADDLE_WIDTH
                                     JNG    DRAW_PADDLE_LEFT_HORIZONTAL

                                     MOV    CX,PADDLE_LEFT_X                    ;the CX goes back to initial
                                     INC    DX                                  ;we advance one line
                        
                                     MOV    AX,DX                               ;DX - PADDLE_LEFT_Y > PADDLE_HEIGHT (Y -> We exit, N -> We continue to the next line)
                                     SUB    AX,PADDLE_LEFT_Y
                                     CMP    AX,PADDLE_HEIGHT
                                     JNG    DRAW_PADDLE_LEFT_HORIZONTAL



                                     MOV    CX,PADDLE_RIGHT_X                   ;set the initial column X
                                     MOV    DX,PADDLE_RIGHT_Y                   ;set the initial line Y

    DRAW_PADDLE_RIGHT_HORIZONTAL:    
                                     MOV    AH,0Ch                              ;write a pixel
                                     MOV    AL,0Fh                              ;color of the pixel F - White
                                     MOV    BH,00h                              ;page 0
                                     INT    10h
                                

                                     INC    CX                                  ;CX = CX + 1
                                     MOV    AX,CX                               ;CX - PADDLE_RIGHT > PADDLE_WIDTH (Y -> We go to the next line, N -> We go to the next column)
                                     SUB    AX,PADDLE_RIGHT_X
                                     CMP    AX,PADDLE_WIDTH
                                     JNG    DRAW_PADDLE_RIGHT_HORIZONTAL

                                     MOV    CX,PADDLE_RIGHT_X                   ;the CX goes back to initial
                                     INC    DX                                  ;we advance one line
                        
                                     MOV    AX,DX                               ;DX - PADDLE_RIGHT_Y > PADDLE_HEIGHT (Y -> We exit, N -> We continue to the next line)
                                     SUB    AX,PADDLE_RIGHT_Y
                                     CMP    AX,PADDLE_HEIGHT
                                     JNG    DRAW_PADDLE_RIGHT_HORIZONTAL

                                     RET
DRAW_PADDLES ENDP

DRAW_UI PROC NEAR
    ;drawing using INT 21h & 10h

    ;draw the text of P1 (left)
                                     MOV    AH,02h                              ;set cursor position
                                     MOV    BH,00h                              ;set page number
                                     MOV    DH,04h                              ;set row
                                     MOV    DL,08h                              ;set column
                                     INT    10h

                                     MOV    AH,09h                              ;Write string to standard output
                                     LEA    DX,TEXT_POINTS_PLAYER_ONE           ;give DX a pointer to string TEXT_POINTS_PLAYER_ONE
                                     INT    21h                                 ;print the string
    ;draw the text of P2 (right)
                                     MOV    AH,02h                              ;set cursor position
                                     MOV    BH,00h                              ;set page number
                                     MOV    DH,04h                              ;set row
                                     MOV    DL,1Fh                              ;set column
                                     INT    10h

                                     MOV    AH,09h                              ;Write string to standard output
                                     LEA    DX,TEXT_POINTS_PLAYER_TWO           ;give DX a pointer to string TEXT_POINTS_PLAYER_TWO
                                     INT    21h                                 ;print the string

                                     RET
DRAW_UI ENDP

UPDATE_TEXT_PLAYER_ONE_POINTS PROC NEAR
                                     XOR    AX,AX
                                     MOV    AL,PLAYER_ONE_POINTS                ;given that P1 -> 2 points => AL,2

    ;before printing, we need to convert decimal to ASCII char
    ;we add 30h (Number to ASCII) and subtract 30h (ASCII to Number)

                                     ADD    AL,30h                              ;AL,'2'
                                     MOV    [TEXT_POINTS_PLAYER_ONE],AL

    ;SUB    AL,30h

                                     RET
UPDATE_TEXT_PLAYER_ONE_POINTS ENDP

UPDATE_TEXT_PLAYER_TWO_POINTS PROC NEAR
                                     XOR    AX,AX
                                     MOV    AL,PLAYER_TWO_POINTS                ;given that P2 -> 2 points => AL,2

    ;before printing, we need to convert decimal to ASCII char
    ;we add 30h (Number to ASCII) and subtract 30h (ASCII to Number)

                                     ADD    AL,30h                              ;AL,'2'
                                     MOV    [TEXT_POINTS_PLAYER_TWO],AL

    ;SUB    AL,30h

                                     RET
UPDATE_TEXT_PLAYER_TWO_POINTS ENDP

DRAW_MAIN_MENU PROC NEAR
    ;draw the game main menu
                                     CALL   CLEAR_SCREEN                        ;clear the screen before displaying the menu

    ;shows the menu title
                                     MOV    AH,02h                              ;set cursor position
                                     MOV    BH,00h                              ;set page number
                                     MOV    DH,04h                              ;set row
                                     MOV    DL,04h                              ;set column
                                     INT    10h

                                     MOV    AH,09h                              ;Write string to standard output
                                     LEA    DX,TEXT_MAIN_MENU_TITLE             ;give DX a pointer to string TEXT_MAIN_MENU_TITLE
                                     INT    21h                                 ;print the string

    ;show the singleplayer option
                                     MOV    AH,02h                              ;set cursor position
                                     MOV    BH,00h                              ;set page number
                                     MOV    DH,07h                              ;set row
                                     MOV    DL,04h                              ;set column
                                     INT    10h

                                     CALL   UPDATE_WINNER_TEXT

                                     MOV    AH,09h                              ;Write string to standard output
                                     LEA    DX,TEXT_MAIN_MENU_SINGLEPLAYER      ;give DX a pointer to select SINGLEPLAYER mode
                                     INT    21h

    ;show the multiplayer option
                                     MOV    AH,02h                              ;set cursor position
                                     MOV    BH,00h                              ;set page number
                                     MOV    DH,09h                              ;set row
                                     MOV    DL,04h                              ;set column
                                     INT    10h

                                     CALL   UPDATE_WINNER_TEXT

                                     MOV    AH,09h                              ;Write string to standard output
                                     LEA    DX,TEXT_MAIN_MENU_MULTIPLAYER       ;give DX a pointer to select MULTIPLAYER mode
                                     INT    21h

    ;show the exit
                                     MOV    AH,02h                              ;set cursor position
                                     MOV    BH,00h                              ;set page number
                                     MOV    DH,14h                              ;set row
                                     MOV    DL,04h                              ;set column
                                     INT    10h

                                     MOV    AH,09h                              ;Write string to standard output
                                     LEA    DX,TEXT_MAIN_MENU_EXIT              ;give DX a pointer to EXIT the game
                                     INT    21h

    ;show the copyright
                                     MOV    AH,02h                              ;set cursor position
                                     MOV    BH,00h                              ;set page number
                                     MOV    DH,16h                              ;set row
                                     MOV    DL,04h                              ;set column
                                     INT    10h

                                     MOV    AH,09h                              ;Write string to standard output
                                     LEA    DX,TEXT_MAIN_MENU_MADE              ; editedbymyself, hi from timmy
                                     INT    21h

    MAIN_MENU_WAIT_FOR_KEY:          
    ;Waits for a key press (to stop drawing)
                                     MOV    AH,00h
                                     INT    16h

    ;check which key was pressed
                                     CMP    AL,'1'
                                     JE     START_SINGLEPLAYER
                                     CMP    AL,'2'
                                     JE     START_MULTIPLAYER
                                     CMP    AL,'E'
                                     JE     EXIT_GAME
                                     CMP    AL,'e'
                                     JE     EXIT_GAME
                                     JMP    MAIN_MENU_WAIT_FOR_KEY

    START_SINGLEPLAYER:              
                                     MOV    CURRENT_SCENE,01h
                                     MOV    GAME_ACTIVE,01h
                                     MOV    COMPUTER_CONTROLLED,01h
                                     RET
    START_MULTIPLAYER:               
                                     MOV    CURRENT_SCENE,01h
                                     MOV    GAME_ACTIVE,01h
                                     MOV    COMPUTER_CONTROLLED,00h
                                     RET
    EXIT_GAME:                       
                                     MOV    EXITING_GAME,01h

                                     RET
DRAW_MAIN_MENU ENDP

DRAW_GAME_OVER_MENU PROC NEAR
    ;draw the game over menu
                                     CALL   CLEAR_SCREEN                        ;clear the screen before displaying the menu

    ;shows the menu title
                                     MOV    AH,02h                              ;set cursor position
                                     MOV    BH,00h                              ;set page number
                                     MOV    DH,04h                              ;set row
                                     MOV    DL,04h                              ;set column
                                     INT    10h

                                     MOV    AH,09h                              ;Write string to standard output
                                     LEA    DX,TEXT_GAME_OVER_TITLE             ;give DX a pointer to string TEXT_GAME_OVER_TITLE
                                     INT    21h                                 ;print the string

    ;show who won the game
                                     MOV    AH,02h                              ;set cursor position
                                     MOV    BH,00h                              ;set page number
                                     MOV    DH,07h                              ;set row
                                     MOV    DL,04h                              ;set column
                                     INT    10h

                                     CALL   UPDATE_WINNER_TEXT

                                     MOV    AH,09h                              ;Write string to standard output
                                     LEA    DX,TEXT_GAME_OVER_WINNER            ;give DX a pointer to string TEXT_GAME_OVER_TITLE
                                     INT    21h

    ;show the play again message
                                     MOV    AH,02h                              ;set cursor position
                                     MOV    BH,00h                              ;set page number
                                     MOV    DH,14h                              ;set row
                                     MOV    DL,04h                              ;set column
                                     INT    10h

                                     MOV    AH,09h                              ;Write string to standard output
                                     LEA    DX,TEXT_GAME_OVER_PLAY_AGAIN        ;give DX a pointer TEXT_GAME_OVER_PLAY_AGAIN
                                     INT    21h

    ;show the main menu message (game over)
                                     MOV    AH,02h                              ;set cursor position
                                     MOV    BH,00h                              ;set page number
                                     MOV    DH,16h                              ;set row
                                     MOV    DL,04h                              ;set column
                                     INT    10h

                                     MOV    AH,09h                              ;Write string to standard output
                                     LEA    DX,TEXT_GAME_OVER_MAIN_MENU         ;give DX a pointer TEXT_GAME_OVER_PLAY_AGAIN
                                     INT    21h

    ;Waits for a key press (to stop drawing)
                                     MOV    AH,00h
                                     INT    16h

    ;'R' or 'r' restarts the game
                                     CMP    AL,'R'
                                     JE     RESTART_GAME
                                     CMP    AL,'r'
                                     JE     RESTART_GAME

    ;'E' or 'e' for the main menu
                                     CMP    AL,'E'
                                     JE     EXIT_TO_MAIN_MENU
                                     CMP    AL,'e'
                                     JE     EXIT_TO_MAIN_MENU
                                     RET

    RESTART_GAME:                    
                                     MOV    GAME_ACTIVE,01h
                                     RET

    EXIT_TO_MAIN_MENU:               
                                     MOV    GAME_ACTIVE,00h
                                     MOV    CURRENT_SCENE,00h

                                     RET
DRAW_GAME_OVER_MENU ENDP

UPDATE_WINNER_TEXT PROC NEAR
                                     MOV    AL,WINNER_INDEX                     ;if winner index is 1 => AL,1
                                     ADD    AL,30h                              ;ASCII to Number AL,31h => AL,'1'
                                     MOV    [TEXT_GAME_OVER_WINNER+7],AL        ;update the index with the character
                                     RET
UPDATE_WINNER_TEXT ENDP


CLEAR_SCREEN PROC NEAR
    ;add again the background to not create a snake for DRAW_BALL
                                     MOV    AH,00h                              ; set video mode
                                     MOV    AL,13h                              ; 13 320x200 256 color (VGA)
                                     INT    10h

                                     MOV    AH,08h                              ;set config
                                     MOV    BH,00h                              ;to the background color
                                     MOV    BL,00h                              ;Black as background 08h - dark gray
                                     INT    10h

                                     RET
CLEAR_SCREEN ENDP

CONCLUDE_EXIT_GAME PROC NEAR
    ;Terminate the game
                                     MOV    AH,00h                              ; set video mode
                                     MOV    AL,02h                              ; video mode to text mode
                                     INT    10h

                                     MOV    AH,4Ch                              ;EXIT - TERMINATE PROGRAM
                                     INT    21h                                 ;INT 21h - DOS Function

CONCLUDE_EXIT_GAME ENDP
 
CODE ENDS
END        

