#!/bin/sh

# Script to retrieve delivery files from LPK 
# Uses Linux ftps and expect scripting
# Copenhagen Airports 11 Okt. 2017 Thomas Meier

VERSION="1.0"


# Host/user/phrase definitions
# ----------------------------
  HOST="10.193.4.205"
  USER="srvlpkdata"
  PHRASE="xJ4Y4cbDcgswcHisZ76R"

# Temporary local file storage
# ----------------------------
LPK_TMP="/tmp/lpk/"

# Remote KMD directory where we want to look for files to fetch
# -------------------------------------------------------------
SRC_DIR="/"

# Local temporary storage where we place the fetched files from KMD
# -----------------------------------------------------------------
TGT_DIR="/home/lpk/testnytsite/"

# Where we 'mv' the files so SAP can see them (only after download is finished)
# prevent SAP from seeing the incomplete files during SFTP transfer
# ----------------------------------------------------------------------------
SAP_DIR="/home/lpk/testnytsite/"
if [ ! -d "${SAP_DIR}" ] ; then
  mkdir -p "${SAP_DIR}"
fi

# Lock file
# ----------------------------------------
LOCKFILE="${LPK_TMP}lock"

# Create local directories if necessary
# -------------------------------------
if [ ! -d "${TGT_DIR}" ] ; then
  mkdir -p "${TGT_DIR}"
fi
if [ ! -d "${LPK_TMP}" ] ; then
  mkdir -p "${LPK_TMP}"
fi
if [ ! -d "${SAP_DIR}" ] ; then
  mkdir -p "${SAP_DIR}"
fi

# Locking mechanism to minimize chances that multiple instances of this script
# are running simultaneously. (In case the download takes longer to complete
# than the time interval between this script is invoked). Failsafe: If the
# lock file is more than 1 hour old we assume that something has gone wrong and
# we delete the lock file.
# ----------------------------------------------------------------------------
EPOCH_NOW="`date +%s`"
EPOCH_1H="`date -d '+ 1 hour' +%s`"
if [ -f "${LPK_TMP}lock" ] ; then
  EPOCH_LCK="`cat ${LPK_TMP}lock`"
  if [ ${EPOCH_LCK} -lt ${EPOCH_NOW} ] ; then
    # If the lock file is older than 1 hour then delete it (assuming something
    # strange has happened - so the lock file would otherwise never be removed)
    rm ${LPK_TMP}lock
  fi
  # Exit silently because lock file exists (or because we just removed the
  # lock file because that lock file had reached it's age of 1 hour).
  echo "Lock file ${LPK_TMP}lock exists, exiting now without further action"
  exit 0
else
  # Create lock file
  echo "${EPOCH_1H}" > ${LPK_TMP}lock
fi

# Create file list
# ----------------
# Ensure than any possible previous file list is cleared - and make sure that
# unnecessary (windows compatibility) carriage return characters are removed
# before they create chaos in this script.....
#if [ -f "${LPK_TMP}/FromLPK_files.txt" ] ; then
#  rm ${LPK_TMP}/FromLPK_files.txt
#fi
#/opt/cph/scripts/FromLPK_ls.exp ${HOST} ${USER} ${PHRASE} ${SRC_DIR} |\
#  egrep -v "^
#$|^Can't|^exit|^$|^sftp|${USER}|${HOST}" |\
#  sed -e 's/
#//g' > ${LPK_TMP}/FromLPK_files.txt
#
# How many files are there on LPK FTPS server
# -------------------------------------------
FILE_COUNT="`wc -l ${LPK_TMP}/FromLPK_files.txt | awk '{ print $1 }'`"
#
# Exit silently if there are no files
# -----------------------------------
#if [ "${FILE_COUNT}" -lt 1 ] ; then
# CLEANUP: Remove lock file
#  if [ -f ${LPK_TMP}lock ] ; then
#    rm ${LPK_TMP}lock
#  fi
#  exit 0
#fi

# OK - if and when we reach this point in the script - then there are files
# ready for retrieval. Retrieve the files and then delete the retrieved files
# one by one from the LPK FTPS server.
# 
for FILE in `cat ${LPK_TMP}/FromLPK_files.txt | awk '{ print $9 }'`
#do
#  # Change to target directory and FTPS get file
  cd ${TGT_DIR}
#  /opt/cph/scripts/FromLPK_get.exp \
#      "${HOST}" \
#      "${USER}" \
#      "${PHRASE}" \
#      "${SRC_DIR}" \
#      "${FILE}" 1>/dev/null
  # Check that the file is actually retrieved. Abort the remainder of this
  # script (and retrieving of any remaining files from the list) if the file
  # transfer fails.
  # If retrieval is OK then proceed to delete file from LPK FTPS server and
  # move the file into the ${SAP_DIR} directory. 
#  if [ -f "${TGT_DIR}/${FILE}" ] ; then
#    /opt/cph/scripts/FromLPK_rm.exp \
#        "${HOST}" \
#        "${USER}" \
#        "${PHRASE}" \
#        "${SRC_DIR}" \
#        "${FILE}" 1>/dev/null
#  else
#    echo "Retrieval of file ${FILE} from ${SRC_DIR} on ${HOST} failed miserably"
#    echo "aborting the entire file retrieval operation."
#    rm ${LPK_TMP}lock
#    exit 1
#  fi
  # Move the retrieved files to the designated SAP directory so SAP does not
  # get confused by incomplete files during the file is physically retrieved.
  # (2>/dev/null discards messages from the 'mv' command complaining about
  # mv: failed to preserve ownership for 'file_name': Operation not permitted).
  # The above behaviour is acceptable - we don't need to preserve ownership
  # across the NFS mount mv operation.
#  mv ${TGT_DIR}/${FILE} ${SAP_DIR}/${FILE} 2>/dev/null
#done

# CLEANUP: Remove lock file
if [ -f ${LPK_TMP}lock ] ; then
  rm ${LPK_TMP}lock
fi

