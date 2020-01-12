#define __SFR_OFFSET 0

#include <avr/io.h>
#include <avr/interrupt.h>

; Caller saved
temp10 = 2

temp1 = 16
temp2 = 17
temp3 = 18
temp4 = 19
temp5 = 20

; `global' registers
switch_prescaler = 10
led_state = 11
requests = 12
hmi_debounce = 13

; Additionally caller saved: Z, SREG

.section .text

.org 0x0000
	rjmp init

.org TIM0_OVF_vect_num * 2
	rjmp timer0_overflow_handler


; Interrupt handlers
timer0_overflow_handler:
	push temp1
	in temp1, SREG
	push temp1
	push temp2
	push temp3
	push temp4
	push temp5
	push ZL
	push ZH

	; 'Soft timers'
	dec switch_prescaler
	brne .after_switches

	ldi temp1, 50
	mov switch_prescaler, temp1

	; Schedule read buttons
	com requests

.after_switches:
	; Both leds enabled?
	mov temp1, led_state
	com temp1
	andi temp1, 0b11
	brne .after_leds

	; Which one to light?
	mov temp1, led_state
	andi temp1, 0xf0
	breq .green

	ldi temp1, 0x0f
	and led_state, temp1

	cbi PORTA, 0
	sbi PORTA, 1
	rjmp .after_leds

.green:
	ldi temp1, 0xf0
	or led_state, temp1

	sbi PORTA, 0
	cbi PORTA, 1

.after_leds:
	pop ZH
	pop ZL
	pop temp5
	pop temp4
	pop temp3
	pop temp2
	pop temp1
	out SREG, temp1
	pop temp1
	reti

; Functions
hmi_comp_delay:
	ret

; Name:        enable_green_led
; Description: Enable the green led
enable_green_led:
	ldi temp1, 0b1
	or led_state, temp1

	mov temp1, led_state
	com temp1
	andi temp1, 0b11
	breq .no_action

	cbi PORTA, 1
	sbi PORTA, 0

.no_action:
	ret

enable_red_led:
	ldi temp1, 0b10
	or led_state, temp1

	mov temp1, led_state
	com temp1
	andi temp1, 0b11
	breq .no_action2

	cbi PORTA, 0
	sbi PORTA, 1

.no_action2:
	ret

disable_green_led:
	ldi temp1, ~0b1
	and led_state, temp1

	cbi PORTA, 0
	cbi PORTA, 1
	sbrc led_state, 1
	sbi PORTA, 1

	ret

disable_red_led:
	ldi temp1, ~0b10
	and led_state, temp1

	cbi PORTA, 0
	cbi PORTA, 1
	sbrc led_state, 0
	sbi PORTA, 0

	ret

; Name:        read_switches
; Description: Read the four switches using the ADC
; Parameters:  None.
; Returns:     temp1: switch positions.
.global read_switches
read_switches:
	; Enable voltage
	;ori temp1, 0b11
	sbi PORTA, 3

	;ori temp2, 0b11
	sbi DDRA, 3

	; Enable ADC and set ADMUX
	ldi temp1, 2
	out ADMUX, temp1

	sbi ADCSRA, ADEN

	; Do a conversion and discard the result after switching the reference
	; voltage source.
	sbi ADCSRA, ADSC

.adc1_loop:
	sbic ADCSRA, ADSC
	rjmp .adc1_loop

	; Measure 64 times and take mean
	clr temp1
	clr temp2

	ldi temp3, 64

.mean_loop:
	sbi ADCSRA, ADSC

.mean_adc_loop:
	sbic ADCSRA, ADSC
	rjmp .mean_adc_loop

	in temp5, ADCL
	add temp1, temp5

	in temp5, ADCH
	adc temp2, temp5

	dec temp3
	brne .mean_loop

	; Disable ADC and restore output state
	cbi DDRA, 3
	cbi PORTA, 3

	cbi ADCSRA, ADEN

	; temp2:temp1 contains the 16.0 representation of the sum of all
	; measurements now. Make it an 8 bit value.
	subi temp1, lo8(-128)
	sbci temp2, hi8(-128)

	; Now, temp2 is the wanted 8 bit value.
	; Compare it with the table.
	ldi temp1, 0xff
	clr temp3
	ldi temp4, 16

	ldi ZL, lo8(codepoint_table + 16)
	ldi ZH, hi8(codepoint_table + 16)

.compare_loop:
	subi temp4, 1
	brcs .compare_loop_end

	subi ZL, 1
	sbci ZH, 0

	lpm temp5, Z

	; Make temp5 >= temp10 ( = temp2 )
	mov temp10, temp2

	cp temp5, temp10
	brsh .compare_loop_after_xchg

	mov temp10, temp5
	mov temp5, temp2

.compare_loop_after_xchg:
	sub temp5, temp10

	; temp5 is absolute difference
	cp temp5, temp1
	brsh .compare_loop

	; A new minimum
	mov temp3, temp4
	mov temp1, temp5

	rjmp .compare_loop

.compare_loop_end:
	; temp3 is the table index (= switch positions) read.
	mov temp1, temp3

	ret

.global init
init:
	ldi temp1, hi8(RAMEND)
	out SPH, temp1

	ldi temp1, lo8(RAMEND)
	out SPL, temp1

	; IO ports
	clr temp2
	out PORTA, temp2

	ldi temp1, 0b11111011
	out DDRA, temp1

	ldi temp1, 0xff
	out DIDR0, temp1

	out PORTB, temp2

	ldi temp1, 0b111
	out DDRB, temp1

	; ADC
	out ADCSRA, temp2
	out ADCSRB, temp2

	; A timer to run ~500 times per second for the switches and charlieplexing
	out TCCR0A, temp2

	ldi temp1, 0b1
	out TCCR0B, temp1

	ldi temp1, 1 << TOIE0
	out TIMSK0, temp1

	ldi temp1, 1
	mov switch_prescaler, temp1

	mov led_state, temp2

	mov requests, temp2
	mov hmi_debounce, temp2

	ldi temp1, (1 << PRTIM1) | (1 << PRUSI)
	out PRR, temp1

	in temp1, MCUCR
	andi temp1, ~0b11000
	out MCUCR, temp1

	sei

.global main
main:
	in temp1, MCUCR
	ori temp1, 1 << SE
	out MCUCR, temp1

	sleep

	andi temp1, ~(1 << SE)
	out MCUCR, temp1


	mov temp1, requests
	cpi temp1, 0
	breq main

	com requests

	; Read switches
	rcall read_switches

	; Output to LEDs
	swap temp1
	andi temp1, 0xf0

	in temp2, PORTA
	andi temp2, 0x0f

	or temp2, temp1
	out PORTA, temp2


	; Test HMI button
	cli

	in temp3, PORTA

	cbi DDRA, 0
	cbi PORTA, 1
	sbi PORTA, 0

	ldi temp1, 0b01000000
	out ACSR, temp1

	sbi ADCSRB, ACME
	ldi temp1, 0
	out ADMUX, temp1

	rcall hmi_comp_delay

	in temp2, ACSR

	out PORTA, temp3
	sbi DDRA, 0

	sbi ACSR, ACD
	cbi ADCSRB, ACME

	sei

	; Debounce button
	andi temp2, 1 << ACO
	breq hmi_open

	ldi temp2, 1
	cp hmi_debounce, temp2
	brsh hmi_accepted

	inc hmi_debounce
	rjmp main

hmi_open:
	clr hmi_debounce
	rjmp main

hmi_accepted:
	ldi temp2, 2
	cp hmi_debounce, temp2
	brsh main

	inc hmi_debounce

	; shift LEDs
	mov temp1, led_state
	andi temp1, 0b11
	breq enable_green

	cpi temp1, 1
	breq enable_red

	cpi temp1, 2
	breq enable_both

	rcall disable_red_led
	rcall disable_green_led
	rjmp main

enable_green:
	rcall enable_green_led
	rjmp main

enable_red:
	rcall disable_green_led
	rcall enable_red_led
	rjmp main

enable_both:
	rcall enable_green_led
	rjmp main


codepoint_table:
.byte 0, 82, 45, 104, 11, 87, 53, 108, 23, 93, 61, 112, 33, 97, 68, 116

.section .fuse
.byte 0xe4, 0xdd, 0xff
