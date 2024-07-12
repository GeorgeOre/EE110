/****************************************************************************/
/*                                                                          */
/*                                   util.h                                 */
/*                          Assembly Utility Functions                      */
/*                                  EE110b HW5                              */
/*                                Include File                              */
/*                                                                          */
/****************************************************************************/

/*
   This is the C include file for the assembly language utility
   functions for EE110b HW5. It includes the constants, structures, typedefs,
   and function prototypes for the utility functions.


   Revision History:
       07/02/24  George Ore      initial revision
*/

#ifndef  __UTIL_H__
    #define  __UTIL_H__

/* library include files */
    /* none */

/* local include files */
    /* none */

/* constants */
    /* none */

/* structures, unions, and typedefs */
    /* none */

/* function prototypes */

void  Wait_1ms();   /* Wait 1ms, can be multiplied by param */
void  Int2Ascii();  /* Stores an integer's value into ascii (buffer) */
void  Divmod();     /* Divides an integer into result and remainder */
void  DivByZero();  /* Catches handling when attempting to divide by 0 */

//GLEN FUNCIONS
void ToggleGreenLED();
void ToggleRedLED();
void GPT0AEventHandler();  /* Event handler */

#endif
