*! version 1.1.0  21 Apr 2026  Malambo Mutila
* statatest_assert_nobs: assert the dataset has exactly N observations
program define statatest_assert_nobs
    version 16
    syntax anything [, msg(string)]

    if "$STTEST_active" != "1" {
        display as error "statatest_assert_nobs called outside of a statatest_begin/end block."
        exit 198
    }

    local expected = `anything'
    local actual   = c(N)

    if "`msg'" == "" local msg "`actual' == `expected' obs"

    if `actual' == `expected' {
        scalar __statatest_pass = __statatest_pass + 1
        display as text "  " as result "PASS" as text " : `msg'"
    }
    else {
        scalar __statatest_fail = __statatest_fail + 1
        display as text "  " as error "FAIL" as text " : `msg'"
        display as error "       expected `expected' observations, got `actual'"
    }
end
