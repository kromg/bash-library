#!/usr/bin/bash
# vim: se et ts=4

set -e
. ./testing_funcs.sh
. ../locking.sh
set +e

function check_normal_loglevels() {
    err    "This is an error"
    grep 'ERROR' $LOG   | grep -q "This is an error" || fail "err() failed"

    warn    "This is a warning"
    grep 'WARNING' $LOG | grep -q "This is a warning" || fail "warn() failed"

    notice "This is a notice"
    grep 'NOTICE' $LOG  | grep -q "This is a notice" || fail "notice() failed"

    log   "This is an info"
    grep 'INFO' $LOG    | grep -q "This is an info" || fail "log() failed"
}


tests 6


function spawnLocker() {
    local LOCKOPT="$1"
    local LOCKFILE="$2"
    local SLEEP="$3"
    if [ "$LOCKOPT" == shared ]; then
        ( ( sharedLock "$LOCKFILE" && sleep 100 & ) & )
    else
        ( ( lock "$LOCKFILE" && sleep 100 & ) & )
    fi
    usleep 150000 # Let the process take the lock
}


caption "Creating a locking process..."
LOCKFILE=$(mktemp /tmp/XXXXXX)
spawnLocker exclusive "$LOCKFILE" 10

tlog "lock() must fail"
lock "$LOCKFILE";          ret="$?"; [ "$ret" == 2 ] || fail "lock() returned $ret ( != 2)"
pass

tlog "exclusiveLock() must fail"
exclusiveLock "$LOCKFILE"; ret="$?"; [ "$ret" == 2 ] || fail "exclusiveLock() returned $ret ( != 2)"
pass

tlog "sharedLock() must fail"
sharedLock "$LOCKFILE";    ret="$?"; [ "$ret" == 2 ] || fail "sharedLock() returned $ret ( != 2)"
pass

rm -f "$LOCKFILE"

caption "Spawning a shared locker"
LOCKFILE=$(mktemp /tmp/XXXXXX)
spawnLocker shared "$LOCKFILE" 10


tlog "lock() must fail"
lock "$LOCKFILE";          ret="$?"; [ "$ret" == 2 ] || fail "sharedLock() returned $ret ( != 2)"
pass

tlog "exclusiveLock() must fail"
exclusiveLock "$LOCKFILE"; ret="$?"; [ "$ret" == 2 ] || fail "sharedLock() returned $ret ( != 2)"
pass

tlog "sharedLock() must succeed"
sharedLock "$LOCKFILE" || fail "$LOCKFILE is locked exclusively"
pass

rm -f "$LOCKFILE"


# TODO: testing exclusiveLockWait() and sharedLockWait(), which is a bit more complicated


done_testing

