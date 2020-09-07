#!/bin/bash
###################################################################################################
# Kopiering af SAP bygnings register til Windows XXXX
DIR=/usr/sap/interface/BUILDREGISTER
DATA_TO_SAP=/usr/sap/interface/BUILDREGISTER         # Her ligger nye data til SAP
INTERFACE_DIR=/usr/sap/interface/BUILDREGISTER
ERR_LOG=${INTERFACE_DIR}/build_err_log
ERR_INFO=${INTERFACE_DIR}/mail_txt.txt
FILE_TO_MOVE="SAP-BR.txt"
###################################################################################################
date >> ${ERR_LOG}
echo ${FILE_TO_MOVE} >> ${ERR_LOG}
###################################################################################################

err_check()
{
if [ $STAT != 0 ]
then
echo error from err_check
cd "${INTERFACE_DIR}"
cat info.txt 				>  ${ERR_INFO}
ls -l  ${INTERFACE_DIR}/${FILE_TO_MOVE}	>> ${ERR_INFO}
tail -20 ${ERR_LOG} 			>> ${ERR_INFO}

#mailx -s"ERROR:Bygnings register file transfer " alert <  ${ERR_INFO}
# 27/9-2013 (jknudsen@cph.dk)
# Alert/alarm modtager ændret til fedtmule@lv-install1.cph.dk
FMULE="fedtmule@lv-install1.cph.dk"
mailx -s"ERROR:Bygnings register file transfer " $FMULE <  ${ERR_INFO}
# der har været en fejl - farvel
exit 2

else
echo ok > /dev/null
fi

}

move_file()
{
cd "${INTERFACE_DIR}"
#
# fejl login
#/usr/bin/smbclient '\\ms-webpub1\sapdata' -W KLH -d0 -N -U srvSAP2BygReg%L7Yr52d <<EOF  2>&1 >> ${ERR_LOG}
#
# Ændret til mv-webpub i stedet for ms-webpub1 (itajekn 16/8-2013)
#/usr/bin/smbclient '\\ms-webpub1\sapdata' -W KLH -d0 -N -U srvSAP2BygReg%L7Yr52dF <<EOF 2>&1 >> ${ERR_LOG}
#/usr/bin/smbclient '\\mv-webpub\sapdata' -W KLH -d0 -N -U srvSAP2BygReg%L7Yr52dF <<EOF 2>&1 >> ${ERR_LOG}
# 27/9-2013 (jknudsen@cph.dk) Tilføjet .klh.cph.ad til windows server navn idet
# serveren tilsyneladende var blevet fjernet fra cph.dk DNS zone
/usr/bin/smbclient '\\mv-webpub.klh.cph.ad\sapdata' -W KLH -d0 -N -U srvSAP2BygReg%L7Yr52dF <<EOF 2>&1 >> ${ERR_LOG}
put "${FILE_TO_MOVE}" 
EOF
STAT=$?
err_check
}
###################################################################################################
# Er filen der skal transporteres der ?

if [ ! -s ${INTERFACE_DIR}/${FILE_TO_MOVE} ]
then
STATS=2
err_check
fi

# Hvis den er der så skal den flyttes
move_file
# flyt fil så vi kan se om der kommer en ny

mv ${INTERFACE_DIR}/${FILE_TO_MOVE} ${INTERFACE_DIR}/${FILE_TO_MOVE}_old

#
