/****************************************************************************/
/*                                                                          */
/*                                   LED.h                                  */
/*                      Assembly LED Interfacing Functions                  */
/*                                 EE110b HW5                               */
/*                                Include File                              */
/*                                                                          */
/****************************************************************************/

/*
   This is the C include file for the assembly language LED interfacing
   functions for EE110b HW5. It includes the constants, structures, typedefs,
   and function prototypes for the LCD handling functions.


   Revision History:
       07/06/24  George Ore      initial revision
*/

#ifndef  __LED_H__
    #define  __LED_H__

/* library include files */
    /* none */

/* local include files */
    /* none */

/* constants */
    /* none */

/* structures, unions, and typedefs */
    /* none */

/* function prototypes */

//Internal Helper Functions
void  InitLEDs();   /* Initializes LEDs */
void  Toggle_Both_LEDS(); /* Toggles both LEDs */

#endif
