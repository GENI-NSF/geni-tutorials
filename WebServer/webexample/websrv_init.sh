#!/bin/sh
# Copyright (c) 2012-2017 Raytheon BBN Technologies
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


sudo apt-get update
sudo apt-get install -y apache2
sudo apt-get install -y curl
sudo cp -R /local/webexample/website/* /var/www/
sudo rm -rf /var/www/html
sudo ln -s /var/www/ /var/www/html


# Start the webserver
# Needed for Apache 2.2
sudo /usr/sbin/apache2ctl restart
# Needed for Apache 2.4
sudo /etc/init.d/apache2 force-reload
# Needed for both
sudo service apache2 restart

