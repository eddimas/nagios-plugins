#!/bin/bash
##########################################################
#
# PLUGIN TO CHECK FREE DISK SPACE
# USING SSH_LOGIN
# BY EDUARDO DIMAS (eddimas@gmail.com)
#
# COMMAND-LINE FOR CHECK_DISKS
# USAGE $USER1$/check_disk.sh -l username -H $HOSTNAME$ -w 75 -c 90"
#
# COMMAND-LINE FOR SERVICE (EXAMPLE)
# $USER1$/check_disk.sh!$USER1$!$HOSTNAME$!75!90
#
# Output example for OK, warning, critical and (the worst) warning + critical
#
# [eddimas@centos7 ~]$ ./check_disk.sh -l eddimas -H 192.168.1.74 -w 75 -c 90
# OK. DISK STATS: / 14% of 33G, /dev 0% of 956M, /dev/shm 1% of 966M, /run 1% of 966M, /sys/fs/cgroup 0% of 966M, /boot 34% of 521M,
#
# [eddimas@centos7 ~]$ ./check_disk.sh -l eddimas -H 192.168.1.74 -w 30 -c 40
# WARNING. DISK STATS: / 14% of 33G, /dev 0% of 956M, /dev/shm 1% of 966M, /run 1% of 966M, /sys/fs/cgroup 0% of 966M, /boot 34% of 521M,; Warning /boot has 34% of utilization or 175M of 521M,
#
# [eddimas@dhcppc10 ~]$ ./check_disk.sh -l eddimas -H 192.168.1.74 -w 15 -c 30
# CRITICAL. DISK STATS: / 14% of 33G, /dev 0% of 956M, /dev/shm 1% of 966M, /run 1% of 966M, /sys/fs/cgroup 0% of 966M, /boot 34% of 521M,; Critical /boot has 34% of utilization or 175M of 521M,
#
# [eddimas@centos7 ~]$ ./check_disk.sh -l eddimas -H 192.168.1.74 -w 10 -c 30
# CRITICAL. DISK STATS: / 14% of 33G, /dev 0% of 956M, /dev/shm 1% of 966M, /run 1% of 966M, /sys/fs/cgroup 0% of 966M, /boot 34% of 521M,; Warning / has 14% of utilization or 4.3G of 33G,; Critical /boot has 34% of utilization or 175M of 521M,
#
##########################################################

j=0; ok=0
warn=0; crit=0
COMMAND='/bin/df -PH'
TEMP_FILE="/tmp/df.$RANDOM.log"

## Help funcion 
help() {
cat << END
Usage :
        check_disk.sh -l [STRING] -H [STRING] -w [VALUE] -c [VALUE]

        OPTION          DESCRIPTION
        ----------------------------------
        -h              Help
        -l [STRING]      Remote user
        -H [STRING]     Host name
        -w [VALUE]      Warning Threshold
        -c [VALUE]      Critical Threshold

        ----------------------------------
Note : [VALUE] must be an integer.
END
}

## Validating and setting the variables and the input args
if [ $# -ne 8 ]
then
        help;
        exit 3;
fi

while getopts "l:H:n:w:c:" OPT
do
        case $OPT in
        l) USERNAME="$OPTARG" ;;
        H) HOSTNAME="$OPTARG" ;;
        w) WARN="$OPTARG" ;;
        c) CRIT="$OPTARG" ;;
        *) help ;;
        esac
done

## Sending the ssh request command and store the result into local log file
SSH_COMMAND="`ssh -l $USERNAME $HOSTNAME -C $COMMAND`"
echo "$SSH_COMMAND"  > $TEMP_FILE.tmp
echo "`cat $TEMP_FILE.tmp | grep -v Used | grep -v opt`" > $TEMP_FILE
EQP_FS="`cat $TEMP_FILE | grep -v Used | grep -v opt | wc -l`"  # determine how many FS are in the server


FILE=$TEMP_FILE                 # read $file using file descriptors
exec 3<&0                       # save current stdin
exec 0<"$FILE"                  # change it to read from file.

  while read LINE; do           # use $LINE variable to process each line of file
      j=$((j+1))
                        FULL[$j]=`echo $LINE | awk '{print $2}'`
                        USED[$j]=`echo $LINE | awk '{print $3}'`
                        FREE[$j]=`echo $LINE | awk '{print $4}'`
                        FSNAME[$j]=`echo $LINE | awk '{print $6}'`
                        PERCENT[$j]=`echo $LINE | awk '{print $5}' | sed 's/[%]//g'`
  done
exec 3<&0
rm $TEMP_FILE.tmp $TEMP_FILE

## According with the number of FS determine if the traceholds are reached (one by one)
for (( i=1; i<=$EQP_FS; i++ )); do
        if [ "${PERCENT[$i]}" -lt "$WARN" ]; then
                ok=$((ok+1))
        elif [ "${PERCENT[$i]}" -eq "$WARN" -o "${PERCENT[$i]}" -gt "$WARN" -a "${PERCENT[$i]}" -lt "$CRIT" ]; then
                warn=$((warn+1))
                WARN_DISKS[$warn]="${FSNAME[$i]} has ${PERCENT[$i]}% of utilization or ${USED[$i]} of ${FULL[$i]},"                
        elif [ "${PERCENT[$i]}" -eq "$CRIT" -o "${PERCENT[$i]}" -gt "$CRIT" ]; then
                crit=$((crit+1))
                CRIT_DISKS[$crit]="${FSNAME[$i]} has ${PERCENT[$i]}% of utilization or ${USED[$i]} of ${FULL[$i]},"                
        fi
done

## Set the data to show in the nagios service status 
for (( i=1; i<=$EQP_FS; i++ )); do
        DATA[$i]="${FSNAME[$i]} ${PERCENT[$i]}% of ${FULL[$i]},"
done

## Just validate and adjust the nagios output   
if [ "$ok" -eq "$EQP_FS" -a "$warn" -eq 0 -a "$crit" -eq 0 ]; then
    echo "OK. DISK STATS: ${DATA[@]}"
    exit 0
  elif [ "$warn" -gt 0 -a "$crit" -eq 0 ]; then
    echo "WARNING. DISK STATS: ${DATA[@]}; Warning ${WARN_DISKS[@]}"
    exit 1
  elif [ "$crit" -gt 0 ]; then
      #Validate if the Warning array is empty if so remove the Warning leyend
      if [ ${#WARN_DISKS[@]} -eq 0 ]; then 
          echo "CRITICAL. DISK STATS: ${DATA[@]}; Critical ${CRIT_DISKS[@]}"
          exit 2
      else
          echo "CRITICAL. DISK STATS: ${DATA[@]}; Warning ${WARN_DISKS[@]}; Critical ${CRIT_DISKS[@]}"
          exit 2
      fi
else
      echo "Unknown"
      exit 3
fi 