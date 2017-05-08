#!/usr/bin

# ============================================================================
# This script is to log routing table while running xorp on a virtual router
# It logs the routing table every x seconds (i.e., x = 2), and compares the 
# current table with previous table, if there is a difference, then 
# marks 1 and log the timestamp, otherwise, marks 0.
#
# Code By Xuan Liu
# June 11, 2014
# ============================================================================


TIMER=$1

XORP_LOG=/local/xorp_run/logs
START=$(date -u +"%m-%d-%Y-%H-%M-%S")
STORE_CSV_FILE=$XORP_LOG/rt-change'_'$START.csv
CSV_FILE=$XORP_LOG/rt-change.csv
echo $CSV_FILE
echo $START

if [ -f $CSV_FILE ]
then
    echo "delete old csv file first!"
    sudo rm $CSV_FILE
fi

# get router id
router_id=`hostname | awk -F'.' '{print $1}'`

# create log folder
if [ -d $XORP_LOG ]
then
    echo "log dir exists"
else
    echo "Create the folder for routing table logs"
    sudo mkdir $XORP_LOG
fi


table_log=$XORP_LOG/xorp-rtable_$START.txt

echo $table_log
last_record=$XORP_LOG/last_table.txt
# First Run XORP to Get Routing Table
run_time=$(date -u +"%m-%d-%Y-%H-%M-%S")
run_time_sec=$(date -u +%s)
echo $run_time $run_time_sec
echo $run_time $run_time_sec | sudo tee $table_log > /dev/null
sudo /usr/local/xorp/sbin/xorpsh -c "show route table ipv4 unicast ospf" | sudo tee $last_record > /dev/null
sudo cat $last_record | sudo tee -a $table_log > /dev/null
#echo $run_time | sudo tee $CSV_FILE > /dev/null
# sleep for 2 seconds
sleep 2

# temp record
tmp_table=$XORP_LOG/tmp.txt

# Recursively collect routing table

while [ $TIMER -ne 0 ]
do
   now=$(date -u +"%m-%d-%Y-%H-%M-%S")
   now_sec=$(date -u +%s)
   sudo /usr/local/xorp/sbin/xorpsh -c "show route table ipv4 unicast ospf" | sudo tee $tmp_table > /dev/null
   # check if there is difference in the routing table
   table_diff=$(diff -q $tmp_table $last_record)
   echo $table_diff
   if [[ "$table_diff" =~ "diff" ]]
   then
       echo "routing table changed!"
       sudo mv $tmp_table $last_record
       echo $run_time $run_time_sec | sudo tee -a $table_log > /dev/null
       sudo cat $last_record | sudo tee -a $table_log > /dev/null
       echo $router_id","$now_sec","1 | sudo tee -a $CSV_FILE > /dev/null
   else
       echo "No Change"
       echo $router_id","$now_sec","0  | sudo tee -a $CSV_FILE > /dev/null
   fi
   sleep $2s
   TIMER=$((TIMER - $2))
   #echo $TIMER
done

sudo cp $CSV_FILE $STORE_CSV_FILE 
