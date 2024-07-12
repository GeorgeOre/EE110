/****************************************************************************/
/*                                                                          */
/*                                   LCD.h                                  */
/*                      Assembly LCD Interfacing Functions                  */
/*                                 EE110b HW5                               */
/*                                Include File                              */
/*                                                                          */
/****************************************************************************/

/*
   This is the C include file for the assembly language LCD interfacing
   functions for EE110b HW5. It includes the constants, structures, typedefs,
   and function prototypes for the LCD handling functions.


   Revision History:
       07/02/24  George Ore      initial revision
*/

#ifndef  __LCD_H__
    #define  __LCD_H__

/* library include files */
    /* none */

/* local include files */
    /* none */

/* constants */
    /* none */

/* structures, unions, and typedefs */
    /* none */

/* function prototypes */

//User Oriented functions
void  Display();        /* Display a string to the LCD */
void  DisplayChar();    /* Display a char to the LCD */
/*** Prep LCD has a modifiable character string and cursor parameters ***/
void  PrepLCD();        /* Prep the LCD to display a number */
void  InitLCD();        /* Initializes the LCD */


//Internal Helper Functions
void  LowestLevelWrite();   /* Handles an LCD write cycle */
void  LowestLevelRead();   /* Handles an LCD read cycle */
void  WaitLCDBusy();   /* Waits until the LCD is not busy */


#endif
