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

void  InitPower();              /* turn on power to the peripherals */
void  InitClocks();             /* turn on the clock to the peripherals */
void  InitGPIO();               /* initialize the I/O pins */
void  InitGPTs();               /* initialize the timers (just GPT0A) */
void  InitVariables();          /* initialize the variable values */
void  InitRegisters();          /* initialize the state of relevant registers */

void  InitGPT0();   //GLEN CODE

#endif
