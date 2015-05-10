#!/bin/sh

##########################################################
#
#   Copyright (C) 2015 Eduardo Dimas (https://github.com/eddimas/nagios-plugins)
#   Copyright (C) 2009 Mike Adolphs (http://www.matejunkie.com/)
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
##########################################################

PROGNAME=`basename $0`
VERSION="Version 1.1,"
AUTHOR="2015, Eduardo Dimas (https://github.com/eddimas/nagios-plugins)"

TEMP_FILE="/temp/$PROGNAME.$RANDOM.log"
COMMAND='cat /proc/stat'

ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

interval=1

print_version() {
    echo "$VERSION $AUTHOR"
}

help() {
cat << END
Usage :
        $PROGNAME -l [STRING] -H [STRING] -i [VALUE] -w [VALUE] -c [VALUE]

        OPTION          DESCRIPTION
        ----------------------------------
        -h              Help
        -l [STRING]      Remote user
        -H [STRING]     Host name
        -i [VALUE]      Defines the pause between the two times /proc/stat is being
                        parsed. Higher values could lead to more accurate result.
                          Default is: 1 second
        -w [VALUE]      Sets a warning level for CPU user. 
                          Default is: off
        -c [VALUE]      Sets a critical level for CPU user.
                          Default is: off

        ----------------------------------
Note : [VALUE] must be an integer.
END
}

if [ $# -ne 10 ]
then
        help;
        exit 3;
fi

while getopts "l:H:i:w:c:" OPT
do
        case $OPT in
        l) USERNAME="$OPTARG" ;;
        H) HOSTNAME="$OPTARG" ;;
        i) interval="$OPTARG" ;;
        w) warn="$OPTARG" ;;
        c) crit="$OPTARG" ;;
        *) help ;;
        esac
done

val_wcdiff() {
    if [ ${warn} -gt ${crit} ]
    then
        wcdiff=1
    fi
}

get_cpuvals() {
  SSH_COMMAND="`ssh -l $USERNAME $HOSTNAME -C $COMMAND`"
  echo "$SSH_COMMAND"  > $TEMP_FILE
	tmp1_cpu_user=`grep -m1 '^cpu' $TEMP_FILE   |awk '{print $2}'`
	tmp1_cpu_nice=`grep -m1 '^cpu' $TEMP_FILE   |awk '{print $3}'`
	tmp1_cpu_sys=`grep -m1 '^cpu' $TEMP_FILE    |awk '{print $4}'`
	tmp1_cpu_idle=`grep -m1 '^cpu' $TEMP_FILE   |awk '{print $5}'`
	tmp1_cpu_iowait=`grep -m1 '^cpu' $TEMP_FILE |awk '{print $6}'`
	tmp1_cpu_irq=`grep -m1 '^cpu' $TEMP_FILE    |awk '{print $7}'`
	tmp1_cpu_softirq=`grep -m1 '^cpu' $TEMP_FILE|awk '{print $8}'`
	tmp1_cpu_total=`expr $tmp1_cpu_user + $tmp1_cpu_nice + $tmp1_cpu_sys + $tmp1_cpu_idle + $tmp1_cpu_iowait + $tmp1_cpu_irq + $tmp1_cpu_softirq`

	sleep $interval
  SSH_COMMAND="`ssh -l $USERNAME $HOSTNAME -C $COMMAND`"
  echo "$SSH_COMMAND"  > $TEMP_FILE
	tmp2_cpu_user=`grep -m1 '^cpu' $TEMP_FILE|awk '{print $2}'`
	tmp2_cpu_nice=`grep -m1 '^cpu' $TEMP_FILE|awk '{print $3}'`
	tmp2_cpu_sys=`grep -m1 '^cpu' $TEMP_FILE|awk '{print $4}'`
	tmp2_cpu_idle=`grep -m1 '^cpu' $TEMP_FILE|awk '{print $5}'`
	tmp2_cpu_iowait=`grep -m1 '^cpu' $TEMP_FILE|awk '{print $6}'`
	tmp2_cpu_irq=`grep -m1 '^cpu' $TEMP_FILE|awk '{print $7}'`
	tmp2_cpu_softirq=`grep -m1 '^cpu' $TEMP_FILE|awk '{print $8}'`
	tmp2_cpu_total=`expr $tmp2_cpu_user + $tmp2_cpu_nice + $tmp2_cpu_sys + $tmp2_cpu_idle + $tmp2_cpu_iowait + $tmp2_cpu_irq + $tmp2_cpu_softirq`

	diff_cpu_user=`echo "${tmp2_cpu_user} - ${tmp1_cpu_user}" | bc -l`
	diff_cpu_nice=`echo "${tmp2_cpu_nice} - ${tmp1_cpu_nice}" | bc -l`
	diff_cpu_sys=`echo "${tmp2_cpu_sys} - ${tmp1_cpu_sys}" | bc -l`
	diff_cpu_idle=`echo "${tmp2_cpu_idle} - ${tmp1_cpu_idle}" | bc -l`
	diff_cpu_iowait=`echo "${tmp2_cpu_iowait} - ${tmp1_cpu_iowait}" | bc -l`
	diff_cpu_irq=`echo "${tmp2_cpu_irq} - ${tmp1_cpu_irq}" | bc -l`
	diff_cpu_softirq=`echo "${tmp2_cpu_softirq} - ${tmp1_cpu_softirq}" | bc -l`
	diff_cpu_total=`echo "${tmp2_cpu_total} - ${tmp1_cpu_total}" | bc -l`

	cpu_user=`echo "scale=2; (1000*${diff_cpu_user}/${diff_cpu_total}+5)/10"       | bc -l | sed 's/^\./0./'`
	cpu_nice=`echo "scale=2; (1000*${diff_cpu_nice}/${diff_cpu_total}+5)/10"       | bc -l | sed 's/^\./0./'`
	cpu_sys=`echo "scale=2; (1000*${diff_cpu_sys}/${diff_cpu_total}+5)/10"         | bc -l | sed 's/^\./0./'`
	cpu_idle=`echo "scale=2; (1000*${diff_cpu_idle}/${diff_cpu_total}+5)/10"       | bc -l | sed 's/^\./0./'`
	cpu_iowait=`echo "scale=2; (1000*${diff_cpu_iowait}/${diff_cpu_total}+5)/10"   | bc -l | sed 's/^\./0./'`
	cpu_irq=`echo "scale=2; (1000*${diff_cpu_irq}/${diff_cpu_total}+5)/10"         | bc -l | sed 's/^\./0./'`
	cpu_softirq=`echo "scale=2; (1000*${diff_cpu_softirq}/${diff_cpu_total}+5)/10" | bc -l | sed 's/^\./0./'`
	cpu_total=`echo "scale=2; (1000*${diff_cpu_total}/${diff_cpu_total}+5)/10"     | bc -l | sed 's/^\./0./'`
	cpu_usage=`echo "(${cpu_user}+${cpu_nice}+${cpu_sys}+${cpu_iowait}+${cpu_irq}+${cpu_softirq})/1" | bc`
  rm $TEMP_FILE
}

#CPU OK : user=0% system=0% iowait=0% idle=99%
#Performance Data:	cpu_user=0%;80;90; cpu_sys=0%;70;90; cpu_iowait=0%;40;60; cpu_idle=99%;


do_output() {
	output="user:${cpu_user}%, sys:${cpu_sys}%, iowait:${cpu_iowait}%, idle:${cpu_idle}%"
}

do_perfdata() {
	perfdata="cpu_user=${cpu_user}%;80;90; cpu_sys=${cpu_sys}%;80;90; iowait=${cpu_iowait}%;80;90;"
}

if [ -n "$warn" -a -n "$crit" ]
then
    val_wcdiff
    if [ "$wcdiff" = 1 ]
    then
		echo "Please adjust your warning/critical thresholds. The warning must be lower than the critical level!"
        exit $ST_UK
    fi
fi

get_cpuvals
do_output
do_perfdata

if [ -n "$warn" -a -n "$crit" ]
then
    if [ "$cpu_usage" -ge "$warn" -a "$cpu_usage" -lt "$crit" ]
    then
		echo "WARNING - ${output} | ${perfdata}"
        exit $ST_WR
    elif [ "$cpu_usage" -ge "$crit" ]
    then
		echo "CRITICAL - ${output} | ${perfdata}"
        exit $ST_CR
    else
		echo "OK - ${output} | ${perfdata}"
        exit $ST_OK
    fi
else
	echo "OK - ${output} | ${perfdata}"
    exit $ST_OK
fi
