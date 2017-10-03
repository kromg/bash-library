#!/usr/bin/bash
# vim: se et ts=4

function test_exList() {
    export list="$(_expandList "$@" )"|| fail "_expandList() returned non-ok status code"
}

function check_against() {
    [ "$list" == "$1" ] || fail "Wrong list returned: $list"
}

set -e
    . ./testing_funcs.sh
    header crontab.sh
    . ../crontab.sh
set +e

# Enlarge the space available for testing message output
export _LINE_LENGTH=80

tests 23

# Minutes
tlog "Testing _expandMin *"
test_exList min any
check_against '0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59'
pass

tlog "Testing _expandMin */5"
test_exList min any/5
check_against '0 5 10 15 20 25 30 35 40 45 50 55'
pass

tlog "Testing _expandMin 3-59/5"
test_exList min 3-59/5
check_against '3 8 13 18 23 28 33 38 43 48 53 58'
pass

tlog "Testing _expandMin 3-20/5,21,22,23,40-59/2"
test_exList min 3-20/5,21,22,23,40-59/2
check_against '3 8 13 18 21 22 23 40 42 44 46 48 50 52 54 56 58'
pass



# Hours
tlog "Testing _expandHour *"
test_exList hour any
check_against '0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23'
pass

tlog "Testing _expandHour */5"
test_exList hour any/5
check_against '0 5 10 15 20'
pass

tlog "Testing _expandHour 2-23/3"
test_exList hour 2-23/3
check_against '2 5 8 11 14 17 20 23'
pass

tlog "Testing _expandHour 3-15/5,16,17,18-23/2"
test_exList hour 3-15/5,16,17,18-23/2
check_against '3 8 13 16 17 18 20 22'
pass


# Week days
tlog "Testing _expandWDay *"
test_exList wday any
check_against '1 2 3 4 5 6 7'
pass

tlog "Testing _expandWDay */2"
test_exList wday any/2
check_against '1 3 5 7'
pass

tlog "Testing _expandWDay 1-4/2"
test_exList wday 1-4/2
check_against '1 3'
pass

tlog "Testing _expandWDay 0-4/2,4,5"
test_exList wday 0-4/2,4,5
check_against '2 4 5 7'
pass

tlog "Testing _expandWDay sun-wed/2,thu,sat"
test_exList wday sun-wed/2,thu,sat
check_against '2 4 6 7'
pass

tlog "Testing _expandWDay mon,tue,wed,fri-sun/2"
test_exList wday mon,tue,wed,fri-sun/2
check_against '1 2 3 5 7'
pass



# Month days
tlog "Testing _expandMDay *"
test_exList mday any
check_against '1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31'
pass

tlog "Testing _expandMDay */5"
test_exList mday any/5
check_against '1 6 11 16 21 26 31'
pass

tlog "Testing _expandMDay 2-23/3"
test_exList mday 2-23/3
check_against '2 5 8 11 14 17 20 23'
pass

tlog "Testing _expandMDay 3-15/5,16,17,18-23/2,30,31"
test_exList mday 3-15/5,16,17,18-23/2,30,31
check_against '3 8 13 16 17 18 20 22 30 31'
pass




# Months
tlog "Testing _expandMon *"
test_exList mon any
check_against '1 2 3 4 5 6 7 8 9 10 11 12'
pass

tlog "Testing _expandMon */2"
test_exList mon any/2
check_against '1 3 5 7 9 11'
pass

tlog "Testing _expandMon 1-9/2"
test_exList mon 1-9/2
check_against '1 3 5 7 9'
pass

tlog "Testing _expandMon 1-7/2,4,6,7-12/3"
test_exList mon 1-7/2,4,6,7-12/3
check_against '1 3 4 5 6 7 10'
pass

tlog "Testing _expandMon jan-jul/3,aug,sep,oct-dec/2"
test_exList mon jan-jul/3,aug,sep,oct-dec/2
check_against '1 4 7 8 9 10 12'
pass


done_testing

