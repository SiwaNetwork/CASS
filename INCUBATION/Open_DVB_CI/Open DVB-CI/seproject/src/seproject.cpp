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

* FILENAME     : seproject.cpp
* CREATED      : July 2005
* PROGRAMMER: Jordi Escoda
* DESCRIPTION  : Test workbench for the transport layer. Simulates 
*                the session layer  
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
#include "../../tlproject/src/CITLObj.h"
#include "../../tlproject/src/CITLMsg.h"

using namespace std;

ostream & showTime(ostream &os)
{
    timeval myTimeVal; 

    gettimeofday(&myTimeVal, NULL); 
    //os<<"tv_sec: "<<myTimeVal.tv_sec<<" tv_usec: "<<myTimeVal.tv_usec<<" "; 
    //os<<myTimeVal.tv_sec<<myTimeVal.tv_usec<<" "; 
    os<<"#################"; 
    return os; 
}

int main(int argc, char *argv[])
{
    MsgTL myMsgToSend;
    MsgSL myReceivedMsg; 
    int SLMsgQueueId; 
    int TLMsgQueueId; 
    int LLMsgQueueId; 
    int TimMsgQueueId; 
    int retVal; 
    int msgSize; 
    int i; 
    U8* pBuff; 

    sleep(2); //To wait to Transport Layer to be created
    //printf ("Session. Arguments:%d ", argc); 
    ofstream file("/home/j.escoda/SessionRCV", ios::binary); //file where is written the received content
    
    if (argc > 3 ) 
    {
        //printf ("SEMsgQueueId:%d. TLMsgQueueId:%d. LIMsgQueueId:%d. TimMsgQueueId:%d \n",atoi(argv[1]),atoi(argv[2]),atoi(argv[3]),atoi(argv[4])); 

        SLMsgQueueId = atoi(argv[1]);  
        TLMsgQueueId = atoi(argv[2]); 
        LLMsgQueueId = atoi(argv[3]);  
        TimMsgQueueId = atoi(argv[4]); 

        if (SLMsgQueueId == -1) 
        {
            cout<<"Session cannot be started because the Session Layer message queue has not been assigned."<<endl;     
        } 
        else if (TLMsgQueueId == -1) 
        {
            cout<<"Session cannot be started because the Transport Layer message queue has not been created."<<endl;     
        }
        else if (LLMsgQueueId == -1) 
        {
            cout<<"Session cannot be started because the Link layer message queue has not been assignd."<<endl;     
        }
        else if (TimMsgQueueId == -1) 
        {
            cout<<"Session cannot be started because the Timer message queue has not been assigned."<<endl;     
        }
        else
        {
            myMsgToSend.msgType = MSG_SL2TL_REQUEST_TC; 
            for (i = 1; i<7; i++)  //This loop creates TC.
            {
                retVal = msgsnd(TLMsgQueueId, &myMsgToSend , 1, 0); 
                if (retVal == -1)
                {
                    perror("Session: Could not send message MSG_SL2TL_REQUEST_TC!"); 
                }
                else
                {
                    cout<<showTime<<"Session: Message MSG_SL2TL_REQUEST_TC sent! QueueId: "<<(int)TLMsgQueueId<<endl; 
                }
            }
        }
        sleep(3); 

#if 0
		//Test: Send destroy object
        myMsgToSend.msgType = MSG_SL2TL_DELETE_TC; 
        myMsgToSend.msgContent.TL_ConnIdAddresee = 7; 
        retVal = msgsnd(TLMsgQueueId, &myMsgToSend , 1, 0); 
        if (retVal == -1)
        {
            perror("Session: Could not send message MSG_SL2TL_DELETE_TC!"); 
        }
        else
        {    
            cout<<showTime<<"Session: Message MSG_SL2TL_DELETE_TC sent! "<<endl; 
        }
#endif

#if 1
        //Test: Send data to TC_Id 6 
        pBuff = new U8[246]; 
        for (i = 0; i<246; i++)
        {
            *(pBuff + i) = i; 
        }
        myMsgToSend.msgType = MSG_SL2TL_DATA; 
        myMsgToSend.msgContent.TL_ConnIdAddresee = 6; 
        memcpy(myMsgToSend.msgContent.Content, pBuff, 246); 
        delete[] pBuff; 
        retVal = msgsnd(TLMsgQueueId, &myMsgToSend , 246 + 1, 0); 
        if (retVal == -1)
        {
            perror("Session: Could not send message MSG_SL2TL_DATA!"); 
        }
        else
        {    
            cout<<showTime<<"Session: Message MSG_SL2TL_DATA sent to TC 6"<<endl; 
        }
#endif

        while(true)
        {
            cout<<showTime<<"Session Layer: Waiting Message."<<endl; 
            msgSize = msgrcv(SLMsgQueueId, &myReceivedMsg, sizeof(myReceivedMsg), 0, 0); //msgtyp = 0 --> Every message is accepted
            if (msgSize < 0)
            {
                perror("Session Layer. msgrcv problem: "); 
            }

            switch (myReceivedMsg.msgType)    
            {
                case MSG_TL2SL_DATA: 
                    cout<<showTime<<"Session Layer: MSG_TL2SL_DATA received "<<msgSize<<" Bytes from TL :"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl; 
                    for (i=0; i < msgSize - 1; i++)
                    {
                        cout<<(int)myReceivedMsg.msgContent.Content[i]<<" "; 
                    }
                    cout<<endl; 
                    //TC4: test de transmitir un fichero
                    if (myReceivedMsg.msgContent.TL_ConnIdSender == 4)
                    {
                        for (i = 0; i < msgSize - 1; i++)
                        {
                            file<<myReceivedMsg.msgContent.Content[i]; 
                        }
                        file.close(); 
                    }
                    break; 

                case MSG_TL2SL_CREATE_TC_FAILED: 
                    cout<<showTime<<"Session Layer: MSG_TL2SL_CREATE_TC_FAILED received "<<msgSize<<" Bytes from TL :"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl; 
                    break;
                
                case MSG_TL2SL_TC_CREATED: 
                    cout<<showTime<<"Session Layer: MSG_TL2SL_TC_CREATED received "<<msgSize<<" Bytes from TL :"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl; 
                    break; 

                case MSG_TL2SL_TC_DELETED: 
                    cout<<showTime<<"Session Layer: MSG_TL2SL_CONNECTION_DELETED received "<<msgSize<<" Bytes from TL :"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl; 
                    break; 

                case MSG_TL2SL_BUSY: 
                    cout<<showTime<<"Session Layer: MSG_TL2SL_BUSY received "<<msgSize<<" Bytes from TL :"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl; 
                    break; 

                case MSG_TL2SL_NOT_ACTIVE: 
                    cout<<showTime<<"Session Layer: MSG_TL2SL_NOT_ACTIVE received "<<msgSize<<" Bytes from TL :"<<(int)myReceivedMsg.msgContent.TL_ConnIdSender<<endl; 
                    break; 
            }

#if 0
            sleep(1); 

            //Test: Send data to TC_Id 6 
            pBuff = new U8[246]; 
            for (i = 0; i<246; i++)
            {
                *(pBuff + i) = i; 
            }
            myMsgToSend.msgType = MSG_SL2TL_DATA; 
            myMsgToSend.msgContent.TL_ConnIdAddresee = 6; 
            memcpy(myMsgToSend.msgContent.Content, pBuff, 246); 
            delete[] pBuff; 
            retVal = msgsnd(TLMsgQueueId, &myMsgToSend , 246 + 1, 0); 
            if (retVal == -1)
            {
                perror("Session: Could not send message MSG_SL2TL_DATA!"); 
            }
            else
            {    
                cout<<showTime<<"Session: Message MSG_SL2TL_DATA sent to TC 6"<<endl; 
            }
#endif


        }
    }
    else
    {
        cout<<"Session: Missing parameter: QueueId."<<endl; 
    }
}

/* EOF */