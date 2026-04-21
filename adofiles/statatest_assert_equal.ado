*! version 1.0.5  21 Apr 2026  Malambo Mutila
* statatest_assert_equal: assert that two expressions evaluate to the same value
* Works for numeric expressions (r(), e(), scalars, expressions) and quoted strings.
program define statatest_assert_equal
    version 16
    // Syntax: statatest_assert_equal <actual> <expected> [, msg(string)]
    // Both tokens are passed unquoted; put strings in double quotes if needed.
    syntax anything [, msg(string)]

    if "$STTEST_active" != "1" {
        display as error "statatest_assert_equal called outside of a statatest_begin/end block."
        exit 198
    }

    tokenize `"`anything'"'
    local actual   `"`1'"'
    local expected `"`2'"'

    if "`msg'" == "" local msg "`actual' == `expected'"

    // Try numeric evaluation of both sides first.
    // `= expr' evaluates the expression; if it fails, fall through to string comparison.
    capture {
        local aval = `actual'
        local eval = `expected'
    }
    if _rc == 0 {
        // Both evaluated as numbers; compare numerically
        if `aval' == `eval' {
            scalar __statatest_pass = __statatest_pass + 1
            display as text "  " as result "PASS" as text " : `msg'"
        }
        else {
            scalar __statatest_fail = __statatest_fail + 1
            display as text "  " as error "FAIL" as text " : `msg'"
            display as error "       expected `eval', got `aval'"
        }
    }
    else {
        // Fall back to string comparison (for quoted string arguments)
        if `"`actual'"' == `"`expected'"' {
            scalar __statatest_pass = __statatest_pass + 1
            display as text "  " as result "PASS" as text " : `msg'"
        }
        else {
            scalar __statatest_fail = __statatest_fail + 1
            display as text "  " as error "FAIL" as text " : `msg'"
            display as error `"       expected "`expected'", got "`actual'""'
        }
    }
end
