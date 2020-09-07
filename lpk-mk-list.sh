#/bin/sh

# lpk-mk-list.sh Ver 0.2 jknudsen@cph.dk 26/9-2013
# Script to create list of available Pcnt20*.csv files
# Necessary for the SAP Abap processing of the lpk
# capacity files
#
# Changed to produce list of just filenames without
# full path 26/9-2013 (jknudsen@cph.dk).

DATA_DIR="/usr/sap/interface/lpk_data/CPR"
FILE_PATTERN="Pcnt20*.csv"

cd  ${DATA_DIR}
ls -1 ${FILE_PATTERN} > liste_do
mv liste_do liste_done
chown lpk:sapsys liste_done
