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
 *
 * FILENAME     : CITLCfg.h
 * CREATED      :  October 2005             
 * PROGRAMMER: Jordi Escoda
 * DESCRIPTION  : Header file for Common Interface Transport Layer. Configuration.
 *                Implementation for EN 50221:1997.
 ***************************************************************************
 */

#ifndef __CITLCFG_H
#define __CITLCFG_H

#include "sps_type.h"

#define MAX_PDU_LENGTH  255   // Link layer will negotiate with the module the maximum length, and will choose the minimum buffer size of both.
#define MAX_BODY_LENGTH  MAX_PDU_LENGTH - 7 //minus Header and Status

#define NUMBER_OF_COMMON_INTERFACE_SLOTS 1  //Number of common interface slots available in the hardware.
#define TRANSPORT_CONNECTIONS  NUMBER_OF_COMMON_INTERFACE_SLOTS * 16 //Number of Transport Connections. Cannot be more than 255!!!

#define TEST_ON_A_PC  1  //1 for Testing TL on a PC


#if TEST_ON_A_PC
//For PC it is slowed down the process
#define TIMEOUT_FROM_POLLING_START  500
#define MAX_PERIOD_POLLING_TIME     100  
#define POLLING_TIME  MAX_PERIOD_POLLING_TIME - 10
#else
//Clause A.4.1.12 Rules for polling function
#define TIMEOUT_FROM_POLLING_START  300  //Time-out started for each polling
#define MAX_PERIOD_POLLING_TIME     100  //100mS for maximum period Polling time
#define POLLING_TIME  MAX_PERIOD_POLLING_TIME - 10
#endif //TEST_ON_A_PC


#if TEST_ON_A_PC
#include <stdio.h>
#include <iostream> 
#include <fstream>  // To write a file
#include <stdlib.h>
#include <sys/time.h>  //Used to show time in the trace

#include <sys/types.h>  //For message queue
#include <sys/ipc.h>    //For message queue (interprocess communication)
#include <sys/msg.h>    //For message queue
#define OSAL_TaskId_t U16 
//#define FALSE false
//#define TRUE true
#define OS_MemoryAlloc malloc
#define OS_MemoryFree free
#endif //TEST_ON_A_PC


#endif  // __CITLCFG_H

/* EOF */
