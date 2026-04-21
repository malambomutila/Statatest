*! version 1.1.0  21 Apr 2026  Malambo Mutila
* statatest_assert_unique: assert no duplicate values for a varlist key
program define statatest_assert_unique
    version 16
    syntax varlist [, msg(string)]

    if "$STTEST_active" != "1" {
        display as error "statatest_assert_unique called outside of a statatest_begin/end block."
        exit 198
    }

    if "`msg'" == "" {
        if `:list sizeof varlist' == 1 local msg "`varlist' is unique"
        else                           local msg "(`varlist') is a unique key"
    }

    tempvar _dup
    quietly duplicates tag `varlist', generate(`_dup')
    quietly count if `_dup' > 0
    local ndup = r(N)

    if `ndup' == 0 {
        scalar __statatest_pass = __statatest_pass + 1
        display as text "  " as result "PASS" as text " : `msg'"
    }
    else {
        scalar __statatest_fail = __statatest_fail + 1
        display as text "  " as error "FAIL" as text " : `msg'"
        display as error "       `ndup' non-unique observation(s) on: `varlist'"
    }
end
