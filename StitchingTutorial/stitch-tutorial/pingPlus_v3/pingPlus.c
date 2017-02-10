/*
 *----------------------------------------------------------------------
 * Copyright (c) 2011-2017 Raytheon BBN Technologies
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and/or hardware specification (the "Work") to
 * deal in the Work without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Work, and to permit persons to whom the Work
 * is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Work.
 *
 * THE WORK IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE WORK OR THE USE OR OTHER DEALINGS
 * IN THE WORK.
 *----------------------------------------------------------------------
 *
 * pingPlus.c
 * Author: mberman
 *
 *  Layer two ping-like client.
 *
 *  Usage: pingPlus remote-host interface eth_type
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <net/if.h>
#include <netinet/ether.h>
#include <linux/if_packet.h>
#include <time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/time.h>


#include "packetFunctions.h"

const int MAX_WAIT_TIME = 1000; // Max time we will wait for a reply before giving up

void showUsage(char *prog)
{
  fprintf(stderr, "Usage: %s remote-host interface eth_type [num_pkts]\n", prog);
  fprintf(stderr, "\tSend a ping-like packet to remote host.\n");
  fprintf(stderr, "\tremote-host is MAC address of host in 00:11:22:33:44:55 form.\n");
  fprintf(stderr, "\tinterface is name of local ethernet interface on which to send.\n");
  fprintf(stderr, "\teth_type is eth_type to use to send the ping.\n");
  fprintf(stderr, "\tnum_pkts option argument that specifies how many packets to send, default is 1.\n");
}

int main(int argc, char **argv)
{
  int localInterfaceIndex;
  struct ether_addr *dstAddr;
  int sock;
  int result,i;
  int num1, num2, sum;
  char buf_snd[ETH_DATA_LEN];
  char buf_rcv[ETH_DATA_LEN];
  struct sockaddr_ll sll, src;
  int src_len;
  int my_eth_proto;
  int num_pkts = 1;
  int rcvdAnswer = 0;

  struct timeval sendTime;  // Time when packet was sent
  struct timeval currTime;  // Current time
  double sendTimeMsecs;     // Time when packet was sent (in msecs)
  double currTimeMsecs;     // Current time in msecs
  double currDelay=0;         // Difference between current time and sendTime


  // Parse arguments. Exit on error.
        if ((argc == 2) && (strcmp(argv[1],"-h") == 0)) {
                showUsage(argv[0]);
                exit(1);
        }
  if (argc < 4) {
    showUsage(argv[0]);
    exit(1);
  } else {
    dstAddr = ether_aton(argv[1]);
    if (dstAddr == NULL) {
      showUsage(argv[0]);
      fprintf(stderr, "Error: failed to parse MAC address %s.\n", argv[1]);
      exit(1);
    }

    localInterfaceIndex = if_nametoindex(argv[2]);
    if (localInterfaceIndex == 0) {
      showUsage(argv[0]);
      fprintf(stderr, "Error: no network interface %s.\n", argv[2]);
      exit(1);
    }
    my_eth_proto = atoi(argv[3]);
    if (my_eth_proto == 0) {
      showUsage(argv[0]);
      fprintf(stderr, "Error: failed to parse ETH_TYPE%s.\n", argv[3]);
      exit(1);
    }
  }
  if (argc == 5) {
    num_pkts = atoi(argv[4]);
    if (num_pkts == 0) {
      showUsage(argv[0]);
      fprintf(stderr, "Error: num_pkts should be >0 (%s).\n", argv[3]);
      exit(1);
    }
  }
    

  // Open a layer two socket.
  sock = socket(AF_PACKET, SOCK_DGRAM, htons(ETH_P_ALL));
  if (sock == -1) {
    perror("Error creating socket");
    exit(1);
  }

  // Bind to specified interface.
  bzero(&sll, sizeof(sll));
  sll.sll_family = AF_PACKET;
  sll.sll_ifindex = localInterfaceIndex;
  result = bind(sock, (struct sockaddr *)&sll, sizeof(sll));
  if (result == -1) {
    perror("Error binding socket to interface: ");
    exit(-1);
  }


  // Send a packet with a random addition problem.
  srand((int) time(NULL));
  for (i=0; i<num_pkts ; i++) {
    rcvdAnswer = 0;
    currDelay = 0.0;
    num1 = rand() % 10000;
    num2 = rand() % 10000;
    (void) memset(buf_snd, 0, sizeof(buf_snd));
    snprintf(buf_snd, sizeof(buf_snd), "RQ:%d+%d", num1, num2);

    gettimeofday(&sendTime, NULL);
    sendTimeMsecs = (sendTime.tv_sec) * 1000 + ((double)sendTime.tv_usec) / 1000;
    result = sendPacket(sock, dstAddr, localInterfaceIndex,
            my_eth_proto, buf_snd, strlen(buf_snd)+1);
    if (result != strlen(buf_snd)+1)
      exit(1);

    printf("RQ:\'%d+%d\' to %s.\n", num1, num2, ether_ntoa(dstAddr));

    // Wait for a response sent with correct protocol.
    while (!rcvdAnswer && currDelay < MAX_WAIT_TIME) {
      memset(buf_rcv, 0, sizeof(buf_rcv));
      result = receivePacket(sock, my_eth_proto, buf_rcv, &src);
      if (buf_rcv[1] == 'Q') {
        continue;
      }
      else {
        rcvdAnswer = 1;
      }

      gettimeofday(&currTime, NULL);
      currTimeMsecs = (currTime.tv_sec) * 1000 + ((double)currTime.tv_usec) / 1000.0;

      currDelay = currTimeMsecs - sendTimeMsecs;
    }

    // Print results.
    printf("%s from %s.\n",
      buf_rcv, ether_ntoa((struct ether_addr *)(&src.sll_addr)));
    printf("RTT = %f\n\n", currDelay);
  }

  exit(0);
}
