#!/bin/bash
 
### getFTP v.1 #################
#
# Variables : use backquotes!#
PROTOCOL="ftps"
DATE=`date +%Y%m%d`
HOME='/home/lpk/testnytsite'
URL='10.193.4.205:990'
#HOST='ftps://mv-ftps.klh.cph.ad:990'
USER='srvlpkdata'
PASS='xJ4Y4cbDcgswcHisZ76R'
FILE='*.txt'
REMOTEDIR="/"
#
####################################
 
# Make directory of current date, make that directory local
#mkdir $HOME/$DATE
#cd $HOME/$DATE
 
cd $HOME

# Login, run get files
lftp $PROTOCOL://$URL <<- DOWNLOAD
set ssl:verify-certificate no
set ftp:ssl-force true
set ftp:ssl-protect-data true
set ftps:initial-prot
user $USER "$PASS"
cd $REMOTEDIR
mget $FILE
!ls > $DATE.list
bye
DOWNLOAD
