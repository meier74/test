#!/bin/bash
PROTOCOL="ftps"
URL="10.193.4.205:990" 
LOCALDIR="/usr/sap/interface/lpk_data/CPR"
REMOTEDIR="/Counter/"
USER="srvlpkdata"
PASS="xJ4Y4cbDcgswcHisZ76R"
REGEX="*.csv"
LOG="/home/lpk/script.log"

#cd $LOCALDIR
cd /usr/sap/interface/lpk_data/CPR/
if [  $? -eq 0 ]; then
    echo "$(date "+%d/%m/%Y-%T") Cant cd to $LOCALDIR. Please make sure this local directory is valid" >> $LOG
fi

lftp  $PROTOCOL://$URL <<- DOWNLOAD
set ssl:verify-certificate no
set ftp:ssl-force true
set ftp:ssl-protect-data true
set ftps:initial-prot
    user $USER "$PASS"
    cd $REMOTEDIR
    mget -E $REGEX
DOWNLOAD

if [  $? -eq 0 ]; then
    echo "$(date "+%d/%m/%Y-%T") Cant download files. Make sure the credentials and server information are correct" >> $LOG
fi
