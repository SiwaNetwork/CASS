 /*
***************************************************************************
 This file is part of Open Common Interface

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
* PROGRAMMER: Angel Manchado
* DESCRIPTION  : Timers management for Common Interface Transport Layer. 
***************************************************************************
*/

#include "../../tlproject/src/CITLCfg.h"
#include "../../tlproject/src/CITLMsg.h"

//------------------------------------------------------------------------

#include <stdio.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <signal.h>
#include <unistd.h>
#include <sys/time.h>

//------------------------------------------------------------------------

#define SHOW_TRACE 0   //1 to show trace

#define TIME_GRAIN_MS   10      // System tick should be 250Hz or 1000Hz
#define TIME_GRAIN_US   (TIME_GRAIN_MS*1000)
#define TIME_POLL       (POLLING_TIME/TIME_GRAIN_MS)
#define TIME_TIMEOUT    (TIMEOUT_FROM_POLLING_START/TIME_GRAIN_MS)

//------------------------------------------------------------------------

// Internal data types
struct timer_struct {
    int current_timeout;
    msgTL_enum timer_type;
};

// Internal data
static struct timer_struct timer[TRANSPORT_CONNECTIONS+1];
MsgTim tim_msg;
int tlmsgqid, timmsgqid;

#if TEST_ON_A_PC
struct sigaction sa_timer;
struct itimerval timer_value;
sigset_t timer_sigset;
sig_atomic_t timer_alarm;
#endif // TEST_ON_A_PC 

void timer_handler(int signum)
{
    timer_alarm = 1;
}

int timer_init(void)
{
    // init timers array
    memset(&timer, 0, sizeof(timer));
#if TEST_ON_A_PC
    //set signal mask for all signals except timer alarm (and Ctl-C)
    sigfillset(&timer_sigset);
    sigdelset(&timer_sigset, SIGALRM);
    sigdelset(&timer_sigset, SIGINT);
    sigprocmask(SIG_SETMASK, &timer_sigset, NULL);
    //init system timer handler
    memset(&sa_timer, 0, sizeof(sa_timer));
    sa_timer.sa_handler = &timer_handler;
    if (sigaction(SIGALRM, &sa_timer, NULL) != 0){
        perror("timer_init: can not set signal handler");
        return -1;
    }
    //start system timer
    timer_value.it_value.tv_sec = 0;
    timer_value.it_value.tv_usec = TIME_GRAIN_US;
    timer_value.it_interval.tv_sec = 0;
    timer_value.it_interval.tv_usec = TIME_GRAIN_US;
    if (setitimer(ITIMER_REAL, &timer_value, NULL) != 0){
        perror("timer_init: can not set timer");
        return -1;
    }
#endif // TEST_ON_A_PC 
    return 0;
}

int msg_queues_init(int tlid, int timid)
{
//#if TEST_ON_A_PC
//  tlmsgqid = msgget(tlid, IPC_EXCL);
//  timmsgqid = msgget(timid, IPC_EXCL);
//#if TEST_ON_A_PC
    tlmsgqid = tlid;
    timmsgqid = timid;
    //printf ("Queue for Transport Layer: %d\n",tlmsgqid);  
    //printf ("Queue for Timer: %d\n",timmsgqid);  
    if (tlmsgqid>0 && timmsgqid>0)
        return 0;
    printf("Error: unable to get message queues\n");
    return -1;
}

void timer_set(MsgTim *timer_msg)
{
    int time;
    msgTL_enum timer_type;
    U8 connIdSender;
    
    switch (timer_msg->msgType){
    case MSG_TL2TIM_TIMEOUT_CREATION:
        time = TIME_TIMEOUT;
        timer_type = MSG_TIM2TL_TIMEOUT;
    break;
    case MSG_TL2TIM_POLLTC_CREATION:
        time = TIME_POLL;
        timer_type = MSG_TIM2TL_POLLTC;
    break;
    case MSG_TL2TIM_TIMEOUT_DELETION:
    case MSG_TL2TIM_POLLTC_DELETION:
        time = 0;
        timer_type = (msgTL_enum)0;
    break;
    default:
        return;         // wrong message! nothing to do
    break;
    }
    connIdSender = timer_msg->msgContent.TL_ConnIdSender;
    timer[connIdSender].current_timeout = time;
    timer[connIdSender].timer_type = timer_type;
}

int main(int argc, char* argv[])
{
    MsgTL tl_msg;

    if (argc != 3){
        printf(" Need message queues identifiers (tl & tim) on input\n");
        return -1;
    }

    if (msg_queues_init(atoi(argv[1]), atoi(argv[2])) != 0)
        return -1;
    if (timer_init() != 0)
        return -1;
    while (TRUE){   // this process never ends; kill from the environment
        int i;
        timer_alarm = 0;
#if TEST_ON_A_PC
        pause();
        //SIGALRM received at this point.
#endif // TEST_ON_A_PC 
        //Set TL connection timers & send messages if expired
        for (i=1; i<=TRANSPORT_CONNECTIONS; i++) {
            if (timer[i].current_timeout == 0)
                continue;
            timer[i].current_timeout -= TIME_GRAIN_MS;
            if (timer[i].current_timeout > 0)
                continue;
//            if (timer[i].timer_type == POLLTC)   Poll Timer reload has no sense (see Rules for folling function
//                timer[i].current_timeout = TIME_POLL;
            tl_msg.msgType = timer[i].timer_type;
            tl_msg.msgContent.TL_ConnIdAddresee = (U8)i;
            switch (timer[i].timer_type)
            {
                case MSG_TIM2TL_TIMEOUT: 
#if SHOW_TRACE
                    printf ("-------Timer type TIMEOUT expired. Addressee: %d.\n", i);      
#endif
                    break; 
                case MSG_TIM2TL_POLLTC: 
#if SHOW_TRACE
                    printf ("-------Timer type POLLTC expired. Addressee: %d.\n", i);      
#endif 
                    break; 
            }            
#if TEST_ON_A_PC
            if (msgsnd(tlmsgqid, &tl_msg, 1, 0) !=0 )
                perror ("Timer could not send messge to Transport Layer"); 
           
            
#endif // TEST_ON_A_PC 
        }
        //Get new connection timers if required
#if TEST_ON_A_PC
        while (msgrcv(timmsgqid, &tim_msg, sizeof(tim_msg.msgContent), 0, IPC_NOWAIT) > 0)
#endif // TEST_ON_A_PC 
        {
#if SHOW_TRACE
            switch(tim_msg.msgType)
            {
                case TIMEOUT_CREATION: 
                    printf ("Timer: Message TIMEOUT_CREATION Received from TC: %d\n", tim_msg.msgContent.TL_ConnIdSender); 
                    break; 
                case TIMEOUT_DELETION: 
                    printf ("Timer: Message TIMEOUT_DELETION Received from TC: %d\n", tim_msg.msgContent.TL_ConnIdSender); 
                    break; 
                case POLLTC_CREATION: 
                    printf ("Timer: Message POLLTC_CREATION Received from TC: %d\n", tim_msg.msgContent.TL_ConnIdSender); 
                    break; 
                case POLLTC_DELETION: 
                    printf ("Timer: Message POLLTC_DELETION Received from TC: %d\n", tim_msg.msgContent.TL_ConnIdSender); 
                    break; 
            }
#endif  //SHOW_TRACE
            timer_set(&tim_msg);
        }        
    }
}

/*EOF*/
