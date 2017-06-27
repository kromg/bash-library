#!/bin/bash
# vim: se et ts=4:

#
# lockings.sh - functions for file locking
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
#   V2016-03-11T23:15:06+0100
#       First release
#


# Check that we're being sourced:
[ "$0" == "$BASH_SOURCE" ] && {
    echo "This script is meant to be sourced, not executed." >&2
    exit 1
}


# ------------------------------------------------------------------------------
#  Locking helpers
# ------------------------------------------------------------------------------

# A helper variable to let us handle file descriptors
declare -A __LOCK_FD


function genLockName() {
    echo "/var/tmp/${0%.sh*}.lock"
}


# ------------------------------------------------------------------------------
#  Locking/unlocking
# ------------------------------------------------------------------------------

function _lock() {
    local LOCKOPTS="$1"
    local LOCKFILE="$2"
    local FD
    [ "$LOCKFILE" ] || LOCKFILE="$(genLockName)"
    exec {FD}<>$LOCKFILE || return 1
    flock $LOCKOPTS $FD        || return 2
    __LOCK_FD["$LOCKFILE"]=$FD
    return 0
}


# An alias to exclusiveLock
function lock() {
    _lock -xn "$1"
}

function exclusiveLock() {
    _lock -xn "$1"
}

function sharedLock() {
    _lock -sn "$1"
}

function exclusiveLockWait() {
    _lock -x "$1"
}

function sharedLockWait() {
    _lock -s "$1"
}


function unlock() {
    local LOCKFILE="$1"
    [ "$LOCKFILE" ] || LOCKFILE="$(genLockName)"

    # It's not an error to unlock a file that's not locked
    [ "${__LOCK_FD[$LOCKFILE]}" ] || return 0

    flock -un ${__LOCK_FD["$LOCKFILE"]} && unset __LOCK_FD["$LOCKFILE"] && return 0
    return 2
}


# EOF

