#!/bin/sh

# Version 1.2 10/12-2014
# /usr/local/bin/oracle_audit_archive.sh 18/11-2014 itajekn
#
# Arkiver filer til saerlige baand i backupsystemet som aldrig bliver
# overskrevet og slet derefter de arkiverede filer ved hjaelp af
# backupsystemets  dertil indrettede bparchive funktionalitet.

# Temporaer filnavn til fil liste
FILE_LIST="/tmp/oracle_audit_archive.list"

# Kataloget hvorfra der skal arkiveres
DIRECTORY="/var/log/oracle/audit"

# Filspecifikation som benyttes til at lave en filliste med 'find'
# Indsæt denne filspecifikation direkte i find kommandoen idet scriptet
# ellers ikke fungerer korrekt.
# FILESPEC='aud_*.xml'

# Alder i dage hvorefter filer arkiveres og foelgende slettes
AGE="90"

# Generer fillisten som bparchive benytter til arkivering og sletning
find ${DIRECTORY} -name 'aud_*.xml' -mtime +${AGE} -exec ls {} \; > ${FILE_LIST}
# Eksekver bparchive med aktuel filliste som argument
/usr/openv/netbackup/bin/bparchive -p Filserver-Arkivering-Linux -s Arkivering -f ${FILE_LIST}
# Fjern filen der indeholder navne paa de filer som netop er arkiveret
rm ${FILE_LIST}
