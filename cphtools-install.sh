#!/bin/sh

# cphtools-install.sh
# 29/05-2007 (itajekn)
#
# Interaktivt script som benyttes til at installere diverse tools som
# benyttes i forbindelse med drift af Unix maskiner.
# Scriptet skal afvikles af root paa lnx-install1 (saadan er det designet).
# itajekn 14 Aug. 2007 updated ssh-keygen hint

# Maskinnavnet paa maskinen hvor dette script skal afvikles
ADMHOST="lnx-install"


WHOAMI=`id | awk -F\( '{ print $2 }' | awk -F\) '{ print $1 }'`
if [ "${WHOAMI}" != "root" ] ; then
  echo "Dette script skal udfoeres som root. Farvel !"
  exit 0
fi

LOCALHOSTNAME=`uname -n`
if [ "${LOCALHOSTNAME}" != "${ADMHOST}" ] ; then
  echo "Dette script skal udfoeres paa ${ADMHOST}. Farvel !"
  exit 0
fi

clear

# Overskrift
# ----------
echo ""
echo "+----------------------------------------------------------------------+"
echo "|   Dette script automatiserer delvist installation  af scripts som    |"
echo "|     benyttes i forbindelse med drift af Unix maskiner i CPH.         |"
echo "|                                                                      |"
#echo "|     NB: Der er ialt 3 scripts som installeres via dette script.      |"
echo "|     NB: Der er 2 scripts som installeres via dette script.           |"
echo "|                                                                      |"
echo "+----------------------------------------------------------------------+"
echo ""

if [ "$1" = "" ] ; then
  echo -n "Hostnavn hvor scripts skal installeres: "
  read HOSTNAME
else
  HOSTNAME=$1
fi

# Check konnektivitet
# -------------------
ping -c1 ${HOSTNAME} 2>/dev/null 1>/dev/null

if [ $? != 0 ] ; then
  echo "Maskinen ${HOSTNAME} svarer ikke paa ping"
  echo -n "Fortsaet aligevel (j/n): "
  read SVAR
  if [ "${SVAR}" != "j" -a "${SVAR}" != "J" ] ; then
    echo "Afbryder......"
    exit 0
  else
    echo "Fortsaetter....."
  fi
fi

# Configure passwordless encrypted ssh access from sol-ov1 to host
echo ""
echo "  ++------------------------------------------------------------------++"
echo "  |+------------------------------------------------------------------+|"
echo "  || Nu konfigureres passwordless ssh forbindelse til klientmaskinen. ||"
echo "  || Root's password paa klientmaskinen skal indtastes 2 gange idet   ||"
echo "  || den offentlige noegle skal kopieres over, og derefter adderes    ||"
echo "  || klientmaskinens .ssh/authorized_keys fil.                        ||"
echo "  |+------------------------------------------------------------------+|"
echo "  ++------------------------------------------------------------------++"
echo ""
echo -n "root@${HOSTNAME}: "
scp "/root/.ssh/id_dsa.pub" \
    "root@${HOSTNAME}:~/.ssh/${LOCALHOSTNAME}-id_dsa.pub" 1>/dev/null
ERRORCODE=$?
if [ ${ERRORCODE} != 0 ] ; then
  echo "Forkert password - afbryder installation af scripts."
  echo " - kan evt. skyldes at flg. kommando skal udfoeres paa klienten:"
  echo " +--------------------+"
  echo " | ssh-keygen -t dsa  |"
  echo " +--------------------+"
  exit 0
fi
echo -n "root@${HOSTNAME}: "
ssh root@${HOSTNAME} \
    "cat ~/.ssh/${LOCALHOSTNAME}-id_dsa.pub >> ~/.ssh/authorized_keys"
ERRORCODE=$?
if [ ${ERRORCODE} != 0 ] ; then
  echo "Forkert password - afbryder installation af scripts."
  exit 0
fi

# HOSTMONITOR (diskfree)
# ----------------------
clear
cat <<EOM

#+---------------------------------------------------------------------------+
#|   Modifikation af root's crontab                                          |
#+---------------------------------------------------------------------------+

A.) Udfoer: "crontab -e"

  --  Og check/Indsaet flg. linier crontabfilen ( benyt cut-and-paste ! )   

# Send system info to ServerInfo via e-mail
45 01 * * * /opt/cph/SiAgent/SiAgent.sh

B.) Udfoer: "exit" (eller ctrl-D)

-----------------==============OOOOOOOOOOOOOO==============-----------------
EOM

BASEDIR="/installroot/installserver/MISC_OTHER/MonitoringScripts"

# Opret katalog paa klienten
#ssh root@${HOSTNAME} "mkdir -p /opt/cph/HOSTMONITOR"

# Kopier script til klienten
#scp ${BASEDIR}/HOSTMONITOR/diskfree.sh \
#    root@${HOSTNAME}:/opt/cph/HOSTMONITOR/ 1>/dev/null

# Udfoer scriptet paa klienten
#ssh root@${HOSTNAME} "/opt/cph/HOSTMONITOR/diskfree.sh"

# ssh til klienten som root saa man kan udfoere de angivne instruktioner
ssh root@${HOSTNAME}  

# SiAgent
clear
cat <<EOM

+---------------------------------------------------------------------------+
+   1.) Installation af SiAgent SCRIPT (/opt/cph/SiAgent/SiAgent.sh)        |
+---------------------------------------------------------------------------+

A.)
  -- Opret ${HOSTNAME} i ServerInfo ( LINK: http://ms-mmc/serverinfo/ )
  -- Udfyld Description feltet , og flg. felter: ServerGroup=Misc  -
  -- Scan Method=Mail - Platform=Unix - samt Priority og Lan/San felterne.

B.) Udfoer: "exit" (eller ctrl-D)

-----------------==============OOOOOOOOOOOOOO==============-----------------
EOM
ssh root@${HOSTNAME} "mkdir -p /opt/cph/SiAgent"
scp ${BASEDIR}/SiAgent/SiAgent.sh \
    root@${HOSTNAME}:/opt/cph/SiAgent/ 1>/dev/null
ssh root@${HOSTNAME}  

# DUMON
clear
cat <<EOM

+---------------------------------------------------------------------------+
+   2.) Installation af DUMON SCRIPT (/opt/cph/DUMON/dumon.sh)
+---------------------------------------------------------------------------+

-- Udfoerer nu automatisk dumon.sh scriptet 1. gang (for at registrere
-- detaljeret billede af pladsforbruget i alle kataloger). Naeste gang
-- scriptet udfoeres kan man se aendringer i pladsforbruget fra den tidligere
-- koersel af scriptet, enten i en rapportfil, eller sendt via e-mail hvis en
-- mailaddresse er angivet i scriptets MAILTO variabel.

 INFO: Rapportfil: /tmp/DUMON/report_<date>_<time>.txt

-----------------==============OOOOOOOOOOOOOO==============-----------------

VENT VENLIGST medens dumon.sh scriptet afvikles paa ${HOSTNAME} .....

EOM
ssh root@${HOSTNAME} "mkdir -p /opt/cph/DUMON"
scp ${BASEDIR}/DUMON/dumon.sh \
    root@${HOSTNAME}:/opt/cph/DUMON/ 1>/dev/null
ssh root@${HOSTNAME} /opt/cph/DUMON/dumon.sh 

# Afslutning
clear
cat <<EOM

--------------------------------------------------------------------------
SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT 
--------------------------------------------------------------------------

      Installationen af scripts er afsluttet (hvis du har udfoert de
      instruktioner der er givet undervejs).

      Scriptet her kan koeres igen hvis der er behov for at checke om
      alt er som det skal vaere.

      Ha' en god dag !

--------------------------------------------------------------------------
SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT SLUT 
--------------------------------------------------------------------------
