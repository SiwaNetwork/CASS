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

* FILENAME     : CITLObj.h
* CREATED      :  July 2005             
* PROGRAMMER: Jordi Escoda
* DESCRIPTION  : Header file for Common Interface Transport Layer. Objects.
*                Implementation for EN 50221:1997.
***************************************************************************
*/

#ifndef __CITLOBJ_H
#define __CITLOBJ_H

#include "CITLCfg.h"
#include "CITLMsg.h"

  
//______________________________________________________________________________

enum tpdu_tag
{
//Clause A.4.1.13 Coding of Transport Tags
//      tpdu_tag       tag value              Direction        Meaning                                    
    TSB            = 0x80,    //Primitive.   Host <-- Module. Provides Status information.               
    TRCV           = 0x81,    //Primitive.   Host --> Module. Confirms data received.                     
    TCREATE_T_C    = 0x82,    //Primitive.   Host --> Module. Creates Transport Connection.               
    TC_T_C_REPLY   = 0x83,    //Primitive.   Host <-- Module. Acknowledges Transport Connection Created.  
    TDELETE_T_C    = 0x84,    //Primitive.   Host <-> Module. Deletes Transport Connection.               
    TD_T_C_REPLY   = 0x85,    //Primitive.   Host <-> Module. Acknowledges Transport Connection Deleted.  
    TREQUEST_T_C   = 0x86,    //Primitive.   Host <-- Module. Requests Transport Connection.              
    TNEW_T_C       = 0x87,    //Primitive.   Host --> Module. Acknowledges Transport Connection Request.  
    TT_C_ERROR     = 0x88,    //Primitive.   Host --> Module. Signals errors.                             
    TDATA_LAST     = 0xA0,    //Constructed. Host <-> Module. Last Data packet.                           
    TDATA_MORE     = 0xA1     //Constructed. Host <-> Module. Data Packet. There are more packets.        
};

//Clause A.4.1.2.
enum SB_Value
{
    SB_MSG_AVAILABLE    = 0x80,  
    SB_NO_MSG_AVAILABLE = 0x00 
};

enum TError
{
    TERROR_NO_TRANSPORT_CONNECTION_AVAILABLE = 0x01   //Clause A.4.1.10. Sent in response to Request_T_C 
                                                      // to signal that no more Transport Conmnections are available
};

//Clause A.4.1.1  Command TPDU (Transport Protocol Data Unit)
class C_TPDU_COMMON_PARTS
{
    public: 
        C_TPDU_COMMON_PARTS(U8); //Constructor

        U32 getSerializeSize(); //Returns the size of the object once serialized
        void serialize(U8*);    //serializes the object

    protected: 
        U8 c_tpdu_tag;
        U8 t_c_id;
}; 

class C_TPDU_TINY:public C_TPDU_COMMON_PARTS
{
    public: 
        C_TPDU_TINY(U8); //Constructor
        
        U32 getSerializeSize(); //Returns the size of the object once serialized
        void serialize(U8*);    //serializes the object into a buffer

    protected: 
        U8 length_field;        //Length field will be 1 or 2
        U8 myBody; 
}; 

class C_TPDU:public C_TPDU_COMMON_PARTS
{
    public: 
        C_TPDU(U8, U16); //Constructor (tc_id, BodySize)
        ~C_TPDU(); 
        
        U32 getSerializeSize(); //Returns the size of the object once serialized
        void serialize(U8*);    //serializes the object into a buffer

    protected: 
        U16 length_field;   //length_field will be properly handled in serialize operations.
        U8* pMyBody; 
}; 

class New_T_C:public C_TPDU_TINY
{
    public: 
        New_T_C(U8, U8); //Constructor
}; 

class Create_T_C:public C_TPDU_TINY
{
    public: 
        Create_T_C(U8); //Constructor
}; 

class C_T_C_Reply:public C_TPDU_TINY
{
    public: 
        C_T_C_Reply(U8); //Constructor
}; 

class Delete_T_C:public C_TPDU_TINY 
{
    public: 
        Delete_T_C(U8); //Constructor
}; 

class D_T_C_Reply:public C_TPDU_TINY
{
    public: 
        D_T_C_Reply(U8); //Constructor
}; 

class Request_T_C:public C_TPDU_TINY
{
    public: 
        Request_T_C(U8); //Constructor
}; 

class TC_Error:public C_TPDU_TINY 
{
    public: 
        TC_Error(U8); //Constructor
}; 

class Poll_T_C:public C_TPDU_TINY
{
    public: 
        Poll_T_C(U8); //Constructor
}; 

class T_RCV:public C_TPDU_TINY
{
    public: 
        T_RCV(U8); //Constructor
}; 

class T_Data_More:public C_TPDU
{
    public: 
        T_Data_More(U8, U16, U8*); //Constructor TC_Id, Body Size, pBuff
}; 

class T_Data_Last:public C_TPDU
{
    public: 
        T_Data_Last(U8, U16, U8*); //Constructor TC_Id, Body Size, pBuff
}; 

//______________________________________________________________________________

//T_SB 
typedef enum
{
    INVALID_T_SB,
    T_SB_NO_DATA,
    T_SB_DATA
} TL_T_SB_enum; 


//Clause A.4.1.2  Response TPDU Header content
class R_TPDU_Header
{
    private:
        U8 r_tpdu_tag;
        U8 length_field_size_ind;   //length_field_size_ind will be 0x81 
        U8 length_field;            //Length of Body 
        U8 t_c_id;        //Transport Connection Identifier
    
    public:
        friend class R_TPDU; 

};

//Clause A.4.1.2  Response TPDU Status content
class R_TPDU_Status
{
    private:
        U8 SB_tag;
        U8 length_field;  //Length of Body
        U8 t_c_id;        //Transport Connection Identifier
        U8 SB_value;    

    public: 
        friend class R_TPDU; 

};

//Clause A.4.1.2  Response TPDU (Transport Protocol Data Unit)
class R_TPDU
{
    private:
        R_TPDU_Header Header;
        U8            Body[MAX_PDU_LENGTH];
        R_TPDU_Status Status;        

    public: 
        void Build_R_TPDU(MsgTL);      //Builds R_TPDU from a MsgTL
        U8 GetBodyLength() const;      //returns body length
        TL_T_SB_enum CheckTSB(U8) const; 
        BOOL Is_TC_T_C_REPLY(U8) const; 
        BOOL Is_TDATA_MORE(U8) const; 
        BOOL Is_TDATA_LAST(U8) const; 
        BOOL Is_TD_T_C_REPLY(U8) const; 
        U8 Get_t_c_id() const; 
        U8 Get_r_tpdu_tag() const; 
        void GetBody(U8*) const; 
};

#endif // __CITLOBJ_H


/*EOF*/
