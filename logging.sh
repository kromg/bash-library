#!/bin/bash
# vim: se et ts=4:

#
# logging.sh - Logging function for bash scripts
#
# Copyright (C) 2015-2017  Giacomo Montagner <kromg@entirelyunlike.net>
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#
# CHANGELOG:
#   V2015-07-20T12:35:45+0200
#       First release
#   V2015-07-30T13:09:40+0200
#       Added __BASH_LOGGING__ variable
#   V2015-07-30T13:19:04+0200
#       Added executed/sourced test
#   V2016-03-01T16:10:52+0100
#       First public release. info() is no more enabled by default (may
#       conflict with a system command).
#   V2017-10-04T17:06:06+02:00
#       die() now prints without prefix.
#
#

# Check that we're being sourced:
[ "$0" == "$BASH_SOURCE" ] && {
    echo "This script is meant to be sourced, not executed." >&2
    exit 1
}

# ------------------------------------------------------------------------------
#  Simple output functions
# ------------------------------------------------------------------------------
function die() {
    echo -e "$@" >&2
    exit 1
}

# ------------------------------------------------------------------------------
#  Internal variables
# ------------------------------------------------------------------------------

declare -a _LOG_LEVELS=('FATAL' 'ERROR' 'WARNING' 'NOTICE' 'INFO' 'DEBUG' 'TRACE')
declare -a _LOG_LABELS

_LOG_LEVEL=4    # Default to INFO

# Map loglevel names to integers
for i in $(seq 0 $(( ${#_LOG_LEVELS[@]} - 1 )) ); do
    eval "_LOG_LEVEL_${_LOG_LEVELS[$i]}=$i"
    _LOG_LABELS+=( "$(printf "%-7s" ${_LOG_LEVELS[$i]})" )
done

# ------------------------------------------------------------------------------
#  _PRIVATE functions
# ------------------------------------------------------------------------------


function _log() {
    local lev="$1"; shift

    [ "${!lev}" -le "$_LOG_LEVEL" ] || return

    local echo_opts=''
    for flag in "$@"; do
        [[ $flag =~ ^- ]] || break
        echo_opts+=" $flag"
        shift
    done

    if [ "$#" -gt 0 ]; then
        # Called with arguments
        echo -e $echo_opts "$(date) | ${_LOG_LABELS[${!lev}]} | [$(printf "%5d" $$ )] | $*"
    else
        while read line; do
            echo -e $echo_opts "$(date) | ${_LOG_LABELS[${!lev}]} | [$(printf "%5d" $$ )] >   $line"
        done <&0
    fi
}



# ------------------------------------------------------------------------------
#  Logging setup
# ------------------------------------------------------------------------------

# setLogLevel()
#   Usage: setLogLevel <LOGLEVEL_NAME>
#      Eg: setLogLevel DEBUG
#   Returns: 0 if LOGLEVEL_NAME was found (and level was set), 1 otherwise
function setLogLevel() {
    local ll="_LOG_LEVEL_$1"

    if [ "${!ll}" ]; then
        _LOG_LEVEL="${!ll}"
        return 0
    fi

    return 1
}


# openLog()
#   Usage: openLog <FILE_NAME>
#      Eg: openLog /tmp/myLog.log
#   Returns: 0 if STDOUT could be redirected to named file, 1 otherwise
#
#   Note: does not clobber destination file, you have to do it yourself if you need to
function openLog() {
    local log="$1"

    eval "exec >>$log" || return 1
    return 0
}


# openErr()
#   Usage: openErr <FILE_NAME> | openErr <FILE_DESCRIPTOR>
#      Eg: openErr /tmp/myErr.log
#   Returns: 0 if STDERR could be redirected to named file, 1 otherwise
#
#   Note: does not clobber destination file, you have to do it yourself if you need to
function openErr() {
    local log="$1"

    eval "exec 2>>$log" || return 1
    return 0
}



# ------------------------------------------------------------------------------
#  Logging functions
# ------------------------------------------------------------------------------

function trace() {
    _log "_LOG_LEVEL_TRACE" "$@"
}

function debug() {
    _log "_LOG_LEVEL_DEBUG" "$@"
}

# NOTE: on many systems, "info" is an OS command. Enable this at you risk.
# function info() {
#     _log "_LOG_LEVEL_INFO" "$@"
# }

function log() {
    _log "_LOG_LEVEL_INFO" "$@"
}

function notice() {
    _log "_LOG_LEVEL_NOTICE" "$@" >&2
}

function warning() {
    _log "_LOG_LEVEL_WARNING" "$@" >&2
}

function warn() {
    _log "_LOG_LEVEL_WARNING" "$@" >&2
}

function error() {
    _log "_LOG_LEVEL_ERROR" "$@" >&2
}

function err() {
    _log "_LOG_LEVEL_ERROR" "$@" >&2
}

function fatal() {
    _log "_LOG_LEVEL_FATAL" "$@" >&2
    exit 1
}



# EOF
