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
#       2017-10-03T17:20:17+02:00
#           - Added detection of duplicated option on command line.
#
#       2017-10-04T13:25:14+02:00
#           - Added functions to mangle help screen.
#
#       2017-10-04T13:55:07+02:00
#           - Fixed an error in _isMultivalued()
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
        -n "${_commandLineMultivalueOptions[$o:]}" \
    ]
}

# Check if this is a flag or an option
function _numArgs() {
    [ "${_commandLineFlags[$1]}" ] && return 0
    [ "${_commandLineOptions[$1:]}" ] && return 1
    [ "${_commandLineMultivalueOptions[$1:]}" ] && return 2
    return 3
}

# Check if this option is mandatory (flags cannot be mandatory)
function _isMandatory() {
    [ "${_commandLineOptionsMandatory[$1]}" ]
}

# Check if this option is multi-valued
function _isMultivalued() {
    [ "${_commandLineMultivalueOptions[$1]}" ]
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
#     optionSpec:
#           a character (e.g.: "f")          -->   a flag (as in bash's getopts)
#           a char and a colon (e.g.: "o:")  -->   an option, with an argument 
#                                                  (as in bash getopts)
#           a char and an "@" (e.g.: "m@")   -->   an option that can be
#                                                  specified on command line
#                                                  multiple times.
#        Values of multi-valued options are stored into an array named after the
#        option itself. For future compatibility, use valueOf "<OPT>" to get the
#        name of such array.
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
    local optspec="${1#!}"
    local opt="${optspec%:}"
          opt="${opt%@}"
    # Forbid the usage of '?' as a flag or option character
    if [ "${opt}" == '?' ]; then
        echo "Cannot use '?' as an option/flag: getopts reserved character"
        exit 1
    fi

    # Prevent duplicate flags w/ or w/o argument
    if _optAlreadyExists "$opt"; then
        echo "Option has already been added: $opt"
        exit 1
    fi

    # Insert the option in the appropriate option set
    case "$optspec" in
        *:)
            _commandLineOptions["$optspec"]=1
            ;;
        *@)
            optspec="${optspec/@/:}"  # "@" won't be needed anymore, ":" will
            _commandLineMultivalueOptions["$optspec"]=1
            ;;
        *)
            _commandLineFlags["$optspec"]=1
            ;;
    esac


    # Fill other information about this option
    [ "$2" ] && _commandLineOptionsHelp["$optspec"]="$2"
    [ "$3" ] && _commandLineOptionsArgs["$optspec"]="$3"
    [[ "$1" =~ ! ]] && _commandLineOptionsMandatory["$optspec"]=1

    return 0
}

# getOptions()
#   Parse the command line according to specifications entered by (possibly
#   repeated) usage of addOption().  
#
#   - EXPORTS an array named ARGV containing all the parameters left on the 
#     command line after parsing of options is finished;
#
#   - EXPORTS one or more array named _${OPTION}_VALUES for all those options
#     that can be specified more than once. These arrays contain the values
#     of the arguments specified on the command line. For example, if there
#     is a "-m" flag that can be spcified, and the command line is: 
#
#       ... -m 1 -m 3 ...
#
#     then the array _m_VALUES will contain the values 1 and 3. The array name
#     is returned by the valueOf() function, in place of the values, and the
#     values may be get as follows:
#
#       arr = $(valueOf "m")     # Same flag as above, returns "_m_VALUES"
#       arr = "${arr}[@]"        # Append [@] to the variable to retrieve values
#       for v in "${!arr}"; do   # "${!arr}" same as "${_m_VALUES[@]}"
#           ...
#
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
                printHelp "Missing argument to option: $OPTARG" >&2
                exit 1
                ;;
            '?')
                printHelp "Unknown option: $OPTARG" >&2
                exit 1
                ;;
            *)  
                _numArgs "$OPT"; numargs=$?
                case $numargs in
                    0)
                        _definedCommandLineFlags[$OPT]=1
                        ;;
                    1)
                        if hasOption "$OPT"; then
                            printHelp "Option -$OPT duplicated on command line. It's not a multi-valued option." >&2
                            exit 1
                        fi
                        _definedCommandLineOptions[$OPT]="$OPTARG"
                        ;;
                    2)
                        local array="_${OPT}_VALUES"
                        _definedCommandLineOptions[$OPT]="$array"
                        eval "export $array"
                        # declare -a "$array"  # NO! This makes this variable local.
                        eval "$array+=('$OPTARG')"
                        ;;
                    *)
                        echo "Probable script bug - invalid number of arguments for -$OPT: $numargs"
                        exit 2
                        ;;
                esac
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
            printHelp "Option ${m%:} is mandatory" >&2
            exit 1
        fi
    done

}



# hasOption()
#   Return true if specified option was given on command line.
#   JUST OPTIONS, not flags. For flags see isSet().
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
#   JUST FLAGS, not options. For options see hasOption().
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
#   Retrieve the value of the arg associated to the named option, or the name
#   of the array containing values for multi-valued options (see addOption
#   help).
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



# setHelp() 
#   Set a personalized help message (overrides help completely, including
#   usage string and help footer).
#
# Usage:
#   setHelp "${HELP_MESSAGE}"
#
function setHelp() {
    _HELP_MESSAGE="$1"
}

# setUsage()
#   Set a personalized "usage" line.
#
# Usage:
#   setUsage "Usage: $0 blah blah blah"
#
function setUsage() {
    _USAGE="$1"
}

# setHelpFooter()
#   Set a text to be printed after help.
#
# Usage:
#   setHelpFooter "${HELP_FOOTER}"
#
function setHelpFooter() {
    _HELP_FOOTER="$1"
}


# printHelp()
#   Prints the whole help string.
#
function printHelp() {

    # If user overrode help message, print that
    [ "$_HELP_MESSAGE" ] && {
        [ "$1" ] && echo "$*"
        echo -e "$_HELP_MESSAGE"
        return 0
    }
        

    local opts=''
    local flags=''
    local optlist=()

    for opt in "${!_commandLineOptionsHelp[@]}"; do
        if [[ $opt =~ : ]]; then
            arg=${_commandLineOptionsArgs["$opt"]}
            arg=${arg:-ARG}
            _isMandatory "$opt" && optlist+=("-${opt%:} $arg") || optlist+=("[-${opt%:} $arg]")
            opts+=$"      -${opt%:} $arg\n        ${_commandLineOptionsHelp[$opt]}\n"
            _isMultivalued "$opt" && opts+=$"        This option can be specified multiple times.\n"
        else
            _isMandatory "$opt" && optlist+=("-$opt") || optlist+=("[-$opt]")
            flags+=$"      -$opt\t${_commandLineOptionsHelp[$opt]}\n"
        fi
    done

    (
        [ "$1" ] && echo "$*"
        [ "$_USAGE" ] && echo -e "\n$_USAGE" || echo -e "\nUsage: $(basename $0) ${optlist[@]}\n"
        [ "$flags" ] && echo -e "    FLAGS\n$flags\n"
        [ "$opts"  ] && echo -e "    OPTIONS\n$opts\n"
        [ "$_HELP_FOOTER" ] && echo -e "\n$_HELP_FOOTER"
    ) | fold -w 80
}

