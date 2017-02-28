#!/bin/sh
#
# Replace 
#       <emulab:openflow_controller url="tcp:<CONTROLLER_IP>:6633"/>`
# with
#       <emulab:openflow_controller url="tcp:CONTROLLER_IP:6633"/>`

for i in $* ; do
   fileName=$i
   fileBaseName=`basename $fileName .rspec`
   echo "fixing" $fileName "with basename" $fileBaseName
   cp $fileName $fileName.save
   sed 's/\<CONTROLLER_IP\>/CONTROLLER_IP/g' $fileName.save > $fileBaseName.rspec
done
