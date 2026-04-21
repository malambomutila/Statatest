{smcl}
{* *! version 1.1.0  21 Apr 2026  Malambo Mutila}{...}
{viewerjumpto "Syntax" "statatest##syntax"}{...}
{viewerjumpto "Description" "statatest##description"}{...}
{viewerjumpto "Options" "statatest##options"}{...}
{viewerjumpto "Examples" "statatest##examples"}{...}
{viewerjumpto "Stored results" "statatest##results"}{...}
{viewerjumpto "Installation" "statatest##install"}{...}
{viewerjumpto "Author" "statatest##author"}{...}
{viewerjumpto "Also see" "statatest##alsosee"}{...}
{title:Title}

{phang}
{bf:statatest} {hline 2} Unit-testing framework for Stata ado-files{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
Initialise a suite:{break}
{cmd:statatest begin} {it:suite_name}

{p 8 17 2}
Assert a boolean condition:{break}
{cmd:statatest assert} {it:condition} [{cmd:,} {cmd:msg(}{it:text}{cmd:)}]

{p 8 17 2}
Assert exact equality of two expressions:{break}
{cmd:statatest assert_equal} {it:expr} {it:expected} [{cmd:,} {cmd:msg(}{it:text}{cmd:)}]

{p 8 17 2}
Assert approximate numeric equality:{break}
{cmd:statatest assert_approx} {it:expr} {it:expected} [{cmd:,} {cmd:tol(}{it:#}{cmd:)} {cmd:msg(}{it:text}{cmd:)}]

{p 8 17 2}
Assert no missing values in a varlist:{break}
{cmd:statatest assert_nomissing} {it:varlist} [{cmd:,} {cmd:msg(}{it:text}{cmd:)}]

{p 8 17 2}
Assert all values of a varlist form a unique key:{break}
{cmd:statatest assert_unique} {it:varlist} [{cmd:,} {cmd:msg(}{it:text}{cmd:)}]

{p 8 17 2}
Assert all non-missing values are within bounds:{break}
{cmd:statatest assert_range} {it:varname} [{cmd:,} {cmd:min(}{it:#}{cmd:)} {cmd:max(}{it:#}{cmd:)} {cmd:msg(}{it:text}{cmd:)}]

{p 8 17 2}
Assert the dataset has exactly N observations:{break}
{cmd:statatest assert_nobs} {it:#} [{cmd:,} {cmd:msg(}{it:text}{cmd:)}]

{p 8 17 2}
Assert all named variables exist in the current dataset:{break}
{cmd:statatest assert_varlist} {it:varnames} [{cmd:,} {cmd:msg(}{it:text}{cmd:)}]

{p 8 17 2}
Assert a command exits with a specific return code:{break}
{cmd:statatest expect_error} {it:command} {cmd:,} {cmd:rc(}{it:#}{cmd:)} [{cmd:msg(}{it:text}{cmd:)}]

{p 8 17 2}
Save a dataset snapshot for later restoration:{break}
{cmd:statatest setup} [{cmd:,} {cmd:msg(}{it:text}{cmd:)}]

{p 8 17 2}
Restore the dataset saved by {cmd:statatest setup}:{break}
{cmd:statatest teardown} [{cmd:,} {cmd:msg(}{it:text}{cmd:)}]

{p 8 17 2}
Run a test do-file and print a session-level summary:{break}
{cmd:statatest run} {it:filename.do} [{cmd:, strict}]

{p 8 17 2}
Finalise a suite and print a summary:{break}
{cmd:statatest end} [{cmd:, strict}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:statatest} provides a unit-testing framework for Stata ado-files,
inspired by Python's {cmd:pytest} and R's {cmd:testthat}. It lets you write
self-contained test suites that report pass/fail for each assertion and print a
summary when the suite ends, making it easy to verify that a custom command
behaves correctly across edge cases.

{pstd}
{bf:Basic workflow.} Each suite begins with {cmd:statatest begin}, which
initialises internal pass/fail counters. Individual assertions are made with
any of the {cmd:assert_*} subcommands. The suite ends with {cmd:statatest end},
which prints a tally and stores {cmd:r(pass)}, {cmd:r(fail)}, and {cmd:r(total)}.

{pstd}
{bf:Domain-specific assertions.} In addition to the generic {cmd:assert},
{cmd:statatest} provides five assertions tailored to survey and administrative data:
{cmd:assert_nomissing} checks for missing values across a varlist;
{cmd:assert_unique} checks for duplicate keys;
{cmd:assert_range} checks all values fall within specified bounds;
{cmd:assert_nobs} checks the observation count;
{cmd:assert_varlist} checks that variable names exist in the dataset.
These provide more informative failure messages than the equivalent {cmd:assert}.

{pstd}
{bf:Setup/teardown.} {cmd:statatest setup} saves a snapshot of the current
dataset to a temp file. {cmd:statatest teardown} restores it. This lets you
make destructive modifications inside a suite without permanently altering the
data. Only one snapshot is kept at a time.

{pstd}
{bf:Running test files.} {cmd:statatest run} {it:filename.do} executes a
do-file containing any number of suites, accumulates pass/fail counts across
all suites, and prints a session-level summary. Use {cmd:, strict} to exit
with return code 1 if any test failed, enabling CI/batch pipelines.

{pstd}
{cmd:statatest} stores no permanent data and leaves your dataset unchanged
unless {cmd:teardown} is called (which restores the snapshot).


{marker options}{...}
{title:Options}

{phang}
{cmd:msg(}{it:text}{cmd:)} specifies a human-readable label for the assertion.
If omitted, a default label is constructed from the condition or variable name.

{phang}
{cmd:tol(}{it:#}{cmd:)} ({cmd:assert_approx} only) sets the numeric tolerance.
Default is {cmd:1e-7}.

{phang}
{cmd:min(}{it:#}{cmd:)} ({cmd:assert_range} only) sets the lower bound.
At least one of {cmd:min()} or {cmd:max()} must be specified.

{phang}
{cmd:max(}{it:#}{cmd:)} ({cmd:assert_range} only) sets the upper bound.

{phang}
{cmd:rc(}{it:#}{cmd:)} ({cmd:expect_error} only) the return code the command must produce.
Required. Use Stata's error code reference ({help error_messages}) to find
the code for a given error.

{phang}
{cmd:strict} ({cmd:statatest end} and {cmd:statatest run} only) causes Stata
to abort with return code 1 if any test failed. Useful in batch scripts
where a non-zero exit code signals failure.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Basic assertions}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. statatest begin "auto dataset checks"}{p_end}
{phang2}{cmd:. statatest assert (c(N) == 74),    msg("74 obs")}{p_end}
{phang2}{cmd:. statatest assert_nobs 74}{p_end}
{phang2}{cmd:. statatest assert_nomissing mpg price}{p_end}
{phang2}{cmd:. statatest assert_unique make}{p_end}
{phang2}{cmd:. statatest assert_range mpg, min(0) max(100)}{p_end}
{phang2}{cmd:. statatest assert_varlist make price mpg rep78}{p_end}
{phang2}{cmd:. statatest end}{p_end}

{pstd}
{bf:Approximate equality (important: capture r() into a local first)}

{phang2}{cmd:. summarize mpg, meanonly}{p_end}
{phang2}{cmd:. local mu = r(mean)}{p_end}
{phang2}{cmd:. statatest begin "mean check"}{p_end}
{phang2}{cmd:. statatest assert_approx `mu' 21.2973, tol(0.001) msg("mean mpg")}{p_end}
{phang2}{cmd:. statatest end}{p_end}

{pstd}
{bf:expect_error -- testing that commands fail correctly}

{phang2}{cmd:. statatest begin "error handling"}{p_end}
{phang2}{cmd:. statatest expect_error use nonexistent_file, rc(601) msg("use fails on missing file")}{p_end}
{phang2}{cmd:. statatest expect_error assert 1 == 2, rc(9)  msg("assert fails with rc=9")}{p_end}
{phang2}{cmd:. statatest end}{p_end}

{pstd}
Commands whose options contain commas must be quoted:{p_end}
{phang2}{cmd:. statatest expect_error "tabulate rep78, missing", rc(9)}{p_end}

{pstd}
{bf:Setup and teardown}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. statatest begin "subset test"}{p_end}
{phang2}{cmd:. statatest setup}{p_end}
{phang2}{cmd:. keep if foreign == 1}{p_end}
{phang2}{cmd:. statatest assert_nobs 22,  msg("22 foreign cars")}{p_end}
{phang2}{cmd:. statatest teardown}{p_end}
{phang2}{cmd:. statatest assert_nobs 74,  msg("full dataset restored")}{p_end}
{phang2}{cmd:. statatest end}{p_end}

{pstd}
{bf:Running a test file (tests in a separate do-file)}

{phang2}{cmd:. statatest run "my_package_tests.do"}{p_end}
{phang2}{cmd:. assert r(fail) == 0}{p_end}

{pstd}
{bf:Batch CI pipeline with strict mode}

{phang2}{cmd:. statatest run "tests.do", strict}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:statatest end} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{synopt:{cmd:r(pass)}}tests passed in this suite{p_end}
{synopt:{cmd:r(fail)}}tests failed in this suite{p_end}
{synopt:{cmd:r(total)}}total tests in this suite{p_end}
{synoptline}

{pstd}
{cmd:statatest run} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{synopt:{cmd:r(pass)}}total tests passed across all suites{p_end}
{synopt:{cmd:r(fail)}}total tests failed across all suites{p_end}
{synopt:{cmd:r(total)}}total tests across all suites{p_end}
{synopt:{cmd:r(suites)}}number of suites that ran{p_end}
{synoptline}

{pstd}
{bf:Note on r() and assert_*.} Because {cmd:statatest assert} calls a program,
it clears the current saved results ({cmd:r()}). If you need to check a value
computed by a prior command (e.g., {cmd:summarize}), save it to a local macro
first: {cmd:local mu = r(mean)} and then use {cmd:`mu'} in the assertion.


{marker install}{...}
{title:Installation}

{pstd}
Install the latest version directly from GitHub:

{phang2}{cmd:. net install statatest, from(https://raw.githubusercontent.com/malambomutila/Statatest/main/) replace}{p_end}

{pstd}
Or install from SSC once available:

{phang2}{cmd:. ssc install statatest}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Malambo Mutila{break}
IDinsight{break}
malambo.mutila@idinsight.org{break}
{browse "https://github.com/malambomutila/Statatest":github.com/malambomutila/Statatest}

{pstd}
Bug reports and feature requests: open an issue on GitHub.


{marker alsosee}{...}
{title:Also see}

{psee}
{helpb assert} — Stata's built-in assertion command{p_end}

{psee}
{helpb capture} — execute a command and capture the return code{p_end}

{psee}
{helpb duplicates} — report, tag, or drop duplicate observations{p_end}
{p2colreset}{...}
