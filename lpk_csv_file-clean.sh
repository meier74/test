#!/bin/sh

# clean_but_keep.sh Ver 1.1 jknudsen@cph.dk
# Script to perform cleanup of log or archive directory. Will keep the last
# KEEP_FILES matching FILESPEC and delete remaining files matching FILESPEC.
# The files deleted are the oldest files as they are sorted by the
# 'ls -latrd *' command.
#
# NOTE: Script may not work as expected if filenames contain space(s)

VERBOSE="no" # Display specifics and progress on STDOUT
MAIL="no"    # Enable sending mail to MAILTO when deleting files
MAILTO="thomas.meier@cph.dk"    # MAILTO recipient mail address
CLEANDIR="/usr/sap/interface/lpk_data/CPR/"   # Directory to cleanup
FILESPEC="Pcnt20*.csv"    # What files to clean
KEEP_FILES="10000"                  # How many files matching FILESPEC to keep

# Check that CLEANDIR exists and exit if not
if [ ! -d "$CLEANDIR" ] ; then
  echo ""
  echo "Sorry. The directory $CLEANDIR does not exist. EXIT"
  echo ""
  exit 1
fi

# Change current working directory to CLEANDIR
cd $CLEANDIR

# Complain if MAIL is enabled but no MAILTO is specified
if [ "$MAIL" = "yes" -a "$MAILTO" = "" ] ; then
  echo "WARNING: MAIL is set to \"yes\" but MAILTO is empty."
fi

# How many files matching the FILESPEC do we have in CLEANDIR
FILECOUNT=`ls -latrd $FILESPEC | wc -l`
if [ "$VERBOSE" = "yes" ] ; then
  echo ""
  echo "Specified cleanup directory : [$CLEANDIR]"
  echo " - FILESPEC is set to       : [$FILESPEC]"
  echo " - Number of matching files : [$FILECOUNT]"
  echo " - VERBOSE is set to        : [$VERBOSE]"
  echo " - MAIL is set to           : [$MAIL]"
  echo " - MAILTO is set to         : [$MAILTO]"
fi

# Do we have more than KEEP_FILES number of files
if [ "$FILECOUNT" -gt "$KEEP_FILES" ] ; then
  # Calculate number of files and select which files to delete
  DELETE_FILECOUNT=`expr $FILECOUNT - $KEEP_FILES`
  for FILE in `ls -latrd $FILESPEC | head -$DELETE_FILECOUNT | awk '{print $9 }'`
  do
    # Verbose output to STDOUT
    if [ "$VERBOSE" = "yes" ] ; then
      echo "Selected for delete...... [$FILE]"
    fi
    # Send MAIL if defined
    if [ "$MAIL" = "yes" ] ; then
      for RECIPIENT in `echo $MAILTO`
      do
        echo "File $FILE selected for removal from $CLEANDIR" |\
          mailx -s "$0: Removing `uname -n`:${CLEANDIR}${FILE}" ${RECIPIENT}
      done
    fi
    # Do the actual removing of the selected file(s)
    rm $FILE
  done
  if [ "$VERBOSE" = "yes" ] ; then
    echo "DONE"
    echo ""
  fi
else
  # Verbose output to STDOUT
  if [ "$VERBOSE" = "yes" ] ; then
    echo ""
    echo "NO files selected for removal"
    echo "DONE"
    echo ""
  fi
fi


