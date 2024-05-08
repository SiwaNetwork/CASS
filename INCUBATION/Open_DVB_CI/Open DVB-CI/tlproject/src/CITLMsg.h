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

* FILENAME     : CITLMsg.h
* CREATED      : September 2005             
* PROGRAMMER(s): Jordi Escoda
* DESCRIPTION  : Header file for Common Interface Transport Layer. Messages.
*                Implementation for EN 50221:1997.
***************************************************************************
*/

#ifndef __CITLMSG_H
#define __CITLMSG_H

#include "CITLCfg.h"

//TODO: What happens when a module is unplugged?

//______________________________________________________________________________
//Message Struct: Output to Session Layer
typedef enum
{
    MSG_TL2SL_DATA = 1,             //Data is built and sent to session layer
    MSG_TL2SL_NO_MORE_TC_AVAILABLE, //Failed to create TC because no more TC available         
    MSG_TL2SL_CREATE_TC_FAILED,     //Failed to create TC because module did not answer C_T_C_Reply
    MSG_TL2SL_TC_CREATED,           //TC has been created. 
    MSG_TL2SL_TC_DELETED,           //TC has been deleted either because of a time out or module request
    MSG_TL2SL_BUSY,                 //Transport Connection is Busy. A transmission is in progress. 
    MSG_TL2SL_NOT_ACTIVE            //Transport Connection is not Active
} msgSL_enum; 

typedef struct 
{
    U8 TL_ConnIdSender;       //TL Sender
    U8 Content[6000];         //TODO: Definir qué longitud
} MsgSLContent; 

//Message structure (Outputs: Host events request or Host --> Module): 
typedef struct 
{
    msgSL_enum msgType;  
    MsgSLContent msgContent; 
} MsgSL; 
//______________________________________________________________________________

//______________________________________________________________________________
//Message Struct: Input from Session Layer or Link Layer or Timer
typedef enum
{
    MSG_SL2TL_REQUEST_TC = 1,   //TC Request from Session Layer
    MSG_SL2TL_DELETE_TC,        //TC Delete Request from Session Layer 
    MSG_SL2TL_DATA,             //Session sends data
    MSG_LL2TL_MODULE_RESPONSE,  //Response from module
    MSG_LL2TL_MODULE_PLUGGED,   //A module has been plugged into the socket
    MSG_TIM2TL_TIMEOUT,         //Timer task sends timeout
    MSG_TIM2TL_POLLTC,          //Timer task sends Poll TC
    TL_KILL,                    //To finish Transport Layer execution
} msgTL_enum; 


typedef struct 
{
    U8 TL_ConnIdAddresee;     //TL Addresee        
    U8 Content[6000];  //Msg Content.//TODO: Definir el tamaño máximo
                       //When LL2TL: Will hold R_TPDU or SPDU.                                     
                       //When SL2TL: Will hold message which maybe will need to be split
} MsgTLContent; 

typedef struct 
{
    msgTL_enum msgType; 
    MsgTLContent msgContent; 
} MsgTL; 

//______________________________________________________________________________

//______________________________________________________________________________
//Message Struct: Transport Layer -> Link Layer
typedef enum
{
    MSG_TL2LL_CREATE_TC = 1,  
    MSG_TL2LL_DELETE_TC,
    MSG_TL2LL_D_T_C_REPLY,
    MSG_TL2LL_POLLTC,
    MSG_TL2LL_TC_ERROR,  //Issued when TC request cannot be accomplished because no more TC available
    MSG_TL2LL_TC_TRCV,
    MSG_TL2LL_SEND_DATA, //Transport Layer received data from Session and Sends it to Link layer
    MSG_TL2LL_NEW_TC,
    MSG_TL2LL_NO_MORE_TC_AVAILABLE //Transport Layer cannot give a new TC. 
} msgLL_enum; 

typedef struct 
{
    U8 TL_ConnIdSender;   //TL Sender
    U8 Content[MAX_PDU_LENGTH+3]; //+3: c_tpdu_tag + length field (2)
} MsgLLContent; 

typedef struct 
{
    msgLL_enum msgType; 
    MsgLLContent msgContent; 
} MsgLL; 
//______________________________________________________________________________


//______________________________________________________________________________
//Message Struct: Output to Timer message queue
typedef enum
{
    MSG_TL2TIM_TIMEOUT_CREATION = 1, //Timer task is the responsible to add this timer
    MSG_TL2TIM_TIMEOUT_DELETION,     //Timer task is the responsible to destroy this timer
    MSG_TL2TIM_POLLTC_CREATION,      //Timer task is the responsible to add this timer
    MSG_TL2TIM_POLLTC_DELETION,      //Timer task is the responsible to destroy this timer
} msgTim_enum; 

typedef struct 
{
    U8 TL_ConnIdSender;       //TL Sender
} MsgTimContent; 

typedef struct 
{
    msgTim_enum msgType; 
    MsgTimContent msgContent; 
} MsgTim; 

//______________________________________________________________________________

#endif // __CITLMSG_H

/* EOF */
