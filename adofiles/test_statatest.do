// test_statatest.do
// Full test suite for the statatest package itself.
// Run with: do test_statatest.do
// Requires: statatest installed (ado-files on adopath)
// Note: written for manual execution; Stata not available in build environment.

version 16
set more off
capture log close
log using test_statatest.log, replace text

display as text "========================================"
display as text "statatest self-test suite"
display as text "========================================"

// Test 1: Basic functionality on auto dataset
sysuse auto, clear
statatest begin "Test 1: Basic on auto"
  statatest assert (c(N) == 74),  msg("74 obs in auto")
  statatest assert (c(k) == 12),  msg("12 vars in auto")
statatest end
assert r(fail) == 0

// Test 2: assert_equal on scalars
statatest begin "Test 2: assert_equal"
  scalar x = 42
  statatest assert_equal x 42,    msg("scalar x equals 42")
  statatest assert_equal "hello" "hello", msg("strings equal")
statatest end
assert r(fail) == 0

// Test 3: assert_approx tolerance
statatest begin "Test 3: assert_approx"
  scalar pi_approx = 3.14159265
  statatest assert_approx pi_approx 3.14159265, tol(1e-8) msg("pi to 8dp")
  statatest assert_approx pi_approx 3.14,       tol(0.002) msg("pi within 0.002")
statatest end
assert r(fail) == 0

// Test 4: Intentional failure detection
// One assert should FAIL; we verify r(fail)==1 and r(pass)==1.
statatest begin "Test 4: Failure detection"
  statatest assert (1 == 1),  msg("sanity: 1==1 passes")
  statatest assert (1 == 2),  msg("deliberate failure")
statatest end
assert r(fail) == 1
assert r(pass) == 1

// Test 5: Empty dataset edge case
preserve
  clear
  statatest begin "Test 5: Empty dataset"
    statatest assert (c(N) == 0), msg("empty after clear")
  statatest end
  assert r(fail) == 0
restore

// Test 6: Single observation
preserve
  sysuse auto, clear
  keep in 1
  statatest begin "Test 6: Single obs"
    statatest assert (c(N) == 1),  msg("single obs")
    statatest assert (!mi(mpg)),   msg("mpg not missing")
  statatest end
  assert r(fail) == 0
restore

// Test 7: Missing-value handling
preserve
  sysuse auto, clear
  replace rep78 = . if rep78 == 1
  statatest begin "Test 7: Missing values"
    summarize rep78, meanonly
    statatest assert (r(N) < 74),  msg("some missing rep78")
    statatest assert (r(N) > 0),   msg("some non-missing rep78")
  statatest end
  assert r(fail) == 0
restore

// Test 8: Error handling -- assert outside begin/end
global STTEST_active 0
capture statatest_assert (1 == 1)
local t8_rc = _rc
global STTEST_active   // clear global
assert `t8_rc' == 198       // must be 198 before re-entering a suite

statatest begin "Test 8: Error handling"
  statatest assert (1 == 1), msg("basic sanity inside suite")
statatest end
assert r(fail) == 0

// Test 9: Return values after statatest end
sysuse auto, clear
statatest begin "Test 9: Return values"
  statatest assert (1 == 1)
  statatest assert (2 == 2)
  statatest assert (3 == 3)
statatest end
assert r(total) == 3
assert r(pass)  == 3
assert r(fail)  == 0

// Test 10: Compatibility -- version 16
version 16: statatest begin "Test 10: version 16"
version 16: statatest assert (1 == 1), msg("runs under version 16")
version 16: statatest end
assert r(fail) == 0

// Test 11: assert_nomissing
sysuse auto, clear
statatest begin "Test 11: assert_nomissing"
  statatest assert_nomissing mpg price,      msg("mpg and price have no missing")
  statatest assert_nomissing rep78,          msg("deliberate: rep78 has missing")
statatest end
assert r(fail) == 1
assert r(pass) == 1

// Test 12: assert_unique
sysuse auto, clear
statatest begin "Test 12: assert_unique"
  statatest assert_unique make,    msg("make is unique")
  statatest assert_unique rep78,   msg("deliberate: rep78 has duplicates")
statatest end
assert r(fail) == 1
assert r(pass) == 1

// Test 13: assert_range
sysuse auto, clear
statatest begin "Test 13: assert_range"
  statatest assert_range mpg, min(0) max(100) msg("mpg in [0,100]")
  statatest assert_range mpg, max(20)         msg("deliberate: some mpg > 20")
statatest end
assert r(fail) == 1
assert r(pass) == 1

// Test 14: assert_nobs
sysuse auto, clear
statatest begin "Test 14: assert_nobs"
  statatest assert_nobs 74,    msg("74 obs in auto")
  statatest assert_nobs 100,   msg("deliberate: auto does not have 100 obs")
statatest end
assert r(fail) == 1
assert r(pass) == 1

// Test 15: assert_varlist
sysuse auto, clear
statatest begin "Test 15: assert_varlist"
  statatest assert_varlist make price mpg,     msg("standard vars exist")
  statatest assert_varlist make ghost_var,     msg("deliberate: ghost_var absent")
statatest end
assert r(fail) == 1
assert r(pass) == 1

// Test 16: setup/teardown
sysuse auto, clear
statatest begin "Test 16: setup/teardown"
  statatest setup
  keep in 1/10
  statatest assert_nobs 10,   msg("dataset modified to 10 obs")
  statatest teardown
  statatest assert_nobs 74,   msg("dataset restored to 74 obs")
statatest end
assert r(fail) == 0

// Test 17: statatest run (uses a temp do-file written inline)
sysuse auto, clear
tempfile mini_do
file open _f using `"`mini_do'"', write replace text
file write _f "version 16" _n
file write _f "sysuse auto, clear" _n
file write _f "statatest begin suite_A" _n
file write _f "  statatest assert_nobs 74" _n
file write _f "  statatest assert_nomissing mpg" _n
file write _f "statatest end" _n
file write _f "statatest begin suite_B" _n
file write _f "  statatest assert (1 == 1)" _n
file write _f "statatest end" _n
file close _f

statatest run `"`mini_do'"'
local r17_pass   = r(pass)
local r17_fail   = r(fail)
local r17_suites = r(suites)

statatest begin "Test 17: statatest run"
  statatest assert (`r17_pass'   == 3), msg("run: 3 assertions passed")
  statatest assert (`r17_fail'   == 0), msg("run: 0 failures")
  statatest assert (`r17_suites' == 2), msg("run: 2 suites executed")
statatest end
assert r(fail) == 0

// Test 18: expect_error
// assert (1 == 2) fails with rc=9; assert (1 == 1) succeeds (rc=0)
sysuse auto, clear
statatest begin "Test 18: expect_error"
  statatest expect_error assert 1 == 2, rc(9)   msg("assert 1==2 gives rc(9)")
  statatest expect_error assert 1 == 2, rc(198) msg("deliberate: wrong rc expected")
statatest end
assert r(fail) == 1
assert r(pass) == 1

display as text "========================================"
display as text "All self-tests completed."
display as text "Inspect test_statatest.log for results."
display as text "========================================"

log close
