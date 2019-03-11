*=$0801

        .byte    $0E, $08, $0A, $00, $9E, $20, $28,  $32, $33, $30, $34, $29, $00, $00, $00

*=$0900

.const VIC2 = $d000
.const JOY_UP     = %00000001
.const JOY_DOWN   = %00000010
.const JOY_LEFT   = %00000100
.const JOY_RIGHT  = %00001000
.const JOY_BUTTON = %00010000

.const JOY_NEUTRAL = %00011111

.label kernal_chrout    = $ffd2
.label joystick_port_1 = $dc01
.label joystick_port_2 = $dc00

.namespace sprites {
    .label positions    = VIC2
    .label enable_bits = VIC2 + 21
    .label colors = VIC2 + 39
    .label pointers = $0400 + 1024 - 8
    .label vertical_stretch_bits = VIC2 + 23
}

.label player       = %00000001
.label playerXPos   = $7000
.label playerYPos   = $7002

.label enemy        = %00000011
.label enemyXPos    = $7004
.label enemyYPos    = $7006

.const COLLISIONX1 = $02
.const COLLISIONX2 = $03
.const COLLISIONY1 = $04
.const COLLISIONY2 = $05

.const XSIZE1 = $06    //The area of the drawn sprite on the left
.const XSIZE2 = $0c    //The area of the drawn sprite on the right
.const YSIZE1 = $0C    //The area of the drawn sprite at the top
.const YSIZE2 = $18    //The area of the drawn sprite at the bottom

main:
    lda #147
    jsr kernal_chrout

    ldx #$00            // set x to zero
    stx $d021           // background color
    stx $d020           // border color

    lda #player
    sta sprites.enable_bits
    .var x = 25
    .var y = 51
    lda #x
    sta playerXPos
    sta sprites.positions + 0
    lda #y
    sta playerYPos
    sta sprites.positions + 1

    lda #enemy
    sta sprites.enable_bits
    .var a = 150
    .var b = 150
    lda #a
    sta enemyXPos
    sta sprites.positions + 2
    lda #b
    sta enemyYPos
    sta sprites.positions + 3
    
    // :draw_sprite(%00000001, 25, 51, 1000, $01, 0, 0)
    // :draw_sprite(%00000011, 255, 51, 1001, $01, 2, 1)

game_loop:
    // :handle_joystick_input(joystick_port_1, 1, 1000)
    // :handle_joystick_input(joystick_port_2, 3, 1010)
    :handle_joystick_input(joystick_port_1)
    jmp game_loop
end:

.macro draw_sprite(sprite, x, y, memLocation, color, offset, spriteIndex) {
    lda #sprite
    sta sprites.enabled_bits
    sta sprites.vertical_stretch_bits
    lda #color
    sta sprites.colors + spriteIndex

    lda #x
    sta playerXPos
    sta sprites.postition + 0 + offset
    lda #y
    sta playerYPos
    sta memLocation
    sta sprites.postition + 1 + offset
    
    lda #254
    sta sprites.pointers + spriteIndex
}

.macro handle_joystick_input(joystick) {
    lda joystick 
    and #JOY_BUTTON
    bne action_up
    //do something with button press
action_up:
    lda joystick
    and #JOY_UP
    bne action_down
    :dely()
    ldy playerYPos
    dey
    sty sprites.positions + 1
    sty playerYPos
    jmp collision
action_down:
    lda joystick
    and #JOY_DOWN
    bne action_left
    :dely()
    ldy playerYPos
    iny
    sty sprites.positions + 1
    sty playerYPos
    jmp collision
action_left:
    lda joystick
    and #JOY_LEFT
    bne action_right
    :dely()
    ldy playerXPos
    dey
    sty sprites.positions
    sty playerXPos
    jmp collision
action_right:
    lda joystick
    and #JOY_RIGHT
    bne collision
    :dely()
    ldy playerXPos
    iny
    sty sprites.positions
    sty playerXPos
    jmp collision

collision:
    lda playerXPos
    sec
    sbc #XSIZE1
    sta COLLISIONX1
    clc
    adc #XSIZE2
    sta COLLISIONX2
    lda playerYPos
    sec
    sbc #YSIZE1
    sta COLLISIONY1
    clc
    adc #YSIZE2
    sta COLLISIONY2

    lda enemyXPos
    cmp COLLISIONX1
    bcc NOTHIT
    cmp COLLISIONX2
    bcs NOTHIT

    lda enemyYPos
    cmp COLLISIONY1
    bcc NOTHIT
    cmp COLLISIONY2
    bcs NOTHIT
HIT:         
    lda #$01
    sta $D020

    lda playerXPos
    sta sprites.positions + 2
    sta sprites.positions + 3
    jmp end
NOTHIT:      
    lda #$00
    sta $D020
end:
}

.macro dely() {
    ldx #$00
loop:
    nop
    inx
    bne loop
}