.equ READ_KEY, 0xff200100
.equ PIXEL_ADDR, 0xc8000000
.equ CHAR_ADDR, 0xc9000000
.global _start

_start:
	bl VGA_clear_pixelbuff_ASM
	bl VGA_grey_pixelbuff_ASM
	bl GoL_draw_grid_ASM
	push {a1}
	ldr a1, =GoLBoard
	bl GoL_draw_board_ASM
	pop {a1}
	bl cursor
	

cursor:
	mov a1, #0 
	mov a2, #0
	ldr a3, =#0xeeee //inactive yellow
	bl VGA_draw_rect_ASM
	push {v1-v8}
	mov v1, #0 //box y coordinate
	mov v2, #0 //box y coordinate
	mov v8, a3

stack:	
	push {v1-v4, v8}
	mov v1, #0
	mov v2, #0
	mov v3, #0
	mov v4, #0

read_PS2_data_ASM:
	cmp v4, #3
	popeq {v1-v4, v8}
	beq poll
	
	ldr v1, =READ_KEY
	ldr v2, [v1]
	lsr v3, v2, #15 
	and v3, v3, #1 //RVALID bit
	
	cmp v3, #0 // check if 1
	moveq v2, #0
	beq dummy_loop // if 0 it returns
	
	AND v2, v2, #0xff
	cmp v4, #0
	moveq a1, v2
	cmp v4, #1
	moveq a2, v2
	cmp v4, #2
	moveq a3, v2
	add v4, v4, #1
	b read_PS2_data_ASM
poll:
	
	mov v3, #0
	mov v4, a1 //read make
	mov v5, a2 //read break1
	mov v6, a3 //read break2
	
	lsl v4, v4, #16 
	lsl v5, v5, #8
	orr v3, v6, v4
	orr v3, v3, v5 // I do this so I have only one compare instead of 3 for each 
	//format is 0x00makebreak1break2
	

	ldr v6, =#0x0029f029
	cmp v3, v6 //space bar

	beq space_bar
	
	ldr v6, =#0x0031f031
	cmp v3, v6 //n
	moveq a1, v1
	moveq a2, v2
	beq neighbor_check
	
	ldr v6, =#0x001df01d
	cmp v3, v6 //w
	beq w_motion
	
	ldr v6, =#0x001cf01c
	cmp v3, v6 //a
	beq a_motion
	
	ldr v6, =0x001bf01b
	cmp v3, v6 //s
	beq s_motion
	
	ldr v6, =0x0023f023
	cmp v3, v6 //d
	beq d_motion
	
space_bar:
	mov v7, #1
	b stack

compare:
	mov a1, v1
	mov a2, v2
	ldr a3, =#0xeeee //inactive
	cmp v7, #1 //space bar 
	bne compare2
	cmp v8, a3 //if inactive make it active
	moveq a3, #0 //if inactive toggle it so that it's a zero
	ldrne a3, =#0x0777 //if active toggle it to green
	bx lr
compare2:
	cmp v8, a3 //inactive
	ldreq a3, =#0x0777
	movne a3, #0
	bx lr
	
	
w_motion:
	cmp v2, #0 //check y coordinates cant go up more than 1 
	beq stack
	push {lr}
	bl compare
	pop {lr}
	cmp v7, #1
	moveq v7, #0
	push {lr}
	bl VGA_draw_rect_ASM
	pop {lr}
	add v2, v2, #-1
	b update
	
a_motion:
	cmp v1, #0 //check x coordinates cant go left if at 0
	beq stack
	push {lr}
	bl compare
	pop {lr}
	cmp v7, #1
	moveq v7, #0
	push {lr}
	bl VGA_draw_rect_ASM
	pop {lr}
	add v1, v1, #-1
	b update
	
s_motion:
	cmp v2, #11 //check y coordinates cant go down if at 12 
	beq stack
	push {lr}
	bl compare
	pop {lr}
	cmp v7, #1
	moveq v7, #0
	push {lr}
	bl VGA_draw_rect_ASM
	pop {lr}
	add v2, v2, #1
	b update
	
d_motion:
	cmp v1, #15 //check y coordinates cant go right if at 16
	beq stack
	push {lr}
	bl compare
	pop {lr}
	cmp v7, #1
	moveq v7, #0
	push {lr}
	bl VGA_draw_rect_ASM
	pop {lr}
	add v1, v1, #1
	b update

update:
	push {lr}
	mov a1, v1
	mov a2, v2
	bl VGA_get_rect_colo_ASM
	pop {lr}
	cmp a3, #0
	ldreq a3, =#0xdddd
	ldrne a3, =#0xeeee
	mov a1, v1
	mov a2, v2
	push {a3, lr}
	bl VGA_draw_rect_ASM
	pop {a3, lr}
	mov v8, a3
	b stack
	
	

	
	
end:
	B end
	
GoL_draw_board_ASM: // I will reverse engineer this process basically, I will flatten
//the 2D array by using a counter and since the size is constant we can find
//the 2D indices and pass them as an argument
	push {v1-v8}
	mov v1, a1
ind_loop:
	cmp v3, #193
	popeq {v1-v8}
	bxeq lr //maximum is 192 in 16x12
	mov v7, #4
	mul v7, v7, v3
	ldr v2, [v1, v7] //offset counter
	cmp v2, #1 
	mov v4, v3
	mov v5, #0
	beq division
	add v3, v3, #1
	b ind_loop
	
division:
	cmp v4, #16
	blt next
	add v5, v5, #1 //quotient row index
	sub v4, v4, #16 //remainder col index
	b division
	
next:
	movlt a2, v5 // col
	movlt a1, v4 // row
	push {v1-v8, lr}
	mov v1, #0
	mov v2, #0
	mov v3, #0
	mov v4, #0
	mov v5, #0
	mov v6, #0
	mov v7, #0
	mov v8, #0
	bl VGA_draw_rect_ASM // draw rectangle 
	pop {v1-v8, lr} 
	add v3, v3, #1
	b ind_loop
	
VGA_draw_rect_ASM:
 // so u need to multiply by 20 to get the starting position
	push {v1 - v8}
	mov v7, #0
	mov v8, #0
	mov v1, #20
	mul a1, a1, v1
	mul a2, a2, v1 //updated starting point
	//you want to draw a line here now and go row by row
	mov v1, #0
	mov v1, a1
	add a1, a1, #1 // this was added so that the grid lines are not overwritten
	mov v2, a2
	add v2, v2, #1 // this too 
	mov v6, a3 //color

rect_loop:
	mov v1, a1
	add v1, v1, v7
	cmp v7, #19 //19 instead of 20 so that grid lines are not overwritten
	moveq v1, a1 //reset x
	addeq v2, v2, #1 //next y
	moveq v7, #0
	addeq v8, v8, #1 //same
	cmp v8, #19
	popeq {v1 - v8}
	bxeq lr
	
	
	lsl v3, v1, #1 // (x << 1)
	lsl v4, v2, #10 // (y << 10)
	ldr v5, =PIXEL_ADDR // load pixel address
	orr v5, v5, v3 // add x to address using bitwise or
	orr v5, v5, v4 // add y to address using bitwise or
	strh v6, [v5] // reset pixels
	add v7, v7, #1 //x++ increment loop counter
	b rect_loop	

VGA_get_rect_colo_ASM:
 // so u need to multiply by 20 to get the starting position
	push {v1 - v8}
	mov v1, #20
	mul a1, a1, v1
	mul a2, a2, v1 //updated starting point
	//you want to draw a line here now and go row by row
	mov v1, #0
	mov v1, a1
	add a1, a1, #1 // this was added so that the grid lines are not overwritten
	mov v2, a2
	add v2, v2, #1 // this too 	
	
	lsl v3, v1, #1 // (x << 1)
	lsl v4, v2, #10 // (y << 10)
	ldr v5, =PIXEL_ADDR // load pixel address
	orr v5, v5, v3 // add x to address using bitwise or
	orr v5, v5, v4 // add y to address using bitwise or
	ldrh v6, [v5, #4] // reset pixels, updated
	mov a3, v6
	pop {v1-v8}
	bx lr

	
GoL_draw_grid_ASM:
	push {v1-v8}

y_poop:	//each grid is 20x20
	cmp v2, #240 //0 =< y =< 239
	moveq v2, #0 //y=0 if y=239
	addeq v1, v1, #20 //x++ if y=239
	addeq v7, v7, #1
	cmp v7, #16
	ldreq v1, =#319 //border line
	cmp v7, #17

	popeq {v1-v8}
	beq draw_horizontal

	lsl v3, v1, #1 // (x << 1)
	lsl v4, v2, #10 // (y << 10)
	ldr v5, =PIXEL_ADDR // load pixel address
	orr v5, v5, v3 // add x to address using bitwise or
	orr v5, v5, v4 // add y to address using bitwise or
	
	strh v6, [v5] // reset pixels
	add v2, v2, #1 //y++ increment loop counter
	b y_poop	
	
draw_horizontal:
	push {v1-v8}

x_poop:
	cmp v1, #320 //0 =< x =< 320
	moveq v1, #0 //x=0 if x=320
	addeq v2, v2, #20 //y+20 if x=320
	addeq v7, v7, #1
	cmp v7, #12
	moveq v2, #239
	cmp v7, #13
	popeq {v1-v8}
	bxeq lr
	
	lsl v3, v1, #1 // (x << 1)
	lsl v4, v2, #10 // (y << 10)
	ldr v5, =PIXEL_ADDR // load pixel address
	orr v5, v5, v3 // add x to address using bitwise or
	orr v5, v5, v4 // add y to address using bitwise or
	
	strh v6, [v5] // reset pixels
	add v1, v1, #1 //y++ increment loop counter
	b x_poop	

	
VGA_clear_pixelbuff_ASM: 
	push {v1-v6}
	mov v6, #0 
	b x_ploop
	
VGA_grey_pixelbuff_ASM: 
	push {v1-v6}
	ldr v6, =#0x0777

x_ploop:
	push {v2}
	ldr v2, =#320
	cmp v1, v2 //0 =< x =< 319
	pop {v2}
	beq loop_end
y_ploop:	
	cmp v2, #240 //0 =< y =< 239
	moveq v2, #0 //y=0 if y=239
	addeq v1, v1, #1 //x++ if y=239
	beq x_ploop 
	
	lsl v3, v1, #1 // (x << 1)
	lsl v4, v2, #10 // (y << 10)
	ldr v5, =PIXEL_ADDR // load pixel address
	orr v5, v5, v3 // add x to address using bitwise or
	orr v5, v5, v4 // add y to address using bitwise or
	
	strh v6, [v5] // reset pixels
	add v2, v2, #1 //y++ increment loop counter
	b y_ploop


loop_end:
	pop {v1-v6}
	bx lr
	
dummy_loop:
	add v8, v8, #1
	add v8, v8, #1
	add v8, v8, #1
	add v8, v8, #1
	add v8, v8, #1
	b read
read:
	add v8, v8, #1
	mov v8, #0
	b read_PS2_data_ASM
	
	
neighbor_check:
	push {v1-v8}
	mov a1, #0
	mov a2, #0
	mov v3, #0
	mov v4, #0
	mov v5, #0
	mov v6, #0
	ldr a4, =GoLBoard2

	
n_check:
	mov a3, #0

xplus1_y: //(x+1, y)
	cmp a1, #15
	beq xminus1_y
	push {a1-a3, lr}
	add a1, a1, #1
	bl VGA_get_rect_colo_ASM
	cmp a3, #0
	pop {a1-a3, lr}
	addeq a3, a3, #1
	
	
xminus1_y:	//(x-1, y)
	cmp a1, #0
	beq x_yplus1
	push {a1-a3, lr}
	add a1, a1, #-1
	bl VGA_get_rect_colo_ASM
	cmp a3, #0
	pop {a1-a3, lr}
	addeq a3, a3, #1
	
x_yplus1: //(x, y+1)
	cmp a2, #11
	beq x_yminus1
	push {a1-a3, lr}
	add a2, a2, #1
	bl VGA_get_rect_colo_ASM
	cmp a3, #0
	pop {a1-a3, lr}
	addeq a3, a3, #1
	
x_yminus1: //(x, y-1)
	cmp a2, #0
	beq xy_plus1
	push {a1-a3, lr}
	add a2, a2, #-1
	bl VGA_get_rect_colo_ASM
	cmp a3, #0
	pop {a1-a3, lr}
	addeq a3, a3, #1
	
xy_plus1: //(x+1, y+1)
	cmp a1, #15
	cmpne a2, #11
	beq xy_minus1
	push {a1-a3, lr}
	add a1, a1, #1
	add a2, a2, #1
	bl VGA_get_rect_colo_ASM
	cmp a3, #0
	pop {a1-a3, lr}
	addeq a3, a3, #1
	
xy_minus1: //(x-1, y-1)
	cmp a1, #0
	cmpne a2, #0
	beq xplus1_yminus1	
	push {a1-a3, lr}
	add a1, a1, #-1
	add a2, a2, #-1
	bl VGA_get_rect_colo_ASM
	cmp a3, #0
	pop {a1-a3, lr}
	addeq a3, a3, #1
	
xplus1_yminus1: //(x+1, y-1)
	cmp a1, #15
	cmpne a2, #0
	beq xminus1_yplus1
	push {a1-a3, lr}
	add a1, a1, #1
	add a2, a2, #-1
	bl VGA_get_rect_colo_ASM
	cmp a3, #0
	pop {a1-a3, lr}
	addeq a3, a3, #1
	
xminus1_yplus1: //(x-1, y+1)
	cmp a1, #0
	cmpne a2, #11
	beq check_activity
	push {a1-a3, lr}
	add a1, a1, #-1
	add a2, a2, #1
	bl VGA_get_rect_colo_ASM
	cmp a3, #0
	pop {a1-a3, lr}
	addeq a3, a3, #1
	
check_activity:
	push {a1-a3, lr}	
	bl VGA_get_rect_colo_ASM
	mov v1, a3
	pop {a1-a3, lr}
	cmp v1, #0 
	bne inactive
	

active:
	

case1: //inactive if only 0 or 1 are active
	cmp a3, #1
	bgt case2
	push {a1-a3, lr}
	mov a1, #0
	str a1, [a4]
	pop  {a1-a3, lr}
	b finalize
		
case2: //remain active if 2 or 3
	cmp a3, #3
	bgt case3
	push {a1-a3}
	mov a1, #1
	str a1, [a4]
	pop {a1-a3}
	b finalize
	
	
case3: //inactive if 4 or more
	cmp a3, #4
	b finalize
	push {a1-a3}
	mov a1, #0
	str a1, [a4]
	pop {a1-a3}
	b finalize
	
inactive:	
	cmp a3, #3
	bne finalize
	push {a1-a3}
	mov a1, #1
	str a1, [a4]
	pop  {a1-a3}
	
	
finalize:
	add a1, a1, #1
	mov v1, #0
	mov v2, #0
	cmp a1, #16
	moveq a1, #0
	addeq a2, #1
	cmp a2, #12
	add a4, a4, #4
	bne n_check
	popeq {v1-v8}
	popeq {v1-v8}
	mov a1, #0
	mov a2, #0
	mov a3, #0
	push {a1, lr}
	bl VGA_clear_pixelbuff_ASM
	bl VGA_grey_pixelbuff_ASM
	bl GoL_draw_grid_ASM
	ldr a1, =GoLBoard2
	bl GoL_draw_board_ASM
	bl GoLBoard2_clear
	pop {a1, lr}
	b cursor
	
	
GoLBoard2_clear:
	push {v1-v8}
	ldr v1, =GoLBoard2
	mov v2, #0
	mov v3, #0
clear_b:
	cmp v2, #196
	popeq {v1-v8}
	bxeq lr
	str v3, [v1]
	add v1, v1, #4
	add v2, v2, #1
	b clear_b

	

GoLBoard2:
	//  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 1
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 2
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 3
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 4
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 5
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 6
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 7
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 8
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 9
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // a
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // b
	
	
space:
	//  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 1
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 2
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 3
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 4
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 5
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 6
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 7
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 8
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 9
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // a
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // b
	
	
GoLBoard:
	//  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 1
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 2
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 3
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 4
	.word 0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0 // 5
	.word 0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0 // 6
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 7
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 8
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 9
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // a
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // b