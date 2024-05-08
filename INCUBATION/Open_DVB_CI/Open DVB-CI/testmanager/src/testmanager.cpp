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

* FILENAME     : testmanager.cpp
* CREATED      : July 2005
* PROGRAMMER: Jordi Escoda
* DESCRIPTION  : Test workbench for the transport layer
***************************************************************************
*/

#include <stdio.h>
#include <iostream>  //Used by memcpy
#include <stdlib.h>

#include <sys/types.h>  //For message queue
#include <sys/ipc.h>    //For message queue (interprocess communication)
#include <sys/msg.h>    //For message queue
#include <unistd.h>
#include <sys/wait.h>  //For message queue

#include <signal.h>

#include "../../tlproject/src/sps_type.h"

#define STRINGSIZE 20

using namespace std;

void abort_handler(int signum)
{
    printf("Control-C cathed!\n"); 
    sleep(2); 
}


int main(int argc, char *argv[])
{
    int SLMsgQueueId; 
    int TLMsgQueueId; 
    int LLMsgQueueId; 
    int TimMsgQueueId; 

    msqid_ds myMsqid_ds; //Pointer to data structure for controlling the queue

    char strSLMsgQueueId[STRINGSIZE]; 
    char strTLMsgQueueId[STRINGSIZE]; 
    char strLLMsgQueueId[STRINGSIZE]; 
    char strTimMsgQueueId[STRINGSIZE]; 

    int execlpRetVal; 
    int* myProcessStatus; 

    //To catch Control C and kill processes
    struct sigaction sa_abort;
    sigset_t abort_sigset;

    //To catch Control C and kill queues
    sigfillset(&abort_sigset); //Fill with signals
    sigdelset(&abort_sigset, SIGINT); //Overrides Control C
    sigprocmask(SIG_SETMASK, &abort_sigset, NULL);
    //init system timer handler
    memset(&sa_abort, 0, sizeof(sa_abort));
    sa_abort.sa_handler = &abort_handler;
    if (sigaction(SIGINT, &sa_abort, NULL) != 0){
        perror("abort: can not set signal handler");
        return -1;
    }


    SLMsgQueueId = msgget(IPC_PRIVATE, IPC_CREAT|0666); //A new message queue is created. read/write permission
    if (SLMsgQueueId == -1)   
    {
        printf ("Parent: Could not create the message queue for the Session Layer.\n");     
    }
    else
    {
        printf ("Parent: Handler for SLMsgQueueId: %d\n", SLMsgQueueId);     
    }

    TLMsgQueueId = msgget(IPC_PRIVATE, IPC_CREAT|0666); //A new message queue is created. read/write permission
    if (TLMsgQueueId == -1)   
    {
        printf ("Parent: Could not create the message queue for the Transport Layer.\n");     
    }
    else
    {
        printf ("Parent: Handler for TLMsgQueueId: %d\n", TLMsgQueueId);     
    }

    LLMsgQueueId = msgget(IPC_PRIVATE, IPC_CREAT|0666); //A new message queue is created. read/write permission
    if (LLMsgQueueId == -1)   
    {
        printf ("Parent: Could not create the message queue for the Link Layer.\n");     
    }

    TimMsgQueueId = msgget(IPC_PRIVATE, IPC_CREAT|0666); //A new message queue is created. read/write permission
    if (TimMsgQueueId == -1)   
    {
        printf ("Parent: Could not create the message queue for the Timer.\n");     
    }

    snprintf(strSLMsgQueueId, STRINGSIZE, "%d", SLMsgQueueId); 
    snprintf(strTLMsgQueueId, STRINGSIZE, "%d", TLMsgQueueId); 
    snprintf(strLLMsgQueueId, STRINGSIZE, "%d", LLMsgQueueId); 
    snprintf(strTimMsgQueueId, STRINGSIZE, "%d", TimMsgQueueId); 

    if ((SLMsgQueueId != -1 ) && (TLMsgQueueId != -1 ) && (LLMsgQueueId != -1 ) && (TimMsgQueueId != -1 ))
    {
        if (fork() == 0) 
        {
            //Process that creates the Session Layer
            execlpRetVal = execlp("seproject", "seproject", strSLMsgQueueId, strTLMsgQueueId, strLLMsgQueueId, strTimMsgQueueId, NULL); 
            //Program only continues here if execlp fails            
            if (execlpRetVal = -1) 
            {
                printf ("Parent: Execlp failed for seproject.\n");     
            }
        } 

        if (fork() == 0) 
        {   
            //Process that creates the Transport Layer
            execlpRetVal = execlp("tlproject", "tlproject", strSLMsgQueueId, strTLMsgQueueId, strLLMsgQueueId, strTimMsgQueueId, NULL); 
            //Program only continues here if execlp fails
            if (execlpRetVal = -1) 
            {
                printf ("Parent: Execlp failed for tlproject.\n");     
            }
        }

        if (fork() == 0) 
        {
            //Process that creates the Link Layer
            execlpRetVal = execlp("lltest", "lltest", strSLMsgQueueId, strTLMsgQueueId, strLLMsgQueueId, strTimMsgQueueId, NULL); 
            //Program only continues here if execlp fails
            if (execlpRetVal = -1) 
            {
                printf ("Parent: Execlp failed for lltest.\n");     
            }
        } 

        if (fork() == 0) 
        {   
            //Process that creates the Timer
            execlpRetVal = execlp("timer", "timer", strTLMsgQueueId, strTimMsgQueueId, NULL); 
            //Program only continues here if execlp fails
            if (execlpRetVal = -1) 
            {
                printf ("Parent: Execlp failed for tlproject.\n");     
            }
        }
    }

    waitpid(-1, myProcessStatus, 0); //Waits for the first process to finish 
    waitpid(-1, myProcessStatus, 0); //Waits for the second process to finish 
    waitpid(-1, myProcessStatus, 0); //Waits for the third process to finish 
    waitpid(-1, myProcessStatus, 0); //Waits for the fourth process to finish 

    printf ("Parent: Queues are going to be destroyed.\n");     

    if (msgctl(SLMsgQueueId, IPC_RMID, &myMsqid_ds) == -1) //The message queue is destroyed
    {
        printf ("Parent: Could not destroy the message queue for the Session Layer.\n");     
    }

    if (msgctl(TLMsgQueueId, IPC_RMID, &myMsqid_ds) == -1) //The message queue is destroyed
    {
        printf ("Parent: Could not destroy the message queue for the Transport Layer.\n");     
    }

    if (msgctl(LLMsgQueueId, IPC_RMID, &myMsqid_ds) == -1) //The message queue is destroyed
    {
        printf ("Parent: Could not destroy the message queue for the Link Layer.\n");     
    }

    if (msgctl(TimMsgQueueId, IPC_RMID, &myMsqid_ds) == -1) //The message queue is destroyed
    {
        printf ("Parent: Could not destroy the message queue for the Timer.\n");     
    }

  return EXIT_SUCCESS;
}

/* EOF */