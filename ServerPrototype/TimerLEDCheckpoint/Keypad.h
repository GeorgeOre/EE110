/****************************************************************************/
/*                                                                          */
/*                                Keypad.h                                  */
/*                   Assembly Keypad Interfacing Functions                  */
/*                                EE110b HW5                                */
/*                               Include File                               */
/*                                                                          */
/****************************************************************************/

/*
   This is the C include file for the assembly language Keypad interfacing
   functions for EE110b HW5. It includes the constants, structures, typedefs,
   and function prototypes for the Keypad handling functions.


   Revision History:
       07/02/24  George Ore      initial revision
*/

#ifndef  __KEYPAD_H__
    #define  __KEYPAD_H__

/* library include files */
#include <stdbool.h>

/* local include files */
    /* none */

/* constants */
    /* none */

/* structures, unions, and typedefs */
    /* none */

/* function prototypes */
void  Debounce();       /* Checks if the zero flag was set which detects a debounce */
void  EnqueueEvent();       /* Enqueue and event */
void  DequeueEvent();       /* Dequeue an event */
void  GPT2AEventHandler();  /* Debounce the keypad every interrupt cycle */
bool  EnqueueCheck();       /* Set a flag indicating that an event has occurred */
bool  DequeueCheck();       /* Handle an event if it is in the buffer */


#endif
