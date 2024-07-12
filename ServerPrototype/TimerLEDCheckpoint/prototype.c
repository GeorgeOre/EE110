/****************************************************************************/
/*                                                                          */
/*                              Server Prototype                            */
/*                         Server Functionality Demo                        */
/*                                                                          */
/****************************************************************************/

/*
   Description:      This program is a demonstration program to show an
                     example of using the RTOS with custom GPIO configuration
                     and timer interrupts. It [WIP DO THIS]
                     blinks the red and green LEDs.  The red LED is blinked
                     at the rate of MS_PER_BLINK (milliseconds per blink)
                     using a timer interrupt.  The green LED is blinked at
                     the rate of LOOPS_PER_BLINK in the main loop.

   Input:            None.
   Output:           The LEDs are blinked at the rate of MS_PER_BLINK for the
                     red LED and LOOPS_PER_BLINK for the green LED.  The red
                     LED starts off on and the green LED starts off off.

   User Interface:   None, LEDs are just blinked.
   Error Handling:   None.

   Algorithms:       None.
   Data Structures:  None.

   Revision History:
      02/18/22  Glen George     initial revision
      07/02/24  George Ore      initial revision
*/


/* RTOS include files */
#include  <ti/sysbios/BIOS.h>   // This is needed for hardware interfacing
#include  <ti/sysbios/hal/Hwi.h>// This is needed to set hardware interrupts
#include  <ti/sysbios/knl/Swi.h>// This is needed to set software interrupts
// These two are from Glen Blink vv
#include <ti/sysbios/knl/Task.h>
#include <ti/sysbios/knl/Event.h>


/* local include files */
#include  "prototype.h" // General include file
#include  "init.h"      // Assembly initialization
#include  "util.h"      // Assembly utility
#include  "Keypad.h"    // Assembly keypad interface
#include  "LCD.h"       // Assembly LCD interface
#include  "LED.h"       // Assembly LCD interface


/* global variables */

//Event_Handle  redLEDEvent;      /* the red LED event - posted when it is    */
//                                /* time to blink the red LED, global        */
//                                /* because the assembly timer event handler */
//                                /* needs to access it                       */

Event_Handle  debounceEvent;    /* the debounce event - posted when it is   */
                                /* time to debounce the keypad, global      */
                                /* because the assembly timer event handler */
                                /* needs to access it                       */


/* shared variables */

//static  Task_Struct  redLEDTask;        /* task for blinking the red LED */
//static  Task_Struct  greenLEDTask;      /* task for blinking the green LED */
//static  Task_Struct  EnqueueTask;       /* task for debouncing and enqueueing buttons */
//static  Task_Struct  DequeueTask;       /* task for handling buttons */
static  Task_Struct  KeypadLCDTask;     /* task for handling keypad and LCD */

                                        /* stacks for all tasks */
//static  uint8_t      redLEDTaskStack[LED_TASK_STACK_SIZE];
//static  uint8_t      greenLEDTaskStack[LED_TASK_STACK_SIZE];
//static  uint8_t      EnqueueTaskStack[QUEUE_TASK_STACK_SIZE];
//static  uint8_t      DequeueTaskStack[QUEUE_TASK_STACK_SIZE];
static  uint8_t      KeypadLCDTaskStack[KEYPAD_LCD_TASK_STACK_SIZE];

/* local function declarations (for forward reference) */

//static  void  GreenLEDTaskRun(UArg, UArg);  /* task for blinking the green LED */
//static  void  RedLEDTaskRun(UArg, UArg);    /* task for blinking the red LED */
//static  void  EnqueueTaskRun(UArg, UArg);   /* task for enqueueing an event */
//static  void  DequeueTaskRun(UArg, UArg);   /* task for dequeueing an event */
static  void  KeypadLCDTaskRun(UArg, UArg);   /* task for handling keypad and LCD */


/*
   KeypadLCDTaskCreate()

   Description:      This function creates the debounce checking task that
                     enqueues an event if the debouncing condition was met.

   Operation:        The function creates the parameter structure and then
                     fills in the appropriate values for the enqueueing task.
                     It then creates the task using the shared task structure
                     variable EnqueueTask.

   Arguments:        None.
   Return Value:     None.
   Exceptions:       None.

   Inputs:           None.
   Outputs:          None.

   Error Handling:   None.

   Algorithms:       None.
   Data Structures:  None.

   Revision History: 07/08/24  George Ore   initial revision
*/
void  KeypadLCDTaskCreate(void)
{

    /* variables */
    Task_Params  taskParams;            /* task parameter structure */

    /* create the task parameter structure */
    Task_Params_init(&taskParams);

    /* fill in non-default values which set the priority and use a */
    /*    statically allocated stack */
    taskParams.stack = KeypadLCDTaskStack;
    taskParams.stackSize = KEYPAD_LCD_TASK_STACK_SIZE;
    taskParams.priority = KEYPAD_LCD_TASK_PRIORITY;


    /* now actually construct the task using the statically allocated */
    /*    task structure */
    Task_construct(&KeypadLCDTask, KeypadLCDTaskRun, &taskParams, NULL);
}

/*
   EnqueueTaskCreate()

   Description:      This function creates the debounce checking task that
                     enqueues an event if the debouncing condition was met.

   Operation:        The function creates the parameter structure and then
                     fills in the appropriate values for the enqueueing task.
                     It then creates the task using the shared task structure
                     variable EnqueueTask.

   Arguments:        None.
   Return Value:     None.
   Exceptions:       None.

   Inputs:           None.
   Outputs:          None.

   Error Handling:   None.

   Algorithms:       None.
   Data Structures:  None.

   Revision History: 07/08/24  George Ore   initial revision
*/
//void  EnqueueTaskCreate(void)
//{
//
//    /* variables */
//    Task_Params  taskParams;            /* task parameter structure */
//
//    /* create the task parameter structure */
//    Task_Params_init(&taskParams);
//
//    /* fill in non-default values which set the priority and use a */
//    /*    statically allocated stack */
//    taskParams.stack = EnqueueTaskStack;
//    taskParams.stackSize = QUEUE_TASK_STACK_SIZE;
//    taskParams.priority = ENQUEUE_TASK_PRIORITY;
//
//
//    /* now actually construct the task using the statically allocated */
//    /*    task structure */
//    Task_construct(&EnqueueTask, EnqueueTaskRun, &taskParams, NULL);
//}


/*
   DequeueTaskCreate()

   Description:      This function creates the debounce checking task that
                     dequeues an event if the debouncing condition was met.

   Operation:        The function creates the parameter structure and then
                     fills in the appropriate values for the dequeueing task.
                     It then creates the task using the shared task structure
                     variable DequeueTask.

   Arguments:        None.
   Return Value:     None.
   Exceptions:       None.

   Inputs:           None.
   Outputs:          None.

   Error Handling:   None.

   Algorithms:       None.
   Data Structures:  None.

   Revision History: 07/08/24  George Ore   initial revision
*/
//void  DequeueTaskCreate(void)
//{
//
//    /* variables */
//    Task_Params  taskParams;            /* task parameter structure */
//
//    /* create the task parameter structure */
//    Task_Params_init(&taskParams);
//
//    /* fill in non-default values which set the priority and use a */
//    /*    statically allocated stack */
//    taskParams.stack = DequeueTaskStack;
//    taskParams.stackSize = QUEUE_TASK_STACK_SIZE;
//    taskParams.priority = DEQUEUE_TASK_PRIORITY;
//
//
//    /* now actually construct the task using the statically allocated */
//    /*    task structure */
//    Task_construct(&DequeueTask, DequeueTaskRun, &taskParams, NULL);
//}

/*
   GreenLEDTaskCreate()

   Description:      This function creates the task for blinking the green
                     LED.

   Operation:        The function creates the parameter structure and then
                     fills in the appropriate values for the green LED task.
                     It then creates the task using the shared task structure
                     variable greenLEDTask.

   Arguments:        None.
   Return Value:     None.
   Exceptions:       None.

   Inputs:           None.
   Outputs:          None.

   Error Handling:   None.

   Algorithms:       None.
   Data Structures:  None.

   Revision History: 02/18/22  Glen George      initial revision
*/

//void  GreenLEDTaskCreate(void)
//{
//
//    /* variables */
//    Task_Params  taskParams;            /* task parameter structure */
//
//
//    /* create the task parameter structure */
//    Task_Params_init(&taskParams);
//
//    /* fill in non-default values which set the priority and use a */
//    /*    statically allocated stack */
//    taskParams.stack = greenLEDTaskStack;
//    taskParams.stackSize = LED_TASK_STACK_SIZE;
//    taskParams.priority = GREEN_LED_TASK_PRIORITY;
//
//
//    /* now actually construct the task using the statically allocated */
//    /*    task structure */
//    Task_construct(&greenLEDTask, GreenLEDTaskRun, &taskParams, NULL);
//
//
//    /* done creating and installing the task, return */
//    return;
//
//}




/*
   RedLEDTaskCreate()

   Description:      This function creates the task for blinking the red LED.

   Operation:        The function creates the parameter structure and then
                     fills in the appropriate values for the red LED task.  It
                     then creates the task using the shared task structure
                     variable redLEDTask.

   Arguments:        None.
   Return Value:     None.
   Exceptions:       None.

   Inputs:           None.
   Outputs:          None.

   Error Handling:   None.

   Algorithms:       None.
   Data Structures:  None.

   Revision History: 02/18/22  Glen George      initial revision
*/

//void  RedLEDTaskCreate(void)
//{
//    /* variables */
//    Task_Params  taskParams;            /* task parameter structure */
//
//
//
//    /* create the task parameter structure */
//    Task_Params_init(&taskParams);
//
//    /* fill in non-default values which set the priority and use a */
//    /*    statically allocated stack */
//    taskParams.stack = redLEDTaskStack;
//    taskParams.stackSize = LED_TASK_STACK_SIZE;
//    taskParams.priority = RED_LED_TASK_PRIORITY;
//
//
//    /* now actually construct the task using the statically allocated */
//    /*    task structure */
//    Task_construct(&redLEDTask, RedLEDTaskRun, &taskParams, NULL);
//
//
//    /* done creating and installing the task, return */
//    return;
//
//}


/*
   KeypadLCDTaskRun(UArg, UArg)

   Description:      This function enqueues a button press event if the
                     debounce condition is met.

   Operation:        The function creates the EnqueueEvent which is used to
                     enqueue keypress events to be handled later.  It loops
                     forever on waiting for the debounce condition to be met.
                     If it it met, it will save the code to a buffer.

   Arguments:        a1 (UArg) - first argument (unused).
                     a2 (UArg) - second argument (unused).
   Return Value:     None.
   Exceptions:       None.

   Inputs:           None.
   Outputs:          None.

   Error Handling:   None.

   Algorithms:       None.
   Data Structures:  None.

   Revision History: 07/08/24   George Ore      initial revision
*/

static  void  KeypadLCDTaskRun(UArg a1, UArg a2)
{

    /* main task init, make sure the LCD turns on */
//    InitLCD();                  /* initialize the LCD */

    /* main task loop, just loop counting how many times have looped */
    while (TRUE)  {

        /* check if it is time to enqueue and event */
        if(EnqueueCheck()){
            EnqueueEvent();
        }


//        if(DequeueCheck()){
//            DequeueEvent();
//        }

        /* change to #if 1 to see the effects of yielding instead of pre-empting */
        #if 0
            /* yield the CPU so other tasks can run */
                Task_yield();
        #endif
    }


    /* should never get here since running an infinite loop */
    return;

}


/*
   EnqueueTaskRun(UArg, UArg)

   Description:      This function enqueues a button press event if the
                     debounce condition is met.

   Operation:        The function creates the EnqueueEvent which is used to
                     enqueue keypress events to be handled later.  It loops
                     forever on waiting for the debounce condition to be met.
                     If it it met, it will save the code to a buffer.

   Arguments:        a1 (UArg) - first argument (unused).
                     a2 (UArg) - second argument (unused).
   Return Value:     None.
   Exceptions:       None.

   Inputs:           None.
   Outputs:          None.

   Error Handling:   None.

   Algorithms:       None.
   Data Structures:  None.

   Revision History: 07/08/24   George Ore      initial revision
*/

//static  void  EnqueueTaskRun(UArg a1, UArg a2)
//{
//
//    /* main task loop, just loop counting how many times have looped */
//    while (TRUE)  {
//
//        /* check if it is time to enqueue and event */
//        EnqueueCheck(); // This function handles the case where it does need to enqueue
//
//        /* change to #if 1 to see the effects of yielding instead of pre-empting */
//        #if 1
//            /* yield the CPU so other tasks can run */
//                Task_yield();
//        #endif
//    }
//
//
//    /* should never get here since running an infinite loop */
//    return;
//
//}


/*
   DequeueTaskRun(UArg, UArg)

   Description:      This function dequeues a button press event if there
                     are events queued.

   Operation:        The function creates the EnqueueEvent which is used to
                     enqueue keypress events to be handled later.  It loops
                     forever on waiting for the debounce condition to be met.
                     If it it met, it will save the code to a buffer.

   Arguments:        a1 (UArg) - first argument (unused).
                     a2 (UArg) - second argument (unused).
   Return Value:     None.
   Exceptions:       None.

   Inputs:           None.
   Outputs:          None.

   Error Handling:   None.

   Algorithms:       None.
   Data Structures:  None.

   Revision History: 07/08/24   George Ore      initial revision
*/

//static  void  DequeueTaskRun(UArg a1, UArg a2)
//{
//
//    /* main task loop, just loop counting how many times have looped */
//    while (TRUE)  {
//
//        /* check if the assembly buffer is non-empty */
//        if (dIndex > 0)  {
//
//            /* Dequeue the most recent event*/
//            DequeueEvent();
//
//            /* time to toggle the LED (for visual debugging)*/
//            ToggleRedLED();
//
//        }
//
//        /* change to #if 1 to see the effects of yielding instead of pre-empting */
//        #if 1
//            /* yield the CPU so other tasks can run */
//                Task_yield();
//        #endif
//    }
//
//
//    /* should never get here since running an infinite loop */
//    return;
//
//}

/*
   GreenLEDTaskRun(UArg, UArg)

   Description:      This function runs the task that blinks the green LED.

   Operation:        The function just loops forever counting how many times
                     it has looped.  Every LOOPS_PER_BLINK times it toggles
                     the LED.

   Arguments:        a1 (UArg) - first argument (unused).
                     a2 (UArg) - second argument (unused).
   Return Value:     None.
   Exceptions:       None.

   Inputs:           None.
   Outputs:          None.

   Error Handling:   None.

   Algorithms:       None.
   Data Structures:  None.

   Revision History: 02/18/22  Glen George      initial revision
*/

//static  void  GreenLEDTaskRun(UArg a1, UArg a2)
//{
//    /* variables */
//    int  loopCount;             /* number of times have looped */
//
//
//
//    /* task initialization */
//
//    /* have not looped yet */
//    loopCount = 0;
//
//
//
//    /* main task loop, just loop counting how many times have looped */
//    while (TRUE)  {
//
//        /* update the loop counter */
//        loopCount++;
//
//        /* check if it is time to toggle the green LED */
//        if (loopCount >= LOOPS_PER_BLINK)  {
//
//            /* time to toggle the LED */
//            ToggleGreenLED();
//
//            /* and reset the loop counter */
//            loopCount = 0;
//        }
//
//        /* change to #if 1 to see the effects of yielding instead of pre-empting */
//        #if 1
//            /* yield the CPU so other tasks can run */
//                Task_yield();
//        #endif
//    }
//
//
//    /* should never get here since running an infinite loop */
//    return;
//
//}




/*
   RedLEDTaskRun(UArg, UArg)

   Description:      This function runs the task that blinks the red LED.

   Operation:        The function creates the redLEDEvent which is used to
                     blink the LED.  It then loops forever on waiting for a
                     redLEDEvent to occur.  Each time a redLEDEvent occurs
                     the red LED is toggled.

   Arguments:        a1 (UArg) - first argument (unused).
                     a2 (UArg) - second argument (unused).
   Return Value:     None.
   Exceptions:       None.

   Inputs:           None.
   Outputs:          None.

   Error Handling:   None.

   Algorithms:       None.
   Data Structures:  None.

   Revision History: 02/18/22  Glen George      initial revision
*/

//static  void  RedLEDTaskRun(UArg a1, UArg a2)
//{
//    /* variables */
//    UInt  events;       /* currently active events */
//
//
//
//    /* task initialization */
//
//    /* just create the event for the LED */
//    redLEDEvent = Event_create(NULL, NULL);
//
//
//
//    /* main task loop, just watch for LED events and toggle the LED when get one */
//    while (TRUE)  {
//
//        /* wait for an event to occur */
//        events = Event_pend(redLEDEvent, Event_Id_NONE, ALL_EVENTS, EVENT_TIMEOUT);
//
//
//        /* check if got an event (should have) */
//        if (events != 0)  {
//
//            /* there is only one redLED event so no need to check value */
//            /* got a red LED event so toggle the red LED */
//            ToggleRedLED();
//        }
//    }
//
//
//    /* should never get here since running an infinite loop */
//    return;
//
//}



///*  DOWN HERE IS THE EMPTY TI STUFF
// *  ======== empty.c ========
// */
//
///* For usleep() */
//#include <unistd.h>
//#include <stdint.h>
//#include <stddef.h>
//#include <stdio.h>
//
///* Driver Header files */
//#include <ti/drivers/GPIO.h>
//#include <ti/drivers/Timer.h>
//// #include <ti/drivers/I2C.h>
//// #include <ti/drivers/SPI.h>
//// #include <ti/drivers/Watchdog.h>
//
/////* Driver configuration */
////#include "ti_drivers_config.h"
//
///* Board Header file */
//#include "ti_drivers_config.h"
//
//
///* Callback used for toggling the LED. */
//void timerCallback(Timer_Handle myHandle, int_fast16_t status);
//
//
///*
// *  ======== mainThread ========
// */
////void *mainThread(void *arg0)
////{
////    Timer_Handle timer0;
////    Timer_Params params;
////
////    /* Call driver init functions */
//////    GPIO_init();
////    Timer_init();
////
////    /* Configure the LED pin */
//////    GPIO_setConfig(CONFIG_GPIO_LED_0, GPIO_CFG_OUT_STD | GPIO_CFG_OUT_LOW);
////
////    /* Turn off user LED */
//////    GPIO_write(CONFIG_GPIO_LED_0, CONFIG_GPIO_LED_OFF);
////
////    /*
////     * Setting up the timer in continuous callback mode that calls the callback
////     * function every 1,000 microseconds, or 1 millisecond.
////     */
////    Timer_Params_init(&params);
////    params.period        = 1000000;
////    params.periodUnits   = Timer_PERIOD_US;
////    params.timerMode     = Timer_CONTINUOUS_CALLBACK;
////    params.timerCallback = timerCallback;
////
////    timer0 = Timer_open(CONFIG_TIMER_0, &params);
////
////    if (timer0 == NULL)
////    {
////        /* Failed to initialized timer */
////        while (1) {}
////    }
////
////    if (Timer_start(timer0) == Timer_STATUS_ERROR)
////    {
////        /* Failed to start timer */
////        while (1) {}
////    }
////
////    Debounce();
////
////    return (NULL);
////}
//
///*
// * This callback is called every 1,000,000 microseconds, or 1 second. Because
// * the LED is toggled each time this function is called, the LED will blink at
// * a rate of once every 2 seconds.
// */
//void timerCallback(Timer_Handle myHandle, int_fast16_t status)
//{
////    GPIO_toggle(CONFIG_GPIO_LED_0);
//    //Toggle_Both_LEDS();
//    GPT2AEventHandler();
//    //printf("LEDS TOGGLED!\n");
//}
