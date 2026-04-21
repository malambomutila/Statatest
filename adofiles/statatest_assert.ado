*! version 1.0.5  21 Apr 2026  Malambo Mutila
* statatest_assert: assert a boolean condition within a test suite
program define statatest_assert
    version 16
    syntax anything [, msg(string)]

    if "$STTEST_active" != "1" {
        display as error "statatest_assert called outside of a statatest_begin/end block."
        exit 198
    }

    if "`msg'" == "" local msg "assert `anything'"

    // Evaluate the condition safely; capture _rc so a syntax error fails gracefully
    capture assert `anything'
    local rc = _rc

    if `rc' == 0 {
        scalar __statatest_pass = __statatest_pass + 1
        display as text "  " as result "PASS" as text " : `msg'"
    }
    else {
        scalar __statatest_fail = __statatest_fail + 1
        display as text "  " as error "FAIL" as text " : `msg'"
        display as error "       (condition was false: `anything')"
    }
end
