*! version 1.1.0  21 Apr 2026  Malambo Mutila
* statatest_run: run a test do-file and print a session-level summary
program define statatest_run, rclass
    version 16
    syntax anything [, strict]

    local dofile `anything'

    // Save any active outer suite state so nested runs don't corrupt it
    local outer_active  "$STTEST_active"
    local outer_suite   `"$STTEST_suite"'
    if "`outer_active'" == "1" {
        local outer_pass = __statatest_pass
        local outer_fail = __statatest_fail
        global STTEST_active   // temporarily suspend outer suite
    }

    // Initialise session-level counters
    scalar __statatest_session_pass   = 0
    scalar __statatest_session_fail   = 0
    scalar __statatest_session_suites = 0
    global STTEST_running 1

    display as text _dup(60) "="
    display as text "statatest run: " as result `"`dofile'"'
    display as text _dup(60) "="

    capture noisily do `"`dofile'"'
    local run_rc = _rc

    local sp = __statatest_session_pass
    local sf = __statatest_session_fail
    local ss = __statatest_session_suites
    local st = `sp' + `sf'

    // Clean up session globals
    global STTEST_running
    capture scalar drop __statatest_session_pass
    capture scalar drop __statatest_session_fail
    capture scalar drop __statatest_session_suites

    // Restore outer suite state if we suspended it
    if "`outer_active'" == "1" {
        global STTEST_active 1
        global STTEST_suite `"`outer_suite'"'
        scalar __statatest_pass = `outer_pass'
        scalar __statatest_fail = `outer_fail'
    }

    display as text _dup(60) "="
    if `run_rc' != 0 {
        display as error `"Run aborted: do-file error (rc=`run_rc')"'
    }
    else if `sf' == 0 {
        display as result `"`sp' / `st' tests passed across `ss' suite(s)"' ///
            as text ": " as result "ALL PASS"
    }
    else {
        display as error `"`sf' / `st' tests FAILED across `ss' suite(s)"'
    }
    display as text _dup(60) "="

    return scalar pass   = `sp'
    return scalar fail   = `sf'
    return scalar total  = `st'
    return scalar suites = `ss'

    if "`strict'" != "" & (`sf' > 0 | `run_rc' != 0) {
        display as error "Strict mode: `sf' test(s) failed."
        exit 1
    }
end
