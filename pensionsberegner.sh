#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin

PENSIONSDATO="May 1 2016"
PENSIONSEPOCH="` date -d ' May 1 2016 00:00' +%s`"
NOWEPOCH="`date +%s`"
SECONDS_TO_PENSION="`expr $PENSIONSEPOCH - $NOWEPOCH`"
MINUTES_TO_PENSION="`expr $SECONDS_TO_PENSION / 60 `"
HOURS_TO_PENSION="`expr $MINUTES_TO_PENSION / 60 `"
DAYS_TO_PENSION="`expr $HOURS_TO_PENSION / 24 `"
WEEKS_TO_PENSION="`expr $DAYS_TO_PENSION / 7 `"
NON_WORKDAYS="`echo \"scale=0; ( ( $DAYS_TO_PENSION / 7 ) * 2 ) + 25 \" | bc -l `"
WORKDAYS_TO_PENSION="`echo \"scale=0; $DAYS_TO_PENSION - $NON_WORKDAYS \"| bc -l`"
MONTHS_TO_PENSION="` echo  "scale= 1 ; $DAYS_TO_PENSION / 30"  | bc -l`"


echo "
Pensionering om:


	$SECONDS_TO_PENSION 	sekunder
	$MINUTES_TO_PENSION 	minutter
	$HOURS_TO_PENSION 	timer
	$DAYS_TO_PENSION 	kalenderdage
	$WORKDAYS_TO_PENSION 	arbejdsdage (minus weekend+helligdage+restferie)
	$WEEKS_TO_PENSION 	kalenderuger
	$MONTHS_TO_PENSION 	maaneder

" | mailx -s "Pensionsreminder" j.knudsen@cph.dk
