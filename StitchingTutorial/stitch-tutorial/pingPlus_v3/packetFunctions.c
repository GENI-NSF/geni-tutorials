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
 * packetFunctions.c
 * Author: mberman
 */

#include <stdio.h>
#include <net/if.h>
#include <net/if_arp.h>
#include <linux/if_packet.h>
#include <sys/socket.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <string.h>

#include "packetFunctions.h"

//
// Send an Ethernet packet.
// Return number of bytes sent, or -1 (and print a message) on error.
//
int sendPacket(const int sock,
			   const struct ether_addr *dst,
			   const int ifindex,
			   const int protocol,
			   const char *payload,
			   const int size)
{
	struct sockaddr_ll dst_addr;
	int result;


	// Populate layer 2 address.
	dst_addr.sll_family = AF_PACKET;
	dst_addr.sll_protocol = htons(protocol);
	dst_addr.sll_ifindex = ifindex;
	dst_addr.sll_hatype = ARPHRD_ETHER;
	dst_addr.sll_pkttype = PACKET_HOST;
	dst_addr.sll_halen = sizeof(struct ether_addr);
	memcpy(dst_addr.sll_addr, dst, sizeof(struct ether_addr));

	// Send packet
	result = sendto(sock, payload, size, 0,
				    (struct sockaddr *) (&dst_addr),
				    (socklen_t) sizeof(dst_addr));
	if (result == -1)
		perror("Error in sendto: ");
	else if (result < size)
		fprintf(stderr, "Short sendto: tried %d, sent %d.\n", size, result);

	return result;
}


//
// Receive an Ethernet packet. Simple wrapper around recvfrom.
// Insist on a packet with the protocol specified, unless ETH_P_ALL.
// Store packet in buffer provided, which must be at least ETH_DATA_LEN bytes.
// Store layer 2 address information in provided src structure.
// Return number of bytes read, or -1 on error.
// Wait for a response sent with correct protocol.
int receivePacket(const int sock,
				  const int protocol,
			   	  char *buf,
			   	  struct sockaddr_ll *src)
{
	int done = 0;
	int src_len;
	int numBytes;

//	int flags = fcntl(sock, F_GETFL);
//	flags |= O_NONBLOCK;
//	fcntl(sock, F_SETFL, flags);

	while (!done) {
		(void) memset(src, 0, sizeof(src));
		(void) memset(buf, 0, sizeof(buf));
		src_len = sizeof(struct sockaddr_ll);
		numBytes = recvfrom(sock, buf, ETH_DATA_LEN, 0,
						 (struct sockaddr *) src, &src_len);
		if (numBytes == -1) {
			perror("Error in recvfrom:");
			return -1;
		}
		done = ((ntohs(protocol) == ETH_P_ALL) ||
				(ntohs(protocol) == src->sll_protocol));
	}

	return numBytes;
}
