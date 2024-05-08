/*
***************************************************************************
This file is part of Open Common Interface
Copyright (C)2005 Jordi Escoda jordi.escoda@gmail.com

This program is free software; you can redistribute it and/or modify it 
under the terms of the GNU General Public License as published by the 
Free Software Foundation; either version 2 of the License, 
or (at your option) any later version.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 * FILENAME     : SPS_type.h
 * CREATED      : July 2005
 * PROGRAMMER: Jordi Escoda
 * DESCRIPTION  : Contains global type definitions
 ***************************************************************************
 */

#ifndef __SPS_TYPE_H
#define __SPS_TYPE_H

#ifdef __cplusplus
extern "C" {
#endif

/*
 ***************************************************************************
 *                            I N C L U D E S
 ***************************************************************************
 */
#ifdef ARCHITECTURE_ST20
    #include "stddefs.h"
#endif

/*
 ***************************************************************************
 *                       G L O B A L   M A C R O S
 ***************************************************************************
 */

#define TRUE true 
#define FALSE false 
	
#define percent(total, partial)     ((100 * (partial)) / (total))
#define toggle(a) a = (((a) == (TRUE)) ? (FALSE) : (TRUE))      // Toggles TRUE<->FALSE
#define min(a,b)         (((a) < (b)) ? (a) : (b))
#define max(a,b)         (((a) > (b)) ? (a) : (b))
#define max3(a,b,c)      (max(c,max(a,b)))

#define BCD_TO_U8(BCD)   ((((BCD) >> 4) & 0x0F) * 10 + ((BCD) & 0x0F))
#define U8_TO_BCD(U_8)   ((((U_8) / 10) << 4) + ((U_8) % 10))

#define MAKEWORD32(H, L) ((U32)((H) << 16) | (U16)(L))
// Returns the next multiple of 'size' starting from 'value'. Ex: length = ROUND(3, 4) -> length = 4 bytes
#define ALIGN(value, size) ((((U32)(value) + (size)-1) / (size)) * (size))
// Rounds the value to the nearest multiple of round. Ex: ROUND(640, 50) = 650, ROUND(660, 50) = 650
#define ROUND(value, round) ((((value) % (round)) == 0) || (((value) % (round)) >= ((round)/2))) ? (ALIGN((value), (round))) : (ALIGN((value), (round)) - (round))

#define ENABLE     TRUE
#define DISABLE    FALSE

#define SUCCESS    TRUE

#define VARIABLE_POINTER    NULL
#define VARIABLE_VALUE      0

#define b0         0x01
#define b1         0x02
#define b2         0x04
#define b3         0x08
#define b4         0x10
#define b5         0x20
#define b6         0x40
#define b7         0x80

#define BIT0       0x01
#define BIT1       0x02
#define BIT2       0x04
#define BIT3       0x08
#define BIT4       0x10
#define BIT5       0x20
#define BIT6       0x40
#define BIT7       0x80


/*
 ***************************************************************************
 *                            E X T E R N A L S
 ***************************************************************************
 */

/*
 ***************************************************************************
 *                     G L O B A L   D A T A   T Y P E S
 ***************************************************************************
 */
typedef unsigned char  BOOL; 


#ifndef ARCHITECTURE_ST20
typedef unsigned char  U8;      // 8-bit 
typedef signed char    S8;
typedef unsigned short U16;     // 16-bit 
typedef signed short   S16;
typedef unsigned int   U32;     // 32-bit 
typedef signed int     S32;
#endif
                                // Compiler optimaly handled types
typedef unsigned       OptU8;   // 8-bit -> 32-bit
typedef signed int     OptS8;
typedef unsigned       OptU16;  // 16-bit-> 32-bit 
typedef signed int     OptS16;
typedef unsigned       OptU32;  // 32-bit-> 32-bit 
typedef signed int     OptS32;

typedef struct {
    void    (*pFunc)(void);
}pVoidFunc_t;

/*
 ***************************************************************************
 *                      G L O B A L   V A R I A B L E S
 ***************************************************************************
 */

/*
 ***************************************************************************
 *            G L O B A L   F U N C T I O N   P R O T O T Y P E S
 ***************************************************************************
 */


#ifdef __cplusplus
}
#endif

#endif  // 

/* EOF */
