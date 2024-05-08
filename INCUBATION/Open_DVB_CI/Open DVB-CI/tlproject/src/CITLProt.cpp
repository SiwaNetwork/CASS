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

 * FILENAME     : CITLProt.cpp
 * CREATED      : September 2005             
 * PROGRAMMER: Jordi Escoda
 * DESCRIPTION  : Common Interface Transport Layer. Protocol.
 *                Implementation for EN 50221:1997.
 ***************************************************************************
 */

#include "CITLProt.hpp"

//Output trace
#define cout file  //Comment this line to send messages to screen


#if TEST_ON_A_PC
using namespace std;

ofstream file("/home/j.escoda/TraceTL"); //Trace output file

ostream & showTime(ostream &os)
{
    timeval myTimeVal; 

    gettimeofday(&myTimeVal, NULL); 
    //os<<"tv_sec: "<<myTimeVal.tv_sec<<" tv_usec: "<<myTimeVal.tv_usec<<" "; 
    os<<myTimeVal.tv_sec<<myTimeVal.tv_usec<<" "; 
    return os; 
}
#endif //TEST_ON_A_PC

//------------------------------------------------------------------------

//Static attribute is initialized here.
TL_Manager* TL_Manager::_instance = 0;   //Singleton pattern

//This method is to build and get the object.
TL_Manager* TL_Manager::Instance()
{
    if (_instance == 0) 
    {
        _instance = new TL_Manager(); 
#if TEST_ON_A_PC
        cout<<showTime<<"TL_Manager has been Created"<<endl;                     
#endif // TEST_ON_A_PC
    }
    return _instance; 
}

//TL_Manager constructor. 
TL_Manager::TL_Manager()
{
    _TLConnCreated = FALSE; 
    _Run = FALSE; 
    _SLmsgQueueId = -1;   //Handler for Session Layer queue
    _TLmsgQueueId = -1;   //Handler for TL message queue 
    _LLmsgQueueId = -1;   //Handler for Link Layer queue
    _TimmsgQueueId = -1;  //Handler for Timer queue
}

//TL_Manager Start. Instantiates MAX_TRANSPORT_CONNECTIONS
void TL_Manager::Start()
{
#if TEST_ON_A_PC
    int msgSize; 
    S32 retVal; 
#endif //TEST_ON_A_PC
    MsgTL myReceivedMsg;  
    MsgSL myMsgToSendToSL;    


    if (_SLmsgQueueId == -1) 
    {
        cout<<showTime<<"TL_Manager NOT started. Session Layer message queue has not been assigned."<<endl;     
    } 
    else if (_TimmsgQueueId == -1) 
    {
        cout<<showTime<<"TL_Manager NOT started. Timer message queue has not been assigned."<<endl;     
    }
    else if (_LLmsgQueueId == -1) 
    {
        cout<<showTime<<"TL_Manager NOT started. Link layer message queue has not been assigned."<<endl;     
    }
    else if (_TLmsgQueueId == -1) 
    {
        cout<<showTime<<"TL_Manager NOT started. Transport Layer message queue has not been assigned."<<endl;     
    }
    else
    {
        if (!_TLConnCreated)
        {
            myTL_Connection[0] = NULL; //TC 0 is reserved.
            for (U8 i = 1; i <= TRANSPORT_CONNECTIONS; i++)
            {
                myTL_Connection[i] = new TL_Connection(i);
            }
            _TLConnCreated = TRUE; 
        }
        
        _Run = TRUE; 
        while(_Run)
        {
#if TEST_ON_A_PC
            cout<<showTime<<"TL_Manager: Waiting Message."<<endl; 
            msgSize = msgrcv(_TLmsgQueueId, &myReceivedMsg, sizeof(myReceivedMsg.msgContent), 0, 0); //msgtyp = 0 --> Every message is accepted. R_TPDU::MAX_PDU_LENGTH + 1: Addresee + TPDU
            { 
                cout<<showTime<<"TL_Manager. MsgReceivedSize: "<<msgSize<<" MsgReceived: "; 
                for (int i = 0; i < msgSize - 1; i++)
                {
                    cout<<(int)myReceivedMsg.msgContent.Content[i]<<" "; 
                }
                cout<<"    Type:"<<(int)myReceivedMsg.msgType<<"    Addresee:"<<(int)myReceivedMsg.msgContent.TL_ConnIdAddresee<<endl; 
                cout<<showTime<<"TL_Manager. States: "; 
                for (int i = 1; i <= TRANSPORT_CONNECTIONS; i++)
                {
                    cout<<(int)myTL_Connection[i]->_state->GetStateId()<<" ";
                }
                cout<<endl; 
            }   
            if (msgSize < 0)
            {
                cout<<showTime<<"TL_Manager. "<<flush;                 
                perror("MsgReceive problem"); 
                _Run = FALSE; 
            }    
#else
            OSAL_MsgWait(); 
#endif //TEST_ON_A_PC
            switch (myReceivedMsg.msgType)
            {
                case MSG_SL2TL_REQUEST_TC: 
#if TEST_ON_A_PC
                    cout<<showTime<<"TL_Manager: Message MSG_SL2TL_REQUEST_TC received!"<<endl;
#endif //TEST_ON_A_PC
                    if (!CreateTC())
                    {
                        //No more transport connection available. Message is given to the Session Layer to feedback.
                        SendToSessionLayer(MSG_TL2SL_NO_MORE_TC_AVAILABLE, 0); 
                    }
                    break; 
                
                case MSG_SL2TL_DELETE_TC: 
#if TEST_ON_A_PC
                    cout<<showTime<<"TL_Manager: Message MSG_SL2TL_DELETE_TC received for TC:"<<(int)myReceivedMsg.msgContent.TL_ConnIdAddresee<<endl; 
#endif //TEST_ON_A_PC
                    Delete_T_C(myReceivedMsg.msgContent.TL_ConnIdAddresee); 
                    break; 

                case MSG_SL2TL_DATA: 
                    if (myTL_Connection[myReceivedMsg.msgContent.TL_ConnIdAddresee]->GetStateId() == TL_ACTIVE) 
                    {
                        if (myTL_Connection[myReceivedMsg.msgContent.TL_ConnIdAddresee]->_pBuffDataFromSL == NULL) //If the Transport connection is free to transmit
                        {
                            myTL_Connection[myReceivedMsg.msgContent.TL_ConnIdAddresee]->LoadDataToSend(myReceivedMsg.msgContent.Content, msgSize - 1); 
#if TEST_ON_A_PC
                            cout<<showTime<<"TL_Manager: Message MSG_SL2TL_DATA received for TC:"<<(int)myReceivedMsg.msgContent.TL_ConnIdAddresee
                                          <<" State:"<<(int)myTL_Connection[myReceivedMsg.msgContent.TL_ConnIdAddresee]->GetStateId()<<endl; 
#endif //TEST_ON_A_PC
                        }
                        else //There is a transmission in progress.
                        {
                            SendToSessionLayer(MSG_TL2SL_BUSY, myReceivedMsg.msgContent.TL_ConnIdAddresee); 
                        }
                    }
                    else  //TC is not in active state. 
                    {
                        SendToSessionLayer(MSG_TL2SL_NOT_ACTIVE, myReceivedMsg.msgContent.TL_ConnIdAddresee); 
                    }
                    break; 

                case MSG_LL2TL_MODULE_RESPONSE: 
                    //Since it is a module response, must be a R_TPDU object.
                    { 
                        R_TPDU myR_TPDU; 
#if TEST_ON_A_PC
                        cout<<showTime<<"TL_Manager: Message MSG_LL2TL_MODULE_RESPONSE received for TC:"<<(int)myReceivedMsg.msgContent.TL_ConnIdAddresee
                                      <<" State:"<<(int)myTL_Connection[myReceivedMsg.msgContent.TL_ConnIdAddresee]->GetStateId()<<endl; 
#endif //TEST_ON_A_PC
                        myR_TPDU.Build_R_TPDU(myReceivedMsg);    
                        myTL_Connection[myR_TPDU.Get_t_c_id()]->ProcessResponse(myR_TPDU); 
                    }
                    break; 

                case MSG_TIM2TL_TIMEOUT: 
#if TEST_ON_A_PC
                    cout<<showTime<<"TL_Manager: Message MSG_TIM2TL_TIMEOUT received for TC:"<<(int)myReceivedMsg.msgContent.TL_ConnIdAddresee
                                  <<" State:"<<(int)myTL_Connection[myReceivedMsg.msgContent.TL_ConnIdAddresee]->GetStateId()<<endl; 

#endif //TEST_ON_A_PC
                    myTL_Connection[myReceivedMsg.msgContent.TL_ConnIdAddresee]->TimeOut(); 
                    break; 
    
                case MSG_TIM2TL_POLLTC:
#if TEST_ON_A_PC
                    cout<<showTime<<"TL_Manager: Message MSG_TIM2TL_POLLTC received for TC:"<<(int)myReceivedMsg.msgContent.TL_ConnIdAddresee
                                  <<" State:"<<(int)myTL_Connection[myReceivedMsg.msgContent.TL_ConnIdAddresee]->GetStateId()<<endl; 
#endif //TEST_ON_A_PC
                    myTL_Connection[myReceivedMsg.msgContent.TL_ConnIdAddresee]->PollTC(); 
                    break;  

                case MSG_LL2TL_MODULE_PLUGGED:  //A new module is plugged. TC Is created. 
#if TEST_ON_A_PC
                    cout<<showTime<<"TL_Manager: Message MSG_LL2TL_MODULE_PLUGGED received."<<endl; 
#endif //TEST_ON_A_PC
                    if (!CreateTC())
                    {
                        //No more transport connection available. Message is given to the Link Layer to feedback.
                        SendToLinkLayer(MSG_TL2LL_NO_MORE_TC_AVAILABLE, 0); 
                    }
                    break; 
    
                case TL_KILL: 
                    _Run = FALSE; 
                    break; 
            }    
        }
    }
}


//Cleans objects. Must be called once Transport Layer is terminated
void TL_Manager::Stop()
{                       
#if TEST_ON_A_PC
    msqid_ds* pmyMsqid_ds; //Pointer to data structure for controlling the queue
#endif //TEST_ON_A_PC

    if (_TLConnCreated) 
    {
        for (U8 i = 1; i <= TRANSPORT_CONNECTIONS; i++)
        {
            myTL_Connection[i]->StopTimeOutTimer(); 
            myTL_Connection[i]->StopPollTimer(); 
            delete myTL_Connection[i]; 
#if TEST_ON_A_PC
            cout<<showTime<<"TL_Connection "<<(int)i<<" has been Destroyed."<<endl;                     
#endif // TEST_ON_A_PC
        }
        _TLConnCreated = FALSE; 
    }
}

//Clause 7.1.2
//Used by the host to Create TC or when a new module is plugged into the socket
BOOL TL_Manager::CreateTC() 
{
    U16 TCLookUp = 1; 
    while ((myTL_Connection[TCLookUp]->GetStateId() != TL_IDLE ) && (TCLookUp < TRANSPORT_CONNECTIONS))
    {
        TCLookUp++; 
    }

    if ((TCLookUp <= TRANSPORT_CONNECTIONS) && (myTL_Connection[TCLookUp]->GetStateId() == TL_IDLE )) 
    {
        myTL_Connection[TCLookUp]->CreateTC(); 
        return TRUE; 
    }
    else
    {
        return FALSE; 
    }
}

//Used when module requests TC
void TL_Manager::CreateTC(U8 ID_RequestedBy)
{
    U16 TCLookUp = 1; 
    while ((myTL_Connection[TCLookUp]->GetStateId() != TL_IDLE ) && (TCLookUp < TRANSPORT_CONNECTIONS))
    {
        TCLookUp++; 
    }

    if ((TCLookUp <= TRANSPORT_CONNECTIONS) && (myTL_Connection[TCLookUp]->GetStateId() == TL_IDLE )) 
    {
        myTL_Connection[ID_RequestedBy]->CreateTC(TCLookUp); 
    }
    else
    {
        myTL_Connection[ID_RequestedBy]->TCError(TERROR_NO_TRANSPORT_CONNECTION_AVAILABLE); //State is TL_Active
    }
}

//Clause 7.1.2
//Used by the host to Delete TC
void TL_Manager::DeleteTC(U8 TL_ConnID)
{
    myTL_Connection[TL_ConnID]->DeleteTC(); 
}


//Sends message to Session Layer
void TL_Manager::SendToSessionLayer(msgSL_enum myMsgType, U8 TC_Id) const
{
    MsgSL myMsgToSend; 
    U32 retVal;     

    myMsgToSend.msgType = myMsgType; 
    myMsgToSend.msgContent.TL_ConnIdSender = TC_Id;         
#if TEST_ON_A_PC
    retVal = msgsnd(GetSLMsgQueueId(), &myMsgToSend , sizeof(myMsgToSend.msgContent.TL_ConnIdSender), 0); 
    if (retVal == -1) 
    {
        perror("TL_Manager::SendToSessionLayer: Failed to send message to Session Layer: ");
    }
    else
    {
        cout<<showTime<<"TL_Manager: Sent "; 
        switch (myMsgType)
        {
            case MSG_TL2SL_DATA:
                cout<<"MSG_TL2SL_DATA";
                break;
            case MSG_TL2SL_NO_MORE_TC_AVAILABLE : 
                cout<<"MSG_TL2SL_NO_MORE_TC_AVAILABLE";
                break;
            case MSG_TL2SL_CREATE_TC_FAILED: 
                cout<<"MSG_TL2SL_CREATE_TC_FAILED";
                break;
            case MSG_TL2SL_TC_CREATED: 
                cout<<"MSG_TL2SL_TC_CREATED";
                break;
            case MSG_TL2SL_TC_DELETED: 
                cout<<"MSG_TL2SL_TC_DELETED";
                break;
            case MSG_TL2SL_BUSY: 
                cout<<"MSG_TL2SL_BUSY";
                break;
            case MSG_TL2SL_NOT_ACTIVE: 
                cout<<"MSG_TL2SL_NOT_ACTIVE";
                break;
            default: 
                cout<<myMsgType; 
        }            
        cout<<" to Session Layer"<<endl;         
    }
#endif //TEST_ON_A_PC
}

//Sends message to Link Layer
void TL_Manager::SendToLinkLayer(msgLL_enum myMsgType, U8 TC_Id) const
{
    MsgLL myMsgToSend; 
    U32 retVal;     

    myMsgToSend.msgType = myMsgType; 
    myMsgToSend.msgContent.TL_ConnIdSender = TC_Id;         
#if TEST_ON_A_PC
    retVal = msgsnd(GetLLMsgQueueId(), &myMsgToSend , sizeof(myMsgToSend.msgContent.TL_ConnIdSender), 0); 
    if (retVal == -1) 
    {
        perror("TL_Manager::SendToLinkLayer: Failed to send message to Link Layer: ");
    }
    else
    {
        cout<<showTime<<"TL_Manager::SendToLinkLayer Sent "; 
        switch (myMsgType)
        {
            case MSG_TL2LL_NO_MORE_TC_AVAILABLE:
                cout<<"MSG_TL2LL_NO_MORE_TC_AVAILABLE";
                break;
            default: 
                cout<<myMsgType; 
        }            
        cout<<" to Link Layer"<<endl;         
    }
#endif //TEST_ON_A_PC
}

//returns a pointer to the TL object which has TcID
TL_Connection* TL_Manager::GetTL_ConnectionByTCId(U8 TcID)
{
    U8 i = 1;   //TC 0 is reserved.

    while ( (myTL_Connection[i]->_TL_ConnID != TcID) 
         && (i <= TRANSPORT_CONNECTIONS) )
    {
        i++;
    }
    if (myTL_Connection[i]->_TL_ConnID == TcID)
    {
        return myTL_Connection[i]; 
    }
    else
    {
        return NULL; 
    }
}

//------------------------------------------------------------------------

//The TL_Connection constructor initializes the object to Idle state
//Only the first instance of TL_Connection will initialize _TCInUse static array
TL_Connection::TL_Connection(U8 TC_Id)
{
    _theTLManager = TL_Manager::Instance(); 
    _TL_ConnID = TC_Id;
    _state = TL_Idle::Instance(); 
    _pBuffDataToSL = NULL;    //Buffer Data To Session Layer is void    
    _BuffSizeDataToSL = 0;   
    _pBuffDataFromSL = NULL;  //Buffer Data From Session Layer is void 
    _BuffSizeDataFromSL = 0; 
    _pBuffTmp = NULL;         //Temporal buffer to used to split messages to Link Layer
    _BuffSizeTmp = 0; 
    _splitIndex = 0; 
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Connection "<<(int)_TL_ConnID<<" has been Built"<<endl;                     
#endif // TEST_ON_A_PC
}

void TL_Connection::ChangeState(TL_State* s)
{
    _state = s; 
}

void TL_Connection::CreateTC()
{
    _state->CreateTC(this); 
}

void TL_Connection::CreateTC(U8 NewTCId)
{
    _state->CreateTC(this, NewTCId); 
}

void TL_Connection::TimeOut()
{
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Connection "<<(int)_TL_ConnID<<" has called _state->TimeOut"<<endl;                     
#endif // TEST_ON_A_PC
    _state->TimeOut(this); 
}

void TL_Connection::PollTC()
{
    _state->PollTC(this); 
}

void TL_Connection::DeleteTC()
{
    _state->DeleteTC(this); 
}

void TL_Connection::TCError(U8 ErrorCode)
{
    _state->TCError(this, ErrorCode); 
}

void TL_Connection::TRCV()
{
    _state->TRCV(this);     
}

//Clause A.4.1.12 Rules for the polling function
/* 
  "At each poll a timeout of 300mS is started and is reset if the poll response is received."
*/
void TL_Connection::StartPollTimer() const
{
    //Since there is only one timer per TC, TimeOut Timer is implicitly stopped when Poll Timer starts. 
    SendToTimerTask(MSG_TL2TIM_POLLTC_CREATION);
}

void TL_Connection::StopPollTimer() const
{
    SendToTimerTask(MSG_TL2TIM_POLLTC_DELETION);
}

void TL_Connection::StartTimeOutTimer() const
{
    SendToTimerTask(MSG_TL2TIM_TIMEOUT_CREATION);
}

void TL_Connection::StopTimeOutTimer() const
{
    SendToTimerTask(MSG_TL2TIM_TIMEOUT_DELETION);
}

void  TL_Connection::ProcessResponse(R_TPDU myR_TPDU)
{
    _state->ProcessResponse(this, myR_TPDU);     
}


//Returns the State Id of the connection
TL_State_enum TL_Connection::GetStateId() const
{
    return (_state->GetStateId()); 
}

//Receives message from the session Layer to send it to the link layer
void TL_Connection::LoadDataToSend(U8* pBuff, U32 MsgSize)
{
    try
    {
        _pBuffDataFromSL = new U8[MsgSize - 1]; 
           //Once sent, TL_Active is the responsible to free the memory
    }
    catch (bad_alloc)
    {
#if TEST_ON_A_PC
        cout<<showTime<<"TL_Connection::SendData. new Failed. Not enough memory."<<endl; 
#else
        DBG_Print(DBG_ERROR, "TL_Connection::SendData. new Failed. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
        return;
    }
    _BuffSizeDataFromSL = MsgSize - 1; 
    memcpy(_pBuffDataFromSL, pBuff, MsgSize - 1);
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Connection::LoadDataToSend. Data loaded."<<endl; 
#endif //TEST_ON_A_PC
}

//Empties the buffer to send to SL
void TL_Connection::cleanBuffDataToSL()
{
    if (_pBuffDataToSL != NULL)
    {        
        delete[] _pBuffDataToSL; 
        _pBuffDataToSL = NULL;  //Message already sent to the Session Layer. Now is void.
        _BuffSizeDataToSL = 0; 
    }
}

//Empties the buffer received from the SL
void TL_Connection::cleanBuffDataFromSL()
{
    if (_pBuffDataFromSL != NULL)
    {
        delete[] _pBuffDataFromSL; 
        _pBuffDataFromSL = NULL; 
        _BuffSizeDataFromSL = 0; 
        _splitIndex = 0; 
    }
}

//Empties the buffer the temporal buffer used to split data to send to Link Layer
void TL_Connection::cleanBuffTmp()
{
    if (_pBuffTmp != NULL)
    {
        delete[] _pBuffTmp; 
        _pBuffTmp = NULL; 
        _BuffSizeTmp = 0; 
    }
}

//Sends message to Timer task
void TL_Connection::SendToTimerTask(msgTim_enum msgType) const
{
    MsgTim myMsgToSend; 

    //Data is sent to the timer task
    myMsgToSend.msgType = msgType; 
    myMsgToSend.msgContent.TL_ConnIdSender = _TL_ConnID;

#if TEST_ON_A_PC
    S32 retVal; 
    retVal = msgsnd(_theTLManager->GetTimMsgQueueId(), &myMsgToSend , sizeof(myMsgToSend.msgContent), 0); 
    if (retVal == -1) 
    {
        perror("TL_Connection has failed to send message to timer: ");
    }
    else
    {
        cout<<showTime<<"TL_Connection::SendToTimerTask has sent ";
        switch(msgType)
        {
            case MSG_TL2TIM_TIMEOUT_CREATION: 
                cout<<"MSG_TL2TIM_TIMEOUT_CREATION";
                break; 
            case MSG_TL2TIM_TIMEOUT_DELETION: 
                cout<<"MSG_TL2TIM_TIMEOUT_DELETION";
                break; 
            case MSG_TL2TIM_POLLTC_CREATION: 
                cout<<"MSG_TL2TIM_POLLTC_CREATION";
                break; 
            case MSG_TL2TIM_POLLTC_DELETION: 
                cout<<"MSG_TL2TIM_POLLTC_DELETION";
                break; 
        }    
        cout<<" for _TL_ConnID: "<<(int)_TL_ConnID<<endl;                     
    }
#endif // TEST_ON_A_PC
}


//------------------------------------------------------------------------

void TL_State::ChangeState(TL_Connection* t, TL_State* s)
{
    t->ChangeState(s); 
}

//Sends message to Link Layer
void TL_State::SendToLinkLayer(TL_Connection* t, msgLL_enum msgType, U8* pBuff, U16 msgSize) const
{
    MsgLL myMsgToSend; 

    myMsgToSend.msgType = msgType; 
    myMsgToSend.msgContent.TL_ConnIdSender = t->_TL_ConnID;
    { 
        for (U16 i = 0; i < msgSize; i++)
        {
            myMsgToSend.msgContent.Content[i] = *(pBuff + i); 
        }
    }
    //Data is sent to the Link Layer
#if TEST_ON_A_PC
    S32 retVal;
    retVal = msgsnd(t->_theTLManager->GetLLMsgQueueId(), &myMsgToSend , msgSize, 0); 
    if (retVal == -1) 
    {
        perror("TL_Connection::SendToLinkLayer has failed to send data to link layer.");
    }
    else
    {
        cout<<showTime<<"TL_Connection::SendToLinkLayer has sent ";
        switch(msgType)
        {
            case MSG_TL2LL_CREATE_TC: 
                cout<<"MSG_TL2LL_CREATE_TC";
                break; 
            case MSG_TL2LL_DELETE_TC: 
                cout<<"MSG_TL2LL_DELETE_TC";
                break; 
            case MSG_TL2LL_D_T_C_REPLY: 
                cout<<"MSG_TL2LL_D_T_C_REPLY";
                break; 
            case MSG_TL2LL_POLLTC: 
                cout<<"MSG_TL2LL_POLLTC";
                break; 
            case MSG_TL2LL_TC_ERROR: 
                cout<<"MSG_TL2LL_TC_ERROR";
                break; 
            case MSG_TL2LL_TC_TRCV: 
                cout<<"MSG_TL2LL_TC_TRCV";
                break; 
            case MSG_TL2LL_SEND_DATA: 
                cout<<"MSG_TL2LL_SEND_DATA";
                break; 
            case MSG_TL2LL_NEW_TC: 
                cout<<"MSG_TL2LL_NEW_TC";
                break; 
            case MSG_TL2LL_NO_MORE_TC_AVAILABLE: 
                cout<<"MSG_TL2LL_NO_MORE_TC_AVAILABLE";
                break; 
        }
        cout<<" for _TL_ConnID :"<<(int)t->_TL_ConnID<<endl;                     
    }
#endif //TEST_ON_A_PC
}


//------------------------------------------------------------------------
//Static attribute is initialized here.
TL_Idle* TL_Idle::_instance = 0;   //Singleton pattern

TL_Idle::TL_Idle() 
{
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Idle has been Created"<<endl;                      
#endif // TEST_ON_A_PC
}; 

TL_Idle* TL_Idle::Instance()      //Singleton pattern
{
    if (_instance == 0) 
    {
        _instance = new TL_Idle; 
    }
    return _instance; 
}

//Clauses 7.1.2 and A.4.1.4  Host --> Module: Create Transport Connection
void TL_Idle::CreateTC(TL_Connection* t)
{
    U8* pBuff; 
    U16 msgSize; 
    Create_T_C myCreate_T_C(t->_TL_ConnID); //TPDU instance

    msgSize = myCreate_T_C.getSerializeSize() + 1; //+1 to hold TL_ConnIdSender
    try
    {
        pBuff = new U8[msgSize]; //Creates a buffer to later serialize the object
    }
    catch (bad_alloc)
    {
#if TEST_ON_A_PC
        cout<<showTime<<"TL_Idle::CreateTC. new Failed. Not enough memory."<<endl; 
#else
        DBG_Print(DBG_ERROR, "TL_Idle::CreateTC. new Failed. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
        return;
    }
    myCreate_T_C.serialize(pBuff); //Serializes the object into the buffer
    SendToLinkLayer(t, MSG_TL2LL_CREATE_TC, pBuff, msgSize); 
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Idle::CreateTC. Has sent Create_T_C("<<(int)t->_TL_ConnID<<")"<<endl; 
#endif
    delete[] pBuff;        
    ChangeState(t, TL_InCreation::Instance()); 
    t->StartTimeOutTimer(); 
    /*
    The Module will answer (answer will be handled by TL_InCreation) these primitives:
    C_T_C_Reply(transportConnectionID, no data) + T_SB(transportConnectionID, data or no data available)
    or 
    The Module may no answer: 
    After a time-out of 300mS the Host returns to Idle
    */
}


//------------------------------------------------------------------------
//Static attribute is initialized here.
TL_InCreation* TL_InCreation::_instance = 0;   //Singleton pattern

TL_InCreation::TL_InCreation() 
{
#if TEST_ON_A_PC
    cout<<showTime<<"TL_InCreation has been Created"<<endl;                     
#endif // TEST_ON_A_PC
}; 

TL_InCreation* TL_InCreation::Instance()      //Singleton pattern
{
    if (_instance == 0) 
    {
        _instance = new TL_InCreation; 
    }
    return _instance; 
}

//Clause 7.1.3
void TL_InCreation::ProcessResponse(TL_Connection* t, R_TPDU myR_TPDU)
{
    if (myR_TPDU.Is_TC_T_C_REPLY(t->_TL_ConnID))
    {
#if TEST_ON_A_PC
        cout<<showTime<<"TL_InCreation::ProcessResponse. Message TC_T_C_REPLY received for TC:"<<(int)myR_TPDU.Get_t_c_id()<<endl; 
#endif //TEST_ON_A_PC
        t->StopTimeOutTimer(); 
        //A message is given to the Session layer
        t->_theTLManager->SendToSessionLayer(MSG_TL2SL_TC_CREATED, t->_TL_ConnID); 
        ChangeState(t, TL_Active::Instance());
        t->StartPollTimer(); 
        t->PollTC(); 
    }
}

//Clause 7.1.3
void TL_InCreation::TimeOut(TL_Connection* t)
{
    ChangeState(t, TL_Idle::Instance());
    t->StopTimeOutTimer(); 
    //A message is given to the Session layer
    t->_theTLManager->SendToSessionLayer(MSG_TL2SL_CREATE_TC_FAILED, t->_TL_ConnID); 
}


//------------------------------------------------------------------------
//Static attribute is initialized here.
TL_Active* TL_Active::_instance = 0;   //Singleton pattern

TL_Active::TL_Active() 
{
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Active has been Created"<<endl;                     
#endif // TEST_ON_A_PC
}; 

TL_Active* TL_Active::Instance()      //Singleton pattern
{
    if (_instance == 0) 
    {
        _instance = new TL_Active; 
    }
    return _instance; 
}


//Clauses 7.1.2 and A.4.1.12 Host --> Module (A TC is polled with an empty T_Data_Last)
/*
    "At each poll a time out of 300mS is started, and is reset when 
    response is received. If no poll response has been received within
    that time, the transport connection is deleted by the host in the
    normal way. The host does not send any additional polls whilst 
    waiting for a poll response, even if its normal poll interval is 
    exceeded.
*/
void TL_Active::PollTC(TL_Connection* t) const
{
    U8* pBuff;         //For temporal buffer
    U16 msgSize;       
    Poll_T_C myPoll_T_C(t->_TL_ConnID); //TPDU instance for PollTC Object

    msgSize = myPoll_T_C.getSerializeSize() + 1 ; //+1 to hold TL_ConnIdSender
    try
    {
        pBuff = new U8[msgSize]; //Creates a buffer to later serialize the object
    }
    catch (bad_alloc)
    {
#if TEST_ON_A_PC
        cout<<showTime<<"TL_Active::PollTC. new. Not enough memory."<<endl; 
#else
        DBG_Print(DBG_ERROR, "TL_Active::PollTC. new. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
        return;
    }
    myPoll_T_C.serialize(pBuff); //Serializes the object into the buffer
    SendToLinkLayer(t, MSG_TL2LL_POLLTC, pBuff, msgSize); 
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Active::PollTC. Has sent Poll_T_C("<<(int)t->_TL_ConnID<<")"<<endl; 
#endif
    delete[] pBuff; 
    t->StartTimeOutTimer(); 
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Active::PollTC. Polled "<<(int)t->_TL_ConnID<<endl; 
#endif //TEST_ON_A_PC
    /*
    The Module will answer any of these primitives: 
    Request_T_C  (Request to initiate another Transport Connection)   
    Delete_T_C   (Request to terminate this Transport Connection)
    T_SB
    T_Data_More
    T_Data_Last
    */    
}



//Concatenates received packets from the Link Layer to build the message
//  which will be sent to the Session Layer
void TL_Active::BuildIncomingData(TL_Connection* t, R_TPDU myR_TPDU)
{
    U8* pBuffTmp; 
    U8* pBuffTmp2;                     
    U16 TPDU_Body_length; 

    TPDU_Body_length =  myR_TPDU.GetBodyLength(); 

    try
    {
        pBuffTmp = new U8[TPDU_Body_length]; //Creates a Buffer 
    }
    catch (bad_alloc)
    {
#if TEST_ON_A_PC
        cout<<showTime<<"TL_Active::BuildIncomingData. new Failed. Not enough memory or Bad Alloc."<<endl; 
#else
        DBG_Print(DBG_ERROR, "TL_Active::BuildIncomingData. new Failed. Not enough memory or Bad Alloc.\n"); 
#endif //TEST_ON_A_PC
        return;
    }
    myR_TPDU.GetBody(pBuffTmp); //Fills the buffer with incoming data
    
    if (t->_pBuffDataToSL == NULL) //First packet
    {
        t->_pBuffDataToSL = pBuffTmp; 
        t->_BuffSizeDataToSL = TPDU_Body_length; 
    }
    else  //Next packet. New received packet is appended.
    {
        try
        {
            pBuffTmp2 = new U8[t->_BuffSizeDataToSL + TPDU_Body_length]; //Creates a buffer of Current Buffer size + New packet size
        }
        catch (bad_alloc)
        {
#if TEST_ON_A_PC
            cout<<showTime<<"TL_Active::BuildIncomingData. new Failed. Not enough memory."<<endl; 
#else
            DBG_Print(DBG_ERROR, "TL_Active::BuildIncomingData. new Failed. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
            return;
        }

        memcpy(pBuffTmp2, t->_pBuffDataToSL, t->_BuffSizeDataToSL); 
        delete[] t->_pBuffDataToSL; 
        memcpy(pBuffTmp2 + t->_BuffSizeDataToSL, pBuffTmp, TPDU_Body_length); //New packet is appended
        t->_pBuffDataToSL = pBuffTmp2;  
        t->_BuffSizeDataToSL = t->_BuffSizeDataToSL + TPDU_Body_length; 
        delete[] pBuffTmp; 
#if TEST_ON_A_PC
        cout<<showTime<<"TL_Active::BuildIncomingData: _BuffSizeDataToSL "<<(int)t->_BuffSizeDataToSL<<endl; 
#endif
    }
}

//Clause 7.1.3
//Processes the response from the Link Layer
void TL_Active::ProcessResponse(TL_Connection* t, R_TPDU myR_TPDU)
{

#if TEST_ON_A_PC
    cout<<showTime<<"TL_Active::ProcessResponse. myR_TPDU.Header.t_c_id :"<<(int)myR_TPDU.Get_t_c_id()
                  <<" t->_TL_ConnID"<<(int)t->_TL_ConnID<<endl; 
#endif //TEST_ON_A_PC
    if (myR_TPDU.Get_t_c_id() == t->_TL_ConnID) 
    {
        t->StopTimeOutTimer(); //Clause A.4.1.12
        switch (myR_TPDU.Get_r_tpdu_tag())
        {
            case TDATA_MORE: 
#if TEST_ON_A_PC
                cout<<showTime<<"TL_Active::ProcessResponse. Message TDATA_MORE received for TC:"<<(int)myR_TPDU.Get_t_c_id()<<endl; 
#endif //TEST_ON_A_PC
                BuildIncomingData(t, myR_TPDU);
                break; 
    
            case TDATA_LAST: 
#if TEST_ON_A_PC
                cout<<showTime<<"TL_Active::ProcessResponse. Message TDATA_LAST received for TC:"<<(int)myR_TPDU.Get_t_c_id()<<endl; 
#endif //TEST_ON_A_PC
                BuildIncomingData(t, myR_TPDU);
                { 
                    MsgSL myMsgToSend; 
                    S32 retVal; 

                    //Message is finished. 
                    //Data is sent to Session Layer. Message is built to do so.
                    myMsgToSend.msgType = MSG_TL2SL_DATA; 
                    myMsgToSend.msgContent.TL_ConnIdSender = t->_TL_ConnID; 
                    memcpy(myMsgToSend.msgContent.Content, t->_pBuffDataToSL, t->_BuffSizeDataToSL);  //Fills buffer
#if TEST_ON_A_PC
                    retVal = msgsnd(t->_theTLManager->GetSLMsgQueueId(), &myMsgToSend , t->_BuffSizeDataToSL + 1, 0); //+1: MsgType
                    if (retVal == -1) 
                    {
                        perror("TL_Active::ProcessResponse has failed to send Data packet: ");
                    }
                    else
                    {
                        cout<<showTime<<"TL_Active::ProcessResponse has sent Data packet to Session Layer : "<<(int)t->_TL_ConnID<<endl;                     
                    }
#endif //TEST_ON_A_PC
                }
                t->cleanBuffDataToSL(); 
                t->StartPollTimer(); 
                break; 

            //Clause 7.1.3
            /*
                "New_T_C is the response to Request_T_C. It is sent on the same Transport Connection
                as the Request_T_C object, and carries the transport connection identifier of the new connection"
            */
            case TREQUEST_T_C: 
                //The TLManager is the responsible to create the new TC.
#if TEST_ON_A_PC
                cout<<showTime<<"TL_Active::ProcessResponse. Message TREQUEST_T_C received for TC:"<<(int)myR_TPDU.Get_t_c_id()<<endl; 
#endif //TEST_ON_A_PC
                t->_theTLManager->CreateTC(t->_TL_ConnID);
                t->StartPollTimer(); 
                break; 
    
            //Clause 7.1.3
            /*
                "If the Host receives a Delete_T_C object from the module it issues a D_T_C_Reply
                object and goes directly to the Idle state"
            */
            case TDELETE_T_C: 
#if TEST_ON_A_PC
                cout<<showTime<<"TL_Active::ProcessResponse. Message TDELETE_T_C received for TC:"<<(int)myR_TPDU.Get_t_c_id()<<endl; 
#endif //TEST_ON_A_PC
                SendDTCReply(t); 
                return;  //Since state is moved to Idle, has no sense to process the status part.
        } 
    }   


    //T_SB tag is checked 
    switch (myR_TPDU.CheckTSB(t->_TL_ConnID))
    {
        case T_SB_NO_DATA:
#if TEST_ON_A_PC
            cout<<showTime<<"TL_Active::ProcessResponse. T_SB_NO_DATA received for TC:"<<(int)t->_TL_ConnID<<endl; 
#endif //TEST_ON_A_PC
            if (t->_pBuffDataFromSL != NULL)  
            {
                //A message is being transmitted from Host to module
                SendDataToLL(t); 
            } 
            else 
            {
                //Neither module nor host have data to send. Restart poll.
                t->StartPollTimer(); 
            }
            break; 

        case T_SB_DATA: 
            //Module is asked to send data
#if TEST_ON_A_PC
            cout<<showTime<<"TL_Active::ProcessResponse. T_SB_DATA received for TC:"<<(int)t->_TL_ConnID<<endl; 
#endif //TEST_ON_A_PC
            if (t->_pBuffDataFromSL != NULL)  
            {
                //A message is being transmitted from Host to module
                SendDataToLL(t); 
            }
            t->TRCV();  
            break; 

        case INVALID_T_SB: 
            //Invalid answer. Ignore it
#if TEST_ON_A_PC
            cout<<showTime<<"TL_Active::ProcessResponse. INVALID_T_SB received for TC:"<<(int)myR_TPDU.Get_t_c_id()<<endl; 
#endif //TEST_ON_A_PC
            t->StartPollTimer(); 
            break; 
    }
}

void TL_Active::SendDTCReply(TL_Connection* t)
{
    U8* pBuff; 
    U16 msgSize; 

    D_T_C_Reply myD_T_C_Reply(t->_TL_ConnID); 

    //Memory is freed.
    t->cleanBuffTmp(); 
    t->cleanBuffDataFromSL(); 
    t->cleanBuffDataToSL();     

    msgSize = myD_T_C_Reply.getSerializeSize() + 1; //+ 1 to hold TL_ConnIdSender
    try
    {
        pBuff = new U8[msgSize]; //Creates a buffer to later serialize the object
    }
    catch (bad_alloc)
    {
#if TEST_ON_A_PC
        cout<<showTime<<"TL_Active::SendDTCReply. new Failed. Not enough memory."<<endl; 
#else
        DBG_Print(DBG_ERROR, "TL_Active::SendDTCReply. new Failed. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
        return;
    }
    myD_T_C_Reply.serialize(pBuff); //Serializes the object into the buffer
    SendToLinkLayer(t, MSG_TL2LL_D_T_C_REPLY, pBuff, msgSize); 
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Active::SendDTCReply. Sent D_T_C_Reply("<<(int)t->_TL_ConnID<<")"<<endl; 
#endif
    delete[] pBuff;        
    t->_theTLManager->SendToSessionLayer(MSG_TL2SL_TC_DELETED, t->_TL_ConnID); 
    //After sending D_T_C_Reply, transport connection moves to Idle state.
    ChangeState(t, TL_Idle::Instance());
    t->StopPollTimer();     
}


//Clause 7.1.3
/*
  If the host wishes to terminate the transport connection, it sends
  a Delete_T_C object and moves to the In Deletion state
*/
//Clause A.4.1.12
/*
  At each poll a timeout of 300mS is started, and is reset when the poll
  response is received. If no poll response has been received within that time,
  then the transport connection is deleted by the host in the normal way.
*/
void TL_Active::DeleteTC(TL_Connection* t)
{
    U8* pBuff; 
    U16 msgSize; 
    Delete_T_C::Delete_T_C myDelete_T_C(t->_TL_ConnID); //TPDU instance

    //Memory is freed.
    t->cleanBuffTmp(); 
    t->cleanBuffDataFromSL(); 
    t->cleanBuffDataToSL();     

    msgSize = myDelete_T_C.getSerializeSize() + 1; //+ 1 to hold TL_ConnIdSender
    try
    {
        pBuff = new U8[msgSize]; //Creates a buffer to later serialize the object
    }
    catch (bad_alloc)
    {
#if TEST_ON_A_PC
        cout<<showTime<<"TL_Active::DeleteTC. new Failed. Not enough memory."<<endl; 
#else
        DBG_Print(DBG_ERROR, "TL_Active::DeleteTC. new Failed. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
        return;
    }
    myDelete_T_C.serialize(pBuff); //Serializes the object into the buffer
    SendToLinkLayer(t, MSG_TL2LL_DELETE_TC, pBuff, msgSize); 
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Active::DeleteTC. Sent Delete_T_C("<<(int)t->_TL_ConnID<<")"<<endl; 
#endif
    delete[] pBuff;        
    t->_theTLManager->SendToSessionLayer(MSG_TL2SL_TC_DELETED, t->_TL_ConnID); 
    ChangeState(t, TL_InDeletion::Instance());
    t->StartTimeOutTimer();     
    /*
    The Module may answer this primitive: 
    D_T_C_Reply + T_SB(transportConnectionID, data or no data available)
    or 
    The Module may no answer: 
    After a time-out of 300mS Transport Connection will be terminated.
    */
}

//Clause 7.1.2
/*
  New_T_C is the response to Request_T_C. It is sent on the same Transport 
  Connection as the Request_T_C object, and carries the transport connection 
  identifier of the new connection. New_T_C is immediately followed by a Create_T_C
  object for the new connection, which sets up the Transport Connection proper.
*/
void TL_Active::CreateTC(TL_Connection* t, U8 newTC_Id)
{
    U8* pBuff; 
    U16 msgSize; 
    New_T_C::New_T_C myNew_T_C(t->_TL_ConnID, newTC_Id); //TPDU instance

    msgSize = myNew_T_C.getSerializeSize() + 1; //+1 to hold TL_ConnIdSender
    try
    {
        pBuff = new U8[msgSize]; //Creates a buffer to later serialize the object
    }
    catch (bad_alloc)
    {
#if TEST_ON_A_PC
        cout<<showTime<<"TL_Active::CreateTC. new Failed. Not enough memory."<<endl; 
#else
        DBG_Print(DBG_ERROR, "TL_Active::CreateTC. new Failed. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
        return;
    }
    myNew_T_C.serialize(pBuff); //Serializes the object into the buffer
    SendToLinkLayer(t, MSG_TL2LL_NEW_TC, pBuff, msgSize); 
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Active::CreateTC. Sent New_T_C("<<(int)t->_TL_ConnID<<","<<(int)newTC_Id<<")"<<endl; 
#endif

    Create_T_C::Create_T_C  myCreate_T_C(newTC_Id); //TPDU instance
    msgSize = myCreate_T_C.getSerializeSize() + 1; //+1 to hold TL_ConnIdSender
    //Create_T_C is smaller size than New_T_C. pBuff can hold it.
    myCreate_T_C.serialize(pBuff); //Serializes the object into the buffer

    SendToLinkLayer(t, MSG_TL2LL_CREATE_TC, pBuff, msgSize); 
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Active::CreateTC. Sent Create_T_C("<<(int)newTC_Id<<")"<<endl; 
#endif
    t->_theTLManager->SendToSessionLayer(MSG_TL2SL_TC_CREATED, newTC_Id); 
    delete[] pBuff;        

    TL_Connection* myTL_Connection; 
    myTL_Connection = t->_theTLManager->GetTL_ConnectionByTCId(newTC_Id);
    ChangeState(myTL_Connection, TL_InCreation::Instance()); 
    myTL_Connection->StartTimeOutTimer(); 
    /*
    The Module will answer (answer will be handled by TL_InCreation) these primitives:
    C_T_C_Reply(transportConnectionID, no data) + T_SB(transportConnectionID, data or no data available)
    or 
    The Module may no answer: 
    After a time-out of 300mS the Host returns to Idle
    */
}

//Clause A.4.1.10
/*  
  Host --> Module: Send error because no more transport connections are available.
*/
//Clause 7.1.2
/*
 "T_C_Error is sent to signal an error condition and carries 1 byte error code specifying
  the error. In this version this is only sent in response to Request_T_C to signal that 
  no more Transport Connections are available."
*/
void TL_Active::TCError(TL_Connection* t, U8 ErrorCode) const
{
    U8* pBuff; 
    U16 msgSize; 
    TC_Error myTC_Error(t->_TL_ConnID); //TPDU instance

    msgSize = myTC_Error.getSerializeSize() + 1; //+1 to hold TL_ConnIdSender
    try
    {
        pBuff = new U8[msgSize]; //Creates a buffer to later serialize the object
    }
    catch (bad_alloc)
    {
#if TEST_ON_A_PC
        cout<<showTime<<"TL_Active::TCError. new Failed. Not enough memory."<<endl; 
#else
        DBG_Print(DBG_ERROR, "TL_Active::TCError. new Failed. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
        return;
    }
    myTC_Error.serialize(pBuff); //Serializes the object into the buffer
    SendToLinkLayer(t, MSG_TL2LL_TC_ERROR, pBuff, msgSize); 
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Active::TCError. Sent TC_Error("<<(int)t->_TL_ConnID<<")"<<endl; 
#endif
    delete[] pBuff;        
}

//Clause A.4.1.12
/*
    "At each poll a time out of 300mS is started, and is reset when 
    response is received. If no poll response has been received within
    that time, the transport connection is deleted by the host in the
    normal way. The host does not send any additional polls whilst 
    waiting for a poll response, even if its normal poll interval is 
    exceeded.
*/
void TL_Active::TimeOut(TL_Connection* t)
{
    TL_Active::DeleteTC(t);  
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Active::TimeOut issued Delete_T_C because No answer to Poll TC. "<<(int)t->_TL_ConnID<<endl;                     
#else
    DBG_Print(DBG_NONE, "TL_Active::TimeOut has issued Delete_T_C because No answer to Poll was received. %d\n",t->_TL_ConnID);                     
#endif // TEST_ON_A_PC
}

//Clause 7.1.2 
/* 
    "T_RCV is sent by the host to request that data the module wishes to send
    (signalled in a previous T_SB from the module) be returned to the host"
*/
//Header of R_TPDU is not existing, but module has data to send.  
void TL_Active::TRCV(TL_Connection* t) const
{
    U8* pBuff; 
    U16 msgSize; 
    T_RCV::T_RCV myT_RCV(t->_TL_ConnID); //TPDU instance

    msgSize = myT_RCV.getSerializeSize() + 1; //+1 to hold TL_ConnIdSender
    try
    {
        pBuff = new U8[msgSize]; //Creates a buffer to later serialize the object
    }
    catch (bad_alloc)
    {
#if TEST_ON_A_PC
        cout<<showTime<<"TL_Active::TRCV. new Failed. Not enough memory."<<endl; 
#else
        DBG_Print(DBG_ERROR, "TL_Active::TRCV. new Failed. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
        return;
    }
    myT_RCV.serialize(pBuff); //Serializes the object into the buffer
    SendToLinkLayer(t, MSG_TL2LL_TC_TRCV, pBuff, msgSize); 
#if TEST_ON_A_PC
    cout<<showTime<<"TL_Active::TRCV. Has sent T_TCV("<<(int)t->_TL_ConnID<<")"<<endl; 
#endif //TEST_ON_A_PC
    delete[] pBuff;        
    t->StartTimeOutTimer(); //Just in case the module does not respond
    /*
    The Module will answer any of these primitives: 
    TData_Last
    TData_More 
    */
}


//Sends to the Link Layer a transport packet of type TDATA_MORE
void TL_Active::SendDataMore(TL_Connection* t)
{
    U8* pBuff; 
    U16 msgSize; 
    T_Data_More::T_Data_More myDataMore(t->_TL_ConnID, t->_BuffSizeTmp, t->_pBuffTmp); //TPDU instance

    msgSize = myDataMore.getSerializeSize() + 1; //+1 to hold TL_ConnIdSender
    try
    {
        pBuff = new U8[msgSize]; //Creates a buffer to later serialize the object
    }
    catch (bad_alloc)
    {
#if TEST_ON_A_PC
        cout<<showTime<<"TL_Active::SendDataMore. new Failed. Not enough memory."<<endl; 
#else
        DBG_Print(DBG_ERROR, "TL_Active::SendDataMore. new Failed. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
        return;
    }
    myDataMore.serialize(pBuff); //Serializes the object into the buffer
    SendToLinkLayer(t, MSG_TL2LL_SEND_DATA, pBuff, msgSize); 
    cout<<showTime<<"TL_Active::SendDataMore. Sent T_Data_More("<<(int)t->_TL_ConnID<<")"
                  <<" "<<msgSize<<" Bytes"
                  <<" BuffSize: "<<(int)t->_BuffSizeDataFromSL
                  <<" Index:"<<(int)t->_splitIndex<<endl;
    delete[] pBuff; 
    t->cleanBuffTmp(); 
    t->StartTimeOutTimer(); //Will be waiting packet confirmation with timeout
}

//Sends to the Link Layer a transport packet of type TDATA_LAST
void TL_Active::SendDataLast(TL_Connection* t)
{
    U8* pBuff; 
    U16 msgSize; 
    T_Data_Last::T_Data_Last myDataLast(t->_TL_ConnID, t->_BuffSizeTmp, t->_pBuffTmp); //TPDU instance

    msgSize = myDataLast.getSerializeSize() + 1; //+1 to hold TL_ConnIdSender
    try
    {
        pBuff = new U8[msgSize]; //Creates a buffer to later serialize the object
    }
    catch (bad_alloc)
    {
#if TEST_ON_A_PC
        cout<<showTime<<"TL_Active::SendDataLast. new Failed. Not enough memory."<<endl; 
#else
        DBG_Print(DBG_ERROR, "TL_Active::SendDataLast. new Failed. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
        return;
    }
    myDataLast.serialize(pBuff); //Serializes the object into the buffer
    SendToLinkLayer(t, MSG_TL2LL_SEND_DATA, pBuff, msgSize); 
    cout<<showTime<<"TL_Active::SendDataLast. Sent T_Data_Last("<<(int)t->_TL_ConnID<<")"
                  <<" "<<msgSize<<" Bytes"
                  <<" BuffSize: "<<(int)t->_BuffSizeDataFromSL
                  <<" Index:"<<(int)t->_splitIndex<<endl;

    delete[] pBuff;        
    //As data is completely send, buffers are clean and variables reset
    t->cleanBuffDataFromSL(); 
    t->cleanBuffTmp(); 
    t->StartTimeOutTimer(); //Will be waiting packet confirmation with timeout
}


//Data from session Layer is sliced (if required) in TPDU packets of MAX_BODY_LENGTH size.
//Calls to send it to the Link Layer
void TL_Active::SendDataToLL(TL_Connection* t)
{
    if ((t->_BuffSizeDataFromSL - t->_splitIndex) > MAX_BODY_LENGTH)
    {
        //Data does not fit in one packet. Has to be split in several ones.
        try
        {
            t->_pBuffTmp = new U8[MAX_BODY_LENGTH]; //Creates a buffer to later serialize the object
        }
        catch (bad_alloc)
        {
#if TEST_ON_A_PC
            cout<<showTime<<"TL_Active::SendDataToLL. new Failed. Not enough memory."<<endl; 
#else
            DBG_Print(DBG_ERROR, "TL_Active::SendDataToLL. new Failed. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
        }
        t->_BuffSizeTmp = MAX_BODY_LENGTH; 
        memcpy(t->_pBuffTmp, t->_pBuffDataFromSL + t->_splitIndex, t->_BuffSizeTmp);
        SendDataMore(t); //SendDataMore will free t->_pBuffTmp
        t->_splitIndex += MAX_BODY_LENGTH; //Next packet    
    } 
    else
    {
        //This is the last packet
        U16 msgSize; 

        msgSize =  t->_BuffSizeDataFromSL - t->_splitIndex; 
        try
        {
            t->_pBuffTmp = new U8[msgSize]; //Creates a buffer to later serialize the object
        }
        catch (bad_alloc)
        {
#if TEST_ON_A_PC
            cout<<showTime<<"TL_Active::SendDataToLL. new Failed. Not enough memory."<<endl; 
#else
            DBG_Print(DBG_ERROR, "TL_Active::SendDataToLL. new Failed. Not enough memory.\n"); 
#endif //TEST_ON_A_PC
        }
        t->_BuffSizeTmp = msgSize; 
        memcpy(t->_pBuffTmp, t->_pBuffDataFromSL + t->_splitIndex, t->_BuffSizeTmp);
        SendDataLast(t); //SendDataLast will free t->_pBuffTmp
    }   
}


//------------------------------------------------------------------------
//Static attribute is initialized here.
TL_InDeletion* TL_InDeletion::_instance = 0;   //Singleton pattern

TL_InDeletion::TL_InDeletion() 
{
#if TEST_ON_A_PC
    cout<<showTime<<"TL_InDeletion has been Created"<<endl;                     
#endif // TEST_ON_A_PC
}; 

TL_InDeletion* TL_InDeletion::Instance()      //Singleton pattern
{
    if (_instance == 0) 
    {
        _instance = new TL_InDeletion; 
    }
    return _instance; 
}

//Clause 7.1.3
/* 
  It then returns to the Idle state upon receipt of a D_T_C_Reply object, or 
  after a Time-Out if none is received
*/
void TL_InDeletion::ProcessResponse(TL_Connection* t, R_TPDU myR_TPDU)
{
    if (myR_TPDU.Is_TD_T_C_REPLY(t->_TL_ConnID))
    {
        t->StopTimeOutTimer(); 
        ChangeState(t, TL_Idle::Instance());
    }
}

//Clause 7.1.3
void TL_InDeletion::TimeOut(TL_Connection* t)
{
    ChangeState(t, TL_Idle::Instance());
}


/*EOF*/
