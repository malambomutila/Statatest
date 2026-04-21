*! version 1.1.0  21 Apr 2026  Malambo Mutila
* statatest_assert_nomissing: assert no missing values in a varlist
program define statatest_assert_nomissing
    version 16
    syntax varlist [, msg(string)]

    if "$STTEST_active" != "1" {
        display as error "statatest_assert_nomissing called outside of a statatest_begin/end block."
        exit 198
    }

    local nmissing 0
    local badvars
    foreach v of local varlist {
        quietly count if mi(`v')
        if r(N) > 0 {
            local nmissing = `nmissing' + r(N)
            local badvars `"`badvars' `v'"'
        }
    }

    if "`msg'" == "" {
        if `:list sizeof varlist' == 1 local msg "no missing in `varlist'"
        else                           local msg "no missing in (`varlist')"
    }

    if `nmissing' == 0 {
        scalar __statatest_pass = __statatest_pass + 1
        display as text "  " as result "PASS" as text " : `msg'"
    }
    else {
        scalar __statatest_fail = __statatest_fail + 1
        display as text "  " as error "FAIL" as text " : `msg'"
        display as error "       `nmissing' missing value(s) in:`badvars'"
    }
end
