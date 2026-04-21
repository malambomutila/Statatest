*! TB_burden_tests.do: statatest comprehensive feature demo
*  Uses WHO TB Burden dataset (1990-2013, 5,120 obs, 47 vars)
*  Demonstrates every statatest subcommand in sequence
*
*  HOW TO RUN: cd to the repo root (the Statatest/ folder) first, then:
*    do logs/TB_burden_tests.do
*  All paths below are relative to that root and work on any OS.

set more off
capture log close
log using "logs/TB_burden_tests.log", replace text

adopath + "adofiles"

// ----- Load and rename -------------------------------------------------
import delimited "exampledata/TB_Burden_Country.csv", ///
    clear varnames(1)

rename countryorterritoryname            country
rename iso3charactercountryterritorycod   iso3
rename estimatedtotalpopulationnumber     pop
rename estimatedprevalenceoftballformsp   prev_rate
rename v9                                prev_rate_lo
rename v10                               prev_rate_hi
rename estimatedmortalityoftbcasesallfo   mort_rate
rename v16                               mort_rate_lo
rename v17                               mort_rate_hi
rename estimatednumberofdeathsfromtball   mort_n
rename estimatedincidenceallformsper100   inc_rate
rename v29                               inc_rate_lo
rename v30                               inc_rate_hi
rename estimatednumberofincidentcasesal   inc_n
rename estimatedhivinincidenttbpercent    hiv_pct
rename estimatedhivinincidenttbpercentl   hiv_pct_lo
rename estimatedhivinincidenttbpercenth   hiv_pct_hi
rename casedetectionrateallformspercent   cdr
rename v46                               cdr_lo
rename v47                               cdr_hi

// ========================================================================
// Suite 1: assert_nobs + assert_varlist
// ========================================================================
statatest begin "Suite 1: Data structure"
    statatest assert_nobs 5120
    statatest assert_varlist country iso3 region year pop inc_rate mort_rate hiv_pct cdr
statatest end

// ========================================================================
// Suite 2: assert_nomissing
// ========================================================================
statatest begin "Suite 2: Data completeness"
    statatest assert_nomissing country iso3 region year
statatest end

// ========================================================================
// Suite 3: assert_unique
// ========================================================================
statatest begin "Suite 3: Uniqueness"
    statatest assert_unique iso3 year
statatest end

// ========================================================================
// Suite 4: assert_range
// ========================================================================
statatest begin "Suite 4: Valid ranges"
    statatest assert_range year, min(1990) max(2013) msg("years within 1990-2013")
    statatest assert_range inc_rate, min(0) msg("incidence rate non-negative")
    statatest assert_range mort_rate, min(0) msg("mortality rate non-negative")
    statatest assert_range hiv_pct, min(0) max(100) msg("HIV% in [0,100]")
    statatest assert_range cdr, min(0) msg("case detection rate non-negative")
statatest end

// ========================================================================
// Suite 5: assert. Epidemiological consistency checks.
// ========================================================================
statatest begin "Suite 5: Epidemiological consistency"
    // Global mean: incidence must exceed mortality (not true row-by-row
    // for small territories due to estimation uncertainty, but holds in aggregate)
    quietly summarize inc_rate if !mi(inc_rate), meanonly
    local mean_inc = r(mean)
    quietly summarize mort_rate if !mi(mort_rate), meanonly
    local mean_mort = r(mean)
    statatest assert (`mean_inc' > `mean_mort'), msg("mean incidence > mean mortality globally")

    quietly count if inc_rate_lo > inc_rate & !mi(inc_rate_lo) & !mi(inc_rate)
    local n_lo = r(N)
    statatest assert (`n_lo' == 0), msg("incidence lower CI bound <= point estimate")

    quietly count if inc_rate_hi < inc_rate & !mi(inc_rate_hi) & !mi(inc_rate)
    local n_hi = r(N)
    statatest assert (`n_hi' == 0), msg("incidence upper CI bound >= point estimate")

    quietly summarize inc_rate if region == "AFR", meanonly
    local afr_mean = r(mean)
    quietly summarize inc_rate if region == "EUR", meanonly
    local eur_mean = r(mean)
    statatest assert (`afr_mean' > `eur_mean'), ///
        msg("Africa mean incidence > Europe mean incidence")
statatest end

// ========================================================================
// Suite 6: assert_equal + assert_approx
// ========================================================================
statatest begin "Suite 6: Summary statistics"
    summarize year, meanonly
    local yr_min  = r(min)
    local yr_max  = r(max)
    local yr_mean = r(mean)
    statatest assert_equal  `yr_min'  1990,     msg("earliest year is 1990")
    statatest assert_equal  `yr_max'  2013,     msg("latest year is 2013")
    statatest assert_approx `yr_mean' 2001.549, tol(0.01) msg("mean year ~2001.5 (slight panel imbalance)")
statatest end

// ========================================================================
// Suite 7: setup and teardown. Africa subset, then restore.
// ========================================================================
statatest begin "Suite 7: Setup and teardown"
    statatest setup
    keep if region == "AFR"
    statatest assert_nobs 1107,        msg("1107 African country-years")
    statatest assert_nomissing region, msg("region complete in Africa subset")
    statatest teardown
    statatest assert_nobs 5120,        msg("full 5,120-row dataset restored")
statatest end

// ========================================================================
// Suite 8: expect_error
// ========================================================================
statatest begin "Suite 8: expect_error"
    statatest expect_error assert 1 == 2,              rc(9)   msg("false assertion gives rc=9")
    statatest expect_error assert nosuchvar == 1,      rc(111) msg("unknown variable gives rc=111")
    statatest expect_error use "/no_such_file.dta",    rc(601) msg("missing file gives rc=601")
statatest end

// ========================================================================
// Suite 9: statatest run. Batch execution of a separate test file.
// ========================================================================
tempfile sea_tests
file open ft using `"`sea_tests'"', write replace
file write ft `"import delimited "exampledata/TB_Burden_Country.csv", clear varnames(1)"' _n
file write ft `"rename estimatedincidenceallformsper100 inc_rate"' _n
file write ft `"rename casedetectionrateallformspercent cdr"' _n
file write ft `"keep if region == "SEA""' _n
file write ft `"statatest begin "SEA region: South-East Asia checks""' _n
file write ft `"  statatest assert_nobs 252"' _n
file write ft `"  statatest assert_nomissing region year"' _n
file write ft `"  statatest assert_range cdr, min(0)"' _n
file write ft `"  statatest assert_range inc_rate, min(0)"' _n
file write ft `"statatest end"' _n
file close ft

statatest begin "Suite 9: statatest run (SEA sub-file)"
    statatest run `"`sea_tests'"'
    statatest assert (r(fail) == 0), msg("SEA sub-file: all tests pass")
statatest end

log close
