section .text
global exec_turtle_cmd

;prolog
exec_turtle_cmd:
	push ebp			
	mov ebp, esp	
	
;main procedure
	mov eax, [ebp+12]	;load command address to eax
	
	mov edx, 0	;clear edx
	mov dh, [eax]	;load half of the command
	inc eax
	mov dl, [eax]	;load second half of the command
	push edx	;push edx (command) to use it later 
	
	and dx, 0x3 ;get only instruction bits in dx
	
	cmp dx, 0	;compare to 0 to check if it is set pen state command
	je set_pen_state
	cmp dx, 1	;compare to 1 to check if it is move command
	je move
	cmp dx, 2	;compare to 2 to check if it is set direction command
	je set_direction
	
;============SET POSITION==================
;set_position:	if dx equals 3 than it is set position command
	pop edx	;pop edx to get command 
	mov ebx, [ebp+16]	;load TurtleContextStruct address
	
	mov ecx, [ebp+8]	;move bitmap address
	mov ecx, [ecx+22]	;get bitmap height
	dec ecx
	and dx, 0xfc	;get y coordinate bits
	shr dx, 2	;dx contains y coordinate
	cmp ecx, edx	;compare if y coordinate is not bigger than bitmap height-1
	jge set_y
	mov edx, ecx	;if y coordinate bigger than bitmap height-1 move bitmap height-1
	
set_y:
	mov [ebx+4], dx	;load y coordinate to TurtleContextStruct
	
	mov ecx, [ebp+8]	;move bitmap address
	mov ecx, [ecx+18]	;get bitmap width
	dec ecx
	lea eax, [eax+1]	;get address of next command (eax contains command address)
	mov dh, [eax]	;load half of next command
	inc eax
	mov dl, [eax]	;load second half of next command
	and dx, 0x3ff	;get x coordinate
	cmp ecx, edx	;compare if x coordinate is not bigger than bitmap width-1
	jge set_x
	mov edx, ecx	;if x coordinate bigger than bitmap width-1 move bitmap width-1
	
set_x:
	mov[ebx], dx	;load x coordinate to TurtleContextStruct
	
	jmp exit

;============SET PEN STATE=================
set_pen_state:
	pop edx	;pop edx to get command 
	mov eax, edx	;load command to eax (as a copy)
	mov ebx, [ebp+16]	;load TurtleContextStruct address
	
	and dx, 0x8	;get pen state bits from command
	shr dx, 3	;dx contains pen state
	mov [ebx+12], dx	;load pen state to TurtleContextStruct
	
	mov DWORD[ebx+16], 0x0	;load 0 to color in TurtleContextStruct
	
	mov edx, eax	;move command to edx from eax
	and edx, 0xf0	;get blue color
	or [ebx+16], edx	;load blue to TurtleContextStruct
	shr edx, 4
	or [ebx+16], edx	;load blue to TurtleContextStruct
	
	mov edx, eax	;move command to edx from eax
	and edx, 0xf00	;get green color
	or [ebx+16], edx	;load green to TurtleContextStruct
	shl edx, 4
	or [ebx+16], edx	;load green to TurtleContextStruct
	
	and eax, 0xf000	;get red color
	shl eax, 4
	or [ebx+16], eax	;load red to TurtleContextStruct
	shl eax, 4
	or [ebx+16], eax	;load red to TurtleContextStruct
	
	jmp exit

;============MOVE==========================
move:
	pop edx	;pop edx to get command 
	mov ebx, [ebp+16]	;load TurtleContextStruct address
	
	and dx, 0xFFC0	;get distance bits
	shr dx, 6	;dx contains distance
	mov [ebx+20], dx	;move distance to TurtleContextStruct
	
	mov edx, [ebp+8]	;move bitmap address
	cmp DWORD[ebx+8], 0	;compare direction to 0 to check if move right
	je move_right
	cmp DWORD[ebx+8], 1	;compare direction to 1 to check if move up
	je move_up
	cmp DWORD[ebx+8], 2	;compare direction to 2 to check if move left
	je move_left
	
;move_down:	if direction equals 3 than it is move down
	mov eax, [ebx+4]	;move y coordinate to eax
	sub eax, [ebx+20]	;y coordinate - distance, eax contains destination y coordinate
	cmp eax, 0	;compare to bmp height
	jge if_move_down_with_color
	mov eax, 0	;if less than zero, move 0 to eax

if_move_down_with_color:
	cmp DWORD[ebx+12], 0	;check if move with color
	je end_move_vertical	;if without the color jump to end_move_vertical
	mov ecx, -1	;move -1 to ecx
	jmp go_vertical
	
move_up:
	mov eax, [ebx+4]	;move y coordinate to eax
	add eax, [ebx+20]	;y coordinate + distance, eax contains destination y coordinate
	mov edx, [edx+22]	;get bitmap height
	dec edx	;get bitmap height-1
	cmp eax, edx	;compare to bmp height-1
	jle if_move_up_with_color
	mov eax, edx	;if more than bmp height-1, move bmp height-1 to eax
	
if_move_up_with_color:
	cmp DWORD[ebx+12], 0	;check if move with color
	je end_move_vertical	;if without the color jump to end_move_vertical
	mov ecx, 1	;move 1 to ecx
	
go_vertical:
	cmp eax, [ebx+4]	;compare if it is last pixel
	je exit
	call put_pixel	;put pixel at coordinates from TurtleContextStruct
	add [ebx+4], ecx	;add 1 (if move up) or -1 (if move down) and get next y coordinate to put pixel
	jmp go_vertical

end_move_vertical:
	mov [ebx+4], eax	;move eax to TurtleContextStruct (important if move without color)
	jmp exit
	
move_right:
	mov eax, [ebx]	;move x coordinate to eax
	add eax, [ebx+20]	;x coordinate + distance, eax contains destination x coordinate
	mov edx, [edx+18]	;get bitmap width
	dec edx	;get bitmap width-1
	cmp eax, edx	;compare to bmp width-1
	jle if_move_right_with_color
	mov eax, edx	;if more than bmp width-1, move bmp width-1 to eax
	
if_move_right_with_color:
	cmp DWORD[ebx+12], 0	;check if move with color
	je end_move_horizontal	;if without the color jump to end_move_horizontal
	mov ecx, 1	;move 1 to ecx
	jmp go_horizontal
	
move_left:
	mov eax, [ebx]	;move x coordinate to eax
	sub eax, [ebx+20]	;x coordinate - distance, eax contains destination x coordinate
	cmp eax, 0	;compare to 0 to check if x coordinate is not less than 0
	jge if_move_left_with_color
	mov eax, 0	;if less than zero, move 0 to eax
	
if_move_left_with_color:
	cmp DWORD[ebx+12], 0	;check if move with color
	je end_move_horizontal	;if without the color jump to end_move_horizontal
	mov ecx, -1	;move -1 to ecx
	
go_horizontal:
	cmp eax, [ebx]	;compare if it is last pixel
	je exit
	call put_pixel	;put pixel at coordinates from TurtleContextStruct
	add [ebx], ecx	;add 1 (if move right) or -1 (if move left) and get next x coordinate to put pixel
	jmp go_horizontal
	
end_move_horizontal:
	mov [ebx], eax	;move eax to TurtleContextStruct (important if move without color)
	jmp exit

;============SET DIRECTION===============
set_direction:
	pop edx	;pop edx to get command
	mov ebx, [ebp+16]	;load TurtleContextStruct address
	
	and dx, 0xc000	;get direction bits
	shr dx, 14	;dx contains direction
	mov [ebx+8], dx		;move direction to TurtleContextStruct

;============EXIT==========================
;epilog
exit:
	mov eax, 0 
	pop ebp				
	ret	
	
;============PUT PIXEL===================
put_pixel:
	push eax	;push eax
	push ebx	;push ebx
	push ecx	;push ecx
	push edx	;push edx
	
	mov eax, [ebp+8]	;load bitmap address
	mov ebx, [eax+18]	;load bitmap width
	mov ecx, [ebp+16]	;load TurtleContextStruct address
	mov edx, [ecx+4]	;load y coordinate from TurtleContextStruct
	
	imul ebx, 3	;(width * 3 + 3) & ~3
	add ebx, 3
	and ebx, 0xFFFFFFFC
	imul ebx, edx	;((width * 3 + 3) & ~3) * y coordinate
	
	mov edx, [ecx]	;load x coordinate from TurtleContextStruct
	imul edx, 3	;x coordinate * 3
	add ebx, edx	;((width * 3 + 3) & ~3) * y coordinate + x coordinate * 3
	add ebx, eax	;add bitmap address
	add ebx, 54	;add bitmap header size, ebx contains address of pixel on x,y coordinates
	
	mov edx, [ecx+16]	;move color to edx
	mov [ebx], dx	;move green and blue
	shr edx, 16	;edx contains 0x000000RR
	mov [ebx+2], dl ;move red
	
	pop edx	;pop edx
	pop ecx	;pop ecx
	pop ebx	;pop ebx
	pop eax	;pop eax
	
