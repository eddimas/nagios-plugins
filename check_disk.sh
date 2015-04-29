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
##########################################################

I=0
ok=0
warn=0
crit=0
COMMAND='/bin/df -PH'
TEMP_FILE="/tmp/df.$RANDOM.log"

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

SSH_COMMAND="`ssh -l $USERNAME $HOSTNAME -C $COMMAND`"
echo "$SSH_COMMAND"  > $TEMP_FILE.tmp
echo "`cat $TEMP_FILE.tmp | grep -v Used | grep -v opt`" > $TEMP_FILE
rm $TEMP_FILE.tmp

EQP_FS="`cat $TEMP_FILE | grep -v Used | grep -v opt | wc -l`"

FILE=$TEMP_FILE         # READ $FILE USING THE FILE DESCRIPTORS
exec 3<&0                       # SAVE CURRENT STDIN
exec 0<"$FILE"          #   AND CHANGE IT TO READ FROM FILE.

  while read LINE; do           # USE $LINE VARIABLE TO PROCESS LINE
      I=$((I+1))
                        FULL[$I]=`echo $LINE | awk '{print $2}'`
                        USED[$I]=`echo $LINE | awk '{print $3}'`
                        FREE[$I]=`echo $LINE | awk '{print $4}'`
                        FSNAME[$I]=`echo $LINE | awk '{print $6}'`
                        PERCENT[$I]=`echo $LINE | awk '{print $5}' | sed 's/[%]//g'`
  done
exec 3<&0

rm $TEMP_FILE

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

for (( i=1; i<=$EQP_FS; i++ )); do
        DATA[$i]="${FSNAME[$i]} ${PERCENT[$i]}% of ${FULL[$i]},"
done

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