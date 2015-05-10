#!/bin/bash
# 

#   Copyright (C) 2015 Eduardo Dimas (https://github.com/eddimas/nagios-plugins)
#   Copyright (C) Markus Walther (voltshock@gmx.de)
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
# Plugin to check processes running
# The script needs an pair of ssh keys working to run on the server side to check it
# 
# Command-Line for check_procs.sh
# command_line    $USER1$/check_procs.sh -l $USERNAME -H $HOSTNAME$ -p $ARG1$ -w $ARG2$ -c $ARG3$"
# 
# Command-Line for service (example)
# check_procs.sh!sshRemoteUser!192.168.1.2!sshd!1!10
#
##########################################################

PROGNAME=`basename $0`
VERSION="Version 1.1,"
AUTHOR="2015, Eduardo Dimas (https://github.com/eddimas/nagios-plugins)"

help() {
cat << END
Usage :
        $PROGNAME -l [STRING] -H [STRING] -p [VALUE] -w [VALUE] -c [VALUE]

        OPTION          DESCRIPTION
        ----------------------------------
        -h              Help
        -l [STRING]     Remote user
        -H [STRING]     Host name
        -p [VALUE]      Name of process to check
        -w [VALUE]      Warning Threshold
        -c [VALUE]      Critical Threshold

        ----------------------------------
Note : [VALUE] must be an integer.
END
}

if [ $# -ne 10 ]
then
        help;
        exit 3;
fi

while getopts "l:H:p:w:c:" OPT
do
        case $OPT in
        l) USERNAME="$OPTARG" ;;
        H) HOSTNAME="$OPTARG" ;;
        p) proc="$OPTARG" ;;
        w) min="$OPTARG" ;;
        c) max="$OPTARG" ;;
        *) help ;;
        esac
done

lines=`ssh -l $USERNAME $HOSTNAME -C "ps -ef | grep $proc | grep -v grep | grep -v check_proc | wc -l"`
perf_data="$proc=$lines;$min;$max;;;"

if [ -n "$lines" ]; then
        if [ "$lines" -eq "0" ]; then
                echo "Warning: Not enough processes ($lines/$min) | $perf_data"
                exit 1
        elif [ "$lines" -lt "$min" ]; then
                echo "OK: $lines processes running (min=$min, max=$max) | $perf_data"
                exit 0
         elif [ "$lines" -eq "$min" -o "$lines" -gt "$min" -a "$lines" -lt "$max" ]; then
                echo "Warning: Too much processes ($lines/$max) | $perf_data"
                exit 1
         elif [ "$lines" -eq "$max" -o "$lines" -gt "$max" ]; then
                echo "Critical: Too much processes ($lines/$max) | $perf_data"
                exit 2
        fi
 else
        echo "Unknown error"
        exit 3
fi
