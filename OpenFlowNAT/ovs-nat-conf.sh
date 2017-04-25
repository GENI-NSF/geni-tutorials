#!/bin/sh
#----------------------------------------------------------------------
# Copyright (c) 2017 Raytheon BBN Technologies
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and/or hardware specification (the "Work") to
# deal in the Work without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Work, and to permit persons to whom the Work
# is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Work.
#
# THE WORK IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE WORK OR THE USE OR OTHER DEALINGS
# IN THE WORK.
#----------------------------------------------------------------------


# Add the OVS bridge that will be the NAT 
ovs-vsctl --if-exists del-br OVS1
ovs-vsctl add-br OVS1
ifconfig $3 0
ovs-vsctl add-port OVS1 $3
ovs-vsctl set-controller OVS1 tcp:$4:6633

# Add the public IP of your NAT server
# Delete any routes for the outside network
sudo route del -net 128.128.128.0 netmask 255.255.255.0
ifconfig OVS1 128.128.128.100/24 up

#Add the bridge for the local switch for subnet 10.10.1.0/24
ovs-vsctl --if-exists del-br OVS2
ovs-vsctl add-br OVS2
ifconfig $1 0
ovs-vsctl add-port  OVS2 $1
ifconfig $2 0
ovs-vsctl add-port  OVS2 $2
#Add the IP for the local router on 10.10.1.0/24 subnet
# Delete any routes for the inside network
sudo route del -net 10.10.1.0 netmask 255.255.255.0
ifconfig OVS2 10.10.1.100/24

# Statically configure the learning switch
ovs-ofctl del-flows OVS2

# Act as a normal switch for all packets on the 10.10.1.0/24 IP subnet
ovs-ofctl add-flow OVS2 priority=1000,in_port=2,dl_type=0x0806,nw_src="10.10.1.0/24",nw_dst="10.10.1.0/24",actions=output:NORMAL
ovs-ofctl add-flow OVS2 priority=1000,in_port=1,dl_type=0x0806,nw_src="10.10.1.0/24",nw_dst="10.10.1.0/24",actions=output:NORMAL
ovs-ofctl add-flow OVS2 priority=1000,in_port=2,dl_type=0x0800,nw_src="10.10.1.0/24",nw_dst="10.10.1.0/24",actions=output:NORMAL
ovs-ofctl add-flow OVS2 priority=1000,in_port=1,dl_type=0x0800,nw_src="10.10.1.0/24",nw_dst="10.10.1.0/24",actions=output:NORMAL

# For all other IP packets forward them to the kernel for routing
#ARP packets
ovs-ofctl add-flow OVS2 priority=100,in_port=1,dl_type=0x806,actions=output:LOCAL
ovs-ofctl add-flow OVS2 priority=100,in_port=2,dl_type=0x806,actions=output:LOCAL
ovs-ofctl add-flow OVS2 priority=100,in_port=LOCAL,dl_type=0x806,actions=output:1,output:2
#IP packets
ovs-ofctl add-flow OVS2 priority=100,in_port=1,dl_type=0x800,actions=output:LOCAL
ovs-ofctl add-flow OVS2 priority=100,in_port=2,dl_type=0x800,actions=output:LOCAL
ovs-ofctl add-flow OVS2 priority=100,in_port=LOCAL,dl_type=0x800,actions=output:1,output:2
