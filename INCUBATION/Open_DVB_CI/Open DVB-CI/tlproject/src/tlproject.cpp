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
* DESCRIPTION  : Test workbench for the transport layer
***************************************************************************
*/

#include "CITLProt.hpp"

using namespace std;

int main(int argc, char *argv[])
{
    TL_Manager* myTLManager; 

    if (argc > 3 ) 
    {
        //cout<<"SEMsgQueueId:"<<atoi(argv[1])<<"TLMsgQueueId:"<<atoi(argv[2])<<"LIMsgQueueId:"<<atoi(argv[3]) <<"TimMsgQueueId:"<<atoi(argv[4])<<endl; 

        myTLManager = TL_Manager::Instance(); 
        myTLManager->SetSEMsgQueueId(atoi(argv[1]));  
        myTLManager->SetTLMsgQueueId(atoi(argv[2])); 
        myTLManager->SetLLMsgQueueId(atoi(argv[3]));  
        myTLManager->SetTimMsgQueueId(atoi(argv[4])); 
        /*    
        printf ("TLQueueId: %d\n", myTLManager->GetTLMsgQueueId()); 
        printf ("SessionQueueId: %d\n", myTLManager->GetToSessionQueueId()); 
        printf ("LinkQueueId: %d\n", myTLManager->GetToLinkQueueId()); 
        printf ("TimerQueueId: %d\n", myTLManager->GetToTimerQueueId()); 
        */
        myTLManager->Start(); 
        myTLManager->Stop();
        cout<<"myTLManager stopped."<<endl; 
        return EXIT_SUCCESS;
    }
    else
    {
        cout<<"Missing parameter(s): Queue Handler."<<endl; 
        return -1;  
    }
}

/* EOF */
