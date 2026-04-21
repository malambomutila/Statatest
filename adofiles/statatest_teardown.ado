*! version 1.1.0  21 Apr 2026  Malambo Mutila
* statatest_teardown: restore dataset snapshot saved by statatest_setup
program define statatest_teardown
    version 16
    syntax [, msg(string)]

    if `"$STTEST_snapshot"' == "" {
        display as error "statatest_teardown: no snapshot found — call statatest setup first"
        exit 198
    }

    if "`msg'" == "" local msg "dataset restored"

    quietly use `"$STTEST_snapshot"', clear
    display as text "  [teardown] `msg'"
end
