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

* FILENAME     : CITLObj.cpp
* CREATED      : July 2005
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

//Clause A.4.1.9
New_T_C::New_T_C(U8 TC_Id, U8 New_TC_Id):C_TPDU_TINY(TC_Id)
{
    c_tpdu_tag = TNEW_T_C; 
    length_field = 2; 
    myBody = New_TC_Id; 
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

/*EOF*/

















