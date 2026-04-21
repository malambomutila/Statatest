*! version 1.1.0  21 Apr 2026  Malambo Mutila
* statatest: unit-testing framework for Stata ado-files
program define statatest
    version 16

    if `"`0'"' == "" {
        display as text "statatest — a unit-testing framework for Stata ado-files"
        display as text ""
        display as text "Subcommands:"
        display as text "  statatest begin suite_name"
        display as text "  statatest assert condition [, msg(text)]"
        display as text "  statatest assert_equal expr expected [, msg(text)]"
        display as text "  statatest assert_approx expr expected [, tol(#) msg(text)]"
        display as text "  statatest assert_nomissing varlist [, msg(text)]"
        display as text "  statatest assert_unique varlist [, msg(text)]"
        display as text "  statatest assert_range varname [, min(#) max(#) msg(text)]"
        display as text "  statatest assert_nobs # [, msg(text)]"
        display as text "  statatest assert_varlist varnames [, msg(text)]"
        display as text "  statatest setup [, msg(text)]"
        display as text "  statatest teardown [, msg(text)]"
        display as text "  statatest expect_error command, rc(#) [msg(text)]"
        display as text "  statatest run filename.do [, strict]"
        display as text "  statatest end [, strict]"
        display as text ""
        display as text "Type help statatest for full documentation."
        exit 0
    }

    // gettoken peels off the first word as subcmd; args holds the remainder
    local args `"`0'"'
    gettoken subcmd args : args

    if "`subcmd'" == "begin" {
        statatest_begin `args'
    }
    else if "`subcmd'" == "assert" {
        statatest_assert `args'
    }
    else if "`subcmd'" == "assert_equal" {
        statatest_assert_equal `args'
    }
    else if "`subcmd'" == "assert_approx" {
        statatest_assert_approx `args'
    }
    else if "`subcmd'" == "assert_nomissing" {
        statatest_assert_nomissing `args'
    }
    else if "`subcmd'" == "assert_unique" {
        statatest_assert_unique `args'
    }
    else if "`subcmd'" == "assert_range" {
        statatest_assert_range `args'
    }
    else if "`subcmd'" == "assert_nobs" {
        statatest_assert_nobs `args'
    }
    else if "`subcmd'" == "assert_varlist" {
        statatest_assert_varlist `args'
    }
    else if "`subcmd'" == "setup" {
        statatest_setup `args'
    }
    else if "`subcmd'" == "teardown" {
        statatest_teardown `args'
    }
    else if "`subcmd'" == "expect_error" {
        statatest_expect_error `args'
    }
    else if "`subcmd'" == "run" {
        statatest_run `args'
    }
    else if "`subcmd'" == "end" {
        statatest_end `args'
    }
    else {
        display as error `"Unknown statatest subcommand: `subcmd'"'
        display as error "Valid subcommands: begin, assert, assert_equal, assert_approx,"
        display as error "                   assert_nomissing, assert_unique, assert_range,"
        display as error "                   assert_nobs, assert_varlist, setup, teardown,"
        display as error "                   expect_error, run, end"
        exit 198
    }
end
