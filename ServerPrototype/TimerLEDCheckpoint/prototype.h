/****************************************************************************/
/*                                                                          */
/*                                prototype.h                               */
/*                         Server Functionality Demo                        */
/*                                Include File                              */
/*                                                                          */
/****************************************************************************/

/*
   This file contains the constants and function prototypes for the RTOS
   demonstration program for the EE110b HW6 assignment.

   Revision History:
    07/02/24  George Ore       initial revision
*/



#ifndef  __PROTOTYPE_H__
    #define  __PROTOTYPE_H__

/* library include files */
#include  <ti/sysbios/BIOS.h>


/* local include files */
    /* none */

/* constants */

/* GPT0A timer constants */
#define  GPT0A_PRIORITY     3           /* priority for the interrupt */
#define  GPT0A_EX_NUM       31          /* GPT0A is exception number 31 */

#define  GPT2A_PRIORITY     3           /* priority for the interrupt */
#define  GPT2A_EX_NUM       35          /* GPT0A is exception number 31 */


/* constants */
#define THREADSTACKSIZE 1024    /* Stack size in bytes */

#define  LED_TASK_STACK_SIZE            400     /* size of stack for LED tasks */
#define  QUEUE_TASK_STACK_SIZE          400     /* size of stack for queue tasks */
#define  KEYPAD_LCD_TASK_STACK_SIZE     400     /* size of stack for the keypad LCD tasks */


#define  RED_LED_TASK_PRIORITY          3       /* priority of red LED task */
#define  GREEN_LED_TASK_PRIORITY        1       /* run green LED task at low priority */
#define  ENQUEUE_TASK_PRIORITY          3       /* priority of enqueueing task */
#define  DEQUEUE_TASK_PRIORITY          1       /* run dequeueing task at low priority */
#define  KEYPAD_LCD_TASK_PRIORITY        1       /* run keypad-LCD task at low priority */


/* mask for all event flags */
#define  ALL_EVENTS                     0xFFFFFFFF

/* timeout when waiting for an event */
/* change to BIOS_NO_WAIT to see the effects of high priority busy waiting */
#define  EVENT_TIMEOUT                  BIOS_WAIT_FOREVER

/* number of loops for toggling green LED */
#define  LOOPS_PER_BLINK                200000


/* structures, unions, and typedefs */
    /* none */


/* function declarations */
void *mainThread(void *arg0);

void  GreenLEDTaskCreate(void);         /* create the green LED task */
void  RedLEDTaskCreate(void);           /* create the red LED task */
void  EnqueueTaskCreate(void);          /* create the enqueue task */
void  DequeueTaskCreate(void);          /* create the dequeue task */
void  KeypadLCDTaskCreate(void);        /* create the keypad LCD task */

#endif
