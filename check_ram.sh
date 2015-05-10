#!/bin/bash

##########################################################
#
# PLUGIN TO CHECK FREE DISK SPACE
# USING CHECK_BY_SSH
#
#   Copyright (C) 2015 Eduardo Dimas (https://github.com/eddimas/nagios-plugins)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# THE SCRIPT NEEDS A WORKING CHECK_BY_SSH CONNECTION AND NEEDS TO RUN ON THE CLIENT TO CHECK IT
#
##########################################################

PROGNAME=`basename $0`
VERSION="Version 1.1,"
AUTHOR="2015, Eduardo Dimas (https://github.com/eddimas/nagios-plugins)"

TEMP_FILE="/tmp/$PROGNAME.$RANDOM.log"
COMMAND1='free -tb'
COMMAND2='free -tm'

help() {
cat << END
Usage :
        $PROGNAME -l [STRING] -H [STRING] -w [VALUE] -c [VALUE]

        OPTION          DESCRIPTION
        ----------------------------------
        -h              Help
        -l [STRING]      Remote user
        -H [STRING]     Host name
        -w [VALUE]      Sets a warning level for memory usage. 
                          Default is: 80
        -c [VALUE]      Sets a critical level for memory usage.
                          Default is: 90

        ----------------------------------
Note : [VALUE] must be an integer.
END
}

if [ $# -ne 8 ]
then
        help;
        exit 3;
fi

while getopts "l:H:w:c:" OPT
do
        case $OPT in
        l) USERNAME="$OPTARG" ;;
        H) HOSTNAME="$OPTARG" ;;
        w) warn="$OPTARG" ;;
        c) crit="$OPTARG" ;;
        *) help ;;
        esac
done


SSH_COMMAND="`ssh -l $USERNAME $HOSTNAME -C $COMMAND1`"
 echo "$SSH_COMMAND"  > $TEMP_FILE.1 
SSH_COMMAND="`ssh -l $USERNAME $HOSTNAME -C $COMMAND2`"
 echo "$SSH_COMMAND"  > $TEMP_FILE.2

 swapTotal_b=`grep Swap $TEMP_FILE.1  | sed -r 's/\ +/\ /g' | cut -d \  -f 2`
 swapFree_b=`grep Swap $TEMP_FILE.1  | sed -r 's/\ +/\ /g' | cut -d \  -f 4`
 memTotal_b=`grep Mem $TEMP_FILE.1  | sed -r 's/\ +/\ /g' | cut -d \  -f 2`
 memFree_b=`grep Mem $TEMP_FILE.1  | sed -r 's/\ +/\ /g' | cut -d \  -f 4`
 memBuffer_b=`grep Mem $TEMP_FILE.1  | sed -r 's/\ +/\ /g' | cut -d \  -f 6`
 memCache_b=`grep Mem $TEMP_FILE.1  | sed -r 's/\ +/\ /g' | cut -d \  -f 7`

 swapTotal_m=`grep Swap $TEMP_FILE.2  | sed -r 's/\ +/\ /g' | cut -d \  -f 2`
 swapFree_m=`grep Swap $TEMP_FILE.2  | sed -r 's/\ +/\ /g' | cut -d \  -f 4` 
 memTotal_m=`grep Mem $TEMP_FILE.2  | sed -r 's/\ +/\ /g' | cut -d \  -f 2`
 memFree_m=`grep Mem $TEMP_FILE.2  | sed -r 's/\ +/\ /g' | cut -d \  -f 4`
 memBuffer_m=`grep Mem $TEMP_FILE.2  | sed -r 's/\ +/\ /g' | cut -d \  -f 6`
 memCache_m=`grep Mem $TEMP_FILE.2  | sed -r 's/\ +/\ /g' | cut -d \  -f 7`

 swapUsed_b=$(($swapTotal_b-$swapFree_b))
 memUsed_b=$(($memTotal_b-$memFree_b-$memBuffer_b-$memCache_b-$swapUsed_b))
 swapUsed_m=$(($swapTotal_m-$swapFree_m))
 memUsed_m=$(($memTotal_m-$memFree_m-$memBuffer_m-$memCache_m-$swapUsed_m))

 swapUsedPrc=$((($swapUsed_b*100)/$swapTotal_b))
 memUsedPrc=$((($memUsed_b*100)/$memTotal_b))
 
  swapUsedWarn=$((($swapTotal_b/100)*$warn))
  swapUsedCrit=$((($swapTotal_b/100)*$crit))
  
  memUsedWarn=$((($memTotal_b/100)*$warn))
  memUsedCrit=$((($memTotal_b/100)*$crit))

rm $TEMP_FILE.1 $TEMP_FILE.2


#Memory usage: 937.71MiB (93.55%) of 1002.40MiB (warning threshold is set to 900MiB), Application memory usage: 210.57MiB (22.11%) of 952.28MiB, Cache usage: 688.96MiB (68.73%) of 1002.40MiB (critical threshold is set to 500MiB), Swap usage: 0.00MiB (0.00%) of 894.99MiB | MemUsed=983260200.96B;943718400;1048576000;0;1051095040 AppMemUsed=220798648.32B;838860800;943718400;0;998540288 CacheUsed=722426920.96B;419430400;524288000;0;1051095040 SwapUsed=0B;734003200;838860800;0;938467328 
#${perf[@]};$WARN;$CRIT;0;;
data="Memory usage: $memUsed_m MB ($memUsedPrc%) of $memTotal_m MB, Swap usage: $swapUsed_m MB ($swapUsedPrc%) of $swapTotal_m MB"
perf="USED=$memUsed_b;$memUsedWarn;$memUsedCrit;0;$memTotal_b; SWAP=$swapUsed_m;$swapUsedWarn;$swapUsedCrit;0;$swapTotal_b;"

if [ "$memUsedPrc" -ge "$crit" ]; then
    echo "Memory: CRITICAL $data | $perf"
    $(exit 2)
  elif [ "$memUsedPrc" -ge "$warn" ]; then
    echo "Memory: WARNING $data | $perf"
    $(exit 1)
  else
    echo "Memory: OK $data | $perf"
    $(exit 0)
fi 