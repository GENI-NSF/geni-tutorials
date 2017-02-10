#!/bin/bash
# Copyright (c) 2010-2017 Raytheon BBN Technologies
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

# Change directory to download ares in ProtoGENI hosts is `/local`
cd /local
#Get the hostname 
hn=`echo $HOSTNAME | cut -d'.' -f 1`

##### Check if install has already run here, if not install packages #####
if [ ! -f "./installed.txt" ]
then
       #### Create the file ####
       sudo touch "./installed.txt"

       #### Run  one-time commands ####

       #Install necessary packages
       sudo apt-get update
       sudo apt-get -y install apache2 iperf & EPID=$!
       wait $EPID
       cd /local/stitch-tutorial/pingPlus_v3
       sudo make & EPID=$!
       wait $EPID
       cd /local


       if [ $hn == "server" ]
       then
           # Install and Enable web server 
           # Enable web server stats
           # Needed for Apache 2.2
	   sudo /usr/sbin/a2enmod status
	   sudo rm /etc/apache2/mods-enabled/status.conf
           # Needed for Apache 2.4
	   sudo a2enmod access_compat
	   sudo a2enmod info

           # Needed for Apache 2.2
	   echo "<Location /server-status>" | sudo tee -a /etc/apache2/sites-available/default > /dev/null
	   echo "   SetHandler server-status" |sudo tee -a /etc/apache2/sites-available/default > /dev/null
	   echo "   Allow from all" | sudo tee -a /etc/apache2/sites-available/default > /dev/null
	   echo "</Location>" | sudo tee -a /etc/apache2/sites-available/default > /dev/null
	   echo "ExtendedStatus On" | sudo tee -a /etc/apache2/conf.d/extendedstatus > /dev/null

           # Needed for Apache 2.4
	   echo "<Location /server-status>" | sudo tee -a /etc/apache2/apache2.conf> /dev/null
	   echo "   SetHandler server-status" |sudo tee -a /etc/apache2/apache2.conf> /dev/null
	   echo "   Allow from all" | sudo tee -a /etc/apache2/apache2.conf> /dev/null
	   echo "</Location>" | sudo tee -a /etc/apache2/apache2.conf> /dev/null
	   echo "ExtendedStatus On" | sudo tee -a /etc/apache2/apache2.conf> /dev/null

           # Copy the website under /var/www/
	   sudo cp -R /local/stitch-tutorial/webserver/* /var/www/
	   sudo rm -rf /var/www/html
	   sudo ln -s /var/www/ /var/www/html

          # Start the iperf server
	   sudo mkdir -p /var/www/html/iperflogs

       fi
fi

# Start services
# If this is the server then start the iperf and configure and start the http server

if [ $hn == "server" ]
then
   iperf_server_log="/var/www/html/iperflogs/iperf-server.log"
   sudo bash -c "iperf -s &> $iperf_server_log"
   sudo bash -c "/local/stitch-tutorial/pingPlus_v3/pingPlusListener 10000 &"

   # Start the webserver
   # Needed for Apache 2.2
   sudo /usr/sbin/apache2ctl restart
   # Needed for Apache 2.4
   sudo /etc/init.d/apache2 force-reload
   # Needed for both
   sudo service apache2 restart 
fi
