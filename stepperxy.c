/*****************************************************************************
* Include Files                                                              *
*****************************************************************************/

#include <stdio.h>
#include <stdint.h>


// Driver header file
#include <prussdrv.h>
#include <pruss_intc_mapping.h>

/*****************************************************************************
* Explicit External Declarations                                             *
*****************************************************************************/

/*****************************************************************************
* Local Macro Declarations                                                   *
*****************************************************************************/

#define PRU_NUM 	0

#define AM33XX
#define PAUZE 1000000

#define RUN 1
#define REVERSE_X 2
#define REVERSE_Y 4
#define STOP 0
#define PULSEWIDTH 30000


#define TIMEBASE 3.33e7
#define BLOCKSIZE 15


typedef struct  {
	uint32_t status;
	uint32_t puls_x;
	uint32_t interval_x;	
	uint32_t puls_y;
	uint32_t interval_y;	
} segm;


/*****************************************************************************
* Local Typedef Declarations                                                 *
*****************************************************************************/


/*****************************************************************************
* Local Function Declarations                                                *
*****************************************************************************/

static int LOCAL_exampleInit ();
int rand_segm();

/*****************************************************************************
* Local Variable Definitions                                                 *
*****************************************************************************/


/*****************************************************************************
* Intertupt Service Routines                                                 *
*****************************************************************************/


/*****************************************************************************
* Global Variable Definitions                                                *
*****************************************************************************/

static void *pruDataMem;
static segm *pruDataMem_seg;
segm seg[200];
int count;
static int *IntData;
/*****************************************************************************
* Global Function Definitions                                                *
*****************************************************************************/

int main (void)
{
    unsigned int ret;
	int i, r, r_old;
	

	
 
    tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;
    
    printf("\nINFO: Starting %s example.\r\n", "blinkslave");
    /* Initialize the PRU */
    prussdrv_init ();		
    // printf("sizof segm = %d\n", sizeof(segm));
    /* Open PRU Interrupt */
    ret = prussdrv_open(PRU_EVTOUT_0);
    if (ret)
    {
        printf("prussdrv_open open failed\n");
        return (ret);
    }
    
    /* Get the interrupt initialized */
    prussdrv_pruintc_init(&pruss_intc_initdata);

    /* Initialize example */
    printf("\tINFO: Initializing example.\r\n");
    LOCAL_exampleInit();
 
    rand_segm();
 	
	for(i=0;i<BLOCKSIZE;i++){
		pruDataMem_seg[i].status=seg[i].status;
		pruDataMem_seg[i].puls_x=seg[i].puls_x;
		pruDataMem_seg[i].interval_x= TIMEBASE/seg[i].puls_x;
		pruDataMem_seg[i].puls_y=seg[i].puls_y;
		pruDataMem_seg[i].interval_y= TIMEBASE/seg[i].puls_y;	
		printf("%d\n", seg[i].status);
	}
	// pruDataMem_seg[10].status=STOP;
	
	r=r_old=0;

    /* Execute example on PRU */
    printf("\tINFO: Executing example.\r\n");
    prussdrv_exec_program (PRU_NUM, "./blinkslave.bin");
	while(r < 10){
		r=IntData[2];
		// printf("%d\n", r);
		if(r!=r_old) {
			if(r%5==0)
			printf("%d\n", r);
			r_old=r;

		}
	}
		
	
    /* Wait until PRU0 has finished execution */
    printf("\tINFO: Waiting for HALT command.\r\n");
    prussdrv_pru_wait_event (PRU_EVTOUT_0);
    printf("\tINFO: PRU completed transfer.\r\n");
    prussdrv_pru_clear_event (PRU0_ARM_INTERRUPT);
	printf("%d %d %d\n", IntData[0],IntData[1],IntData[2]);
    /* Disable PRU and close memory mapping*/
    prussdrv_pru_disable (PRU_NUM);
    prussdrv_exit ();

    return(0);

}

/*****************************************************************************
* Local Function Definitions                                                 *
*****************************************************************************/

static int LOCAL_exampleInit ()
{  
	int BlockPos=0;

    prussdrv_map_prumem (PRUSS0_PRU0_DATARAM, &pruDataMem);
	IntData = (int*)pruDataMem;
	IntData[0] = PULSEWIDTH;
	IntData[1] = BLOCKSIZE*sizeof(segm);
	IntData[2] = BlockPos;
    pruDataMem_seg = (segm*) pruDataMem + 1 ;  // reserveer memory voor header
	

	pruDataMem_seg[0].status = RUN | REVERSE_X;
	pruDataMem_seg[0].puls_x=5;
    pruDataMem_seg[0].interval_x= TIMEBASE/pruDataMem_seg[0].puls_x;
    pruDataMem_seg[0].puls_y=8;
    pruDataMem_seg[0].interval_y= TIMEBASE/pruDataMem_seg[0].puls_y;
	


    return(0);
}

int rand_segm(){
	int i;
	for (i = 0;i < 199; i++){

		seg[i].status = RUN | REVERSE_X | REVERSE_Y;
		seg[i].puls_x=2+i;
		seg[i].interval_x= TIMEBASE/seg[i].puls_x;
		seg[i].puls_y=206-i;
		seg[i].interval_y= TIMEBASE/seg[i].puls_y;
		
	}
	seg[10].status = STOP;
	
	return 0;
}

