/*
 *  ======== main_tirtos.c ========
 */

/* Standard C libraries */
#include <stdint.h>

/* User assembly functions */
#include "init.h"
#include "util.h"
#include "Keypad.h"
#include "LCD.h"
#include "LED.h"

/* Project specific files */
#include "prototype.h"

/* POSIX Header files */
#include <pthread.h>

/* RTOS header files */
#include  <ti/sysbios/BIOS.h>   // This is needed for hardware interfacing
#include  <ti/sysbios/hal/Hwi.h>// This is needed to set hardware interrupts
#include  <ti/sysbios/knl/Swi.h>// This is needed to set software interrupts
#include <ti/drivers/Board.h>

/*
 *  ======== main ========
 */
int main(void)
{

    /* variables */
    static  Hwi_Struct  GPT2A_Task;     /* GPT2A timer task */

    Hwi_Params          GPT2A_Params;   /* parameters for GPT2A timer task */


    /* initialize the system */
    InitPower();                /* turn on power to everything */
    InitClocks();               /* turn on clocks to everything */
    InitGPIO();                 /* setup the I/O (only output) */
    InitGPTs();                 /* initialize the internal timer */
    InitVariables();          /* initialize the variable values */
    InitRegisters();          /* initialize the state of relevant registers */
    InitLCD();                  /* initialize the LCD */

    /* setup Hardware Interrupt Task for timer */

    /* setup the parameters */
    Hwi_Params_init(&GPT2A_Params);
    GPT2A_Params.eventId = GPT2A_EX_NUM;
    GPT2A_Params.priority = GPT2A_PRIORITY;

    /* now create the task */
    Hwi_construct(&GPT2A_Task, GPT2A_EX_NUM, GPT2AEventHandler, &GPT2A_Params, NULL);



//    /* setup Software Interrupt Task for timer */
//
//    /* setup the parameters */
//    Hwi_Params_init(&GPT2A_Params);
//    GPT2A_Params.eventId = GPT2A_EX_NUM;
//    GPT2A_Params.priority = GPT2A_PRIORITY;
//
//    /* now create the task */
//    Hwi_construct(&GPT2A_Task, GPT2A_EX_NUM, GPT2AEventHandler, &GPT2A_Params, NULL);

    /* create tasks */
    KeypadLCDTaskCreate();      /* create the task for the activating the keypad and LCD */
//    EnqueueTaskCreate();        /* create the task for enqueueing into asm buffer*/
//    DequeueTaskCreate();        /* create the task for dequeueing the asm buffer */

    BIOS_start();

    return (0);
}
