#!/usr/bin/bash
# vim: se et ts=4

set -e
    . ./testing_funcs.sh
    header getopts.sh
    . ../getopts.sh
set +e

tests 29

tlog "printing help in case of -h"
HELP="$(getOptions '-h')"
[[ $HELP =~ Usage: ]] || fail "-h does not print help"
pass

tlog "help of a flag"
HELP="$(addOption 'q' 'Be quiet'; getOptions -h)"
[[ "$HELP" =~ 'Be quiet' ]] || fail "Could not set help of a flag"
pass

tlog "help of an option"
HELP="$(addOption -a "COEFFICIENT" 'k:' 'Force coefficient'; getOptions -h)"
[[ "$HELP" =~ '-k COEFFICIENT' ]] || fail "Could not set help of an option"
[[ "$HELP" =~ 'This option can be specified multiple times' ]] && fail "Single-valued option read as multi-valued"
pass

tlog "help of a multi-valued option"
HELP2="$(addOption -a 'oneValue' "m@" 'Multivalued'; getOptions -h)"
[[ "$HELP2" =~ '-m oneValue' ]] || fail "Could not set help of a multi-valued option"
[[ "$HELP2" =~ 'This option can be specified multiple times' ]] || fail "Multi-valued help not explicit on multi-values"
pass

tlog "help of an option with no help"
HELP3="$(addOption 'k:'; getOptions -h)"
[[ "$HELP3" =~ '-k <ARG>' ]] || fail "Options with no help are excluded from help screen"
pass

tlog "setting of a flag"
VERBOSE="$(getOptions '-v'; isSet v && echo "OK")"
[ $VERBOSE == OK ] || fail "-v does not set verbose"
pass

tlog "value of an option"
VALUE="$(addOption 'c:'; getOptions "-c" "OK"; valueOf "c")"
[ "$VALUE" == OK ] || fail "Could not get option value"
pass

tlog "value with default"
VALUE2="$(addOption -d 'DEFAULT' 'c:'; getOptions "-c" "OK"; valueOf "c")"
[ "$VALUE2" == OK ] || fail "Could not get option value with default"
pass

tlog "value with default and no value"
VALUE3="$(addOption -d 'DEFAULT' 'c:'; getOptions; valueOf "c")"
[ "$VALUE3" == DEFAULT ] || fail "Could not get option default value"
pass

tlog "help with default"
VALUED="$(addOption -d 'defaultVal' 'c:' 'Help string'; getOptions -h)"
[[ "$VALUED" =~ 'Default: defaultVal' ]] || fail "Default value not listed in help"
pass

tlog "detection of absence of a mandatory flag"
MISS_MANDATORY="$(addOption '!c:'; getOptions '-v' 2>&1 && echo "OK")"
[[ "$MISS_MANDATORY" =~ "is mandatory" ]] || fail "Mandatory option not detected"
pass

tlog "detection of absence of required argument"
MISS_ARG="$(addOption "c:"; getOptions "-c" 2>&1 && echo "OK")"
[[ "$MISS_ARG" =~ "Missing argument " ]] || fail "Required argument absence not detected"
[[ "$MISS_ARG" =~ "OK"                ]] && fail "Required argument absence not detected"
pass

tlog "detection of unconfigured option"
UNCONF="$(getOptions "-k" 2>&1 && echo "OK")"
[[ "$UNCONF" =~ "Unknown option: " ]] || fail "Unconfigured option not detected"
[[ "$UNCONF" =~ OK                 ]] && fail "Unconfigured option not detected"
pass

tlog "getting arguments"
ARGS="$(getOptions '-v' '-V' a b c d; echo "${ARGV[3]} ${ARGV[1]}")"
[ "$ARGS" == 'd b' ] || fail "Arguments are wrong: $ARGS"
pass

tlog "forbidding ? as option"
QM="$(addOption '?' 'QuestionMark!' 2>&1 ; getOptions '-?')"
[[ "$QM" =~ 'getopts reserved character' ]] || fail "faild to recognize '?' as a reserved character"
pass

tlog "option already added 1/4"
AD="$(addOption 'c' 'Flag'; addOption 'c' 'Flag2'; getOptions '-c')"
[[ "$AD" =~ 'already been added' ]] || fail "faild to recognize duplicated flag"
pass

tlog "option already added 2/4"
AD="$(addOption 'c' 'Flag'; addOption 'c:' 'Option'; getOptions '-c')"
[[ "$AD" =~ 'already been added' ]] || fail "faild to recognize duplicated flag/option"
pass

tlog "option already added 3/4"
AD="$(addOption 'c:' 'Option'; addOption 'c' 'Flag'; getOptions '-c')"
[[ "$AD" =~ 'already been added' ]] || fail "faild to recognize duplicated option/flag"
pass

tlog "option already added 4/4"
AD="$(addOption 'c:' 'Option'; addOption 'c:' 'Option2'; getOptions '-c')"
[[ "$AD" =~ 'already been added' ]] || fail "faild to recognize duplicated option"
pass

tlog "detection of duplicated opts on command line"
DO="$(addOption 'c:' 'Option'; getOptions '-c' 1 '-c' 2 2>&1)"
[[ "$DO" =~ 'duplicated on command line' ]] || fail "Duplicated options on cmdline not detected"
pass

tlog "multi-valued option add"
MVA="$(addOption 'm@' && echo "OK")"
[ "$MVA" == OK ] || fail "faild to add multi-valued option"
pass

tlog "mandatory multi-valued option add"
MVA2="$(addOption '!m@' && echo "OK")"
[ "$MVA2" == OK ] || fail "faild to add mandatory multi-valued option"
pass

tlog "mandatory multi-valued option detection"
MMVD="$(addOption '!m@'; addOption 'c'; getOptions '-c' 2>&1 && echo "OK")"
[[ "$MMVD" =~ "Option m is mandatory" ]] || fail "Mandatory multi-valued option not recognized as mandatory"
pass

tlog "multi-valued opt parsing"
MVP="$(addOption 'm@'; getOptions '-m' 1 '-m' 2 && echo "OK")"
[ "$MVP" == OK ] || fail "Multi-valued option parsing returned error"
pass

tlog "multi-valued opt value (array name)"
MVV="$(addOption 'm@'; getOptions '-m' 1 '-m' 2 && valueOf 'm')"
[ "$MVV" == _m_VALUES ] || fail "Multi-valued valueOf() does not return array name"
pass

tlog "multi-valued opt value (real)"
MVR="$(addOption 'm@'; getOptions '-m' 1 '-m' '2 3 4' -m '5 6' -m 7 && arr="$(valueOf 'm')[@]"; for v in "${!arr}"; do echo -n "X${v}X"; done)"
[ "$MVR" == "X1XX2 3 4XX5 6XX7X" ] || fail "faild to retrieve multi-values"
pass

tlog "usage overriding"
UO="$(addOption -a 'c-arg' 'c:' 'c Help'; setUsage "Usage and blah blah blah"; getOptions '-h')"
[[ "$UO" =~ 'Usage and blah blah blah' ]] || fail "setUsage() not setting usage"
[[ "$UO" =~ $(basename $0) ]] && fail "setUsage() not overriding usage"
[[ "$UO" =~ '-c c-arg' ]] || fail "setUsage() altering help"
pass

tlog "help footer"
HF="$(addOption -a 'c-arg' 'c:' 'c Help'; setHelpFooter "THIS MESSAGE AFTER ALL"; getOptions '-h')"
[[ "$HF" =~ 'THIS MESSAGE AFTER ALL' ]] || fail "setHelpFooter() not setting footer"
[[ "$HF" =~ $(basename $0) ]] || fail "setHelpFooter() overriding usage"
[[ "$HF" =~ '-c c-arg' ]] || fail "setHelpFooter() altering help"
pass

tlog "override help"
OH="$(addOption -a 'c-arg' 'c:' 'c Help'; setHelp "Usage and blah blah blah"; getOptions '-h')"
[[ "$OH" =~ 'Usage and blah blah blah' ]] || fail "setHelp() not setting help"
[[ "$OH" =~ $(basename $0) ]] && fail "setHelp() not overriding usage"
[[ "$OH" =~ '-c c-arg' ]] && fail "setHelp() not overriding help"
pass

done_testing

