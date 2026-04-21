*! version 1.0.5  21 Apr 2026  Malambo Mutila
* statatest_assert_approx: assert two numeric values are equal within tolerance
program define statatest_assert_approx
    version 16
    syntax anything [, tol(real 1e-7) msg(string)]

    if "$STTEST_active" != "1" {
        display as error "statatest_assert_approx called outside of a statatest_begin/end block."
        exit 198
    }

    tokenize `"`anything'"'
    local actual   `"`1'"'
    local expected `"`2'"'

    if "`msg'" == "" local msg "`actual' ≈ `expected' (tol=`tol')"

    local aval = `actual'
    local eval = `expected'
    local diff = abs(`aval' - `eval')

    if `diff' <= `tol' {
        scalar __statatest_pass = __statatest_pass + 1
        display as text "  " as result "PASS" as text " : `msg'"
    }
    else {
        scalar __statatest_fail = __statatest_fail + 1
        display as text "  " as error "FAIL" as text " : `msg'"
        display as error "       expected `eval' ± `tol', got `aval' (diff=`diff')"
    }
end
