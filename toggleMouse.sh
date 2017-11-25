#!/bin/bash
################################################################################
# -- NAME:      toggleMouse.sh
# -- PURPOSE:   Toggle status of touchpad and trackpoint of my Lenovo Thinkpad
# -- 
# --            Touchpad:   SynPS/2 Synaptics TouchPad
# --            Trackpoint: TPPS/2 IBM TrackPoint
# -- 
# --            Usage:
# --            toggleMouse.sh
# --            
# -- REVISIONS:
# -- Ver        Date        Author           Description
# -- ---------  ----------  ---------------  -----------------------------------
# -- 0.1        22.10.2017  T. Winterhalder  Created
################################################################################

XINPUT_BIN=$(which xinput)
GREP_BIN=$(which grep)
CUT_BIN=$(which cut)

TOUCHPAD=$(${XINPUT_BIN} list | ${GREP_BIN} -i touchpad | ${CUT_BIN} -f 2 | ${GREP_BIN} -oE [[:digit:]]+)
TRACKPOINT=$(${XINPUT_BIN} list | ${GREP_BIN} -i trackpoint | ${CUT_BIN} -f 2 | ${GREP_BIN} -oE [[:digit:]]+)

STATUS=$(${XINPUT_BIN} list-props ${TOUCHPAD} | ${GREP_BIN} -i enabled | ${CUT_BIN} -f 3)

if [ "${STATUS}" = "1" ]
then
	${XINPUT_BIN} disable ${TOUCHPAD}
	${XINPUT_BIN} disable ${TRACKPOINT}
else
	${XINPUT_BIN} enable ${TOUCHPAD}
	${XINPUT_BIN} enable ${TRACKPOINT}
fi

