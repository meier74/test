#!/bin/bash
#!/bin/sh
# set -x
VERSION="6"
# FTP Server address, path and user/password
# ==========================================
#FTP_SERVER="lv-install1.cph.dk"
#FTP_USER="diskalert"
#FTP_PASS="D2013Alert"
#MAILTO="thomas.meier@cph.dk"

# Path to executables that needs to be available when this script is run
# without sufficient environment.
# ======================================================================
PATH=$PATH:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin
export PATH

# Shell script to monitor or watch the disk space
# It will send an email to $ADMIN, if the (free available) percentage of space is >= 90%.
# -------------------------------------------------------------------------
# Set admin email so that you can get email.
ADMIN="nobody"
# set alert level 90% is default
ALERT=98
#Exclude list of unwanted monitoring, if several partions then use "|" to separate the partitions.
# An example: EXCLUDE_LIST="/dev/hdd1|/dev/hdc5"
EXCLUDE_LIST=""
#
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#
function main_prog() {
while read output;
do
#echo $output
  usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1)
  partition=$(echo $output | awk '{print $2}')
  if [ $usep -ge $ALERT ] ; then
logger -p user.err "E-123456 Disksystem $VERSION $(hostname) $partition $usep%"
    if [ "$ADMIN" != "nobody" ] ; then
     echo "Running out of space \"$partition ($usep%)\" on server $(hostname), $(date)" | \
     mail -s "Alert: Almost out of disk space $usep%" $ADMIN
  fi
fi
done
}
if [ "$EXCLUDE_LIST" != "" ] ; then
  df -hPl --type=ext3 --type=ext4 --type=reiserfs --type=ext2 | grep -vE "^Filesystem|tmpfs|cdrom|${EXCLUDE_LIST}" | awk '{print $5 " " $6}' | main_prog
else
  df -hPl --type=ext3 --type=ext4 --type=reiserfs --type=ext2 | grep -vE "^Filesystem|tmpfs|cdrom" | awk '{print $5 " " $6}' | main_prog
fi

# Attempt to update this script
# =============================

# Change directory to diskalert directory
# -------------------------------------
#cd /home/diskalert

#wget nyt script hvis der er sådan et
OUTPUT="`wget http://lv-install/repo/MISC/MonitoringScripts/diskAlert.sh-new 2>/dev/null`"

#EXITCODE="`echo $?`" 
#if [ $EXITCODE = 0 ] ; then
#dummy= ingenting 
#fi
# (Attempt to) retrieve <script>-new from FTP server
# --------------------------------------------------
#ftp -n -i  $FTP_SERVER <<EOF 1>/dev/null 2>/dev/null
#user $FTP_USER $FTP_PASS
#get diskAlert-new
#quit
#EOF

# If <script>-new exists locally may be used for updating the
# diskAlert script (if integer VERSION is higher than the existing).
# --------------------------------------------------------------------
if [ -f diskAlert.sh-new ] ; then
  NEWVERSION=`grep "^VERSION=" diskAlert.sh-new | awk -F\" '{ print $2 }'`
  if [ ${NEWVERSION} -gt ${VERSION} ] ; then
    mv diskAlert.sh diskAlert.sh-old
    mv diskAlert.sh-new diskAlert.sh
    chmod 755 diskAlert.sh
    #DEBUG: echo "Version: New version (${NEWVERSION}) distributed"
  else
    rm diskAlert.sh-new
    #DEBUG: echo "Version: (${VERSION}) OK"
  fi
fi

