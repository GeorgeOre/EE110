/****************************************************************************/
/*                                                                          */
/*                                   init.h                                 */
/*                      Assembly Initialization Functions                   */
/*                                  EE110b HW5                              */
/*                                Include File                              */
/*                                                                          */
/****************************************************************************/

/*
   This is the C include file for the assembly language initialization
   functions for EE110b HW5. It includes the constants, structures, typedefs,
   and function prototypes for the initialization functions.


   Revision History:
       6/29/24  George Ore      initial revision
*/

#ifndef  __INIT_H__
    #define  __INIT_H__

/* library include files */
    /* none */

/* local include files */
    /* none */

/* constants */
    /* none */

/* structures, unions, and typedefs */
    /* none */

/* function prototypes */

void  InitClocks();             /* turn on the clock to the peripherals */
void  InitGPIO();               /* initialize the I/O pins */
void  InitGPT0();               /* initialize the timers (just GPT0A) */
void  InitLEDs();               /* initialize the red and green LEDs */
void  InitPower();              /* turn on power to the peripherals */

//void  GPT0AEventHandler();      /* event handler for GPTOA interrupt */
//
//
//void  ToggleRedLED();           /* toggle the red LED */
//void  ToggleGreenLED();         /* toggle the green LED */



#endif
