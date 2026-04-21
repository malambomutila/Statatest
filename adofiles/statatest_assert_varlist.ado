*! version 1.1.0  21 Apr 2026  Malambo Mutila
* statatest_assert_varlist: assert all named variables exist in the current dataset
program define statatest_assert_varlist
    version 16
    syntax anything [, msg(string)]

    if "$STTEST_active" != "1" {
        display as error "statatest_assert_varlist called outside of a statatest_begin/end block."
        exit 198
    }

    local missing_vars
    foreach v of local anything {
        capture confirm variable `v'
        if _rc local missing_vars `"`missing_vars' `v'"'
    }
    local missing_vars = strtrim("`missing_vars'")

    if "`msg'" == "" local msg "variables exist: `anything'"

    if "`missing_vars'" == "" {
        scalar __statatest_pass = __statatest_pass + 1
        display as text "  " as result "PASS" as text " : `msg'"
    }
    else {
        scalar __statatest_fail = __statatest_fail + 1
        display as text "  " as error "FAIL" as text " : `msg'"
        display as error "       missing variable(s): `missing_vars'"
    }
end
