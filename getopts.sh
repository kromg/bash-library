#!/usr/bin/bash
# vim: se ts=4 et syn=sh:

# getopts.sh - simplify command line handling and help printing.
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
#   CHANGELOG:
#
#       2017-06-26T15:51:45+02:00
#           - First release.
#
#       2017-06-27T11:23:31+02:00
#           - First fixes after setting up simple test suite.
#
#       2017-06-27T12:11:16+02:00
#           - Added non-duplication checks; added check for -? option
#       
#       2017-10-03T14:01:24+02:00
#           - Added special syntax (@) for flags that can be specified more than
#             once.
#

# ------------------------------------------------------------------------------
#  Helper variables
# ------------------------------------------------------------------------------

# Associative arrays used to store command line properties
declare -A _commandLineOptions
declare -A _commandLineFlags
declare -A _commandLineMultivalueOptions
declare -A _commandLineOptionsHelp
declare -A _commandLineOptionsArgs
declare -A _commandLineOptionsMandatory

# Add default options: -h (help), -v (verbose) and -V (version).
#  This should be done via addOption but I cannot do it here.
_commandLineFlags["h"]=1
_commandLineFlags["v"]=1
_commandLineFlags["V"]=1
_commandLineOptionsHelp["h"]="Print this help message"
_commandLineOptionsHelp["v"]="Be verbose"
_commandLineOptionsHelp["V"]="Print version and exit"

# Flags found in the command line
declare -A _definedCommandLineFlags

# Options found in the command line
declare -A _definedCommandLineOptions


# ------------------------------------------------------------------------------
#  Helper functions - usage by external scripts should be avoided
# ------------------------------------------------------------------------------

# Check if an option/flag was already added
function _optAlreadyExists() {
    local o="${1%:}"
          o="${o%@}"
    [ \
        -n "${_commandLineFlags[$o]}"   -o \
        -n "${_commandLineOptions[$o:]}" -o \
        -n "${_commandLineMultivalueOptions[$o@]}" \
    ]
}

# Check if this is a flag or an option
function _hasArgs() {
    [ \
        -n "${_commandLineOptions[$1:]}" -o \
        -n "${_commandLineMultivalueOptions[$1:]}" \
    ]
}

# Check if this option is mandatory (flags cannot be mandatory)
function _isMandatory() {
    [ "${_commandLineOptionsMandatory[$1]}" ]
}



# ------------------------------------------------------------------------------
#  Public functions
# ------------------------------------------------------------------------------

# addOption()
#   Add an element to the list of the possible command line flags/options.
#
# Usage:
#   addOption <optionSpec> <helpString> [<argName>]
#
#     optionSpec: like for getopts, a character identifies a flag, a character
#                 followed by a colon specifies an option with a mandatory
#                 argument; SINCE VERSION '2017-10-03T14:01:24+02:00' options
#                 followed by a '@' character are allowed to be specified
#                 multiple times on the command line, and all their arguments
#                 are stored into an array.
#                 
#        EXTENSION: prepend the option specification with a bang (!) if
#                 you want the option to be considered mandatory (has no meaning
#                 for flags).
#
#     helpString: a string to be used in the help message.
#
#     argName: for options (with argument), the argument name to be displayed in
#              help string.
#
function addOption() {
    # Get the option/flag without the optional '!' 
    local opt="${1#!}"
    # Forbid the usage of '?' as a flag or option character
    if [ "${opt%:}" == '?' -o "${opt%@}" == '?' ]; then
        echo "Cannot use '?' as an option/flag: getopts reserved character"
        exit 1
    fi

    # Prevent duplicate flags w/ or w/o argument
    if _optAlreadyExists "$opt"; then
        echo "Option has already been added: $opt"
        exit 1
    fi

    # Insert the option in the appropriate option set
    case "$opt" in
        *:)
            _commandLineOptions["$opt"]=1
            ;;
        *@)
            _commandLineMultivalueOptions["${opt/@/:}"]=1
            ;;
        *)
            _commandLineFlags["$opt"]=1
            ;;
    esac

    # Fill other information about this option
    [ "$2" ] && _commandLineOptionsHelp["$opt"]="$2"
    [ "$3" ] && _commandLineOptionsArgs["$opt"]="$3"
    [[ "$1" =~ ! ]] && _commandLineOptionsMandatory["$opt"]=1
}

# getOptions()
#   Parse the command line according to specifications entered by (possibly
#   repeated) usage of addOption().  EXPORTS an array named ARGV containing
#   all the parameters left on the command line after parsing of options is
#   finished.
#
#   - Automatically prints help if -h was specified on the command line.
#
#   - Automatically dies with an error if a specified mandatory option is
#     missing.
#
# Usage (copy-paste this literally):
#   getOptions "$@"     # Pass script's args to getOptions()
#
function getOptions() {
    local optString=':'
    # Build the options string. Start with a colon so getopts uses silent
    # error reporting
    IFS='' optString+="${!_commandLineFlags[*]}"
    IFS='' optString+="${!_commandLineOptions[*]}"
    IFS='' optString+="${!_commandLineMultivalueOptions[*]}"

    while getopts "$optString" OPT; do
        case "$OPT" in
            ':')
                echo "Missing argument to option: $OPTARG"
                printHelp
                exit 1
                ;;
            '?')
                echo "Unknown option: $OPTARG"
                printHelp
                exit 1
                ;;
            *)  
                if _hasArgs "$OPT"; then
                    _definedCommandLineOptions[$OPT]="$OPTARG"
                else
                    _definedCommandLineFlags[$OPT]=1
                fi
                ;;
        esac
    done

    # Get the arguments at the end of the command line (if any)
    shift $(( $OPTIND - 1 ))
    # Do NOT set and export array at the same time. Do it in 2 steps:
    ARGV=( "$@" ); export ARGV

    # Print help and exit 0 if required on command line (-h)
    if isSet "h"; then
        printHelp
        exit 0
    fi

    # Check for mandatory options, die if a mandatory option was not found.
    for m in "${!_commandLineOptionsMandatory[@]}"; do
        if ! hasOption "${m%:}"; then
            echo "Option ${m%:} is mandatory"
            printHelp
            exit 1
        fi
    done

}



# hasOption()
#   Return true if specified option was given on command line.
#
# Usage: 
#   hasOption "<an option>"
#
#   Do NOT include the dash (-) in the option specification, just use the
#   associated character. 
#
function hasOption() {
    [ "${_definedCommandLineOptions[$1]}" ]
}

# isSet()
#   Return true if specified flag was given on command line.
#
# Usage:
#   isSet "<a flag>"
#
#   Do NOT include the dash (-) in the option specification, just use the
#   associated character. 
#
function isSet() {
    [ "${_definedCommandLineFlags[$1]}" ]
}

# valueOf()
#   Retrieve the value of the arg associated to the named option.
#
# Usage:
#   myVal="$(valueOf "<an option>")"
#
#   Do NOT include the dash (-) in the option specification, just use the
#   associated character. 
#
function valueOf() {
    echo "${_definedCommandLineOptions[$1]}"
}

# getArgs()
#   Retrieve the array of command line arguments (if any)
#
# Usage:
#   

# printHelp()
#   Prints the whole help string.
#
function printHelp() {
    local opts=''
    local flags=''
    local optlist=()

    for opt in "${!_commandLineOptionsHelp[@]}"; do
        if [[ $opt =~ : ]]; then
            arg=${_commandLineOptionsArgs["$opt"]}
            arg=${arg:-ARG}
            _isMandatory "$opt" && optlist+=("-${opt%:} $arg") || optlist+=("[-${opt%:} $arg]")
            opts+=$"      -${opt%:} $arg\n        ${_commandLineOptionsHelp[$opt]}\n"
        else
            _isMandatory "$opt" && optlist+=("-$opt") || optlist+=("[-$opt]")
            flags+=$"      -$opt\t${_commandLineOptionsHelp[$opt]}\n"
        fi
    done

    (
        echo -e "\nUsage: $(basename $0) ${optlist[@]}\n"
        [ "$flags" ] && echo -e "    FLAGS\n$flags\n"
        [ "$opts"  ] && echo -e "    OPTIONS\n$opts\n"
    ) | fold -w 80

}

