*! version 1.1.0  21 Apr 2026  Malambo Mutila
* statatest_expect_error: assert a command exits with a specific return code
program define statatest_expect_error
    version 16
    syntax anything, rc(integer) [msg(string)]

    if "$STTEST_active" != "1" {
        display as error "statatest_expect_error called outside of a statatest_begin/end block."
        exit 198
    }

    if "`msg'" == "" local msg "rc(`rc') from: `anything'"

    capture `anything'
    local actual_rc = _rc

    if `actual_rc' == `rc' {
        scalar __statatest_pass = __statatest_pass + 1
        display as text "  " as result "PASS" as text " : `msg'"
    }
    else if `actual_rc' == 0 {
        scalar __statatest_fail = __statatest_fail + 1
        display as text "  " as error "FAIL" as text " : `msg'"
        display as error "       expected rc(`rc'), command succeeded (rc=0)"
    }
    else {
        scalar __statatest_fail = __statatest_fail + 1
        display as text "  " as error "FAIL" as text " : `msg'"
        display as error "       expected rc(`rc'), got rc(`actual_rc')"
    }
end
