#!/usr/bin/bash
# vim: se et ts=4

# Save STDOUT & STDERR
exec 3<&1
exec 4<&2

set -e
. ./testing_funcs.sh
. ../bashHelpers.sh
set +e

tests 17

tlog "Testing functionExists for existence"
functionExists tlog || fail "functionExists() can't find tlog() function"
pass

tlog "Testing functionExists for non-existence"
! functionExists _bkasjhjhuhdsk_ || fail "functionExists() returns true on non-existent function"
pass


skip "Testing printCallStack is difficult"


tlog "Testing isNumber on a number"
isNumber 4 || fail "isNumber() doesn't recognize 4 as a number"
pass

tlog "Testing isNumber on a string"
! isNumber a || fail "isNumber() returns true on a string"
pass



tlog "Testing isPositive on a negative number"
! isPositive -4 || fail "isPositive() doesn't recognize -4 as a (negative) number"
pass

tlog "Testing isPositive on a positive number"
isPositive 4 || fail "isPositive() doesn't recognize 4 as a (positive) number"
pass

tlog "Testing isPositive on 0"
! isPositive 0 || fail "isPositive() doesn't recognize 0 as a (non-positive) number"
pass

tlog "Testing isPositive on a string"
! isPositive a || fail "isPositive() returns true on a string"
pass


tlog "Testing isNatural on a negative number"
! isNatural -4 || fail "isNatural() doesn't recognize -4 as a (negative) number"
pass

tlog "Testing isNatural on a positive number"
isNatural 4 || fail "isNatural() doesn't recognize 4 as a (positive) number"
pass

tlog "Testing isNatural on 0"
isNatural 0 || fail "isNatural() doesn't recognize 0 as a (non-positive) number"
pass

tlog "Testing isNatural on a string"
! isNatural a || fail "isNatural() returns true on a string"
pass



tlog "Testing count"
[ "$( count a b c )" == 3 ] || fail "count() returns wrong count"
pass


tlog "Testing uc()"
[ "$(uc uppercase)" == "UPPERCASE" ] || fail "uc() failed"
pass


tlog "Testing lc()"
[ "$(lc LOWERCASE)" == "lowercase" ] || fail "lc() failed"
pass



tlog "Testing throwException"

function f1() {
    f2
}

function f2() {
    f3
}

function f3() {
    throwException "TESTCASE"
}

# Expected output:
#   Exception: TESTCASE
#   Stack trace for f3():
#     f3 called @./01_test_bashHelpers.sh:LINE[95]
#       f2 called @./01_test_bashHelpers.sh:LINE[91]
#         f1 called @./01_test_bashHelpers.sh:LINE[102]

except="$(set +x; f1 2>&1 1>/dev/null; echo "TEST FAILED")"
ret="$?"
echo "$except" | grep -q 'TEST FAILED' && fail "throwException() does not exit()"
[ "$ret" == 1 ] || fail "throwException() does not exit() with return code: 1"

for o in "TESTCASE" "Stack trace for f3" "f3 called @" "f2 called @" "f1 called @"; do
    echo "$except" | grep -q "$o" || fail "throwException(): string \"$o\" not found in output"
done
pass


done_testing

