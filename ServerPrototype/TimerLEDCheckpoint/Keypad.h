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
    /* none */

/* local include files */
    /* none */

/* constants */
    /* none */

/* structures, unions, and typedefs */
    /* none */

/* function prototypes */
void  EnqueueEvent();       /* Set a flag indicating that an event has occurred */
void  GPT0EventHandler();   /* Debounce the keypad every interrupt cycle */

#endif
