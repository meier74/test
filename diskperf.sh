#!/bin/bash

# Ver. 1.0.2 j.knudsen@cph.dk 02 Feb. 2013
#
# Script to Analyze contents of /proc/diskstats and generate warning
# if disk performance is not within predetermined limits.
#
# The script will process diskstat information for each harddrive
# found in /proc/partitions.  In this script we use the total number
# of milliseconds spent on  reads and writes divided by total number
# of reads and writes to determine approximate milliseconds per read
# and per write.  (The numbers used are the additional count since
# the previous run of this  script) so we actually measure the average
# since the previous run of the script.
#
# Needs the /proc/ structure present in Linux kernel versions 2.6
# or higher. Exits with exit code 254 if requirement is not met.
# Obviously also needs Linurxs. Exits with exit code 253 if script is
# not run on a Linux machine.
#
# NOTE: In order to avoid strange results caused by integer
#       math we artificially force minimum values (1) for both
#       the number of read/writes and number of milliseconds
#       spent reading and writing. SO! reads and writes measured
#       by this script will NEVER assume values below the value
#       1 (one as in the single digit), and are NOT 100% accurate
#       (but more than close enough for monitoring and warning).

# References:
# KERNEL DOCUMENTATION: /usr/src/linux/Documentation/iostats.txt
# Partition information in: /proc/partitions
# Disk statistics in: /proc/diskstats
# O/S release in /proc/sys/kernel/osrelease

# Our warning trigger limits (milliseconds per read or write)
MSECS_PER_READ_LIMIT="1000"
MSECS_PER_WRITE_LIMIT="1000"
# Enable/disable extra verbosity
VERBOSE="yes"
# Also send mail when warning limit(s) exceeded
MAIL="no"
MAILTO="fedtmule@lv-install1.cph.dk"

# We rely on the Linux /proc/ structure for kernel information
LINUX_TEST=`uname -a | grep "Linux"`
if [ -z "$LINUX_TEST" ] ; then
  echo "exit:253"
  echo "This script only runs on Linux"
  exit 253
fi

# Different kernel versions have different /proc/diskstat formats - we need
# to know the kernel version so we  can act accordingly.
OS_MAJOR=`cat /proc/sys/kernel/osrelease | awk -F\. '{ print $1 }'`
OS_MINOR=`cat /proc/sys/kernel/osrelease | awk -F\. '{ print $2 }'`

# Display kernel version if VERBOSE="yes"
if [ "${VERBOSE}" = "yes" ] ; then
  echo ""
  echo "Kernel major and minor version : ${OS_MAJOR}.${OS_MINOR}"
fi

# Check that kernel is minumum 2.6 and exit if not
if [ "${OS_MAJOR}" -lt "3" -a "${OS_MINOR}" -lt "6" ] ; then
  echo "exit:254"
  echo "Kernel versions prior to 2.6 are not supported by this script"
  echo " "
  exit 254
fi

# Generate list of disks
DISKS=`cat /proc/partitions | egrep "hd[a-z]$|sd[a-z]$" | awk '{ print $4 }'`
# Special selection of /dev/sdb for debugging purposes 31/1-2014
DISKS="sdb"
if [ "${VERBOSE}" = "yes" ] ; then
  echo ""
  echo -ne "Disk(s): "
  for DISK in `echo ${DISKS}`
    do
      echo -ne " ${DISK}"
    done
  echo ""
fi

#
for DISK in `echo ${DISKS}`
do
  # Read current diskstats and read diskstats from previous run of this script
  # then calculate some simple disk performance statistics.
  # Diskstats from /proc/diskstats right now
  DISKSTAT_STRING=`grep "${DISK} " /proc/diskstats |\
   awk '{ print $4 ":" $5 ":" $6 ":" $7 ":" $8 ":" $9 ":" $10 ":" $11 ":" $12 ":" $13 ":" $14 }'`

  # Diskstats from previous run is read from file, then current stat stored
  # in that file for use in next run of this script.
  PREV_FILE="/tmp/${DISK}_prev_diskstats"
  CURRENT_RUN=`date`
  # If this is the first run (or /tmp/ file cleared)
  if [ -f "$PREV_FILE" ] ; then
    PREVIOUS_RUN=`date -r $PREV_FILE`
  else
    PREVIOUS_RUN="${CURRENT_RUN}"
  fi
  if [ -f "${PREV_FILE}" ] ; then
    PREV_DISKSTAT_STRING=`cat ${PREV_FILE}`
    echo "${DISKSTAT_STRING}" > ${PREV_FILE}
  else
    echo "${DISKSTAT_STRING}" > ${PREV_FILE}
    PREV_DISKSTAT_STRING=`echo ${DISKSTAT_STRING}`
  fi
  READS_COMPLETED=`echo ${DISKSTAT_STRING} | awk -F\: '{ print $1 }'`
  PREV_READS_COMPLETED=`echo ${PREV_DISKSTAT_STRING} | awk -F\: '{ print $1 }'`

  # If number of prev reads exceeds current number of reads we conclude that
  # a system restart has been performed so we quietly exit without attempting
  # to calculate disk stats and generating warnings.
  if [ "$PREV_READS_COMPLETED" -gt "$READS_COMPLETED" ] ; then
    if [ "$VERBOSE" = "yes" ] ; then
      echo "exit:0"
      echo "Previous number of reads  greater than current number of reads."
      echo "This may be the first run after (re)boot."
      echo "Quietly exiting with exit code 0 ......"
      exit 0
    else
      echo "exit:0"
      exit 0
    fi
  fi
  DIFF_READS_COMPLETED=`echo "scale=0 ; $READS_COMPLETED - $PREV_READS_COMPLETED" | bc -l`
  # Prevent possibility for divide by zero later in this script
  if [ "$DIFF_READS_COMPLETED" = "0" ] ; then
    DIFF_READS_COMPLETED="1"
  fi
  READS_MERGED=`echo ${DISKSTAT_STRING} | awk -F\: '{ print $2 }'`
  PREV_READS_MERGED=`echo ${PREV_DISKSTAT_STRING} | awk -F\: '{ print $2 }'`
  SECTORS_READ=`echo ${DISKSTAT_STRING} | awk -F\: '{ print $3 }'`
  PREV_SECTORS_READ=`echo ${PREV_DISKSTAT_STRING} | awk -F\: '{ print $3 }'`
  MSECS_SPENT_READING=`echo ${DISKSTAT_STRING} | awk -F\: '{ print $4 }'`
  PREV_MSECS_SPENT_READING=`echo ${PREV_DISKSTAT_STRING} | awk -F\: '{ print $4 }'`
  DIFF_MSECS_SPENT_READING=`echo "scale=0 ; $MSECS_SPENT_READING - $PREV_MSECS_SPENT_READING" | bc -l`
  # Prevent possibility for divide by zero
  if [ "$DIFF_MSECS_SPENT_READING" = "0" ] ; then
    DIFF_MSECS_SPENT_READING="1"
  fi
  MSECS_PER_READ=`echo "scale=0 ; $DIFF_MSECS_SPENT_READING / $DIFF_READS_COMPLETED " | bc -l`

  WRITES_COMPLETED=`echo ${DISKSTAT_STRING} | awk -F\: '{ print $5 }'`
  PREV_WRITES_COMPLETED=`echo ${PREV_DISKSTAT_STRING} | awk -F\: '{ print $5 }'`
  DIFF_WRITES_COMPLETED=`echo "scale=0 ; $WRITES_COMPLETED - $PREV_WRITES_COMPLETED" | bc -l`
  # Prevent possibility for divide by zero
  if [ "$DIFF_WRITES_COMPLETED" = "0" ] ; then
    DIFF_WRITES_COMPLETED="1"
  fi
  WRITES_MERGED=`echo ${DISKSTAT_STRING} | awk -F\: '{ print $6 }'`
  PREV_WRITES_MERGED=`echo ${PREV_DISKSTAT_STRING} | awk -F\: '{ print $6 }'`
  SECTORS_WRITTEN=`echo ${DISKSTAT_STRING} | awk -F\: '{ print $7 }'`
  PREV_SECTORS_WRITTEN=`echo ${PREV_DISKSTAT_STRING} | awk -F\: '{ print $7 }'`
  MSECS_SPENT_WRITING=`echo ${DISKSTAT_STRING} | awk -F\: '{ print $8 }'`
  PREV_MSECS_SPENT_WRITING=`echo ${PREV_DISKSTAT_STRING} | awk -F\: '{ print $8 }'`
  DIFF_MSECS_SPENT_WRITING=`echo "scale=0 ; $MSECS_SPENT_WRITING - $PREV_MSECS_SPENT_WRITING" | bc -l`
  # Prevent possibility for divide by zero
  if [ "$DIFF_MSECS_SPENT_WRITING" = "0" ] ; then
    DIFF_MSECS_SPENT_WRITING="1"
  fi
  MSECS_PER_WRITE=`echo "scale=0 ; $DIFF_MSECS_SPENT_WRITING / $DIFF_WRITES_COMPLETED " | bc -l`
  IOS_IN_PROGRESS=`echo ${DISKSTAT_STRING} | awk -F\: '{ print $9 }'`
  PREV_IOS_IN_PROGRESS=`echo ${PREV_DISKSTAT_STRING} | awk -F\: '{ print $9 }'`
  MSECS_SPENT_DOING_IOS=`echo ${DISKSTAT_STRING} | awk -F\: '{ print $10 }'`
  PREV_MSECS_SPENT_DOING_IOS=`echo ${PREV_DISKSTAT_STRING} | awk -F\: '{ print $10 }'`
  WMSECS_SPENT_DOING_IOS=`echo ${DISKSTAT_STRING} | awk -F\: '{ print $11 }'`
  PREV_WMSECS_SPENT_DOING_IOS=`echo ${PREV_DISKSTAT_STRING} | awk -F\: '{ print $11 }'`
  if [ "${VERBOSE}" = "yes" ] ; then
    echo " "
    echo "======================================================"
    echo " Disk: ${DISK}:"
    echo " measurement start: $PREVIOUS_RUN"
    echo " Measurement end  : $CURRENT_RUN"
    echo "======================================================"
    echo "Milliseconds spent reading             : ${MSECS_SPENT_READING} ($DIFF_MSECS_SPENT_READING)"
    echo "Reads completed                        : ${READS_COMPLETED} (${DIFF_READS_COMPLETED})"
    echo "Reads merged                           : ${READS_MERGED}"
    echo "Sectors read                           : ${SECTORS_READ}"
    echo ">Calculated milliseconds per read<     : >${MSECS_PER_READ}<"
    echo "Milliseconds spent writing             : ${MSECS_SPENT_WRITING} ($DIFF_MSECS_SPENT_WRITING)"
    echo "Writes completed                       : ${WRITES_COMPLETED} ($DIFF_WRITES_COMPLETED)"
    echo "Writes merged                          : ${WRITES_MERGED}"
    echo "Sectors written                        : ${SECTORS_WRITTEN}"
    echo ">Calculated milliseconds per write<    : >${MSECS_PER_WRITE}<"
    echo "I/Os in progress                       : ${IOS_IN_PROGRESS}"
    echo "Milliseconds spent doing I/Os          : ${MSECS_SPENT_DOING_IOS}"
    echo "Weighted milliseconds spent doing I/Os : ${WMSECS_SPENT_DOING_IOS}"
    echo "======================================================"
    echo " "
  fi
  if [ "${MSECS_PER_READ_LIMIT}" -lt "${MSECS_PER_READ}" -o \
       "${MSECS_PER_WRITE_LIMIT}" -lt "${MSECS_PER_WRITE}" ] ; then
    if [ "${VERBOSE}" = "yes" ] ; then
      echo ""
      echo " | WARNING: `uname -n` disk: ${DISK}"
      echo " |  Read average    : ${MSECS_PER_READ} ms (limit:${MSECS_PER_READ_LIMIT})"
      echo " |  Write average   : ${MSECS_PER_WRITE} ms (limit:${MSECS_PER_WRITE_LIMIT})"
      echo ""
    fi
    # Send WARNING mail to monitoring system if MAIL set to "yes"
    if [ "$MAIL" = "yes" ] ; then
      echo -e "WARNING: `uname -n` disk: ${DISK} \n Disk Read Average  ${MSECS_PER_READ} ms (limit:${MSECS_PER_READ_LIMIT}) \n Disk Write Average  ${MSECS_PER_WRITE} ms (limit:${MSECS_PER_WRITE_LIMIT})\n" | \
      mutt -s "`uname -n`: $0: $DISK: Warning" -- ${MAILTO}
    fi
      # Remember disk warning state so we can generate one common
      # exit code when all the systems hard disks have been checked.
      WARNING_STATE="yes"
  fi
done

# Exit with exit code 1 if one or more of the disks exceeded defined
# warning trigger limit(s).
if [ "${WARNING_STATE}" = "yes" ] ; then
  echo "exit:1"
  exit 1
else
  echo "exit:0"
  exit 0
fi
