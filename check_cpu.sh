#!/usr/bin/env bash

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

PROGNAME=$(basename -s .sh $0)
TIMESTAMP=$(date +%Y-%m-%d_%H.%M.%S)

VERSION="Version 1.2,"
AUTHOR="2015, Eduardo Dimas (https://github.com/eddimas/nagios-plugins)"

TEMP_FILE="/var/tmp/${PROGNAME}_${TIMESTAMP}.log"; touch ${TEMP_FILE}
COMMAND='cat /proc/stat'

ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

interval=5

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
        -l [STRING]     Remote user
        -H [STRING]     Host name
        -i [VALUE]      Defines the period where the statistics are being colected.
                          Default is: 5 samples each second
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
  nTimes=$1
  SSH_COMMAND=$()
  for ((x=0;x<=${nTimes};x++)); do
    ssh -l ${USERNAME} ${HOSTNAME} -C ${COMMAND}  > ${TEMP_FILE}
    TEMP_VAR=();
    for ((y=2;y<=8;y++)); do
      TEMP_VAR+=( $(grep -m1 '^cpu' ${TEMP_FILE} |awk -v var="$y" '{print $var}') );
    done
    cpu_user+=( ${TEMP_VAR[0]} );
    cpu_nice+=( ${TEMP_VAR[1]} );
    cpu_sys+=( ${TEMP_VAR[2]} );
    cpu_idle+=( ${TEMP_VAR[3]} );
    cpu_iowait+=( ${TEMP_VAR[4]} );
    cpu_irq+=( ${TEMP_VAR[5]} );
    cpu_softirq+=( ${TEMP_VAR[6]} );
    cpu_total+=( $(expr ${cpu_user} + ${cpu_nice} + ${cpu_sys} + ${cpu_idle} + ${cpu_iowait} + ${cpu_irq} + ${cpu_softirq}) );
    sleep 1
  done;

  for ((x=0;x<=${nTimes};x++)); do
    avg_cpu_user=$( expr $avg_cpu_user + ${cpu_user[$x]} ) ;
    avg_cpu_nice=$( expr $avg_cpu_nice + ${cpu_nice[$x]} ) ;
    avg_cpu_sys=$( expr $avg_cpu_sys + ${cpu_sys[$x]} ) ;
    avg_cpu_idle=$( expr $avg_cpu_idle + ${cpu_idle[$x]} ) ;
    avg_cpu_iowait=$( expr $avg_cpu_iowait + ${cpu_iowait[$x]} ) ;
    avg_cpu_irq=$( expr $avg_cpu_irq + ${cpu_irq[$x]} ) ;
    avg_cpu_softirq=$( expr $avg_cpu_softirq + ${cpu_softirq[x]} ) ;
    avg_cpu_total=$( expr $avg_cpu_total + ${cpu_total[$x]} ) ;
  done

  #               T0	   T1	     T2      T3	     T4	     Avg (5 sec)	Percentage
  #cpu_user     555402	555419	555439	555456	555473	555437.8	 5.84371764093243
  #cpu_nice     14964	  14964	  14964	  14964	  14964	  14964	     0.157435073340188
  #cpu_sys      181464	181476	181484	181496	181506	181485.2	 1.90939159129636
  #cpu_idle     8618807	8618886	8618965	8619040	8619118	8618963.2	 90.6794375506806
  #cpu_iowait   88994   88995	  88995	  88995	  88995	  88994.8	   0.936307328581622
  #cpu_irq      28725   28726	  28726	  28727	  28728	  28726.4	   0.30222820708364
  #cpu_softirq	16298   16298	  16299	  16300	  16301	  16299.2	   0.171482608085164
  #cpu_total	 9504654	9504764	9504872	9504978	9505085	9504870.6	 100

  cpu_user=$(echo "scale=2; (1000*(${avg_cpu_user}/${nTimes})/(${avg_cpu_total}/${nTimes}))/10"       | bc -l | sed 's/^\./0./');
  cpu_nice=$(echo "scale=2; (1000*(${avg_cpu_nice}/${nTimes})/(${avg_cpu_total}/${nTimes}))/10"       | bc -l | sed 's/^\./0./');
  cpu_sys=$(echo "scale=2; (1000*(${avg_cpu_sys}/${nTimes})/(${avg_cpu_total}/${nTimes}))/10"         | bc -l | sed 's/^\./0./');
  cpu_idle=$(echo "scale=2; (1000*(${avg_cpu_idle}/${nTimes})/(${avg_cpu_total}/${nTimes}))/10"       | bc -l | sed 's/^\./0./');
  cpu_iowait=$(echo "scale=2; (1000*(${avg_cpu_iowait}/${nTimes})/(${avg_cpu_total}/${nTimes}))/10"   | bc -l | sed 's/^\./0./');
  cpu_irq=$(echo "scale=2; (1000*(${avg_cpu_irq}/${nTimes})/(${avg_cpu_total}/${nTimes}))/10"         | bc -l | sed 's/^\./0./');
  cpu_softirq=$(echo "scale=2; (1000*(${avg_cpu_softirq}/${nTimes})/(${avg_cpu_total}/${nTimes}))/10" | bc -l | sed 's/^\./0./');
  cpu_total=$(echo "scale=2; (1000*(${avg_cpu_total}/${nTimes})/(${avg_cpu_total}/${nTimes}))/10"     | bc -l | sed 's/^\./0./');
  cpu_usage=$(echo "(${cpu_user}+${cpu_nice}+${cpu_sys}+${cpu_iowait}+${cpu_irq}+${cpu_softirq})/1" | bc);
  rm ${TEMP_FILE}
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

get_cpuvals ${interval}
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
