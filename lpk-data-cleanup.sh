#!/bin/sh

# Created 18 November 2011 by Jens Knudsen (jknudsen@cph.dk)
# Modified 25 September 2013 by Jens Knudsen (jknudsen@cph.dk)
#
# Parking data is copied (pushed) to lv-cphsapcpr:/home/lpk/data
# by the server lpk-gw. Copying is done by a cronjob executed
# by the user lpk on the server lpk-gw. 
#
# For some obscure reason SAP has not been configured to delete
# the copied files after they have been read/processed by SAP
# so the files piled up and eventually created huge problems.
#
# This script implements a cleanup which is designed to be run
# from cron on a daily basis.

# Where the files "live"
DATADIR="/usr/sap/interface/lpk_data/CPR/"

# We keep files for ${MAX_AGE} days. Files older than that are
# deleted.
MAX_AGE="30"

# Files to cleanup (remove files older than MAX_AGE days)
#FILENAMES='Pcnt20*.csv AllPayments20*.csv bwcapa20*.csv'
# Right now we only clean the 'Pcnt20*.csv' files.
#-------------------------------------------------------
# 
# AllPayments*.csv ar no longer copied by crop scripts
# and therefore removed from this cleanup script as well
# 
#-------------------------------------------------------
#FILENAMES='Pcnt20*.csv AllPayments20*.csv bwcapa20*.csv'
FILENAMES='Pcnt20*.csv bwcapa20*.csv'

# Do this (find and remove) for each defined filename
for FNAME in `echo ${FILENAMES}`
do
  #find ${DATADIR} -name ${FNAME} -mtime +${MAX_AGE} -exec ls -la {} \;
  find ${DATADIR} -name ${FNAME} -mtime +${MAX_AGE} -exec rm {} \;
done

# Finish
exit 0
