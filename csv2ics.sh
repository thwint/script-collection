#!/bin/bash
################################################################################
# -- NAME:      csv2ics.sh
# -- PURPOSE:   Generate one ics-file per category from a given csv-file.
# --
# --            CSV-format:
# --            number,weekday,datefrom,timefrom,dateto,timeto,category,summary,
# --            location, description
# -- 
# --            The columns number and weekday are not used.
# --
# --            Usage:
# --            ./csv2ics.sh /path/file.csv
# --            
# -- REVISIONS:
# -- Ver        Date        Author           Description
# -- ---------  ----------  ---------------  -----------------------------------
# -- 0.1        22.11.2017  Enrico Buchs     Created
# -- 0.2        24.11.2017  T. Winterhalder  One ics per category
# -- 0.3        25.11.2017  T. Winterhalder  Adding timezone and alerts
################################################################################
# User configration
################################################################################
# Available categories in csv file Each category results in a file 
# ${categoryName}.ics
categories=('cat1' 'cat2' 'cat3' )

# Host-part of UID
icsUIDPart='yourdomain.ch'

# add reminder
# 0 = no reminder added
# 1 = only for events with start and stop time
# 2 = only for full day events
# 3 = for all events
addAlarm=1

# time for trigger
alarmTime='15M'

################################################################################
# print usage
function usage {
	echo -e "Error! File-path missing!"
	echo -e "\nUsage:"
	echo -e "======"
	echo -e "$0 /path/file.csv"
	exit 1
}

################################################################################
# create dateTimeString from date and time
function icalTime {
	local dateArray=($(echo ${1} | tr '. ' "\n"))
	local timeArray=($(echo ${2} | tr ': ', "\n"))
	if [ "${#zeit[@]}" -gt "1" ]; then
		local icalstring=:${dateArray[2]}${dateArray[1]}${dateArray[0]}T${timeArray[0]}${timeArray[1]}${timeArray[2]}Z
	else
		local icalstring=";VALUE=DATE:${dateArray[2]}${dateArray[1]}${dateArray[0]}"
	fi
	echo $icalstring
}

################################################################################
# print ical header to file
function initCalFile {
	local ical=${1}.ics
	cat << EOF > ${ical}
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//SabreDAV//SabreDAV//EN
X-WR-CALNAME:${1}
METHOD:PUBLISH
EOF
}

################################################################################
# print ical ent to file
function closeCalFile {
	local ical=${1}.ics
	echo END:VCALENDAR >> $ical
}

################################################################################
# add timezone Europe/Zurich
function addZurichTimezone {
	local ical=${1}.ics
	cat << EOF >> ${ical}
BEGIN:VTIMEZONE
TZID:Europe/Zurich
BEGIN:DAYLIGHT
TZOFFSETFROM:+0100
TZOFFSETTO:+0200
TZNAME:CEST
DTSTART:19700329T020000
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
TZNAME:CET
DTSTART:19701025T030000
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
END:STANDARD
END:VTIMEZONE
EOF
}

################################################################################
# add alarm 
function addAlarm {
	cat << EOF >> ${1}
BEGIN:VALARM
ACTION:AUDIO
TRIGGER:-PT${alarmTime}
END:VALARM
EOF
}

################################################################################
#                                                                              #
#                                       MAIN                                   #
#                                                                              #
################################################################################
if [ $# -lt 1 -a ! -f "$1" ]
then
	usage
fi

file=${1}

echo generate ics for ${1}
actualDate=`date '+%d.%m.%Y'`
actualTime=`date '+%H:%M:%S'`

# prepare ics file for each category
for i in ${categories[@]}; do
	initCalFile ${i}
	addZurichTimezone ${i}
done

IFS=$'\n'

# try to match category for each line.
#for line in ${file}
while read line
do
	array=($(echo ${line} | tr ',' "\n"))
	#echo ${line}
	category=$(echo ${array[6]}|tr -d ' ')
	for i in ${categories[@]}; do
		if [ "${i}" = "${category}" ]; then
			ical=${category}.ics
       			#continue 2
    		fi
	done
	# add calendar event to ics file
	cat << EOF >> ${ical}
BEGIN:VEVENT
UID:'$(echo ${array[2]}|tr -d '. ')-${array[6]/ }-${array[7]/ }@${icsUIDPart}'
LOCATION:${array[8]}
SUMMARY:${array[7]}
DESCRIPTION:${array[9]}
DTSTART;TZID=Europe/Zurich$(icalTime ${array[2]} ${array[3]})
DTEND;TZID=Europe/Zurich$(icalTime ${array[4]} ${array[5]})
DTSTAMP$(icalTime $actualDate ${actualTime})
EOF
	# add alarm to event
	case ${addAlarm} in
		1)
			if  [ ${#array[3]} -gt 1 ];
			then
				addAlarm ${ical}
			fi
			;;
		2)
			if [ ${#array[3]} -lt 6 ];
			then
				addAlarm ${ical}
			fi
			;;
		3)
			addAlarm ${ical}
			;;
	esac
	echo "END:VEVENT" >> ${ical}
done < ${file}

# add closing tag to each ics file
for i in ${categories[@]}; do
	closeCalFile ${i}
done
exit 0
