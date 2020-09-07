#!/bin/sh

# /usr/local/bin/lpkGetFile.sh Ver. 1.1.2 23/9.2013 (jknudsen@cph.dk)
#
# Change: # 19/9-2013 (itajekn) 
# Added the user root's public key to the user sap's authorisation on the lpk
# server so fetching files or mounting the lpk fileshare as a SSHFS filesystem
# from lv-cphsapcpr can be done without requiring someone to physically type
# the password.

# Script designed to copy selected files related to the CPH parking business
# from the Windows server located in the Lufthavnsparkeringen DMZ to the
# lv-cphsapcpr SAP server. Must be run as the user root. Can be run on the
# command line as well as via root's crontab like this:
# /usr/local/bin/lpkGetFile.sh
#
# It is assumed that SAP reads the files every 15 minutes at 0,15,30,45
# the following is a possible root crontab entry:
#
# # Check for new lpk files. If new files are detected then copy the new
# # files from the LPK server to the SAP server. 
# 13,28,43,58 * * * * /usr/local/bin/lpkGetFile.sh

# Contacts: 
# SAP: iTelligence: Brian Skjøt adsen (Brian.Skjot.Madsen@itelligence.dk)
# SAP: iTelligence: Christian Petersen (Ccrittian.Petersen@iTelligence.dk)
# SAP: iTelligence: Kaj Arvad Larsen (Kaj.Arvad.Larsenitelligence.dk)
# Lufthavnsparkeringen: Kim De Lony (kim.de.lony@cph.dk)
# CPH BackOffice Unix/Linux: Thomas Meier thomas.meier@cph.dk

# Windows server located in the Lufthavnsparkeringen DMZ, (administered by
# the personnel working with the AirPortParking (Lufthavnsparkering) solution.
# Some details for INFO:
# SOURCE_HOST="10.153.143.67"
# SOURCE_ALLPAY="\ZMS-Share\AllPay"
# SOURCE_COUNTER="\ZMS-Share\Counter"
# The ZMS-Share is the '/' directory for the 'sap' SFTP user
# SOURCE_USER="sap"
# SOURCE_CRED="password can be found encrypted in the 'password database'"

# The source is being used for SFTP access by mounting a SSHFS filesystem on
# this # SAP server. The SSHFS filesystem is automatically mounted and
# unmounted every time this script needs access. Therefore the following
# (very long) line in /etc/fstab s required:
#
#  sshfs,noauto,users,exec,allow_other,reconnect,transform_symlinks,idmap=user 0 sshfs#sap@10.153.143.67:/ /home/lpk/lpk-sshfsmount  fuse    comment=sshfs,noauto,users,exec,allow_other,reconnect,transform_symlinks,idmap=user 0
#
# The mount procedure does not require someone to manually type aa password.
# The root@lv-cphsapcpr public key has been distributed to the 'sap' user on
# the source server.

# Where the source SFTP home directory is mounted on this the SAP server
 SOURCE_SSHFS="/home/lpk/lpk-sshfsmount"

# Mount the SSHFS filesystem (it is actually 'tweaking' a SFTP connection)
# and creating an abstraction layer that makes it appear to be an ordinary
# Unix/Linux filesystem
mount ${SOURCE_SSHFS}

# Check if the SSHFS filesystem is mounted, and exit if not.
# Also e-mail error to the fedtmule surveillance system.
if [ "`mount | grep lpk-sshfsmount`" = "" ] ; then
  echo "
  On `uname -n` the SSHFS filesystem mount failed, a single failure is OK
  because the missing lpk files will simply be copied during the next
  invocation of the script (which is run by cron 4 times per hour).

  You may test by issuing the command \'mount /home/lpk/lpk-sshfsmount\'
  as the user root on `uname -n`.

  " | mailx -s "`uname -n`: SSHFS mountpoint missing" fedtmule@lv-install.cph.dk
  exit 1
fi


#==================================================
# Handle AllPayments*.csv files
#==================================================

# -------------------------------------------------
#
#
# itajekn 22/10-2015 AllPayments*.csv is NO LONGER
# copied by this script
#
#
# -------------------------------------------------

# Source AllPayments<date>.csv files are located here
 ALLPAY_SRC="/home/lpk/lpk-sshfsmount/AllPay"

# File pattern
 ALLPAY_PATTERN="AllPayments*.csv"

# Where the copied files lives on this SAP server
 ALLPAY_DEST="/usr/sap/interface/lpk_data/CPR"

# Change directory to something neutral so we do not get strange 
# results from the script due to the shell expanding filename wildcards
# if the working directory is full of files with a particular pattern.
cd /home/lpk

# Oldest existing file that has already been copied to this system
 OLDEST_FILE="`ls -trd ${ALLPAY_DEST}/${ALLPAY_PATTERN} | tail -1 `"

# Exit and give up if we do not find a reference "oldest file"
# itajekn 22/10-2015 AllPayments*.csv is NO LONGER
# copied by this script
#if [ "$OLDEST_FILE" = "" ] ; then
#  echo "There is no oldest AllPayment file present, Script $0  on `uname -n`
#        stopped. Something is seriously wrong please look into it" |\
#  mailx -s "`uname -n`: No oldest AllPayment file" fedtmule@lv-install.cph.dk 
#  umount ${SOURCE_SSHFS}
#  exit 1
#fi

# Copy matching files newer than the oldest matching reference file 
# (already/previously copied) on this system. Use touch to preserve
# the original timestamps

    # ######################################################
    #
    # Include archived files for 2013 into the search for newer files
    # USE ONLY FOR CATCH UP DELAYED COPY DUE TO MALFUNCTION
    #
    # ######################################################
    # This section should normally be commented away
    # ------------------------------------------------------------------------
    #for FILENAME in `find ${ALLPAY_SRC}/2013 -maxdepth 1 -name $ALLPAY_PATTERN -newer ${OLDEST_FILE} -exec ls {} \;`
    #do
    #  FILE=`basename $FILENAME`
    #  cp $FILENAME ${ALLPAY_DEST}/${FILE}.part
    #  touch -r $FILENAME ${ALLPAY_DEST}/${FILE}.part
    #  mv ${ALLPAY_DEST}/${FILE}.part ${ALLPAY_DEST}/${FILE}
    #  chown lpk:sapsys ${ALLPAY_DEST}/${FILE}
    #  chmod 744 ${ALLPAY_DEST}/${FILE}
    #done
    # -------------------------------------------------------------------------

# The daily files can be found here 
# itajekn 22/10-2015 AllPayments*.csv is NO LONGER
# copied by this script
#for FILENAME in `find $ALLPAY_SRC -maxdepth 1 -name $ALLPAY_PATTERN -newer ${OLDEST_FILE} -exec ls {} \;`
#do
#  FILE=`basename $FILENAME`
#  cp $FILENAME ${ALLPAY_DEST}/${FILE}.part
#  touch -r $FILENAME ${ALLPAY_DEST}/${FILE}.part
#  mv ${ALLPAY_DEST}/${FILE}.part ${ALLPAY_DEST}/${FILE}
#  chown lpk:sapsys ${ALLPAY_DEST}/${FILE}
#  chmod 744 ${ALLPAY_DEST}/${FILE}
#done

#==================================================
# Handle Pcnt*.csv files
#==================================================

# Source Pcnt<date>.csv files are located here
PCNT_SRC="/home/lpk/lpk-sshfsmount/Counter"

# File pattern
PCNT_PATTERN="Pcnt*.csv"

# Where the copied files lives on this SAP server
PCNT_DEST="/usr/sap/interface/lpk_data/CPR"

# Oldest existing file that has already been copied to this system
 OLDEST_FILE="`ls -trd ${PCNT_DEST}/${PCNT_PATTERN} | tail -1 `"

# Exit and give up if we do not find a reference "oldest file"
if [ "$OLDEST_FILE" = "" ] ; then
  echo "There is no oldest Pcnt file present, Script $0  on `uname -n`
        stopped. Something is seriously wrong please look into it" |\
  mailx -s "`uname -n`: No oldest AllPayment file" fedtmule@lv-install.cph.dk 
  umount ${SOURCE_SSHFS}
  exit 1
fi

# Copy matching files newer than the oldest matching reference file 
# (already/previously copied) on this system.  Use touch to preserve
# the original timestamps

    # Include archived files for 2013 into the search for newer files
    # USE ONLY FOR CATCH UP DELAYED COPY DUE TO MALFUNCTION
    # This section should normally be commented away
    # -------------------------------------------------------------------------
    #for FILENAME in `find ${PCNT_SRC}/2013 -maxdepth 1 -name $PCNT_PATTERN -newer ${OLDEST_FILE} -exec ls {} \;`
    #do
    #  FILE=`basename $FILENAME`
    #  cp $FILENAME ${PCNT_DEST}/${FILE}.part
    #  touch -r $FILENAME ${PCNT_DEST}/${FILE}.part
    #  mv ${PCNT_DEST}/${FILE}.part ${PCNT_DEST}/${FILE}
    #  chown lpk:sapsys ${PCNT_DEST}/${FILE}
    #  chmod 744 ${PCNT_DEST}/${FILE}
    #done
    # -------------------------------------------------------------------------

# The daily files can be found here 
for FILENAME in `find ${PCNT_SRC} -maxdepth 1 -name ${PCNT_PATTERN} -newer ${OLDEST_FILE} -exec ls {} \;`
do
  FILE=`basename $FILENAME`
  cp $FILENAME ${PCNT_DEST}/${FILE}.part
  touch -r $FILENAME ${PCNT_DEST}/${FILE}.part
  mv ${PCNT_DEST}/${FILE}.part ${PCNT_DEST}/${FILE}
  chown lpk:sapsys ${PCNT_DEST}/${FILE}
  chmod 744 ${PCNT_DEST}/${FILE}
done

# Unmount the SSHFS filesystem
umount ${SOURCE_SSHFS}
