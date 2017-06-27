#!/bin/bash
# vim: se et ts=4:

#
# crontab.sh - Crontab-parsing functions
#
#     Copyright (C) 2017 Giacomo Montagner <kromg@entirelyunlike.net>
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
#
# CHANGELOG:
#   V2015-07-30T12:55:08+0200
#       Work in progress
#

# Check that we're being sourced:
[ "$0" == "$BASH_SOURCE" ] && {
    echo "This script is meant to be sourced, not executed." >&2
    exit 1
}


# We need bash helpers
set -e
. $(dirname $BASH_SOURCE)/bashHelpers.sh
set +e





# "INTERNAL" VARIABLES

declare -a _crontabProcessStartTimes
declare -a _crontabProcessStopTimes




# ------------------------------------------------------------------------------
#  Internal helpers
# ------------------------------------------------------------------------------

function _expandList() {
    local lType="$1"
    shift

    # Separate each comma-separated token by space, lowercase everything
    local args="$( lc "$@" | sed -e 's/,/ /g' )"

    case "$lType" in
        hour)
            local first=0
            local last=23
        ;;
        min)
            local first=0
            local last=59
        ;;
        mday)
            local first=1
            local last=31
        ;;
        mon)
            local first=1
            local last=12
            args="$( echo "$args" | sed -e 's/jan/1/g' -e 's/feb/2/g' -e 's/mar/3/g' -e 's/apr/4/g' -e 's/may/5/g' -e 's/jun/6/g' -e 's/jul/7/g' -e 's/aug/8/g' -e 's/sep/9/g' -e 's/oct/10/g' -e 's/nov/11/g' -e 's/dec/12/g' )"
        ;;
        wday)
            local first=1
            local last=7
            args="$(echo "$args" | sed -e 's/mon/1/g' -e 's/tue/2/g' -e 's/wed/3/g' -e 's/thu/4/g' -e 's/fri/5/g' -e 's/sat/6/g' -e 's/sun/7/g' )"
        ;;
        *)
            throwException "first arg must be list type"
        ;;
    esac


    declare -a list
    local arg
    local step
    local i

    for arg in $args; do
        # Split interval and step if there is a / in the argument
        if [[ "$arg" =~ / ]]; then
            step="${arg#*/}"
            step="${step#0}"
            isNatural "$step" || throwException "Argument after \"/\" is not an integer in: $arg"
            # Remove the "step" part from arg:
            arg="${arg%/*}"
        fi

        # Here arg is an interval or a single value only
        if [[ "$arg" =~ - ]]; then

            first="${arg%-*}"
            first="${first#0}"
            isNatural "$first" || throwException "Argument before \"-\" is not an integer in: $arg"

            last="${arg#*-}"
            last="${last#0}"
            isNatural "$last" || throwException "Argument after \"-\" is not an integer in: $arg"

            # I must take into account the fact that sun can be either 0 or 7
            # and both are valid
            if [ "$lType" == 'wday' ]; then
                [ "$first" == 7 ] && first=0
            fi

            # Invalid specification unless $first comes before $last
            [ "$first" -lt "$last" ] || throwException "Beginning of interval is past its end in: $arg"


            for i in $( seq $first $step $last ); do
                list[$i]=$i
            done

        elif [ "$arg" == 'any' ]; then

            for i in $( seq $first $step $last ); do
                list[$i]=$i
            done

        else

            # $arg is a defined single value, take it as-is
            isNatural "$arg" || throwException "Argument is not an integer: $arg"
            list[$arg]=$arg

        fi
    done

    # Must still manage sundays separately if they were used as "0"
    if [ "$lType" == 'wday' ] && [ "${list[0]}" ]; then
        unset list[0]
        list[7]=7
    fi

    echo ${list[@]}

}



function _expandMin() {
    _expandList min "$@"
}

function _expandHour() {
    _expandList hour "$@"
}

function _expandMDay() {
    _expandList mday "$@"
}

function _expandMon() {
    _expandList mon "$@"
}

function _expandWDay() {
    _expandList wday "$@"
}


# This requires an externally defined function: getStartLines(), that greps from
# crontab the lines with the start of the process
function _getStartLines() {
    functionExists getStartLines || throwException "Undefined required function: getStartLines()"
    getStartLines | sed -e 's/\*/any/g'
}

function _getStartTimesFor(){
    local day="$1"
    [ "$day" ] || throwException "Mandatory argument \$day is missing"

    declare -a startTimes

    while read line; do
        for t in $(crontabExtractTimesFrom "$line" "$day" ); do
            startTimes[$(_timeToNumber $t)]="$t"
        done
    done < ( _getStartLines )

    echo "${startTimes[@]}"
}


# This requires an externally defined function: getStopLines(), that greps from
# crontab the lines with the stop of the process
function _getStopLines() {
    functionExists getStopLines || throwException "Undefined required function: getStopLines()"
    getStopLines | sed -e 's/\*/any/g'
}

function _getStopTimesFor(){
    local day="$1"
    [ "$day" ] || throwException "Mandatory argument \$day is missing"

    declare -a stopTimes

    while read line; do
        for t in $(crontabExtractTimesFrom "$line" "$day" ); do
            stopTimes[$(_timeToNumber $t)]="$t"
        done
    done < ( _getStopLines )

    echo "${stopTimes[@]}"
}












function _zeroPad() {
    local n="0$1"
    echo "${n: -2:2}"
}


function _timeToNumber() {
    local t="${1/:/}"
    [[ $t =~ ^0+([0-9]+) ]]
    echo "${BASH_REMATCH[1]}"
}


function _shiftBy() {
    local dayShift="$1"
    local day="$2"
    echo "$(( ( $day - $dayShift + 7 ) % 7 + 1 ))"
}




# ------------------------------------------------------------------------------
#  "Public" functions
# ------------------------------------------------------------------------------

function crontabMinutes() {
    echo "$1"
}

function crontabHours() {
    echo "$2"
}

function crontabMonthDays() {
    echo "$3"
}

function crontabMonths() {
    echo "$4"
}

function crontabWeekDays() {
    echo "$5"
}



function crontabExtractTimesFrom() {
    local line="$1"
    shift

    # Filter by day if it was specified
    if [ "$#" -gt 0 ]; then
        local found=''
        for day in "$@"; do
            daysInLine="$( _expandWDay $( crontabWeekDays $line ) )" || throwException "failed to extract weekdays from $line"
            [[ $daysInLine =~ $day ]] && {
                found=1
                break
            }
        done
        [ "$found" ] || return
    fi

    hours="$( _expandHours $( crontabHours $line ) )" || throwException "failed to extract hours from $line"
    minutes="$( _expandMinutes $( crontabMinutes $line ) )" || throwException "failed to extract minutes from $line"

    declare -a list
    for hour in $hours; do
        hour="$(_zeroPad $hour)"
        for min in $minutes; do
            min="$(_zeroPad $min)"
            local tm="$hour:$min"
            list[$( _timeToNumber "$tm" )]="$tm"
        done
    done

    echo "${list[@]}"
}



# This is the main function for crontab parsing. This function calls
#       _getStartLines()
# and
#       _getStopLines()
# and populates a couple of arrays containing all start and stop times for the
# current date.
# These informations will be used by processShouldBeStarted() and
# processShouldBeStopped() to see if a process is in its running window or not.
function _parseCrontab() {

    # Override the name of getStartLines() and getStopLines() functions if
    # function names were specified on command line
    [ "$1" ] && function getStartLines() { $1; }
    [ "$2" ] && function getStopLines() { $2; }

    local today=''
    [ "$1" ] && today="$1" || today="$(date +%u)"

    declare -a startTimes
    declare -a stopTimes

    # Read all start times for this day
    startTimes=( $( _getStartTimes "$today" ) )

    # Read all stop times for this day
    stopTimes=( $( _getStopTimes "$today" ) )


    # CASE 1: all data found
    if arrayIsNotEmpty startTimes && arrayIsNotEmpty stopTimes; then
        # There are times set for $today
        _crontabProcessStartTimes=( "${startTimes[@]}" )
        _crontabProcessStopTimes=( "${stopTimes[@]}" )
        return 0
    # CASE 2: found start(s) for today, but not any stop. We must search for stop
    #         events in the preceding days, to see if there are any (batches and
    #         restart scripts have starts but not stops).
    elif arrayIsNotEmpty startTimes; then
        _crontabProcessStartTimes=( "${startTimes[@]}" )

        for dayShift in $(seq 2 7); do
            local day="$( _shiftBy $dayShift $today )"
            stopTimes=( $( _getStopTimes "$day" ) )
            arrayIsNotEmpty stopTimes && break
        done

        if arrayIsNotEmpty stopTimes


            # TODO: make a function that tells wether last was
            #       a start or not or what, change the following into
            #       a "case" statement and reuse the same function above
            #       and below in case starts or stops were not found.

        return 0
    # CASE 3: found stop(s) for today, but
    elif arrayIsNotEmpty stopTimes; then
    elif arrayIsEmpty startTimes && arrayIsEmpty stopTimes; then
        # Nothing found for today, then we must go backwards until we find
        # if the last event was a start or a stop
        for dayShift in $(seq 2 7); do
            local day="$( _shiftBy $dayShift $today )"

            startTimes=( $( _getStartTimes "$day" ) )
            stopTimes=( $( _getStopTimes "$day" ) )

            arrayIsNotEmpty startTimes && break
            arrayIsNotEmpty stopTimes  && break
        done

        if arrayIsNotEmpty startTimes && arrayIsNotEmpty stopTimes; then
            if [ "$( _timeToNumber ${startTimes[-1]} )" -gt "$( _timeToNumber ${stopTimes[-1]} )" ]; then
                # Last was a start
                _crontabProcessStartTimes=( "00:00" )
                # There is no stop for the current day
                _crontabProcessStopTimes=( "24:00" )
                return 0
            else
                # Last was a stop
                _crontabProcessStopTimes=( "00:00" )
                # There is no start for today
                _crontabProcessStartTimes=( "24:00" )
                return 0
            fi
        elif arrayIsNotEmpty startTimes; then
            # There were no stops in the past days (for example, for batches and restart scripts)
            _crontabProcessStartTimes=( "${startTimes[@]}" )
            _crontabProcessStopTimes=( "24:00" )
            return 0
        elif arrayIsNotEmpty stopTimes; then
            # There were no starts at all in the pas days. Does it even make sense?
            _crontabProcessStopTimes=( "${stopTimes[@]}" )
            _crontabProcessStartTimes=( "24:00" )
            return 0
        else
            # Errr....
            throwException "No data could be found!"
        fi



    fi



    if arrayIsEmpty stopTimes; then     # start time(s) found, but not stop

        for dayShift in $(seq 2 7); do
            local day="$(( ( $today - $dayShift + 7 ) % 7 + 1 ))"
        done




    for dayShift in $( seq 1 7 ); do
        # Countdown from today to a week ago, using day numbers:
        # 1 == mon..7 == sun
        local day="$(( ( ($today - $dayShift + 7 ) % 7) + 1 ))"



    done
}
# EOF
