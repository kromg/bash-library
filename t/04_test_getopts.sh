#!/usr/bin/bash
# vim: se et ts=4

set -e
    . ./testing_funcs.sh
    header getopts.sh
    . ../getopts.sh
set +e

tests 21

tlog "printing help in case of -h"
HELP="$(getOptions '-h')"
[[ $HELP =~ Usage: ]] || fail "-h does not print help"
pass

tlog "help of a flag"
HELP="$(addOption 'q' 'Be quiet'; getOptions "-h")"
[[ "$HELP" =~ 'Be quiet' ]] || fail "Could not set help of a flag"
pass

tlog "help of an option"
HELP="$(addOption 'k:' 'Force coefficient' "COEFFICIENT"; getOptions -h)"
[[ "$HELP" =~ '-k COEFFICIENT' ]] || fail "Could not set help of an option"
pass

tlog "help of a multi-valued option"
HELP2="$(addOption "m@" 'Multivalued' 'oneValue'; getOptions -h)"
[[ "$HELP2" =~ '-m oneValue' ]] || fail "Could not set help of a multi-valued option"
[[ "$HELP2" =~ 'This option can be specified multiple times' ]] || fail "Multi-valued help not explicit on multi-values"
pass

tlog "setting of a flag"
VERBOSE="$(getOptions '-v'; isSet v && echo "OK")"
[ $VERBOSE == OK ] || fail "-v does not set verbose"
pass

tlog "value of an option"
VALUE="$(addOption 'c:'; getOptions "-c" "OK"; valueOf "c")"
[ "$VALUE" == OK ] || fail "Could not get option value"
pass

tlog "detection of absence of a mandatory flag"
MISS_MANDATORY="$(addOption '!c:'; getOptions '-v' && echo "OK")"
[[ "$MISS_MANDATORY" =~ "is mandatory" ]] || fail "Mandatory option not detected"
pass

tlog "detection of absence of required argument"
MISS_ARG="$(addOption "c:"; getOptions "-c" && echo "OK")"
[[ "$MISS_ARG" =~ "Missing argument " ]] || fail "Required argument absence not detected"
[[ "$MISS_ARG" =~ "OK"                ]] && fail "Required argument absence not detected"
pass

tlog "detection of unconfigured option"
UNCONF="$(getOptions "-k" && echo "OK")"
[[ "$UNCONF" =~ "Unknown option: " ]] || fail "Unconfigured option not detected"
[[ "$UNCONF" =~ OK                 ]] && fail "Unconfigured option not detected"
pass

tlog "getting arguments"
ARGS="$(getOptions '-v' '-V' a b c d; echo "${ARGV[3]} ${ARGV[1]}")"
[ "$ARGS" == 'd b' ] || fail "Arguments are wrong: $ARGS"
pass

tlog "forbidding ? as option"
QM="$(addOption '?' 'QuestionMark!' 2>&1 ; getOptions '-?')"
[[ "$QM" =~ 'getopts reserved character' ]] || fail "Failed to recognize '?' as a reserved character"
pass

tlog "option already added 1/4"
AD="$(addOption 'c' 'Flag'; addOption 'c' 'Flag2'; getOptions '-c')"
[[ "$AD" =~ 'already been added' ]] || fail "Failed to recognize duplicated flag"
pass

tlog "option already added 2/4"
AD="$(addOption 'c' 'Flag'; addOption 'c:' 'Option'; getOptions '-c')"
[[ "$AD" =~ 'already been added' ]] || fail "Failed to recognize duplicated flag/option"
pass

tlog "option already added 3/4"
AD="$(addOption 'c:' 'Option'; addOption 'c' 'Flag'; getOptions '-c')"
[[ "$AD" =~ 'already been added' ]] || fail "Failed to recognize duplicated option/flag"
pass

tlog "option already added 4/4"
AD="$(addOption 'c:' 'Option'; addOption 'c:' 'Option2'; getOptions '-c')"
[[ "$AD" =~ 'already been added' ]] || fail "Failed to recognize duplicated option"
pass

tlog "multi-valued option add"
MVA="$(addOption 'm@' && echo "OK")"
[ "$MVA" == OK ] || fail "Failed to add multi-valued option"
pass

tlog "mandatory multi-valued option add"
MVA2="$(addOption '!m@' && echo "OK")"
[ "$MVA2" == OK ] || fail "Failed to add mandatory multi-valued option"
pass

tlog "mandatory multi-valued option detection"
MMVD="$(addOption '!m@'; addOption 'c'; getOptions '-c' && echo "OK")"
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
[ "$MVR" == "X1XX2 3 4XX5 6XX7X" ] || fail "Failed to retrieve multi-values"
pass


done_testing

