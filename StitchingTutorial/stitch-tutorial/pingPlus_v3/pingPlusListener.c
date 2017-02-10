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
 * pingPlusListener.c
 * Author: mberman
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <net/if.h>
#include <net/ethernet.h>
#include <netinet/ether.h>
#include <linux/if_packet.h>
#include <time.h>
#include <sys/types.h>
#include <sys/socket.h>

#include "packetFunctions.h"

void showUsage(char *prog)
{
        fprintf(stderr, "Usage: %s eth-type \n", prog);
        fprintf(stderr, "\tSend a ping-like packet to remote host.\n");
        fprintf(stderr, "\teth-type : the number of eth-type to use for listening.\n");
}

int main(int argc, char **argv)
{
  int sock;
  int result;
  int num1, num2, sum;
  char *plusPos;
  char buf_rcv[ETH_DATA_LEN];
  char buf_snd[ETH_DATA_LEN];
  struct sockaddr_ll src;
  int my_eth_proto;

  // Parse arguments. Exit on error.
  if (argc != 2) {
    showUsage(argv[0]);
    exit(1);
  } else {
    if (strcmp(argv[1],"-h") == 0) {
                        showUsage(argv[0]);
                        exit(1);
                }
    my_eth_proto = atoi(argv[1]);
    if (my_eth_proto == 0) {
      showUsage(argv[0]);
      fprintf(stderr, "Error: failed to parse ETH_TYPE%s.\n", argv[1]);
      exit(1);
    }

  }


  // Open a layer two socket.
  sock = socket(AF_PACKET, SOCK_DGRAM, htons(ETH_P_ALL));
  if (sock == -1) {
    perror("Error creating socket");
    exit(1);
  }

  // Loop forever.
  while (1) {

    // Wait for a response sent with correct protocol.
    memset(buf_rcv, 0, sizeof(buf_rcv));
    result = receivePacket(sock, my_eth_proto, buf_rcv, &src);

    // Parse ping packet and send response.
    // Make sure this is a request and not a REPLY from another Listener
    if (buf_rcv[1] == 'Q') {
      printf("%s from %s.\n",
        buf_rcv, ether_ntoa((struct ether_addr *)(&src.sll_addr)));
      plusPos = index(buf_rcv, '+');
      // Make sure we pass the 'RQ:' portion
      num1 = atoi(buf_rcv+3);
      num2 = atoi(plusPos+1);
      (void) memset(buf_snd, 0, sizeof(buf_snd));
      snprintf(buf_snd, sizeof(buf_snd), "RL:%d+%d=%d", num1, num2, num1+num2);
      result = sendPacket(sock, (struct ether_addr *)(&src.sll_addr),
              src.sll_ifindex, 
               my_eth_proto, buf_snd,
              strlen(buf_snd)+1);
      if (result != strlen(buf_snd)+1)
        exit(1);
      printf("%s.\n", buf_snd);
    }

  }
  return 0;
}
