*! version 1.1.0  21 Apr 2026  Malambo Mutila
* statatest_setup: save a dataset snapshot for restoration by statatest_teardown
program define statatest_setup
    version 16
    syntax [, msg(string)]

    if "`msg'" == "" local msg "dataset snapshot saved"

    // Fixed path in c(tmpdir) -- only one snapshot at a time
    local snapfile "`c(tmpdir)'/statatest_snapshot.dta"
    quietly save `"`snapfile'"', replace
    global STTEST_snapshot `"`snapfile'"'

    display as text "  [setup] `msg'"
end
