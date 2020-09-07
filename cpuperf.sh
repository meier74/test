#!/bin/bash

# cpuperf.sh: ver. 1.0.5  06 Feb. 2013 (j.knudsen@cph.dk)
# Script that generates exit code when CPU usage exceeds certain limits.
#  EXIT code 1: I/O Wait limit exceeded (default 30%)
#  EXIT code 2: CPU Usage limit exceedes (default 95%)
#
# Mail can also be sent if MAIL="yes". Mail is sent for every condition
# also when more conditions are met simultaneously.
#
# The percentages measured are an average measured during the time from the
# previous run of the script and until the current run.
#  Note: If a I/Owait warning condition is detected only the exit code 1
#  will result. Any concurrent cpu usage exit code is 'hidden' when the
#  two conditions are met at the same time. This is working as designed
#  as the I/O wait condition is considered a more severe performance issue.

PREVIOUS_STAT="/tmp/previous_stat"

# stat percentage textual display yes/no (for debugging purposes)
VERY_VERBOSE="no"
VERBOSE="yes"

# Optionally send an e-mail to $MAILTO when detecting limit(s) exceeded
MAIL="yes"
MAILTO="fedtmule@lv-install1.cph.dk"

# The alarm limits (defaults IOWAIT=30 CPU_USAGE=95)
IOWAIT_ALARM="20"
CPU_USAGE_ALARM="70"

# Information about when this script is run, and when it was last run so
# the time period of the measurement can be documented/shown
if [ "$VERY_VERBOSE" = "yes" ] ; then
  echo "Previous run : `/bin/date -r $PREVIOUS_STAT`"
  echo "Current run  : `/bin/date`"
fi

# Get current cpu usage string from kernel and remove the 'cpu ' prefix from
# string.
CUR_STRING=`/usr/bin/grep "^cpu " /proc/stat |  /usr/bin/sed -e 's/cpu//'`   	

# Read previous cpu usage stat records from file, and then replace file
# contents current  cpu usage stats for use in subsequent runs of this script.
if [ -f $PREVIOUS_STAT ] ; then
  PREV_STRING=`/bin/cat $PREVIOUS_STAT`
  echo $CUR_STRING > $PREVIOUS_STAT
else
  echo $CUR_STRING > $PREVIOUS_STAT
  # We do nothing on the first run except writing the current stat  for
  # use with the next execution of this script.
  #echo "exit:0"
  exit 0
fi

# Separate the field values read from the /proc/stat file into variables   
for PREV_FIELD in `echo "PREV_USER PREV_NICE PREV_SYSTEM PREV_IDLE PREV_IOWAIT PREV_IRQ PREV_SOFTIRQ PREV_STEAL PREV_GUEST PREV_GUEST_NICE"`
do
  case "$PREV_FIELD" in
    PREV_USER)       PREV_USER=`echo $PREV_STRING | awk '{ print $1 }'` ;;
    PREV_NICE)       PREV_NICE=`echo $PREV_STRING | awk '{ print $2 }'` ;;
    PREV_SYSTEM)     PREV_SYSTEM=`echo $PREV_STRING | awk '{ print $3 }'` ;;
    PREV_IDLE)       PREV_IDLE=`echo $PREV_STRING | awk '{ print $4 }'` ;;
    PREV_IOWAIT)     PREV_IOWAIT=`echo $PREV_STRING | awk '{ print $5 }'` ;;
    PREV_IRQ)        PREV_IRQ=`echo $PREV_STRING | awk '{ print $6 }'` ;;
    PREV_SOFTIRQ)    PREV_SOFTIRQ=`echo $PREV_STRING | awk '{ print $7 }'` ;;
    PREV_STEAL)      PREV_STEAL=`echo $PREV_STRING | awk '{ print $8 }'` ;;
    PREV_GUEST)      PREV_GUEST=`echo $PREV_STRING | awk '{ print $9 }'` ;;
    PREV_GUEST_NICE) PREV_GUEST_NICE=`echo $PREV_STRING | awk '{ print $10 }'` ;;
  esac
done

if [ "$PREV_GUEST_NICE" = "" ] ; then
  PREV_GUEST_NICE="0"
fi

# Add all previously recorded cpu stat types into a grand total
let "PREV_TOTAL=$PREV_USER+$PREV_NICE+$PREV_SYSTEM+$PREV_IDLE+$PREV_IOWAIT+$PREV_IRQ+$PREV_SOFTIRQ+$PREV_STEAL+$PREV_GUEST+$PREV_GUEST_NICE"

# Separate all the field values into separate variables   
for FIELD in `echo "USER NICE SYSTEM IDLE IOWAIT IRQ SOFTIRQ STEAL GUEST GUEST_NICE"`
do
  case "$FIELD" in
    USER)       USER=`echo $CUR_STRING | awk '{ print $1 }'` ;;
    NICE)       NICE=`echo $CUR_STRING | awk '{ print $2 }'` ;;
    SYSTEM)     SYSTEM=`echo $CUR_STRING | awk '{ print $3 }'` ;;
    IDLE)       IDLE=`echo $CUR_STRING | awk '{ print $4 }'` ;;
    IOWAIT)     IOWAIT=`echo $CUR_STRING | awk '{ print $5 }'` ;;
    IRQ)        IRQ=`echo $CUR_STRING | awk '{ print $6 }'` ;;
    SOFTIRQ)    SOFTIRQ=`echo $CUR_STRING | awk '{ print $7 }'` ;;
    STEAL)      STEAL=`echo $CUR_STRING | awk '{ print $8 }'` ;;
    GUEST)      GUEST=`echo $CUR_STRING | awk '{ print $9 }'` ;;
    GUEST_NICE) GUEST_NICE=`echo $CUR_STRING | awk '{ print $10 }'` ;;
  esac
done

if [ "$GUEST_NICE" = "" ] ; then
  GUEST_NICE="0"
fi

# Add all cpu stat types into a grand total
let "TOTAL=$USER+$NICE+$SYSTEM+$IDLE+$IOWAIT+$IRQ+$SOFTIRQ+$STEAL+$GUEST+$GUEST_NICE"

# Calculate difference between previous run and current stats
let "DELTA_USER=$USER-$PREV_USER"
let "DELTA_NICE=$NICE-$PREV_NICE"
let "DELTA_SYSTEM=$SYSTEM-$PREV_SYSTEM"
let "DELTA_IDLE=$IDLE-$PREV_IDLE"
let "DELTA_IOWAIT=$IOWAIT-$PREV_IOWAIT"
let "DELTA_IRQ=$IRQ-$PREV_IRQ"
let "DELTA_SOFTIRQ=$SOFTIRQ-$PREV_SOFTIRQ"
let "DELTA_STEAL=$STEAL-$PREV_STEAL"
let "DELTA_GUEST=$GUEST-$PREV_GUEST"
let "DELTA_GUEST_NICE=$GUEST_NICE-$PREV_GUEST_NICE"

# Add all previously recorded cpu stat types into a grand total
let "DELTA_TOTAL=$DELTA_USER+$DELTA_NICE+$DELTA_SYSTEM+$DELTA_IDLE+$DELTA_IOWAIT+$DELTA_IRQ+$DELTA_SOFTIRQ+$DELTA_STEAL+$DELTA_GUEST+$DELTA_GUEST_NICE"

# Calculate and display stats
if [ "$VERY_VERBOSE" = "yes" ] ; then
 echo "---------- * BEGIN * Very verbose textual stat output -------"
 echo -en "User:       "; echo "scale=2 ; ($USER * 100) / $TOTAL" | bc -l
 echo -en "DeltaUser   "; echo "scale=2 ; ($DELTA_USER * 100) / $DELTA_TOTAL" | bc -l
 echo -en "Nice:             "; echo "scale=2 ; ($NICE * 100) / $TOTAL" | bc -l
 echo -en "DeltaNice:        "; echo "scale=2 ; ($DELTA_NICE * 100) / $DELTA_TOTAL" | bc -l
 echo -en "System:      "; echo "scale=2 ; ($SYSTEM * 100) / $TOTAL" | bc -l
 echo -en "DeltaSystem: "; echo "scale=2 ; ($DELTA_SYSTEM * 100) / $DELTA_TOTAL" | bc -l
 echo -en "Idle:             "; echo "scale=2 ; ($IDLE * 100) / $TOTAL" | bc -l
 echo -en "DeltaIdle:        "; echo "scale=2 ; ($DELTA_IDLE * 100) / $DELTA_TOTAL" | bc -l
 echo -en "Iowait:      "; echo "scale=2 ; ($IOWAIT * 100) / $TOTAL" | bc -l
 echo -en "DeltaIowait: "; echo "scale=2 ; ($DELTA_IOWAIT * 100) / $DELTA_TOTAL" | bc -l
 echo -en "Irq:               "; echo "scale=2 ; ($IRQ * 100) / $TOTAL" | bc -l
 echo -en "DeltaIrq:          "; echo "scale=2 ; ($DELTA_IRQ * 100) / $DELTA_TOTAL" | bc -l
 echo -en "Softirq:      "; echo "scale=2 ; ($SOFTIRQ * 100) / $TOTAL" | bc -l
 echo -en "DeltaSoftirq: "; echo "scale=2 ; ($DELTA_SOFTIRQ * 100) / $DELTA_TOTAL" | bc -l
 echo -en "Steal:             "; echo "scale=2 ; ($STEAL * 100) / $TOTAL" | bc -l
 echo -en "DeltaSteal:        "; echo "scale=2 ; ($DELTA_STEAL * 100) / $DELTA_TOTAL" | bc -l
 echo -en "Guest:        "; echo "scale=2 ; ($GUEST * 100) / $TOTAL" | bc -l
 echo -en "DeltaGuest:   "; echo "scale=2 ; ($DELTA_GUEST * 100) / $DELTA_TOTAL" | bc -l
 echo -en "Guest Nice:        "; echo "scale=2 ; ($GUEST_NICE * 100) / $TOTAL" | bc -l
 echo -en "DeltaGuest Nice:   "; echo "scale=2 ; ($DELTA_GUEST_NICE * 100) / $DELTA_TOTAL" | bc -l
 echo "---------- * END *Very verbose textual stat output -------"
 echo " "
fi

# Integer percentage IDLE and IOwait since last run suitable for
# warning purposes
IDLE_SLR=`/usr/bin/expr $DELTA_IDLE \* 100 / $DELTA_TOTAL `
CPU_USAGE_SLR=`/usr/bin/expr 100 - $IDLE_SLR`
IOWAIT_SLR=`/usr/bin/expr $DELTA_IOWAIT \* 100 / $DELTA_TOTAL `

# If VERBOSE=yes then print to STDOUT - otherwise be quiet
if [ "$VERBOSE" = "yes" ] ; then
  echo "CPU usage % since last run: $CPU_USAGE_SLR"
  echo "IoWait % since last run: $IOWAIT_SLR"
fi

# Handling of I/O wait condition and optional e-mail
if [ "${IOWAIT_SLR}" -gt "${IOWAIT_ALARM}" ] ; then
    if [ "$MAIL" = "yes" ] ; then
      echo "I/O wait ${IOWAIT_SLR}: Warning sent via $0 from `uname -n`" |
      /usr/bin/mailx -s "Warning: `uname -n`: I/O wait ${IOWAIT_SLR}" $MAILTO
    fi
  echo "exit:2"
  exit 2
fi

# Handling of CPU usage condition and optional e-mail 
if [ "${CPU_USAGE_SLR}" -gt "${CPU_USAGE_ALARM}" ] ; then
   if [ "$MAIL" = "yes" ] ; then
     echo "CPU usage ${CPU_USAGE_SLR}: Warning sent via $0 from `uname -n`" |
     /usr/bin/mailx -s "Warning: `uname -n`: CPU usage ${CPU_USAGE_SLR}" $MAILTO
   fi
  echo "exit:1"
  exit 1
fi

# EXIT 0 indicates ALL IS WELL ; no warning conditions detected
#echo "exit:0"
exit 0
