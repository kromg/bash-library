#!/bin/bash
# vim: se et ts=4:

#
# bashHelpers.sh - Shell-helpers functions
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
#   V2015-07-30T13:23:04+0200
#       First (minimal) release
#


# Check that we're being sourced:
[ "$0" == "$BASH_SOURCE" ] && {
    echo "This script is meant to be sourced, not executed." >&2
    exit 1
}


# ------------------------------------------------------------------------------
#  Shell helpers
# ------------------------------------------------------------------------------

function functionExists() {
    ( type -t "$1" | grep -q 'function' ) &> /dev/null \
        && return 0

    return 1
}

function printCallStack() {

    # ${FUNCNAME[0]} == printCallStack of course!!!

    # firstLevel is defined as the first parameter to this function or is set to
    # "1" automatically
    local firstLevel="${1:-1}"

    echo "Stack trace for ${FUNCNAME[$firstLevel]}():"
    local ind='  '
    for (( i=$firstLevel; i < $(( ${#FUNCNAME[@]} - 1 )); i++)); do
        echo "${ind}${FUNCNAME[$i]} called @${BASH_SOURCE[$(( $i + 1 ))]}:LINE[${BASH_LINENO[$i]}]"
        ind="${ind}  "
    done
}

function throwException() {
    echo "Exception [ in ${FUNCNAME[1]}() ] :: $*" >&2
    printCallStack 2 >&2
    exit 1
}


# ------------------------------------------------------------------------------
#  Data types
# ------------------------------------------------------------------------------

function isNumber() {
    [ "$1" -eq "$1" ] &> /dev/null
}

function isPositive() {
    [ "$1" -gt 0 ] &> /dev/null
}

function isNatural() {
    [ "$1" -ge 0 ] &> /dev/null
}


# ------------------------------------------------------------------------------
#  Arguments
# ------------------------------------------------------------------------------

function count() {
    echo "$#"
}

function arrayNumElements() {
    local arrayName="$1"
    eval "echo \${#${arrayName}[@]}"
}

function arrayIsEmpty() {
    [ "$(arrayNumElements "$1")" -eq 0 ]
}

function arrayIsNotEmpty() {
    [ "$(arrayNumElements "$1")" -gt 0 ]
}

# ------------------------------------------------------------------------------
#  Value mangling
# ------------------------------------------------------------------------------

if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then

    # UPPERCASE
    function uc() {
        echo "$@" | tr '[[:lower:]]' '[[:upper:]]'
    }

    # lowercase
    function lc() {
        echo "$@" | tr '[[:upper:]]' '[[:lower:]]'
    }

else

    # UPPERCASE
    function uc() {
        echo "${1^^}"
    }

    # lowercase
    function lc() {
        echo "${1,,}"
    }

fi







# EOF
