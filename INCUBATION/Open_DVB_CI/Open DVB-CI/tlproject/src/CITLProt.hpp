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

* FILENAME     : CITLProt.hpp
* CREATED      : 22/7/2005             
* PROGRAMMER: Jordi Escoda
* DESCRIPTION  : Header file for Common Interface Transport Layer. Protocol. 
*                Implementation for EN 50221:1997.
***************************************************************************
*/

#ifndef __CITLPROT_H
#define __CITLPROT_H

#include "CITLCfg.h"
#include "CITLMsg.h"
#include "CITLObj.h"


class TL_State;      //Just class declaration. Class definition will come later.
class TL_Connection; //Just class declaration. Class definition will come later.

//States enum
typedef enum
{
    TL_IDLE,
    TL_INCREATION,
    TL_ACTIVE,
    TL_INDELETION
} TL_State_enum; 

//TL_Manager is the responsible to Initiate / Manage / Terminate the Transport Layer 
//To instantiate this object, use this way: TL_Manager::Instance()
//Patterns used: Singleton. Because there must exist only one TL_Manager.
//               Facade. Because is the entry point to a complex set of objects.
class TL_Manager
{
    public: 
        static TL_Manager* Instance(); 

        void Start();        //Must be called first to create the communication objects
        void Stop();        //Must be called first to create the communication objects        

        void SetTLMsgQueueId(S32 myId)  {_TLmsgQueueId = myId;} 
        S32 GetTLMsgQueueId() const     {return _TLmsgQueueId;}
        void SetSEMsgQueueId(S32 myId)  {_SLmsgQueueId = myId;}
        S32 GetSLMsgQueueId() const     {return _SLmsgQueueId;}
        void SetTimMsgQueueId(S32 myId) {_TimmsgQueueId = myId;}
        S32 GetTimMsgQueueId() const    {return _TimmsgQueueId;}
        void SetLLMsgQueueId(S32 myId)  {_LLmsgQueueId = myId;}
        S32 GetLLMsgQueueId() const     {return _LLmsgQueueId;}
        void SendToSessionLayer(msgSL_enum, U8) const;  //Sends message to session
        void SendToLinkLayer(msgLL_enum, U8) const;     //Sends message to link layer

    protected: 
        TL_Manager(); //Singleton pattern. Protected constructor.
        
    private:
        static TL_Manager* _instance; 
        S32 _SLmsgQueueId;    //Stores Handler for msg queue Session Layer
        S32 _TLmsgQueueId;    //Stores Handler for msg queue Transport Layer
        S32 _LLmsgQueueId;    //Stores Handler for msg queue Link Layer
        S32 _TimmsgQueueId;   //Stores Handler for msg queue Timer

        BOOL _TLConnCreated;  //Stores if TLConnection objects have been created
        BOOL _Run;            //While is true, the object is running, waiting for messages
        TL_Connection* myTL_Connection[TRANSPORT_CONNECTIONS + 1];  //Clause 7.1.2: Connection 0 will not be used. It is reserved.

        BOOL CreateTC();   //Used by the host to Create TC
        void CreateTC(U8); //Used when module requests TC
        void DeleteTC(U8); //Used by the host to Delete TC
        TL_Connection* GetTL_ConnectionByTCId(U8);

        friend class TL_Active;   //To get access to CreateTC
}; 


//Implementation Uses State pattern
class TL_Connection
{
    public: 
        TL_Connection(U8);  //Constructor

        TL_State_enum GetStateId() const; //Returns the State Id

    private: 
        TL_Manager* _theTLManager; //There will be only one TLManager  
        U8 _TL_ConnID;          //Stores connection ID
        U8* _pBuffDataToSL;     //Pointer to the message buffer which has to sent to the Session Layer
        U32 _BuffSizeDataToSL;  //Size of data contained in the buffer _pBuffDataToSL.
        U8* _pBuffDataFromSL;   //Pointer to the message buffer which has been received from Session Layer and has to sent to the Link Layer
        U32 _BuffSizeDataFromSL;//Size of data contained in the buffer _pBuffDataFromSL.
        U8* _pBuffTmp;          //Temporal Buffer used to split data to send to Link Layer
        U16 _BuffSizeTmp;       //Size of data contained in the buffer _pBuffTmp.
        U32 _splitIndex;        //Index used to split data to send to link layer

        void CreateTC();
        void CreateTC(U8);
        void TimeOut();
        void PollTC(); 
        void DeleteTC();
        void TCError(U8);
        void TRCV(); 

        void ProcessResponse(R_TPDU); 
        void cleanBuffDataToSL();   //Empties the buffer of Data sent to Session Layer
        void cleanBuffDataFromSL(); //Empties the buffer of Data received from Session Layer
        void cleanBuffTmp();        //Empties the temporal buffer sed to split data to send to link layer
        void LoadDataToSend(U8*, U32); //Receives message from the session Layer and loads data wich will be sent to the link layer

        void ChangeState(TL_State*);
    
    protected: 
        void StartPollTimer() const; 
        void StopPollTimer() const; 
        void StartTimeOutTimer() const; 
        void StopTimeOutTimer() const; 
        void SendToTimerTask(msgTim_enum) const;  //Sends message to Timer task

    private: 
        friend class TL_State; 
        friend class TL_Idle;       //This class will take care about the state TL_Idle
        friend class TL_InCreation; //This class will take care about the state TL_InCreation
        friend class TL_Active;     //This class will take care about the state TL_Active
        friend class TL_InDeletion; //This class will take care about the state TL_InDeletion
        friend class TL_Manager; 

    private: 
        TL_State* _state;     //Stores state. State is handled only by TL_State subclasses
        static void * pObject;      
}; 


//Class to manage states
//TL_State will never be instantiated. Only Subclasses will be. Inheritance is used.
class TL_State
{
    public: 
        virtual void CreateTC(TL_Connection*)                 {/*Implemented in a subclass*/}
        virtual void CreateTC(TL_Connection*, U8)             {/*Implemented in a subclass*/}
        virtual void TimeOut(TL_Connection*)                  {/*Implemented in a subclass*/}
        virtual void PollTC(TL_Connection*) const             {/*Implemented in a subclass*/} 
        virtual void DeleteTC(TL_Connection*)                 {/*Implemented in a subclass*/} 
        virtual void TCError(TL_Connection*, U8) const        {/*Implemented in a subclass*/} 
        virtual void TRCV(TL_Connection*) const               {/*Implemented in a subclass*/} 
        virtual void ProcessResponse(TL_Connection*, R_TPDU)  {/*Implemented in a subclass*/} 
        virtual void SendDataToLL(TL_Connection*)             {/*Implemented in a subclass*/} 
        virtual TL_State_enum GetStateId() const              {/*Implemented in a subclass*/} 

    protected: 
        void ChangeState(TL_Connection*, TL_State*);

        void SendToLinkLayer(TL_Connection*, msgLL_enum, U8*, U16) const;  //Sends message to Link layer 
};


//Class to manage Idle State
class TL_Idle:public TL_State
{
    public: 
        static TL_Idle* Instance();  //Singleton pattern. 
                                      //There will be only one instance of TL_Idle.
                                      //This means that all TL_Connection will share the same TL_State Object.
                                      //This can be done because state variable is stored in TL_Connection Object.

        virtual TL_State_enum GetStateId() const {return TL_IDLE; } //Returns the State Id

    private: 
        virtual void CreateTC(TL_Connection*);

    protected: 
        TL_Idle(); //Constructor Protected: Singleton pattern. 
        
    private: 
        static TL_Idle* _instance; 

        friend class TL_InCreation; //This gives access to TL_InCreation::Instance()
        friend class TL_Active;     //This gives access to TL_Active::Instance()
        friend class TL_InDeletion; //This gives access to TL_InDeletion::Instance()
};

//Class to manage In Creation State
class TL_InCreation:public TL_State
{
    public: 
        static TL_InCreation* Instance();  //Singleton pattern. 
                                      //There will be only one instance of TL_InCreation.
                                      //This means that all TL_Connection will share the same TL_State Object.
                                      //This can be done because state variable is stored in TL_Connection Object.

        virtual TL_State_enum GetStateId() const  {return TL_INCREATION;} //Returns the State Id

    private: 
        virtual void ProcessResponse(TL_Connection*, R_TPDU); 
        virtual void TimeOut(TL_Connection*);

    protected: 
        TL_InCreation(); //Constructor Protected: Singleton pattern. 
        
    private: 
        static TL_InCreation* _instance; 
        friend class TL_Idle;       //This gives access to TL_Idle::Instance()
        friend class TL_Active;     //This gives access to TL_Active::Instance()
        friend class TL_InDeletion; //This gives access to TL_InDeletion::Instance()

};

//Class to manage Active State
class TL_Active:public TL_State
{
    public: 
        static TL_Active* Instance();  //Singleton pattern. 
                                      //There will be only one instance of TL_Active.
                                      //This means that all TL_Connection will share the same TL_State Object.
                                      //This can be done because state variable is stored in TL_Connection Object.

        virtual TL_State_enum GetStateId() const    {return TL_ACTIVE; } //Returns the State Id


    private:
        virtual void PollTC(TL_Connection* t) const; 
        virtual void DeleteTC(TL_Connection*);
        virtual void CreateTC(TL_Connection* t, U8);
        virtual void TCError(TL_Connection*, U8) const;
        virtual void TRCV(TL_Connection*) const; 
        virtual void TimeOut(TL_Connection* t);  
        virtual void SendDataToLL(TL_Connection*); 
        void SendDataMore(TL_Connection*); 
        void SendDataLast(TL_Connection*); 
        void SendDTCReply(TL_Connection*); 

        virtual void ProcessResponse(TL_Connection*, R_TPDU); //Processes the response from the Link Layer
        void BuildIncomingData(TL_Connection*, R_TPDU); //Concatenates received packets to build the message

    protected: 
        TL_Active(); //Constructor Protected: Singleton pattern. 
        
    private: 
        static TL_Active* _instance; 
        friend class TL_Idle;       //This gives access to TL_Idle::Instance()
        friend class TL_InCreation; //This gives access to TL_InCreation::Instance()
        friend class TL_InDeletion; //This gives access to TL_InDeletion::Instance()
}; 

//Class to manage In Deletion State
class TL_InDeletion:public TL_State
{
    public: 
        static TL_InDeletion* Instance();  //Singleton pattern. 
                                      //There will be only one instance of TL_InDeletion.
                                      //This means that all TL_Connection will share the same TL_State Object.
                                      //This can be done because state variable is stored in TL_Connection Object.

        virtual TL_State_enum GetStateId() const    {return TL_INDELETION;} //Returns the State Id

    private:
        virtual void ProcessResponse(TL_Connection*, R_TPDU); 
        virtual void TimeOut(TL_Connection*);

    protected: 
        TL_InDeletion();  //Constructor Protected: Singleton pattern. 
        
    private: 
        static TL_InDeletion* _instance; 
        friend class TL_Idle;       //This gives access to TL_Idle::Instance()
        friend class TL_InCreation; //This gives access to TL_InCreation::Instance()
        friend class TL_Active;     //This gives access to TL_Active::Instance()
};

#endif // __CITLPROT_H

/*EOF*/
