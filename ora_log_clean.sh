#!/bin/sh

# ora_log_clean.sh: Ver.: 1.3.4   March 11. 2016 (jknudsen@cph.dk)
#
# Description: Script to perform cleanup of oracle related logfiles
#
# NOTE: Default TEST_RUN="no" - which means that the script will
#       delete oracle logfiles older than defined with NO QUESTIONS ASKED
#       when activated (typically by a entry in root's crontab).
#       If you want to see the number of files that would be handled by the
#       script before it is actually user you must change TEST_RUN to "yes"
#
#       The delete AGE for the different types of logfiles can be changed
#       by editing and changing the values in this script.
#
# The objective of this script is to create a CPH standard for cleaning
# all oracle related logfiles. This should eliminate the need for the
# many different ways of cleaning (including logrotate) and should provide
# a SINGLE standardized cleanup which is used on all CPH's AIX and Linux
# oracle servers.
#
# Over time this script is expected to evolve into the ONLY script/method
# of cleaning oracle related logfiles in CPH. (Except what oracle itself
# is configured to do with it's logfiles).
#
# Ver 1.0.2: Added special case for hostname lnx-db04 where audit logfiles
#            are placed in a non standard directory structure.
#
# Ver 1.0.5: Changed so all SID's listed in /etc/oratab will be cleaned even
#            when a particular SID is not marked for atomatic startup.
#
# Ver 1.1.1: Added Oracle 11 specific procedure for cleaning the
#            listener log (default location changed).
#
# Ver 1.2.0: Added Oracle 11 specific procedure for cleaning the alertlogfiles
#            located in /oracle/diag/rdbms/<dbname>/trace/alert_<dbname>.log
#
# Ver 1.2.1  alertlog files are now only handled the first day of the month
#
# Ver 1.3.0  alertlog file rotation for NON oracle 11 versions is added as
#            a feature. This was previously done using logrotate
#
# Ver 1.3.1  backuplog removal enhanced. Added compression and removal of
#            sqlnet.log files
#
# Ver 1.3.2  removed misplaced #TODO remark
# Ver 1.3.3  removed OPT="-e" from Linux file pack/compression section
#
# itajekn 11/3-2016
# Ver 1.3.4  Fixed filename restrictions so cleanup of alert files is
#            performed even though the originally predefined naming scheme
#            is not being followed 100% (Oracle administrators cannot be
#            trusted to follow strict literal naming conventions. ;-)  )

#
# If set to "yes" do not perform any actions, only display to stdout
# "yes" setting probably only useful for debugging/testingvalidation purpose.

TEST_RUN="no"

# Delete files older than (days) 
ALERT_AGE=182
AUDIT_AGE=92
BACKUP_AGE=365
LISTENER_AGE=92
TRACE_AGE=92
CORE_AGE=92
SQLNET_AGE=182

# Mail adress(es) for people that should receive alert if script fails
# Multiple adresses (if used) must be separated by space
#
#RECIPIENTS="jknudsen@cph.dk j.knudsen@cph.dk"
RECIPIENTS="E-ITDOracleDBA@cph.dk" # Oracle admins mail-liste

# This script does it's best to be selfconfiguring - to do that we need to
# extract SID information from the /etc/oratab file.
ORATAB="/etc/oratab"

# Where all the logfiles are assumed to be located (assuming that the CPH
# standard has been applied when creating the logging directory structure)
LOG_BASEDIR="/oracle/admin"

# Check for /etc/oratab file and send warning mail(s) if file is not present 
# Then exit with exit code 1 - we cannot proceed without knowing the oracle
# SID names that CPH is using as part of the oracle log directory structure.
if [ ! -f "${ORATAB}" ] ; then 
  for RECIPIENT in `echo ${RECIPIENTS}`
  do
    echo "
    `uname -n`: $0: The \"${ORATAB}\" file is missing. Script stopped.  
    " |\
    mailx -s "`uname -n`: $0: No /etc/oratab present. Abort." ${RECIPIENT}
  done
  exit 1
fi

# Determine whether we are on a Linux or a AIX system in order to compensate
# for differences in the 'echo' command output (different default option)
# Also choose the correct compression command for the relevant O/S
SYSTEM_OS="`uname`"

# Determine echo option to use
case $SYSTEM_OS in 
Linux)
  # On Linux escape character interpretation is NOT the default
  #OPT="-e"
  COMPRESS="bzip2"
  ;;
AIX)
  # On AIX escape character interpretation is the default
  OPT=""
  COMPRESS="compress"
  ;;
*)
  # On everything other than Linux and AIX: Who cares ;-)
  OPT=""
  ;;
esac

# Oracle 11 detection (dependent on Oracle administrators 
# following the default syntax within /etc/oratab)
if [ -f "/etc/oratab" ] ; then
  ORA_VER=`cat /etc/oratab |\
           grep "11\." |\
           awk -F\: '{print $2 }' |\
           awk -F\/ '{ print $4 }' |\
           sort -u`
  ORA_MAJ_VER=`echo ${ORA_VER} |\
               awk -F\. '{ print $1 }' |\
               sort -u`
else
  ORA_VER="Unknown"
fi

if [ "${TEST_RUN}" = "yes" ] ; then
  echo "Oracle version: ${ORA_VER}"
  echo "Oracle major version: ${ORA_MAJ_VER}"
fi

#################################
# - Cleanup of listener log files -
#################################
# +------------------------------------------------------------------------+
# | Rotate listener.log once every month on the first day of the month.
# | Compress the rotated logfile, and then delete any previously rotated and
# | compressed listener.log files older than LISTENER_AGE days.
# +------------------------------------------------------------------------+

# Day number and timestamp defined
DAY="`date +%d`"
TIMESTAMP="`date '+%Y%m%d'`"


# --------------------------------
# Special case Oracle 11 alertlogs
# --------------------------------
#ALERTLOG_SPEC="'/oracle/diag/rdbms/<dbnavn>/<DBNAVN>/trace/alert_<DB_NAVN>.log'"
# Rotate/delete/compress/delete alertlog files on the first day of the month
ALERTLOG_DIRS="/oracle/diag/rdbms/*/*/trace/"
if [ "${DAY}" = "01" ] ; then
  if [ "${ORA_MAJ_VER}" = "11" ] ; then
    for ALERTLOG_DIR in `echo ${ALERTLOG_DIRS}`
    do
      if [ "${TEST_RUN}" = "yes" ] ; then
        echo "   O R A C L E   11  alertlog special case invoked "
        echo "       --- Alert logfiles in ${ALERTLOG_DIR} ---"
        echo "Alert logfiles that would be deleted prior to rotation (if any)"
        find ${ALERTLOG_DIR} -name 'alert_*.log*' -mtime +${ALERT_AGE} -exec ls -la {} \;
        echo "Alert logfiles to be rotated and compressed on 1'st of month (if any)"
        find ${ALERTLOG_DIR} -name 'alert_*.log.[Z|bz2]' -exec ls -la {} \; 
      else
        find ${ALERTLOG_DIR} -name 'alert_*.log*.[Z|bz2]' -mtime +${ALERT_AGE} -exec rm {} \;
        for FIL in `find ${ALERTLOG_DIR} -name 'alert_*.log'`
        do
          mv ${FIL} ${FIL}-${TIMESTAMP}TMP
          bzip2 ${FIL}-${TIMESTAMP}TMP
          cp ${FIL}-${TIMESTAMP}TMP.bz2 ${FIL}-${TIMESTAMP}.bz2
          chown oracle:dba ${FIL}-${TIMESTAMP}.bz2
          mv ${FIL}-${TIMESTAMP}TMP.bz2 ${FIL}
          cat /dev/null > ${FIL}
        done
      fi
    done
  fi
fi

# ---------------------------------------------------------
# Special case Oracle 11: listener logfile location changed
# ---------------------------------------------------------
# /oracle/diag/tnslsnr/lnx-pora101/listener/trace/listener.log
LSNR_DIR="/oracle/diag/tnslsnr/`hostname`/listener/trace"
if [ "${ORA_MAJ_VER}" = "11" ] ; then
  if [ "${TEST_RUN}" = "yes" ] ; then
    echo "   O R A C L E   11  listener special case invoked "
    echo "--- Listener logfiles in ${LSNR_DIR} ---"
    echo "Listener logfiles that would be deleted prior to rotation (if any)"
    find ${LSNR_DIR} -name 'listener*.log.*.[Z|bz2]' -mtime +${LISTENER_AGE} -exec ls -la {} \;
    echo "Listener logfiles to be rotated and compressed on 1'st of month (if any)"
    find ${LSNR_DIR} -name 'listener*.log' -exec ls -la {} \; 
  else
    if [ "${DAY}" = "01" ] ; then
      find ${LSNR_DIR} -name 'listener*.log.*.[Z|bz2]' -mtime +${LISTENER_AGE} -exec rm {} \;
      for FILE in `ls ${LSNR_DIR}listener*.log`
      do
        cp ${FILE} ${FILE}.${TIMESTAMP}
        # Compress command depends on platform (AIX/LInux)
        $COMPRESS ${FILE}.${TIMESTAMP}
        chown oracle:dba ${FILE}.${TIMESTAMP}*
        # Create new listener file
        echo ${OPT} "\c " > ${FILE}
      done
    fi
  fi
fi

# ------------------------------------------------------
# For all other versions than Oracle 11 do the following
# listener logfile cleanup. This is also done on Oracle
# 11 server in order to cover situations where there are
# multiple versions of Oracle is used.
# ------------------------------------------------------
# For each line in /etc/oratab
for LSNR_DIR in `cat /etc/oratab |\
                egrep -v "^#|^$" |\
                grep ":Y$" |\
                awk -F\: '{ print $2 }' |\
                sort -u `
do
  LSNR_DIR=$LSNR_DIR/network/log/
  if [ "${TEST_RUN}" = "yes" ] ; then
    echo ""
    echo "--- Listener logfiles in ${LSNR_DIR} ---"
    echo "Listener logfiles that would be deleted prior to rotation (if any)"
    find ${LSNR_DIR} -name 'listener*.log.*.[Z|bz2]' -mtime +${LISTENER_AGE} -exec ls {} \;
    echo "Listener logfiles to be rotated and compressed on 1'st of month (if any)"
    find ${LSNR_DIR} -name 'listener*.log' -exec ls {} \; 
    echo ""
  else
    if [ "${DAY}" = "01" ] ; then
      find ${LSNR_DIR} -name 'listener*.log.*.[Z|bz2]' -mtime +${LISTENER_AGE} -exec rm {} \;
      for FILE in `ls ${LSNR_DIR}listener*.log`
      do
        cp ${FILE} ${FILE}.${TIMESTAMP}
        # Compress command depends on platform (AIX/LInux)
        $COMPRESS ${FILE}.${TIMESTAMP}
        chown oracle:dba ${FILE}.${TIMESTAMP}* 
        echo ${OPT} "\c" > ${FILE}
      done
    fi
  fi 
done

# +---------------------------------------------------------------+
# | *NON* Oracle 11  ( in reality 9 and 10 ) alert log rotation
# | typical path and file: /oracle/admin/ARIS/bdump/alert_ARIS.log
# +---------------------------------------------------------------+
ALERTLOG_DIRS="/oracle/admin/*/bdump"
if [ "${ORA_MAJ_VER}" != "11" ] ; then
  if [ "${DAY}" = "01" ] ; then
    if [ $TEST_RUN = "yes" ] ; then
      echo "--- Evaluating alert log rotation for NON Oracle 11 versions" 
      for FIL in `find ${ALERTLOG_DIRS} -name 'alert_*.log'`
        do
          echo "${FIL}"
          # udskift med aktuel alertlog rotation
          #echo "mv ${FIL} ${FIL}-${TIMESTAMP}TMP"
          #echo "bzip2 ${FIL}-${TIMESTAMP}TMP"
          #echo "cp ${FIL}-${TIMESTAMP}TMP.bz2 ${FIL}-${TIMESTAMP}.bz2"
          #echo "chown oracle:dba ${FIL}-${TIMESTAMP}.bz2"
          #echo "mv ${FIL}-${TIMESTAMP}TMP.bz2 ${FIL}"
          #echo "cat /dev/null > ${FIL}"
        done
    else
      for FIL in `find ${ALERTLOG_DIRS} -name 'alert_*.log'`
        do
          mv ${FIL} ${FIL}-${TIMESTAMP}TMP
          bzip2 ${FIL}-${TIMESTAMP}TMP
          cp ${FIL}-${TIMESTAMP}TMP.bz2 ${FIL}-${TIMESTAMP}.bz2
          chown oracle:dba ${FIL}-${TIMESTAMP}.bz2
          mv ${FIL}-${TIMESTAMP}TMP.bz2 ${FIL}
          cat /dev/null > ${FIL}
        done
    fi
  fi
fi

# +------------------------------------------------------------------------+
# | This is the beginning of the SID-loop where most of the SID dependent  |
# | stuff happens                                                          |
# +------------------------------------------------------------------------+
# For every oracle instance marked for automatic start
# (lines ending with a ":Y" ) in /etc/oratab do some work
# 31/7-2013 Added exception from the ":Y" requirement - The atos user will
# start the database, so it is not marked for automatic start vis /etc/oratab
for ORASID in `cat /etc/oratab |\
                 egrep -v "^#|^$" |\
                 egrep ":Y$|:N$" |\
                 awk -F\: '{ print $1 }' |\
                 sort -u `
do

if [ $TEST_RUN = "yes" ] ; then
  echo ""
  echo " ---  Evaluating logfiles for Oracle SID: [ ${ORASID} ] ---"
fi

#################################
# - Cleanup of alert log files -
#################################
# Delete files older than defined in  it's respective [....]_AGE
# variable (see in beginning of this script for defined values).

FILESPEC="alert*.log"

CLEAN_PATH="${LOG_BASEDIR}/${ORASID}/bdump/"
if [ -d ${CLEAN_PATH} ] ; then
if [ $TEST_RUN = "yes" ] ; then
  echo $OPT "${CLEAN_PATH}${FILESPEC} files older than ${ALERT_AGE} days: \c"
  find ${CLEAN_PATH} -type f -name ${FILESPEC} -mtime +${ALERT_AGE} -exec ls -la {} \; | wc -l
else
  find ${CLEAN_PATH} -type f -name ${FILESPEC} -mtime +${ALERT_AGE} -exec rm {} \;
fi
  else
    if [ $TEST_RUN = "yes" ] ; then
      echo "${CLEAN_PATH} no such directory, ignored..."
    fi
fi

#################################
# - Cleanup of audit log files -
#################################
# Delete files older than defined in  it's respective [....]_AGE
# variable (see in beginning of this script for defined values).
FILESPEC="*.aud"

CLEAN_PATH="${LOG_BASEDIR}/${ORASID}/adump/"
if [ -d ${CLEAN_PATH} ] ; then
if [ $TEST_RUN = "yes" ] ; then
  echo $OPT "${CLEAN_PATH}${FILESPEC} files older than ${AUDIT_AGE} days: \c"
  find ${CLEAN_PATH} -type f -name ${FILESPEC} -mtime +${AUDIT_AGE} -exec ls -la {} \; | wc -l
else
  find ${CLEAN_PATH} -type f -name ${FILESPEC} -mtime +${AUDIT_AGE} -exec rm {} \;
fi
  else
    if [ $TEST_RUN = "yes" ] ; then
      echo "${CLEAN_PATH} no such directory, ignored..."
    fi
fi

# Exception from the CPH standard directory structure for audit file location
# on lnx-db04
if [ "`uname -n`" = "lnx-db04" ] ; then
  FILESPEC="*.aud"
  CLEAN_PATH="/data/u01/app/oracle/product/9.2.0/rdbms/audit/"
  if [ -d ${CLEAN_PATH} ] ; then
  if [ $TEST_RUN = "yes" ] ; then
    echo $OPT "${CLEAN_PATH}${FILESPEC} files older than ${AUDIT_AGE} days: \c"
    find ${CLEAN_PATH} -type f -name ${FILESPEC} -mtime +${AUDIT_AGE} -exec ls -la {} \; | wc -l
  else
    find ${CLEAN_PATH} -type f -name ${FILESPEC} -mtime +${AUDIT_AGE} -exec rm {} \;
  fi
    else
      if [ $TEST_RUN = "yes" ] ; then
        echo "${CLEAN_PATH} no such directory, ignored..."
      fi
  fi
fi


#################################
# - Cleanup of backup log files -
#################################
# Delete files older than defined in  it's respective [....]_AGE
# variable (see in beginning of this script for defined values).
FILESPEC1="backup*.log"
FILESPEC2="backup_*.out_*-*"

CLEAN_PATH="${LOG_BASEDIR}/${ORASID}/backup/logs/"
if [ -d ${CLEAN_PATH} ] ; then
if [ $TEST_RUN = "yes" ] ; then
  echo $OPT "${CLEAN_PATH}${FILESPEC1} files older than ${BACKUP_AGE} days: \c"
  find ${CLEAN_PATH} -type f -name ${FILESPEC1} -mtime +${BACKUP_AGE} -exec ls -la {} \; | wc -l
  echo $OPT "${CLEAN_PATH}${FILESPEC2} files older than ${BACKUP_AGE} days: \c"
  find ${CLEAN_PATH} -type f -name ${FILESPEC2} -mtime +${BACKUP_AGE} -exec ls -la {} \; | wc -l
else
  find ${CLEAN_PATH} -type f -name ${FILESPEC1} -mtime +${BACKUP_AGE} -exec rm {} \; 
  find ${CLEAN_PATH} -type f -name ${FILESPEC2} -mtime +${BACKUP_AGE} -exec rm {} \;
fi
  else
    if [ $TEST_RUN = "yes" ] ; then
      echo "${CLEAN_PATH} no such directory, ignored..."
    fi
fi

#################################
# - Cleanup of core files -
#################################
# Delete files older than defined in  it's respective [....]_AGE
# variable (see in beginning of this script for defined values).
FILESPEC="core*"

CLEAN_PATH1="${LOG_BASEDIR}/${ORASID}/bdump/"
if [ -d ${CLEAN_PATH1} ] ; then
if [ $TEST_RUN = "yes" ] ; then
  echo $OPT "${CLEAN_PATH1}${FILESPEC} files older than ${CORE_AGE} days: \c"
  find ${CLEAN_PATH1} -type f -name ${FILESPEC} -mtime +${CORE_AGE} -exec ls -la {} \; | wc -l
else
  find ${CLEAN_PATH1} -type f -name ${FILESPEC} -mtime +${CORE_AGE} -exec rm {} \;
fi
  else
    if [ $TEST_RUN = "yes" ] ; then
      echo "${CLEAN_PATH1} no such directory, ignored..."
    fi
fi

CLEAN_PATH2="${LOG_BASEDIR}/${ORASID}/cdump/"
if [ -d ${CLEAN_PATH2} ] ; then
if [ $TEST_RUN = "yes" ] ; then
  echo $OPT "${CLEAN_PATH2}${FILESPEC} files older than ${CORE_AGE} days: \c"
  find ${CLEAN_PATH2} -type f -name ${FILESPEC} -mtime +${CORE_AGE} -exec ls -la {} \; | wc -l
else
  find ${CLEAN_PATH2} -type f -name ${FILESPEC} -mtime +${CORE_AGE} -exec rm {} \; 
fi
  else
    if [ $TEST_RUN = "yes" ] ; then
      echo "${CLEAN_PATH2} no such directory, ignored..."
    fi
fi

#################################
# - Cleanup of tracefiles -
#################################
# Delete files older than defined in  it's respective [....]_AGE
# variable (see in beginning of this script for defined values).
# TODO: Oracle 11 may need some cleanup in the directory structure
#       /oracle/diag/rdbms/<sid>/SID/trace/
FILESPEC="*.trc"

CLEAN_PATH1="${LOG_BASEDIR}/${ORASID}/bdump/"
if [ -d ${CLEAN_PATH1} ] ; then
if [ $TEST_RUN = "yes" ] ; then
  echo $OPT "${CLEAN_PATH1}${FILESPEC} files older than ${TRACE_AGE} days: \c"
  find ${CLEAN_PATH1} -type f -name ${FILESPEC} -mtime +${TRACE_AGE} -exec ls -la {} \; | wc -l
else
  find ${CLEAN_PATH1} -type f -name ${FILESPEC} -mtime +${TRACE_AGE} -exec rm {} \;
fi
  else
    if [ $TEST_RUN = "yes" ] ; then
      echo "${CLEAN_PATH1} no such directory, ignored..."
    fi
fi

CLEAN_PATH2="${LOG_BASEDIR}/${ORASID}/udump/"
if [ -d ${CLEAN_PATH2} ] ; then
if [ $TEST_RUN = "yes" ] ; then
  echo $OPT "${CLEAN_PATH2}${FILESPEC} files older than ${TRACE_AGE} days: \c"
  find ${CLEAN_PATH2} -type f -name ${FILESPEC} -mtime +${TRACE_AGE} -exec ls -la {} \; | wc -l
else
  find ${CLEAN_PATH2} -type f -name ${FILESPEC} -mtime +${TRACE_AGE} -exec rm {} \;
fi
  else
    if [ $TEST_RUN = "yes" ] ; then
      echo "${CLEAN_PATH2} no such directory, ignored..."
    fi
fi

# +------------------------------------------------------------------------+
# |       This is the end of the SID-loop where it all happens            |
# +------------------------------------------------------------------------+
done

#########################################
# - Rotate and cleanup SQLnet logfile - #
#########################################

FILE=""
if [ $TEST_RUN = "yes" ] ; then
  echo ""
  echo " --- Evaluating SQLnet logfiles ---"
fi

for ORA_HOME in `cat /etc/oratab | egrep -v "^$|^#" |\
            awk -F\: '{ print $2 }' | sort -u`
do 
  if [ $TEST_RUN = "yes" ] ; then
    #echo " --- searching for logfiles in ${ORA_HOME}/network/log/ ---"
    FILE="`find ${ORA_HOME}/network/log/ -name 'sqlnet.log' -exec ls -a1 {} \;`"
    if [ ! -z "${FILE}" ] ; then
      echo "sqlnet.log file(s) to be rotated and compressed on day 01 (today is day ${DAY})"
      echo "${FILE}"
    fi
    echo $OPT "${ORA_HOME}/network/log/sqlnet.log- files older than ${SQLNET_AGE} days: \c"
    find ${ORA_HOME}/network/log -name 'sqlnet.log-*' -mtime +${SQLNET_AGE} -exec ls -la {} \; | wc -l
  else
    if [ "${DAY}" = "01" ] ; then
      FILE="`find ${ORA_HOME}/network/log/ -name 'sqlnet.log' -exec ls -a1 {} \;`"
      cp ${FILE} ${FILE}-${TIMESTAMP}
      cat /dev/null > ${FILE}
      ${COMPRESS} ${OPT} ${FILE}-${TIMESTAMP}
    fi
    find ${ORA_HOME}/network/log -name 'sqlnet.log-*' -mtime +${SQLNET_AGE} -exec rm {} \;
  fi
done

if [ $TEST_RUN = "yes" ] ; then
  echo ""
  echo " Done"
  echo ""
fi
