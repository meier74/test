#!/bin/bash

# Ver. 0.1 29/1-2014 jenknu@cph.dk

# Display /proc/diskstats data in a human readable format

# The single DEVICE from which we want to view/present diskstats
DEVICE="dm-7"

# Get the diskstats data
DISKSTATS="`cat /proc/diskstats | grep "${DEVICE}"`"

# Isolate the individual numbers
DEV_MAJ="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $1 }' `"
DEV_MIN="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $2 }' `"
DEV_NAM="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $3 }' `"
READS_COMPLETED_SUCCESFULLY="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $4 }' `"
READS_MERGED="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $5 }' `"
SECTORS_READ="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $6 }' `"
TIME_SPENT_READING="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $7 }' `"
WRITES_COMPLETED="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $8 }' `"
WRITES_MERGED="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $9 }' `"
SECTORS_WRITTEN="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $10 }' `"
TIME_SPENT_WRITING="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $11 }' `"
IOS_CURRENTLY_IN_PROGRESS="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $12 }' `"
TIME_SPENT_DOING_IOS="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $13 }' `"
WEIGHTED_TIME_SPENT_DOING_IOS="`echo ${DISKSTATS} | grep "dm-7" | awk '{ print $14 }' `"

# Output the separate diskstat data with description on separate lines

echo ""
echo " >>> Devicename: ${DEV_NAM} Major: ${DEV_MAJ} Minor: ${DEV_MIN} <<<"
echo "      ----- Reads -----"
echo "Reads completed succesfully:          ${READS_COMPLETED_SUCCESFULLY}"
echo "Reads merged:                         ${READS_MERGED}"
echo "Sectors read:                         ${SECTORS_READ}"
echo "Time spent reading (ms):              ${TIME_SPENT_READING}"
echo ""
echo "      ----- Writes -----"
echo "Writes completed:                     ${WRITES_COMPLETED}"
echo "Writes merged:                        ${WRITES_MERGED}"
echo "Sectors written:                      ${SECTORS_WRITTEN}"
echo "Time spent writing (ms)               ${TIME_SPENT_WRITING}"
echo ""
echo "      ----- Combined r/w stats -----"
echo "Number of I/Os currently in progress: ${IOS_CURRENTLY_IN_PROGRESS}"
echo "Time spent doing I/Os (ms):           ${TIME_SPENT_DOING_IOS}"
echo "Weighted time doing I/Os (ms):        ${WEIGHTED_TIME_SPENT_DOING_IOS}"

