#!/usr/bin
#
# Copyright (c) 2017 Raytheon BBN Technologies
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this 
# software and/or hardware specification (the “Work”) to deal in the Work without 
# restriction, including without limitation the rights to use, copy, modify, merge, 
# publish, distribute, sublicense, and/or sell copies of the Work, and to permit 
# persons to whom the Work is furnished to do so, subject to the following conditions:  
# 
# The above copyright notice and this permission notice shall be included in all 
# copies or substantial portions of the Work.  
# 
# THE WORK IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE WORK 
# OR THE USE OR OTHER DEALINGS IN THE WORK. 
#
# =====================================================================
# 
# This script is to generate ospf configuration for the VMs
# that has XORP installed, and start xorp process. 
#
# The script first to get the network configuration information, 
# such as virtual interfaces (neither eth0 nor lo), hostname, etc. 
# 
# Secondly, the script will start xorp process in the VM 
#
#
# Code by Xuan Liu
# xliu@bbn.com
# 
# June 9, 2014
# =====================================================================


cd /local/xorp_autostart/

ABS_PATH=/local/xorp_autostart

vm_info_file=$ABS_PATH/vm_info.txt
host=echo `hostname`
echo $host

# get hostname 
hostname | sudo tee $vm_info_file > /dev/null
# get interface information
/sbin/ifconfig | egrep 'eth|inet addr' | sudo tee -a $vm_info_file > /dev/null
# get timestamp
timestamp=$(date +"%Y-%m-%d %r")
echo $timestamp


xorp_conf_dir=/etc/xorp

if [ -d $xorp_conf_dir ] 
then
   echo "XORP dir exist"
else
   echo "creating xorp dir"
   sudo mkdir $xorp_conf_dir
fi

sudo /usr/bin/awk -f $ABS_PATH/ospfd-conf-gen.awk $vm_info_file "$timestamp" 24 | sudo tee $ABS_PATH/ospfd.conf > /dev/null

sudo cp $ABS_PATH/ospfd.conf $xorp_conf_dir/.

# check if xorp has been added to the group
xorp_group=`sudo cat /etc/group | grep "xorp"`
if [ "$xorp_group" = "" ]
then
   echo "Add xorp to group"
   sudo groupadd xorp
else
   echo "xorp is already added to the group"
fi



# first stop current xorp process if it's running

xorp_pids=`ps -ef | grep xorp_ | /usr/bin/awk '{ if ( $1 == "root" ) {print $2}}'`
if [ "$xorp_pids" = "" ]
then
   echo "xorp is not running at this time"
else
   echo "xorp is running, stop it first"
   ps -ef | grep xorp_ | /usr/bin/awk '{ if ( $1 == "root" ) {print "sudo kill -9 " $2}}' | sh
fi


# start xorp
cd /usr/local/xorp/sbin/
echo "XORP is starting ......"
sudo ./xorp_rtrmgr -b $xorp_conf_dir/ospfd.conf -l /tmp/xorp_rtrmgr_log -d


# restart the interface

/sbin/ifconfig -a | grep eth | awk '{ if (substr($1, 4,4) != 0) { print "sudo /sbin/ifconfig " $1 " down"}}' |sh
/sbin/ifconfig -a | grep eth | awk '{ if (substr($1, 4,4) != 0) { print "sudo /sbin/ifconfig " $1 " up"}}' |sh 


# Turn off the reverse path filter on ubuntu
sudo sysctl -w net.ipv4.conf.all.rp_filter=0
sudo sysctl -w net.ipv4.conf.default.rp_filter=0
/sbin/ifconfig -a | grep eth | awk '{ if (substr($1, 4,4) != 0) { print "sudo sysctl -w net.ipv4.conf." $1 ".rp_filter=0"}}' | sh

