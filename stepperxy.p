.origin 0
.entrypoint START

#include "stepperxy.hp"

#define GPIO1 0x4804c000
#define GPIO_CLEARDATAOUT 0x190
#define GPIO_SETDATAOUT 0x194
#define DELAYCLICS 10000000
#define LED_OFFSET 21

#define COUNTER			r1
#define BLOCKSIZE		r8
#define PULSEWIDTH		r9
#define BLOCKPOS		r7

#define SEGM			r10
#define SEGM_SIZE		20

#define STATUS 			r10
#define PULSE_X 		r11
#define INTERVAL_X		r12
#define PULSE_Y     	r13
#define INTERVAL_Y		r14

#define X_POS			r15
#define Y_POS			r16

#define X_OFF			r17
#define Y_OFF 			r18

#define MEM_POS			r19

#define STEPX			21
#define DIRX			22
#define STEPY			23
#define DIRY			24

#define RUN				0
#define X_REVERSE		1
#define Y_REVERSE 		2



.macro NOP
MOV r1, r1
.endm

START:
    // clear that bit  maak ram en gpio bereikbaar
    LBCO r0, C4, 4, 4
    CLR r0, r0, 4
    SBCO r0, C4, 4, 4
	

	LBCO PULSEWIDTH, CONST_PRUDRAM, 0, 4  // read first integer from memory
	LBCO BLOCKSIZE, CONST_PRUDRAM, 4, 4  // read first integer from memory
	LBCO BLOCKPOS, CONST_PRUDRAM, 8, 4  // read first integer from memory

	mov MEM_POS, SEGM_SIZE

	
 	MOV COUNTER, 0	
	
	
BEGIN:
    LBCO SEGM, CONST_PRUDRAM, MEM_POS, SEGM_SIZE					// 7
	MOV MEM_POS, SEGM_SIZE											// 1
	
	MOV r2, 1<<STEPX												// 1
    MOV r3, GPIO1 | GPIO_CLEARDATAOUT								// 1
    SBBO r2, r3, 0, 4												// 3

	QBBC EXIT, STATUS, 0	  // stoppen als status is -stop-		// 1
    SUB INTERVAL_X, INTERVAL_X, PULSEWIDTH							// 1
    SUB INTERVAL_Y, INTERVAL_Y, PULSEWIDTH							// 1
	
	ADD X_POS, COUNTER, INTERVAL_X									// 1
	ADD X_OFF, X_POS, PULSEWIDTH									// 1
	ADD Y_POS, COUNTER, INTERVAL_Y									// 1
	ADD Y_OFF, Y_POS, PULSEWIDTH									// 1

	ADD BLOCKPOS, BLOCKPOS, 1										// 1
	SBCO BLOCKPOS, CONST_PRUDRAM, 8, 4								// 3
	SBCO MEM_POS, CONST_PRUDRAM, 12, 4								// 3
	
    QBBC REVERSE_X, STATUS, X_REVERSE 								// 1
	MOV r2, 1<<DIRX													// 1
    MOV r3, GPIO1 | GPIO_SETDATAOUT									// 1
    SBBO r2, r3, 0, 4												// 3
	QBA DONE_X														// 1
REVERSE_X:
	MOV r2, 1<<DIRX													// 1
    MOV r3, GPIO1 | GPIO_CLEARDATAOUT								// 1
    SBBO r2, r3, 0, 4												// 3

DONE_X:
    QBBC REVERSE_Y, STATUS, Y_REVERSE 								// 1
	MOV r2, 1<<DIRY													// 1
    MOV r3, GPIO1 | GPIO_SETDATAOUT									// 1
    SBBO r2, r3, 0, 4												// 3
	QBA BLINK														// 1
REVERSE_Y:					
	MOV r2, 1<<DIRY													// 1
    MOV r3, GPIO1 | GPIO_CLEARDATAOUT								// 1
    SBBO r2, r3, 0, 4												// 3
	
BLINK:
	ADD COUNTER, COUNTER, 1											// 1

LOOPX:
	QBNE LOOPX1, COUNTER, X_POS										// 1
	
    MOV r2, 1<<STEPX												// 1
	MOV r3, GPIO1 | GPIO_SETDATAOUT									// 1
    SBBO r2, r3, 0, 4												// 3
	
LOOPX1:
	
	QBNE LOOPX2, COUNTER, X_OFF										// 1
	
	MOV r2, 1<<STEPX												// 1
    MOV r3, GPIO1 | GPIO_CLEARDATAOUT								// 1
    SBBO r2, r3, 0, 4												// 3
	
	ADD X_POS, COUNTER, INTERVAL_X									// 1
	ADD X_OFF, X_POS, PULSEWIDTH									// 1
	
LOOPX2:

LOOPY:							
	QBNE LOOPY1, COUNTER, Y_POS										// 1
	
    MOV r2, 1<<STEPY												// 1
    MOV r3, GPIO1 | GPIO_SETDATAOUT									// 1
    SBBO r2, r3, 0, 4												// 3
	
LOOPY1:
	
	QBNE LOOPY2, COUNTER, Y_OFF										// 1
	
	MOV r2, 1<<STEPY												// 1
    MOV r3, GPIO1 | GPIO_CLEARDATAOUT								// 1
    SBBO r2, r3, 0, 4												// 3
					
	ADD Y_POS, COUNTER, INTERVAL_Y									// 1
	ADD Y_OFF, Y_POS, PULSEWIDTH									// 1
 
	SUB PULSE_Y, PULSE_Y, 1											// 1
	QBEQ BEGIN, PULSE_Y, 0											// 1
	
LOOPY2:
	QBA BLINK														// 1
	
 

EXIT:
    MOV r2, 15<<21
    MOV r3, GPIO1 | GPIO_CLEARDATAOUT
    SBBO r2, r3, 0, 4

#ifdef AM33XX
    // Send notification to Host for program completion
    MOV R31.b0, PRU0_ARM_INTERRUPT+16
#else
    MOV R31.b0, PRU0_ARM_INTERRUPT
#endif

    HALT
