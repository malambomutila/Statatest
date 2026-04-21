*! version 1.1.0  21 Apr 2026  Malambo Mutila
* statatest_end: finalise a test suite and print a summary
program define statatest_end, rclass
    version 16
    syntax [, strict]

    if "$STTEST_active" != "1" {
        display as error "statatest_end called without a matching statatest_begin."
        exit 198
    }

    local pass = __statatest_pass
    local fail = __statatest_fail
    local total = `pass' + `fail'

    display as text _dup(60) "-"
    if `fail' == 0 {
        display as result `"`pass' / `total' tests passed"' ///
            as text "  —  " as result "ALL PASS" as text "  [$STTEST_suite]"
    }
    else {
        display as error `"`fail' / `total' tests FAILED"' ///
            as text "  —  [$STTEST_suite]"
    }
    display as text _dup(60) "-"

    // Accumulate into session totals when called from statatest run
    if "$STTEST_running" == "1" {
        capture {
            scalar __statatest_session_pass   = __statatest_session_pass   + `pass'
            scalar __statatest_session_fail   = __statatest_session_fail   + `fail'
            scalar __statatest_session_suites = __statatest_session_suites + 1
        }
    }

    // Clean up globals
    global STTEST_active
    global STTEST_suite

    // Return results
    return scalar pass  = `pass'
    return scalar fail  = `fail'
    return scalar total = `total'

    // If --strict-- is set, exit non-zero when any test failed
    if "`strict'" != "" & `fail' > 0 {
        display as error "Strict mode: exiting with error because `fail' test(s) failed."
        exit 1
    }
end
