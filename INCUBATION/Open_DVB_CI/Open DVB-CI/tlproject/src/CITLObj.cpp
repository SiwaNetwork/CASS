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
* FILENAME     : CITLObj.cpp
* CREATED      : 22/7/2005             
* PROGRAMMER: Jordi Escoda
* DESCRIPTION  : Header file for Common Interface Transport Layer. Objects.
*                Implementation for EN 50221:1997.
***************************************************************************
*/

#include "CITLObj.h"

using namespace std;

//------------------------------------------------------------------------
//Constructors and Destructors
C_TPDU_COMMON_PARTS::C_TPDU_COMMON_PARTS(U8 TC_Id)
{
    t_c_id = TC_Id; 
}

C_TPDU_TINY::C_TPDU_TINY(U8 TC_Id):C_TPDU_COMMON_PARTS(TC_Id){}; 

C_TPDU::C_TPDU(U8 TC_Id, U16 BodySize):C_TPDU_COMMON_PARTS(TC_Id)
{
    length_field = BodySize + 1 ; //Length field includes t_c_id
    try
    {
        pMyBody = new U8[BodySize]; //Creates a buffer to later serialize the object

    }
    catch (bad_alloc)
    {
#if TEST_ON_A_PC
        cout<<"C_TPDU::C_TPDU. new Failed. Not enough memory."<<endl; 
#else
        DBG_Print(DBG_ERROR, "C_TPDU::C_TPDU. new Failed. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
    }
}

C_TPDU::~C_TPDU()
{
    if (pMyBody != NULL)
    {
        delete[] pMyBody ; 
    }
}

//Clause A.4.1.4
Create_T_C::Create_T_C(U8 TC_Id):C_TPDU_TINY(TC_Id)
{
    c_tpdu_tag = TCREATE_T_C; 
    length_field = 1; 
    myBody = 0; 
}

//Clause A.4.1.5
C_T_C_Reply::C_T_C_Reply(U8 TC_Id):C_TPDU_TINY(TC_Id)
{
    c_tpdu_tag = TC_T_C_REPLY; 
    length_field = 1; 
    myBody = 0; 
}

//Clause A.4.1.6
Delete_T_C::Delete_T_C(U8 TC_Id):C_TPDU_TINY(TC_Id)
{
    c_tpdu_tag = TDELETE_T_C; 
    length_field = 1; 
    myBody = 0; 
}

//Clause A.4.1.7
D_T_C_Reply::D_T_C_Reply(U8 TC_Id):C_TPDU_TINY(TC_Id)
{
    c_tpdu_tag = TD_T_C_REPLY; 
    length_field = 1; 
    myBody = 0; 
}

//Clause A.4.1.8
Request_T_C::Request_T_C(U8 TC_Id):C_TPDU_TINY(TC_Id)
{
    c_tpdu_tag = TREQUEST_T_C; 
    length_field = 1; 
    myBody = 0; 
}

//Clause A.4.1.10
TC_Error::TC_Error(U8 TC_Id):C_TPDU_TINY(TC_Id)
{
    c_tpdu_tag = TT_C_ERROR; 
    length_field = 2; 
    myBody = TERROR_NO_TRANSPORT_CONNECTION_AVAILABLE; 
}


Poll_T_C::Poll_T_C(U8 TC_Id):C_TPDU_TINY(TC_Id)
{
    c_tpdu_tag = TDATA_LAST; 
    length_field = 1; 
    myBody = 0; 
}

T_RCV::T_RCV(U8 TC_Id):C_TPDU_TINY(TC_Id)
{
    c_tpdu_tag = TRCV; 
    length_field = 1; 
    myBody = 0; 
}; 


//Clause A.4.1.11
T_Data_More::T_Data_More(U8 TC_Id, U16 BodySize, U8* pBuff):C_TPDU(TC_Id, BodySize)
{
    c_tpdu_tag = TDATA_MORE; 
    memcpy(pMyBody, pBuff, BodySize);  
}

//Clause A.4.1.11
T_Data_Last::T_Data_Last(U8 TC_Id, U16 BodySize, U8* pBuff):C_TPDU(TC_Id, BodySize)
{
    c_tpdu_tag = TDATA_LAST; 
    memcpy(pMyBody, pBuff, BodySize);  
}

//Clause A.4.1.9
New_T_C::New_T_C(U8 TC_Id, U8 New_TC_Id):C_TPDU_TINY(TC_Id)
{
    c_tpdu_tag = TNEW_T_C; 
    length_field = 2; 
    myBody = New_TC_Id; 
}

//------------------------------------------------------------------------
//Methods
U32 C_TPDU_TINY::getSerializeSize()
{
    U32 retVal; 
        
    if (length_field == 1) 
    {
        retVal = 3;  //c_tpdt_tag + length_field + t_c_id
    }
    else
    {
        retVal = 4; ////c_tpdt_tag + length_field + t_c_id + Body (1 byte)
    }

    /*
    cout<<"C_TPDU_TINY::getSerializeSize: "<<(int)retVal<<endl; 
    */
    return retVal; 
}

//Serializes the object into a buffer. 
void C_TPDU_TINY::serialize(U8* pBuff)
{
    *pBuff = c_tpdu_tag; 
    pBuff ++; 
    *pBuff = length_field; 
    pBuff ++; 
    *pBuff = t_c_id; 
    if (length_field == 2)
    {
        pBuff ++; 
        *pBuff = myBody; 
    }
}

//------------------------------------------------------------------------

//serializes the object into a buffer which has to be previously allocated.
void C_TPDU::serialize(U8* pBuff)
{
    *pBuff = c_tpdu_tag; 
    pBuff ++; 
    //Length field: See length_field() defined in 7 of EN50221:1997
    if (length_field < 128)
    {
        //As size_indicator is 0, length is encoded in one byte
        *pBuff =  (U8)length_field; 
        pBuff ++; 
    }
    else if ((length_field > 127) && (length_field < 256))
    {
        //As size_indicator is 1, and size > 127 and < 256 is encoded in two bytes
        *pBuff =  129;  //Indicates length_field_size
        pBuff ++; 
        *pBuff = (U8)length_field;  //length_field
        pBuff ++; 
    }
    *pBuff = t_c_id; 
    pBuff ++; 
    for (U8 i = 0; i < length_field - 1; i++)
    {
        *pBuff = *(pMyBody + i); 
        pBuff ++; 
    }
}

//Clause A.4.1.1
U32 C_TPDU::getSerializeSize()
{
    U32 retVal; 
    if (length_field < 128)
    {
        //As size_indicator is 0, length is encoded in one byte
        retVal = (U32)(2 + length_field); 
    }
    else if ((length_field > 127) && (length_field < 256))
    {
        //As size_indicator is 1, and size > 127 and < 256 is encoded in two bytes
        retVal = (U32)(3 + length_field);
    }
    //cout<<"C_TPDU::getSerializeSize: "<<(int)retVal<<endl; 
    return retVal; 
}

//------------------------------------------------------------------------

//Extracts data from MsgTL to properly fill R_TPDU
void R_TPDU::Build_R_TPDU(MsgTL myReceivedMsg) 
{
    U16 index = 0; 
    if (myReceivedMsg.msgContent.Content[index] != TSB) //Header + Body + Status has been received
    {
        Header.r_tpdu_tag = myReceivedMsg.msgContent.Content[index++];
        if (myReceivedMsg.msgContent.Content[index] < 128)
        { //Length field is coded in one byte
            Header.length_field_size_ind = myReceivedMsg.msgContent.Content[index++];        
            Header.length_field = 0;        
            Header.t_c_id = myReceivedMsg.msgContent.Content[index++];        
            for (U16 i = 0; i < Header.length_field_size_ind - 1; i++)
            {
                Body[i] = myReceivedMsg.msgContent.Content[index++]; 
            }
        }
        else
        { //Length field is coded in two bytes
            Header.length_field_size_ind = myReceivedMsg.msgContent.Content[index++];        
            Header.length_field = myReceivedMsg.msgContent.Content[index++];        
            Header.t_c_id = myReceivedMsg.msgContent.Content[index++];        
            for (U16 i = 0; i < Header.length_field - 1; i++)
            {
                Body[i] = myReceivedMsg.msgContent.Content[index++]; 
            }
        }
    }
    else  //No header was received. Fills it with 0
    {
        Header.r_tpdu_tag = 0;
        Header.length_field_size_ind = 0;        
        Header.length_field = 0;        
        Header.t_c_id = 0;        
    }
    //Mandatory Status is filled
    Status.SB_tag = myReceivedMsg.msgContent.Content[index++]; 
    Status.length_field = myReceivedMsg.msgContent.Content[index++];     
    Status.t_c_id = myReceivedMsg.msgContent.Content[index++];
    Status.SB_value = myReceivedMsg.msgContent.Content[index];

#if 0 //Debug
    cout<<showTime<<"TL_Manager::Fill_R_TPDU: index: "<<(int)index<<endl; 
    cout<<showTime<<"TL_Manager::Fill_R_TPDU: c_tpdu_tag: "<<(int)Header.r_tpdu_tag<<endl;  
    cout<<showTime<<"TL_Manager::Fill_R_TPDU: length_field_size_ind: "<<(int)Header.length_field_size_ind<<endl;  
    cout<<showTime<<"TL_Manager::Fill_R_TPDU: length_field: "<<(int)Header.length_field<<endl;  
    cout<<showTime<<"TL_Manager::Fill_R_TPDU: tc_id: "<<(int)Header.t_c_id<<endl;  

    cout<<showTime<<"TL_Manager::Fill_R_TPDU: Body[0]: "<<(int)Body[0]<<endl;  
    cout<<showTime<<"TL_Manager::Fill_R_TPDU: Body[1]: "<<(int)Body[1]<<endl;  
    cout<<showTime<<"TL_Manager::Fill_R_TPDU: Body[8]: "<<(int)Body[8]<<endl;  
    cout<<showTime<<"TL_Manager::Fill_R_TPDU: Body[9]: "<<(int)Body[9]<<endl;  

    cout<<showTime<<"TL_Manager::Fill_R_TPDU: SB_tag: "<<(int)Status.SB_tag<<endl;  
    cout<<showTime<<"TL_Manager::Fill_R_TPDU: length_field: "<<(int)Status.length_field<<endl;  
    cout<<showTime<<"TL_Manager::Fill_R_TPDU: t_c_id: "<<(int)Status.t_c_id<<endl;  
    cout<<showTime<<"TL_Manager::Fill_R_TPDU: SB_value: "<<(int)Status.SB_value<<endl;  
#endif 
}


U8 R_TPDU::GetBodyLength() const
{
    if (Header.length_field_size_ind < 128)
    {
        return (Header.length_field_size_ind - 1);  //-1: t_c_id is excluded
    }
    else
    {
        return (Header.length_field - 1 );//-1: t_c_id is excluded
    }
}

//Checks for the T_SB tag and data availability of a R_TPDU 
//Clause A.4.1.2
TL_T_SB_enum R_TPDU::CheckTSB(U8 Tc_Id) const
{
#if TEST_ON_A_PC
    //cout<<showTime<<"R_TPDU::CheckT_SB"<<endl; 
#endif //TEST_ON_A_PC
    if ( (Status.SB_tag == TSB) 
      && (Status.length_field == 2) 
      && (Status.t_c_id == Tc_Id) )
    {
        if  (Status.SB_value == SB_MSG_AVAILABLE) 
        {
            return T_SB_DATA; 
        }

        if (Status.SB_value == SB_NO_MSG_AVAILABLE)
        {
            return T_SB_NO_DATA; 
        }

        return INVALID_T_SB; 
    }
    return INVALID_T_SB; 
}

BOOL R_TPDU::Is_TC_T_C_REPLY(U8 TC_Id) const
{
    return ((Header.r_tpdu_tag == TC_T_C_REPLY) 
         && (Header.length_field_size_ind == 1) 
         && (Header.t_c_id == TC_Id));
}


BOOL R_TPDU::Is_TDATA_MORE(U8 TC_Id) const
{
    return ((Header.r_tpdu_tag != TDATA_MORE)  
         && (Status.t_c_id == TC_Id) 
         && (Status.length_field == 2 ));
}

BOOL R_TPDU::Is_TDATA_LAST(U8 TC_Id) const
{
    return ((Header.r_tpdu_tag != TDATA_LAST)  
         && (Status.t_c_id == TC_Id) 
         && (Status.length_field == 2 ));
}

BOOL R_TPDU::Is_TD_T_C_REPLY(U8 TC_Id) const
{
    return ((Header.r_tpdu_tag == TD_T_C_REPLY)
         && (Header.length_field_size_ind == 1)
         && (Header.t_c_id == TC_Id));
}


U8 R_TPDU::Get_t_c_id() const
{
    if (Header.t_c_id == 0)
    {
        return Status.t_c_id;
    }
    return Header.t_c_id; 
}

U8 R_TPDU::Get_r_tpdu_tag() const
{
    return (Header.r_tpdu_tag);
}

//Fills a buffer with the body content
void R_TPDU::GetBody(U8* pBuff) const
{
    memcpy(pBuff, &Body, GetBodyLength()); 
}

/* EOF */