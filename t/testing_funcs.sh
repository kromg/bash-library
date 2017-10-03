#!/usr/bin/bash
# vim: se et ts=4:

# Always log to "real" STDOUT/STDERR, even if other functions redirect them
exec 3<&1
exec 4<&2

export _DONE_TESTS=0
export _LINE_LENGTH=60

# Redefine die() and log() for testing
function fail() {
    echo -e "\033[${_LINE_LENGTH}G\033[1;31mFAIL\\033[0;39m\n\t$*" >&4
    exit 1
}

function header() {
    echo -e "\n\n ============== TESTING $1 ==============\n" >&3
}

function caption() {
    echo ".... $*" >&3
}

function tlog() {
    printf "TEST (%${_PAD}d/%${_PAD}d): %s" "$(( $_DONE_TESTS + 1 ))" "$_DECLARED_TESTS" "$*" >&3
}

function pass() {
    echo -e "\033[${_LINE_LENGTH}G\033[1;32mPASSED\\033[0;39m" >&3
    ((_DONE_TESTS++))
}

function skip() {
    echo -ne "SKIP: $*" >&3
    echo -e "\033[${_LINE_LENGTH}G\033[1;33mSKIPPED\\033[0;39m" >&3
    ((_DONE_TESTS++))
}

function tests() {
    export _BEFORE="$(date +%s.%N)"
    export _DECLARED_TESTS="$1"
    export _PAD="${#_DECLARED_TESTS}"
}

function done_testing() {

    echo "*****" >&3
    echo -ne  "     Verifying TEST SUITE" >&3
    [ "$_DONE_TESTS" == "$_DECLARED_TESTS" ] || \
        fail "$_DECLARED_TESTS tests were declared but $_DONE_TESTS actually ran"

    pass

    printf "Total run time: %.3fms\n" "$( echo "scale=20;$(date +%s.%N) - $_BEFORE" | bc )" >&3

}
