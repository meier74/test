#!/bin/sh

# Create consolidated daily Pcnt files containing the data from
# all Pcnt files int each it's daily file.

# Go to a neutral directory in order to avoid wildcard confusion
cd /usr/local/bin

# The location of both source and destination files
SRCDIR="/usr/sap/interface/lpk_data/CPR"

# The filespec of the files we are contatenatint into daily files
FILESPEC="Pcnt*.csv"

# Date part of  the relevant filenames (YearMonthDay)
# Must be updated manually if we need to generatefiles from a
# period different than Aug15-Sep20 2013
DATES="20130815 20130816 20130817 20130818 20130819 20130820 20130821 20130822 20130823 20130824 20130825 20130826 20130827 20130828 20130829 20130830 20130831 20130901 20130902 20130903 20130904 20130905 20130906 20130907 20130908 20130909 20130910 20130911 20130912 20130913 20130914 20130915 20130916 20130917 20130918 20130919 20130920"

# For each day listed in DATES variable
for DAY in `echo $DATES`
do
  DAYFILE="${SRCDIR}/DayPcnt${DAY}.csv"
  if [ -f "${DAYFILE}" ] ; then
    echo "Deleting unwanted ${DAYFILE}"
    rm ${DAYFILE}
  fi
  echo ""
  echo "Creating ${DAYFILE}"
  # For every 5 minute file add contents to day file
  for SRCFILE in `ls -1 ${SRCDIR}/Pcnt${DAY}*.csv`
    do
      DUMMY=""
      cat $SRCFILE >> ${DAYFILE}
    done
done
echo ""
chown lpk:sapsys /usr/sap/interface/lpk_data/CPR/DayPcnt*.csv
echo "Done"
