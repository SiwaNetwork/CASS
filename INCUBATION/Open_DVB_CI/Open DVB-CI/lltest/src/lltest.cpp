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

* FILENAME     : lltest.cpp
* CREATED      : July 2005
* PROGRAMMER: Jordi Escoda
* DESCRIPTION  : Helps to test Transport layer. Simulates the link layer 
***************************************************************************
*/

#include <stdio.h>
#include <iostream>  //Used by memcpy
#include <stdlib.h>

#include <sys/types.h>  //For message queue
#include <sys/ipc.h>    //For message queue (interprocess communication)
#include <sys/msg.h>    //For message queue
#include <errno.h>        //For error control

#include "../../tlproject/src/CITLCfg.h"
#include "../../tlproject/src/CITLMsg.h"
#include "../../tlproject/src/CITLObj.h"

using namespace std;

ofstream file("/home/j.escoda/TraceLL"); //Trace output file

#define cout file  //Comment this line to send messages to screen


ostream & showTime(ostream &os)
{
    timeval myTimeVal; 

    gettimeofday(&myTimeVal, NULL); 
    //os<<"tv_sec: "<<myTimeVal.tv_sec<<" tv_usec: "<<myTimeVal.tv_usec<<" "; 
    //os<<myTimeVal.tv_sec<<myTimeVal.tv_usec<<" "; 
    os<<"================="; 
    return os; 
}



void SendPacketDataLast(int TLMsgQueueId, MsgLL myReceivedMsg)
{
    MsgTL myMsgToSend; 
    S32 retVal; 
    U8 BuffPayLoad[10]; 
    U8* pBuffSerializedMsg; 

    {
        U8 i; 
        for (i = 0; i < 10; i++)
        {
            BuffPayLoad[i] = i+10; 
        }
    }                                    
    T_Data_Last::T_Data_Last myT_Data_Last(myReceivedMsg.msgContent.TL_ConnIdSender, 10, BuffPayLoad); 
    pBuffSerializedMsg = new U8[myT_Data_Last.getSerializeSize()+ 4]; //alllocs buffer
    myT_Data_Last.serialize(pBuffSerializedMsg); //Serializes de packet
    
    *(pBuffSerializedMsg + myT_Data_Last.getSerializeSize()) = TSB; 
    *(pBuffSerializedMsg + myT_Data_Last.getSerializeSize() + 1) = 2; 
    *(pBuffSerializedMsg + myT_Data_Last.getSerializeSize() + 2) = myReceivedMsg.msgContent.TL_ConnIdSender; 
    *(pBuffSerializedMsg + myT_Data_Last.getSerializeSize() + 3) = SB_NO_MSG_AVAILABLE; 

    myMsgToSend.msgType = MSG_LL2TL_MODULE_RESPONSE;                                 
    myMsgToSend.msgContent.TL_ConnIdAddresee = myReceivedMsg.msgContent.TL_ConnIdSender;

    
    memcpy(myMsgToSend.msgContent.Content, pBuffSerializedMsg, myT_Data_Last.getSerializeSize() + 4); 

    retVal = msgsnd(TLMsgQueueId, &myMsgToSend , myT_Data_Last.getSerializeSize() + 5, 0); //+5: Addresee,  TSB, 2, tc_id, SB
    if (retVal == -1) 
    {
        perror("Link Layer has failed to send T_DATA_LAST ");
    }
    else
    {
        cout<<showTime<<"Link Layer has sent T_DATA_LAST for _TL_ConnID "<<(int)myReceivedMsg.msgContent.TL_ConnIdSender
                      <<" "<<(int)(myT_Data_Last.getSerializeSize() + 5)<<" Bytes"<<endl; 
    }
    delete[] pBuffSerializedMsg; 
}

void SendPacketDataMore(int TLMsgQueueId, MsgLL myReceivedMsg)
{
    MsgTL myMsgToSend; 
    S32 retVal; 
    U8 BuffPayLoad[10]; 
    U8* pBuffSerializedMsg; 

    {
        U8 i; 
        for (i = 0; i < 10; i++)
        {
            BuffPayLoad[i] = i; 
        }
    }                                    
    T_Data_More::T_Data_More myT_Data_More(myReceivedMsg.msgContent.TL_ConnIdSender, 10, BuffPayLoad); 
    pBuffSerializedMsg = new U8[myT_Data_More.getSerializeSize()+ 4]; //alllocs buffer
    myT_Data_More.serialize(pBuffSerializedMsg); //Serializes de packet
    
    *(pBuffSerializedMsg + myT_Data_More.getSerializeSize()) = TSB; 
    *(pBuffSerializedMsg + myT_Data_More.getSerializeSize() + 1) = 2; 
    *(pBuffSerializedMsg + myT_Data_More.getSerializeSize() + 2) = myReceivedMsg.msgContent.TL_ConnIdSender; 
    *(pBuffSerializedMsg + myT_Data_More.getSerializeSize() + 3) = SB_MSG_AVAILABLE; 

    myMsgToSend.msgType = MSG_LL2TL_MODULE_RESPONSE;                                 
    myMsgToSend.msgContent.TL_ConnIdAddresee = myReceivedMsg.msgContent.TL_ConnIdSender;

    
    memcpy(myMsgToSend.msgContent.Content, pBuffSerializedMsg, myT_Data_More.getSerializeSize() + 4); 

    retVal = msgsnd(TLMsgQueueId, &myMsgToSend , myT_Data_More.getSerializeSize() + 5, 0); //+5: Addresee,  TSB, 2, tc_id, SB
    if (retVal == -1) 
    {
        perror("Link Layer has failed to send T_DATA_MORE ");
    }
    else
    {
        cout<<showTime<<"Link Layer has sent T_DATA_MORE for _TL_ConnID "<<(int)myReceivedMsg.msgContent.TL_ConnIdSender
            <<" "<<(int)(myT_Data_More.getSerializeSize() + 5)<<" Bytes"<<endl; 
    }
    delete[] pBuffSerializedMsg; 
}

void SendPacketSB_NO_MSG_AVAILABLE(int TLMsgQueueId, MsgLL myReceivedMsg)
{
    MsgTL myMsgToSend; 
    S32 retVal; 

    myMsgToSend.msgType = MSG_LL2TL_MODULE_RESPONSE; 

    myMsgToSend.msgContent.TL_ConnIdAddresee = myReceivedMsg.msgContent.TL_ConnIdSender;
    myMsgToSend.msgContent.Content[0] = TSB; 
    myMsgToSend.msgContent.Content[1] = 2; 
    myMsgToSend.msgContent.Content[2] = myReceivedMsg.msgContent.TL_ConnIdSender; 
    myMsgToSend.msgContent.Content[3] = SB_NO_MSG_AVAILABLE; 

    retVal = msgsnd(TLMsgQueueId, &myMsgToSend , 5, 0); 
    if (retVal == -1) 
    {
        perror("Link Layer has failed to send SB_NO_MSG_AVAILABLE ");
    }
    else
    {
        cout<<showTime<<"Link Layer has sent SB_NO_MSG_AVAILABLE for _TL_ConnID "<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl; 
    }
}

void SendPacketSB_MSG_AVAILABLE(int TLMsgQueueId, MsgLL myReceivedMsg)
{
    MsgTL myMsgToSend; 
    S32 retVal; 

    myMsgToSend.msgType = MSG_LL2TL_MODULE_RESPONSE; 

    myMsgToSend.msgContent.TL_ConnIdAddresee = myReceivedMsg.msgContent.TL_ConnIdSender;
    myMsgToSend.msgContent.Content[0] = TSB; 
    myMsgToSend.msgContent.Content[1] = 2; 
    myMsgToSend.msgContent.Content[2] = myReceivedMsg.msgContent.TL_ConnIdSender; 
    myMsgToSend.msgContent.Content[3] = SB_MSG_AVAILABLE; 

    retVal = msgsnd(TLMsgQueueId, &myMsgToSend , 5, 0); 
    if (retVal == -1) 
    {
        perror("Link Layer has failed to send SB_MSG_AVAILABLE ");
    }
    else
    {
        cout<<showTime<<"Link Layer has sent SB_MSG_AVAILABLE for _TL_ConnID "<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl; 
    }
}

void SendPacketTC_T_C_REPLY(int TLMsgQueueId, MsgLL myReceivedMsg)
{
    MsgTL myMsgToSend; 
    S32 retVal; 

    myMsgToSend.msgType = MSG_LL2TL_MODULE_RESPONSE; 

    //myMsgToSend.msgContent.TL_ConnIdAddresee = myReceivedMsg.msgContent.TL_ConnIdSender;
    myMsgToSend.msgContent.TL_ConnIdAddresee = myReceivedMsg.msgContent.Content[2];
    myMsgToSend.msgContent.Content[0] = TC_T_C_REPLY; 
    myMsgToSend.msgContent.Content[1] = 1; //msg Length
    myMsgToSend.msgContent.Content[2] = myReceivedMsg.msgContent.Content[2];  //tc_id
    myMsgToSend.msgContent.Content[3] = TSB; 
    myMsgToSend.msgContent.Content[4] = 2; 
    //myMsgToSend.msgContent.Content[5] = myReceivedMsg.msgContent.TL_ConnIdSender;
    myMsgToSend.msgContent.Content[5] = myReceivedMsg.msgContent.Content[2];
    myMsgToSend.msgContent.Content[6] = SB_NO_MSG_AVAILABLE; 
    retVal = msgsnd(TLMsgQueueId, &myMsgToSend , 8, 0); 
    if (retVal == -1) 
    {
        perror("Link Layer has failed to send TC_T_C_REPLY ");
    }
    else
    {
        cout<<showTime<<"Link Layer has sent TC_T_C_REPLY for _TL_ConnID "<<(int)myReceivedMsg.msgContent.Content[2]<<endl; 
    }
}


void SendPacketTD_T_C_REPLY(int TLMsgQueueId, MsgLL myReceivedMsg)
{
    MsgTL myMsgToSend; 
    S32 retVal; 

    myMsgToSend.msgType = MSG_LL2TL_MODULE_RESPONSE; 

    myMsgToSend.msgContent.TL_ConnIdAddresee = myReceivedMsg.msgContent.TL_ConnIdSender;
    myMsgToSend.msgContent.Content[0] = TD_T_C_REPLY; 
    myMsgToSend.msgContent.Content[1] = 1;   //msg Length
    myMsgToSend.msgContent.Content[2] = myReceivedMsg.msgContent.TL_ConnIdSender; //tc_id
    myMsgToSend.msgContent.Content[3] = TSB; 
    myMsgToSend.msgContent.Content[4] = 2; 
    myMsgToSend.msgContent.Content[5] = myReceivedMsg.msgContent.TL_ConnIdSender; 
    myMsgToSend.msgContent.Content[6] = SB_NO_MSG_AVAILABLE; 
    retVal = msgsnd(TLMsgQueueId, &myMsgToSend , 8 , 0); 
    if (retVal == -1) 
    {
        perror("Link Layer has failed to send TD_T_C_REPLY ");
    }
    else
    {
        cout<<showTime<<"Link Layer has sent TD_T_C_REPLY for _TL_ConnID "<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl; 
    }
}

void SendPacketTDELETE_T_C(int TLMsgQueueId, MsgLL myReceivedMsg)
{
    MsgTL myMsgToSend; 
    S32 retVal; 
    
    myMsgToSend.msgType = MSG_LL2TL_MODULE_RESPONSE; 

    myMsgToSend.msgContent.TL_ConnIdAddresee = myReceivedMsg.msgContent.TL_ConnIdSender;
    myMsgToSend.msgContent.Content[0] = TDELETE_T_C; 
    myMsgToSend.msgContent.Content[1] = 1; //msg Length
    myMsgToSend.msgContent.Content[2] = myReceivedMsg.msgContent.TL_ConnIdSender;  //tc_id
    myMsgToSend.msgContent.Content[3] = TSB; 
    myMsgToSend.msgContent.Content[4] = 2; 
    myMsgToSend.msgContent.Content[5] = myReceivedMsg.msgContent.TL_ConnIdSender; 
    myMsgToSend.msgContent.Content[6] = SB_NO_MSG_AVAILABLE; 
    retVal = msgsnd(TLMsgQueueId, &myMsgToSend , 8, 0); 
    if (retVal == -1) 
    {
        perror("Link Layer has failed to send TC_T_C_REPLY ");
    }
    else
    {
        cout<<showTime<<"Link Layer has sent TDELETE_T_C for _TL_ConnID "<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl; 
    }
}

void SendPacketTREQUEST_T_C(int TLMsgQueueId, MsgLL myReceivedMsg)
{
    MsgTL myMsgToSend; 
    S32 retVal; 

    myMsgToSend.msgType = MSG_LL2TL_MODULE_RESPONSE; 

    myMsgToSend.msgContent.TL_ConnIdAddresee = myReceivedMsg.msgContent.TL_ConnIdSender;
    myMsgToSend.msgContent.Content[0] = TREQUEST_T_C; 
    myMsgToSend.msgContent.Content[1] = 1; //msg Length
    myMsgToSend.msgContent.Content[2] = myReceivedMsg.msgContent.TL_ConnIdSender;  //tc_id
    myMsgToSend.msgContent.Content[3] = TSB; 
    myMsgToSend.msgContent.Content[4] = 2; 
    myMsgToSend.msgContent.Content[5] = myReceivedMsg.msgContent.TL_ConnIdSender; 
    myMsgToSend.msgContent.Content[6] = SB_NO_MSG_AVAILABLE; 
    retVal = msgsnd(TLMsgQueueId, &myMsgToSend , 8, 0); 
    if (retVal == -1) 
    {
        perror("Link Layer has failed to send TREQUEST_T_C ");
    }
    else
    {
        cout<<showTime<<"Link Layer has sent TREQUEST_T_C over _TL_ConnID "<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl; 
    }
}


U8* SplitAndSend(int TLMsgQueueId, MsgLL myReceivedMsg, long &buffSize, U8* pBuff, U8* pCursor)
{
    MsgTL myMsgToSend; 
    int i; 
    int index; 
    int retVal; 
    int serializeSize; 
    U8 BuffPayLoad[MAX_BODY_LENGTH]; // -1: t_c_id is included in the length
    U8* pBuffSerializedMsg; 


    if (pCursor != NULL)
    {
        pBuff = pCursor; 
    }
    

    myMsgToSend.msgType = MSG_LL2TL_MODULE_RESPONSE; 
    myMsgToSend.msgContent.TL_ConnIdAddresee = myReceivedMsg.msgContent.TL_ConnIdSender;
    index = 0; 
    if (buffSize > MAX_BODY_LENGTH) 
    {
        {
            U8 i; 
            for (i = 0; i < MAX_BODY_LENGTH; i++)
            {
                BuffPayLoad[i] = *pBuff; 
                pBuff++; 
            }
        }                                    

        T_Data_More::T_Data_More myT_Data_More(myReceivedMsg.msgContent.TL_ConnIdSender, MAX_BODY_LENGTH, BuffPayLoad); 
        serializeSize = myT_Data_More.getSerializeSize(); 
        //cout<<"LinkLayer.SerializeSize: "<<(int)serializeSize<<"^^^^^^^^^^^^^^^^^^^^"<<endl;

        pBuffSerializedMsg = new U8[serializeSize + 4]; //allocs buffer
        myT_Data_More.serialize(pBuffSerializedMsg); //Serializes de packet
        *(pBuffSerializedMsg + serializeSize) = TSB; 
        *(pBuffSerializedMsg + serializeSize + 1) = 2; 
        *(pBuffSerializedMsg + serializeSize + 2) = myReceivedMsg.msgContent.TL_ConnIdSender; 
        *(pBuffSerializedMsg + serializeSize + 3) = SB_MSG_AVAILABLE; 

        memcpy(myMsgToSend.msgContent.Content, pBuffSerializedMsg, serializeSize + 4); 
        delete[] pBuffSerializedMsg; 
        /*
        {
            cout<<"LinkLayer^^^^^^^^^^^^^^^^^^^^^^^^^^"<<endl;
            cout<<"LinkLayer^^^^^^^^buffSize:"<<(int)buffSize<<endl;
            int i; 
            for (i = 0; i < serializeSize + 4; i++)
            {
                cout<<*pBuffSerializedMsg; 
                pBuffSerializedMsg++; 
            }    
            cout<<endl; 
        }
        */
        retVal = msgsnd(TLMsgQueueId, &myMsgToSend , serializeSize + 5, 0); //+5: Addresee,  TSB, 2, tc_id, SB
        if (retVal == -1) 
        {
            perror("Link Layer has failed to send T_DATA_MORE ");
        }
        else
        {
            cout<<showTime<<"Link Layer has sent T_DATA_MORE for _TL_ConnID "<<(int)myReceivedMsg.msgContent.TL_ConnIdSender
                      <<" "<<(int)(serializeSize + 5)<<" Bytes"<<endl; 
        }
        buffSize -= MAX_BODY_LENGTH; 
    }
    else
    {
        //cout<<"LinkLayer^^^^^Last:^^buffSize:"<<(int)buffSize<<endl;
        {
            U8 i; 
            for (i = 0; i < buffSize - 1; i++)
            {
                BuffPayLoad[i] = *pBuff; 
                pBuff++; 
            }
        }                                    
        T_Data_Last::T_Data_Last myT_Data_Last(myReceivedMsg.msgContent.TL_ConnIdSender, buffSize, BuffPayLoad); 
        serializeSize = myT_Data_Last.getSerializeSize(); 
        pBuffSerializedMsg = new U8[serializeSize + 4]; //allocs buffer
        myT_Data_Last.serialize(pBuffSerializedMsg); //Serializes de packet
        *(pBuffSerializedMsg + serializeSize ) = TSB; 
        *(pBuffSerializedMsg + serializeSize + 1) = 2; 
        *(pBuffSerializedMsg + serializeSize + 2) = myReceivedMsg.msgContent.TL_ConnIdSender; 
        *(pBuffSerializedMsg + serializeSize + 3) = SB_NO_MSG_AVAILABLE; 

        memcpy(myMsgToSend.msgContent.Content, pBuffSerializedMsg, serializeSize + 4); 
        delete[] pBuffSerializedMsg; 

        retVal = msgsnd(TLMsgQueueId, &myMsgToSend , serializeSize + 5, 0); //+5: Addresee,  TSB, 2, tc_id, SB
        if (retVal == -1) 
        {
            perror("Link Layer has failed to send T_DATA_LAST ");
        }
        else
        {
            cout<<showTime<<"Link Layer has sent T_DATA_LAST for _TL_ConnID "<<(int)myReceivedMsg.msgContent.TL_ConnIdSender
                          <<" "<<(int)(serializeSize + 5)<<" Bytes"<<endl; 
        }
        buffSize = 0; 
    }
    return pBuff; 
}

//Reads a file and puts it into a buffer.
void ReadFile(char* fileName, U8* pBuff)
{
    ifstream file_in (fileName, ios::in|ios::binary);
    if (!file_in)
    {
        cout<<"File not found!"<<endl;
    }
    else
    {
        while (!file_in.eof())
        {
            file_in>>*pBuff; 
            pBuff++;         
        } 
        file_in.close();
    }    
}

long GetFileSize(char* fileName)
{
    long l,m;

    ifstream file_in (fileName, ios::in|ios::binary);
    if (!file_in)
    {
        cout<<"File not found!"<<endl;
    }
    else
    {
        l = file_in.tellg();
        file_in.seekg (0, ios::end);  //moves to the end of stream buffer
        m = file_in.tellg();
        file_in.close();
    }    
    cout<<" Link Layer: fileSize:"<<m-l<<endl; 
    return (m - l); 
}


void Run(int SLMsgQueueId, int TLMsgQueueId, int LLMsgQueueId, int TimMsgQueueId)
{
    MsgLL myReceivedMsg;    
    int msgSize; 
    U8* pBuff; 
    long buffSize; 
    U8* pCursor = NULL; 
    char fileName[] = "/home/j.escoda/ll2se"; 
    bool nextIsDataLast = false; 
    bool NewTCIssued = false; 
    int i; 

    buffSize = GetFileSize(fileName); 
    pBuff = new U8[buffSize];  //allocs space to hold file
    ReadFile(fileName, pBuff); //fills buffer with file content
    /*
    {
        int i; 
        U8* tmppBuff;

        tmppBuff = pBuff; 

        cout<<" Link Layer: File content:"<<endl;
        for (i = 0 ; i < buffSize; i ++)
        {    
            cout<<*tmppBuff;
            tmppBuff++; 
        }
        cout<<endl; 
        cout<<" Link Layer: End of file content"<<flush<<endl; 
    }
    */

    while(true)
    {
        cout<<showTime<<"Link Layer: Waiting Message"<<endl;
        msgSize = msgrcv(LLMsgQueueId, &myReceivedMsg, sizeof(MsgLL), 0, 0); //msgtyp = 0 --> Every message is accepted
        if (msgSize < 0)
        {
            perror("Link Layer. msgrcv problem: "); 
        }    

        cout<<"Msg received: "; 
        for (i = 0; i < msgSize - 1; i++)                
        {   
            cout<<(int)myReceivedMsg.msgContent.Content[i]<<" ";
        }
        cout<<endl; 

        switch(myReceivedMsg.msgType)
        {
            case (MSG_TL2LL_CREATE_TC): 
                cout<<showTime<<"Link Layer: MSG_TL2LL_CREATE_TC received!. Sender:"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl;
                SendPacketTC_T_C_REPLY(TLMsgQueueId, myReceivedMsg);
                break; 

            case (MSG_TL2LL_DELETE_TC): 
                cout<<showTime<<"Link Layer: DELETE_MSG_TL2LL_DELETE_TC received!. Sender:"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl;
                SendPacketTD_T_C_REPLY(TLMsgQueueId, myReceivedMsg);
                break; 

            case (MSG_TL2LL_POLLTC): 
                cout<<showTime<<"Link Layer: POLLTC_TOLINK received!. Sender:"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl;
                if (myReceivedMsg.msgContent.TL_ConnIdSender == 1) //Test: Module deletes TC 1
                {
                    if (!NewTCIssued) 
                    {
                        SendPacketTDELETE_T_C(TLMsgQueueId, myReceivedMsg); 
                    }
                    else
                    {
                        SendPacketSB_NO_MSG_AVAILABLE(TLMsgQueueId, myReceivedMsg);
                    }
                }
                else if (myReceivedMsg.msgContent.TL_ConnIdSender == 2) //Test: Module sends data LAST
                {
                    //SendPacketSB_MSG_AVAILABLE(TLMsgQueueId, myReceivedMsg);
                    if (!NewTCIssued)
                    {
                        SendPacketTREQUEST_T_C(TLMsgQueueId, myReceivedMsg); //The TL will assign a free TC
                        NewTCIssued = true; 
                    }
                    else
                    {
                        //SendPacketSB_NO_MSG_AVAILABLE(TLMsgQueueId, myReceivedMsg);
                        SendPacketSB_MSG_AVAILABLE(TLMsgQueueId, myReceivedMsg);
                    }
                }
                else if (myReceivedMsg.msgContent.TL_ConnIdSender == 3) //Test: Module sends DATA_MORE
                {
                    //SendPacketSB_NO_MSG_AVAILABLE(TLMsgQueueId, myReceivedMsg);
                    SendPacketSB_MSG_AVAILABLE(TLMsgQueueId, myReceivedMsg);
                }
                else if (myReceivedMsg.msgContent.TL_ConnIdSender == 4) //Test: Module sends a file
                {
                    if (pBuff != NULL)
                    {
                        //SendPacketSB_NO_MSG_AVAILABLE(TLMsgQueueId, myReceivedMsg);
                        SendPacketSB_MSG_AVAILABLE(TLMsgQueueId, myReceivedMsg);
                    } 
                    //Test: TC 4 will die due to time-out when file is sent

                }
                else  //Module sends no data available
                {  
                    SendPacketSB_NO_MSG_AVAILABLE(TLMsgQueueId, myReceivedMsg);
                }
                break; 

            case (MSG_TL2LL_TC_TRCV): 
                cout<<showTime<<"Link Layer: TRCV_TOLINK received!. Sender:"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl;

                if (myReceivedMsg.msgContent.TL_ConnIdSender == 2) //Test: Module sends data LAST
                {
                        SendPacketDataLast(TLMsgQueueId, myReceivedMsg); 
                }
                else if (myReceivedMsg.msgContent.TL_ConnIdSender == 3) //Test: Module sends DATA_MORE
                {
                    if (nextIsDataLast) 
                    {
                        SendPacketDataLast(TLMsgQueueId, myReceivedMsg); 
                        nextIsDataLast = false; 
                    }
                    else
                    {
                        SendPacketDataMore(TLMsgQueueId, myReceivedMsg); 
                        nextIsDataLast = true;  
                    }
                }
                else if (myReceivedMsg.msgContent.TL_ConnIdSender == 4) //Test: Module sends a file
                {
                    pCursor = SplitAndSend(TLMsgQueueId, myReceivedMsg, buffSize, pBuff, pCursor);
                    if ((buffSize == 0) && (pBuff != NULL))
                    {
                        delete[] pBuff;         
                        pBuff = NULL; 
                        cout<<showTime<<"Link Layer: File sent. pBuff freed."<<endl;
                    }
                }
                break; 

            case (MSG_TL2LL_SEND_DATA): 
                {
                    cout<<showTime<<"Link Layer: MSG_TL2LL_SEND_DATA received!: "<<(int)msgSize<<"Bytes. Sender:"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl;
                    //ask for the next packet
                    SendPacketSB_NO_MSG_AVAILABLE(TLMsgQueueId, myReceivedMsg);
                }
                break; 

            case (MSG_TL2LL_D_T_C_REPLY): 
                cout<<showTime<<"Link Layer: MSG_TL2LL_D_T_C_REPLY received!. Sender:"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl;
                break; 

            case (MSG_TL2LL_TC_ERROR): 
                cout<<showTime<<"Link Layer: MSG_TL2LL_TC_ERROR received!. Sender:"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl;
                break; 

            case (MSG_TL2LL_NEW_TC): 
                cout<<showTime<<"Link Layer: MSG_TL2LL_NEW_TC received!. Sender:"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl;
                break; 

            case (MSG_TL2LL_NO_MORE_TC_AVAILABLE): 
                cout<<showTime<<"Link Layer: MSG_TL2LL_NO_MORE_TC_AVAILABLE received!. Sender:"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl;
                break; 
        }
    }
}


int main(int argc, char *argv[])
{
    int SLMsgQueueId; 
    int TLMsgQueueId; 
    int LLMsgQueueId; 
    int TimMsgQueueId; 

    //printf ("Link Layer. Arguments:%d ", argc); 
    
    if (argc > 3 ) 
    {
        //printf ("SEMsgQueueId:%d. TLMsgQueueId:%d. LIMsgQueueId:%d. TimMsgQueueId:%d \n",atoi(argv[1]),atoi(argv[2]),atoi(argv[3]),atoi(argv[4])); 

        SLMsgQueueId = atoi(argv[1]);  
        TLMsgQueueId = atoi(argv[2]); 
        LLMsgQueueId = atoi(argv[3]);  
        TimMsgQueueId = atoi(argv[4]); 

        if (SLMsgQueueId == -1) 
        {
            printf("Link Layer cannot be started because the Session Layer message queue has not been assigned.\n");     
        } 
        else if (TLMsgQueueId == -1) 
        {
            printf("Link Layer cannot be started because the Transport Layer message queue has not been created.\n");     
        }
        else if (LLMsgQueueId == -1) 
        {
            printf("Link Layer cannot be started because the Link layer message queue has not been assignd.\n");     
        }
        else if (TimMsgQueueId == -1) 
        {
            printf("Link Layer cannot be started because the Timer message queue has not been assigned.\n");     
        }
        else
        {
            Run(SLMsgQueueId, TLMsgQueueId, LLMsgQueueId, TimMsgQueueId);
        }
    }
  return EXIT_SUCCESS;
}

/* EOF */