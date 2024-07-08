
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
#include <ti/drivers/Board.h>

extern void *mainThread(void *arg0);

/* Stack size in bytes */
#define THREADSTACKSIZE 1024

/*
 *  ======== main ========
 */
int main(void)
{
    pthread_t thread;
    pthread_attr_t attrs;
    struct sched_param priParam;
    int retc;
//
//    Board_init();
//
//
    /* Initialize the attributes structure with default values */
    pthread_attr_init(&attrs);

    /* Set priority, detach state, and stack size attributes */
    priParam.sched_priority = 1;
    retc                    = pthread_attr_setschedparam(&attrs, &priParam);
    retc |= pthread_attr_setdetachstate(&attrs, PTHREAD_CREATE_DETACHED);
    retc |= pthread_attr_setstacksize(&attrs, THREADSTACKSIZE);
    if (retc != 0)
    {
        /* failed to set attributes */
        while (1) {}
    }

    retc = pthread_create(&thread, &attrs, mainThread, NULL);
    if (retc != 0)
    {
        /* pthread_create() failed */
        while (1) {}
    }

    /* variables */
//    static  Hwi_Struct  GPT0A_Task;     /* GPT0A timer task */

//    Hwi_Params          GPT0A_Params;   /* parameters for GPT0A timer task */


    /* initialize the system */
    InitPower();                /* turn on power to everything */
    InitClocks();               /* turn on clocks to everything */
    InitGPIO();                 /* setup the I/O (only output) */
    InitGPT0();                 /* initialize the internal timer */

    InitLEDs();                 /* initialize the LED state */


//    /* create tasks */
//    RedLEDTaskCreate();         /* create the task for the red LED */
//    GreenLEDTaskCreate();       /* create the task for the green LED */
//
//    /* setup Hardware Interrupt Task for timer */
//
//    /* setup the parameters */
//    Hwi_Params_init(&GPT0A_Params);
//    GPT0A_Params.eventId = GPT0A_EX_NUM;
//    GPT0A_Params.priority = GPT0A_PRIORITY;
//
//    /* now create the task */
//    Hwi_construct(&GPT0A_Task, GPT0A_EX_NUM, GPT0AEventHandler, &GPT0A_Params, NULL);


    BIOS_start();

    return (0);
}
