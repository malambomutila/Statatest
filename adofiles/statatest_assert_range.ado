*! version 1.1.0  21 Apr 2026  Malambo Mutila
* statatest_assert_range: assert all non-missing values of a variable fall within bounds
program define statatest_assert_range
    version 16
    syntax varname [, min(numlist max=1) max(numlist max=1) msg(string)]

    if "$STTEST_active" != "1" {
        display as error "statatest_assert_range called outside of a statatest_begin/end block."
        exit 198
    }

    if "`min'" == "" & "`max'" == "" {
        display as error "statatest_assert_range: specify at least min() or max()"
        exit 198
    }

    local has_min = "`min'" != ""
    local has_max = "`max'" != ""

    if `has_min' & `has_max' {
        quietly count if !mi(`varlist') & (`varlist' < `min' | `varlist' > `max')
        local rangedesc "[`min', `max']"
    }
    else if `has_min' {
        quietly count if !mi(`varlist') & `varlist' < `min'
        local rangedesc ">= `min'"
    }
    else {
        quietly count if !mi(`varlist') & `varlist' > `max'
        local rangedesc "<= `max'"
    }

    local nout = r(N)
    if "`msg'" == "" local msg "`varlist' `rangedesc'"

    if `nout' == 0 {
        scalar __statatest_pass = __statatest_pass + 1
        display as text "  " as result "PASS" as text " : `msg'"
    }
    else {
        scalar __statatest_fail = __statatest_fail + 1
        display as text "  " as error "FAIL" as text " : `msg'"
        display as error "       `nout' value(s) outside `rangedesc'"
    }
end
