.equ READ_KEY, 0xff200100
.equ PIXEL_ADDR, 0xc8000000
.equ CHAR_ADDR, 0xc9000000
.global _start
//RVALID = ((*(volatile int *)0xff200100) >> 15) & 0x1
//RVALID is true, the low 8 bits correspond to a byte of keyboard data.

_start:
        bl      input_loop
end:
        b       end

read_PS2_data_ASM:
	push {v1-v4}
	ldr v1, =READ_KEY
	ldr v2, [v1]
	lsr v3, v2, #15 
	and v3, v3, #1 //RVALID bit
	
	cmp v3, #0 // check if 1
	moveq a1, #0
	popeq {v1-v4}
	bxeq lr // if 0 it returns
	
	
	AND v4, v2, #0xff
	strb v4, [a1]
	mov a1, #1 // else
	pop {v1-v4}
	bx lr
	
VGA_draw_point_ASM:
	push {v1}
	ldr v1, =#319
	cmp a1, v1
	cmplt a2, #239
	pop {v1}
	bxgt lr
	
	push {a1, a2, v1}
	lsl a1, a1, #1 // (x << 1)
	lsl a2, a2, #10 // (y << 10)
	
	ldr v1, =PIXEL_ADDR // load pixel address
	orr v1, v1, a1 // add y to address
	orr v1, v1, a2 // add x to address
	
	strh a3, [v1] // store color at adress its 16 bits so halfword
	pop {a1, a2, v1} //restore stack
	bx lr
	
VGA_clear_pixelbuff_ASM: 
	push {v1-v6}
	mov v6, #0 //store reset value

x_ploop:
	push {v2}
	ldr v2, =#319
	cmp v1, v2 //0 =< x =< 319
	pop {v2}
	beq loop_end
y_ploop:	
	cmp v2, #239 //0 =< y =< 239
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

	
VGA_write_char_ASM:
	cmp a1, #79
	cmplt a2, #59
	bxgt lr
	
	push {a1, a2, v1}
	lsl a2, a2, #7 // (y << 7)
	
	ldr v1, =CHAR_ADDR // load pixel address
	orr v1, v1, a1 // add y to address
	orr v1, v1, a2 // add x to address
	
	strb a3, [v1] // store char at address
	pop {a1, a2, v1} //restore stack
	bx lr
	
VGA_clear_charbuff_ASM: 
	push {v1-v6}
	mov v6, #0 //store reset value

x_cloop:
	cmp v1, #79 //0 =< x =< 319
	beq loop_end
y_cloop:	
	cmp v2, #59 //0 =< y =< 239
	moveq v2, #0 //y=0 if y=239
	addeq v1, v1, #1 //x++ if y=239
	beq x_cloop 
	
	lsl v3, v1, #1 // (x << 1)
	lsl v4, v2, #10 // (y << 10)
	ldr v5, =PIXEL_ADDR // load pixel address
	orr v5, v5, v3 // add x to address using bitwise or
	orr v5, v5, v4 // add y to address using bitwise or
	
	strb v6, [v5] // reset characters
	add v2, v2, #1 //y++ increment loop counter
	b y_cloop	
	
	
loop_end:
	pop {v1-v6}
	bx lr

write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}