#!/usr/bin/bash
# vim: se et ts=4

set -e
. ./testing_funcs.sh
. ../logging.sh
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


tests 5


caption "Creating log..."
LOG='/tmp/test.log'
> $LOG || fail "Unable to write to $LOG"



tlog "Redirecting STDOUT"
openLog $LOG || fail "Unable to redirect STDOUT"
pass

tlog "Redirecting STDERR"
openErr $LOG || fail "Unable to redirect STDERR"
pass




tlog "Logging one message per loglevel"

check_normal_loglevels

debug  "This is not logged"
grep -q "This is not logged" $LOG && fail "debug() logged in default configuration"

trace  "This is not logged"
grep -q "This is not logged" $LOG && fail "trace() logged in default configuration"

pass




> $LOG || fail "Unable to clobber $LOG"


tlog "Checking logs with maximum loglevel"

setLogLevel TRACE || fail "setLogLevel() TRACE failed"

check_normal_loglevels

debug  "This is a debug message"
grep 'DEBUG' $LOG | grep -q "This is a debug message" || fail "debug() failed"

trace  "This is a trace message"
grep 'TRACE' $LOG | grep -q "This is a trace message" || fail "trace() failed"

pass


tlog "Checking wether fatal() dies correctly"
( fatal "This is a fatal error"; info "This must not be logged" )
[ "$?" != 1 ] && fail "fatal() failed to die properly"
grep 'FATAL' $LOG | grep -q "his is a fatal error" || fail "fatal() failed"
grep -q "This must not be logged" $LOG && fail "fatal() did not cause subshell to exit"
pass


done_testing

