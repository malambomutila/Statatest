*! version 1.0.5  21 Apr 2026  Malambo Mutila
* statatest_begin: initialise a test suite
program define statatest_begin
    version 16
    syntax [anything]

    if `"`anything'"' == "" {
        local suitename "unnamed"
    }
    else {
        local suitename `anything'
    }

    scalar __statatest_pass  = 0
    scalar __statatest_fail  = 0
    global STTEST_suite `"`suitename'"'
    global STTEST_active 1

    display as text _dup(60) "-"
    display as text "statatest suite: " as result `"`suitename'"'
    display as text _dup(60) "-"
end
