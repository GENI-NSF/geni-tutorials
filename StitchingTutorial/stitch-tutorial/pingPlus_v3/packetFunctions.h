/*
 *----------------------------------------------------------------------
 * Copyright (c) 2011 Raytheon BBN Technologies
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
 * packetFunctions.h
 *
 * Author: mberman
 */

#ifndef PACKETFUNCTIONS_H_
#define PACKETFUNCTIONS_H_

#include <net/ethernet.h>
//#include <netinet/ether.h>

extern int sendPacket(const int sock,
				      const struct ether_addr *dst,
			   	      const int ifindex,
			   	      const int protocol,
			   	      const char *payload,
			   	      const int size);

extern int receivePacket(const int sock,
						 const int protocol,
			   	  	     char *buf,
			   	  	     struct sockaddr_ll *src);

#endif /* PACKETFUNCTIONS_H_ */
