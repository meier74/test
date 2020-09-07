#!/bin/bash

# SAP-BR_copy.sh Ver 0.1 27/9 2013 (jknudsen@cph.dk)

# Renskrivning og tilpasning af Bent Kirkegaards oprindelige script fra ~2005
# Aendring/tilfoejelse 27/9-2013: Tilfoejet '.klh.cph.ad' efter 'mv-webpub'
# server navnet saa IP-Addressen kan slaas op via DNS.
# Aendret mailadresse saa alert meddelelser sendes til Backoffice Unix gruppens
# fedtmuleovervaagning.

###############################################################################
# Kopiering af SAP bygnings register til mv-webpub.klh.cph.ad
###############################################################################

# Hvor data lever paa lv-cphsapapr
INTERFACE_DIR=/usr/sap/interface/BUILDREGISTER
# Fejllog
ERR_LOG=${INTERFACE_DIR}/build_err_log
# Info tekst der medsendes i fejlmeldings mails
ERR_INFO=${INTERFACE_DIR}/mail_txt.txt
FILE_TO_MOVE="SAP-BR.txt"

# Skriv i haendelseslog
date >> ${ERR_LOG}
echo ${FILE_TO_MOVE} >> ${ERR_LOG}

# Fejlkontrol/fejlmeldings-routine
err_check()
{
  if [ "$STAT" != 0 ] ; then
    echo error from err_check
    cd "${INTERFACE_DIR}"
    cat info.txt 				>  ${ERR_INFO}
    ls -l  ${INTERFACE_DIR}/${FILE_TO_MOVE}	>> ${ERR_INFO}
    tail -20 ${ERR_LOG} 			>> ${ERR_INFO}
    mailx -s"Fejl: `uname -n`: $0: Bygningsregister filkopiering" fedtmule@lv-install.cph.dk <  ${ERR_INFO}
    exit 2 # exit med fejlkode 2
  else
    echo ok > /dev/null
  fi
}

# Kopieringsroutine
copy_file()
{
cd "${INTERFACE_DIR}"
/usr/bin/smbclient '\\mv-webpub.klh.cph.ad\sapdata' -W KLH -d0 -N -U srvSAP2BygReg%L7Yr52dF <<EOF 2>&1 >> ${ERR_LOG}
 put "${FILE_TO_MOVE}" 
EOF
STAT=$?
err_check
}

# Hvis filen ikke er til stede
if [ ! -s ${INTERFACE_DIR}/${FILE_TO_MOVE} ]
  then
  STATS=2
  err_check
fi

# Hvis filen er til stede kopieres den
copy_file

# Omdoeb kildefilen saa scriptet kan se naar der er kommet en ny
mv ${INTERFACE_DIR}/${FILE_TO_MOVE} ${INTERFACE_DIR}/${FILE_TO_MOVE}_old

