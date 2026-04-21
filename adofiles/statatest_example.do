// statatest_example.do
// Demonstrates statatest with Stata's built-in datasets.
// Run this file in Stata after installing statatest.
// Usage: do statatest_example.do

version 16
set more off
capture log close
log using statatest_example.log, replace text

// ---------------------------------------------------------------------------
// SUITE 1: Dataset integrity checks on auto
// ---------------------------------------------------------------------------
sysuse auto, clear

statatest begin "auto dataset -- basic integrity"

  statatest assert (c(N) == 74),  msg("74 observations")
  statatest assert (c(k) == 12),  msg("12 variables")
  statatest assert (!mi(mpg)),    msg("mpg has no missing values")

  // Check mean mpg from summarize
  summarize mpg, meanonly
  statatest assert_approx r(mean) 21.2973 , tol(0.0001) msg("mean mpg ≈ 21.30")
  statatest assert (r(min) >= 0),           msg("mpg is non-negative")
  statatest assert (r(max) <= 50),          msg("mpg max is plausible (≤50)")

statatest end

// ---------------------------------------------------------------------------
// SUITE 2: Variable type checks on auto
// ---------------------------------------------------------------------------
statatest begin "auto -- variable types"

  statatest assert ("`: type mpg'"   == "int"),    msg("mpg is int")
  statatest assert ("`: type price'" == "int"),    msg("price is int")
  statatest assert ("`: type make'"  == "str18"),  msg("make is str18")

statatest end

// ---------------------------------------------------------------------------
// SUITE 3: Edge cases -- empty dataset
// ---------------------------------------------------------------------------
preserve
  clear
  statatest begin "edge case -- empty dataset"
    statatest assert (c(N) == 0),  msg("c(N)==0 after clear")
    statatest assert (c(k) == 0),  msg("c(k)==0 after clear")
  statatest end
restore

// ---------------------------------------------------------------------------
// SUITE 4: Testing a simple user-written command inline
// This defines a tiny command that mean-centres a variable, then tests it.
// ---------------------------------------------------------------------------
capture program drop mycenter
program define mycenter, rclass
    version 16
    syntax varname
    quietly summarize `varlist', meanonly
    local mu = r(mean)
    generate double `varlist'_c = `varlist' - `mu'
    return scalar mean = r(mean)
end

sysuse auto, clear
statatest begin "mycenter command tests"

  mycenter mpg

  summarize mpg_c, meanonly
  statatest assert_approx r(mean) 0 , tol(1e-8) msg("centered mean is 0")
  statatest assert (r(min) < 0),                msg("some centered values are negative")
  statatest assert (r(max) > 0),                msg("some centered values are positive")

  // New variable should exist
  capture confirm variable mpg_c
  statatest assert (_rc == 0),  msg("mpg_c was created")

statatest end

// ---------------------------------------------------------------------------
// SUITE 5: Error-handling -- command must fail gracefully on bad input
// ---------------------------------------------------------------------------
statatest begin "error handling"

  capture mycenter nonexistent_var
  statatest assert (_rc != 0),  msg("mycenter fails on non-existent var")

  // statatest itself should fail if called outside begin/end.
  // Save _rc immediately after capture because internal commands reset it.
  global STTEST_active 0
  capture statatest_assert (1 == 1)
  local saved_rc = _rc
  global STTEST_active 1   // restore before next assert
  statatest assert (`saved_rc' == 198), msg("assert outside begin/end returns rc=198")

statatest end

// ---------------------------------------------------------------------------
// Final note
// ---------------------------------------------------------------------------
display as text _dup(60) "="
display as text "statatest_example.do completed."
display as text "Inspect the log file: statatest_example.log"
display as text _dup(60) "="

log close
