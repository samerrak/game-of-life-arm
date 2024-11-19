.equ PIXEL_ADDR, 0xc8000000
.equ CHAR_ADDR, 0xc9000000
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071
		
.global _start

_start:
        bl      draw_test_screen
end:
        b       end

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
	
draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}