# Statatest: Unit Testing for Stata

**Statatest** lets you write simple checks that verify your Stata code is working correctly. Think of it as a way to ask Stata questions like: *"Does this variable have the right number of observations?"* or *"Did my command produce the right result?"* and get a clear PASS or FAIL answer for each one.

If you have never written a test before, that is fine. This guide starts from zero.

---

## What problem does this solve?

When you write a Stata command or do-file, how do you know it's doing the right thing? Most people run it, look at the output, and decide "looks right." That works, but:

- What if you change the code later and accidentally break something?
- What if the results look plausible but are actually slightly wrong?
- What if someone else needs to run your code and verify it works on their machine?

**statatest** solves this by letting you write down exactly what you expect, so Stata can check it for you automatically every time.

---

## Installation

### Option A: net install from GitHub (recommended)

Type this in the Stata command window:

```stata
net install statatest, from(https://raw.githubusercontent.com/malambomutila/Statatest/main/adofiles/) replace
```

That's it. Stata downloads and installs all files automatically. To confirm it worked:

```stata
statatest
```

You should see a short help message listing all subcommands.

---

### Option B: manual install

If you prefer to copy the files yourself:

**Step 1: Find your personal ado folder**

```stata
sysdir
```

The line that says `PERSONAL:` gives you the folder path.

**Step 2: Copy all ado files**

Copy every `.ado` file from the `adofiles/` folder of this repository into your PERSONAL folder. If the folder does not exist yet, create it.

**Step 3: Tell Stata to reload**

```stata
discard
```

---

## Your first test: a five-minute walkthrough

Open a new do-file in Stata (File → New Do-file Editor). Paste in the following and run it:

```stata
sysuse auto, clear

statatest begin "my first test suite"

  statatest assert (c(N) == 74), msg("the auto dataset has 74 rows")

statatest end
```

When you run it, you should see something like this in the Results window:

```
------------------------------------------------------------
statatest suite: my first test suite
------------------------------------------------------------
  PASS : the auto dataset has 74 rows
------------------------------------------------------------
1 / 1 tests passed: ALL PASS [my first test suite]
------------------------------------------------------------
```

That's it. You just wrote and ran your first test.

Now break it on purpose to see what a failure looks like. Change `74` to `75` and run again:

```stata
statatest assert (c(N) == 75), msg("the auto dataset has 74 rows")
```

You will see:

```
  FAIL : the auto dataset has 74 rows
         (condition was false: (c(N) == 75))
------------------------------------------------------------
1 / 1 tests FAILED: [my first test suite]
------------------------------------------------------------
```

A red `FAIL` line tells you exactly which check failed and what the condition was. Change it back to `74` before continuing.

---

## The three parts of every test

Every statatest block follows the same structure:

**Syntax**

```stata
statatest begin "suite name"

    statatest assert ...   ← your checks go here
    statatest assert ...

statatest end [, strict]
```

| Part | What to type | What it does |
|---|---|---|
| `statatest begin "suite name"` | Replace `suite name` with any descriptive label in double quotes | Starts a group of tests and prints a header with your label |
| `statatest assert (...)` | Write the condition you want to check inside the parentheses | Checks one condition and prints PASS or FAIL |
| `statatest end` | Type exactly as shown | Prints the final count of how many tests passed and how many failed |
| `statatest end, strict` | Add `, strict` only if you want Stata to stop on failure | Same as above, but exits with an error code if any test failed. Useful when running tests automatically. |

**Example `begin` labels**: use anything that describes what you are testing:

```stata
statatest begin "data quality checks after import"
statatest begin "household survey: completeness"
statatest begin "TB burden dataset: valid ranges"
```

You can have as many `statatest assert` lines between `begin` and `end` as you like. statatest does not stop on failure. It records the result and moves to the next check.

---

## How to read the syntax examples

Every command in this guide is shown using a compact notation. Before diving into the individual commands, here is what each symbol means.

---

### `#` is a number you supply

Replace `#` with the exact whole number you want. Do not type the `#` symbol itself.

```stata
// Syntax shown in this guide:
statatest assert_nobs #

// What you actually type:
statatest assert_nobs 5120
statatest assert_nobs 74
```

---

### `varname` is the name of a column in your dataset

A variable (also called a column or field) is one piece of information collected for every row. Replace `varname` with the actual name of a variable in your data.

```stata
// Syntax shown in this guide:
statatest assert_nomissing varname

// What you actually type:
statatest assert_nomissing country
statatest assert_nomissing respondent_id
```

---

### `varname [varname ...]` is one or more variable names

Square brackets `[...]` mean the part inside is **optional**: you can include it or leave it out. The `...` means you can repeat it as many times as you like. When listing variable names, separate them with spaces (not commas).

```stata
// Syntax shown in this guide:
statatest assert_nomissing varname [varname ...]

// What you actually type. All of the following are valid:
statatest assert_nomissing country
statatest assert_nomissing country year
statatest assert_nomissing country year region iso3
```

---

### `[, option]` is the comma and what follows are optional

In Stata, a **comma** separates the main part of a command from its options. When you see `[, ...]` in a syntax line, the comma and everything after it are optional. You can leave the whole thing out entirely. Do not type the square brackets.

```stata
// Syntax shown in this guide:
statatest assert_nobs # [, msg(string)]

// Without the option, perfectly valid:
statatest assert_nobs 5120

// With the option, add a comma first, then the option name:
statatest assert_nobs 5120, msg("TB dataset has 5120 rows")
```

---

### `msg(string)` is a label you write that appears in the output

`msg()` lets you attach a short description to any assertion. The text inside the parentheses (in double quotes) appears on the PASS or FAIL line when you run the tests. The word `string` in the syntax is a placeholder, replace it with your own text.

```stata
statatest assert_nobs 5120, msg("TB dataset has 5120 rows")
```

Produces:
```
  PASS : TB dataset has 5120 rows
```

Without `msg()`, statatest generates a default label automatically (like `5120 == 5120 obs`). With it, you control exactly what the line says. Writing a good `msg()` makes failures much easier to understand, your future self will thank you.

---

### `{min(#)|max(#)|min(#) max(#)}`: choose one of these alternatives

Curly braces `{...}` with alternatives separated by `|` mean **choose exactly one**. In `assert_range`, you must provide at least one bound. Either or both are fine.

```stata
statatest assert_range year, min(1990)              // lower bound only
statatest assert_range year, max(2013)              // upper bound only
statatest assert_range year, min(1990) max(2013)    // both bounds
```

---

### Stored results: `r(name)` and `e(name)`

When you run a command like `summarize`, `count`, or `regress`, Stata automatically saves the results so you can use them in the next line. These saved values are called **stored results**.

```stata
summarize mpg, meanonly
// After this runs, Stata has stored:
//   r(mean): the mean of mpg
//   r(min):  the smallest value
//   r(max):  the largest value
//   r(N):    the count of non-missing observations
// Save to locals first — statatest clears r() when it runs
local mpg_min  = r(min)
local mpg_mean = r(mean)

statatest assert_equal  `mpg_min'  0,    msg("minimum mpg is 0")
statatest assert_approx `mpg_mean' 21.3, tol(0.1) msg("mean mpg is about 21")
```

To see what is stored after any command, type `return list` in the Command window.

---

### `actual` and `expected`: the two values being compared

In `assert_equal` and `assert_approx`, the two unnamed arguments are:

- **`actual`**: the value your code just produced (usually a stored result or a scalar)
- **`expected`**: the value you expect it to equal (usually a number you type)

```stata
summarize year, meanonly
local yr_min = r(min)   // save r() before statatest clears it

statatest assert_equal `yr_min' 1990   // actual = r(min) saved as yr_min, expected = 1990
//                     ↑         ↑
//                  actual     expected
```

---

### `[, strict]`: stop if a test fails

Adding `, strict` after `statatest end` or after the filename in `statatest run` tells Stata to exit with an error if any test failed. This is only needed when running tests automatically (for example, in a CI pipeline). For normal interactive use, leave it out.

```stata
statatest end             // always continues: just prints the summary
statatest end, strict     // stops Stata if any test in this suite failed
```

---

## The four types of checks

### 1. `statatest assert`: check any true/false condition

Use this for anything you can express as a comparison.

**Syntax**

```stata
statatest assert (expression) [, msg(string)]
```

| Argument | What it means | Example |
|---|---|---|
| `(expression)` | The condition you want to check, written inside parentheses. It must be something that is either true or false: a comparison, a logical statement, or a check on a stored result. The parentheses are required. | `(c(N) == 74)` checks there are 74 rows; `(!mi(mpg))` checks mpg has no missing values |
| `msg(string)` | A short description in double quotes. This text appears on the PASS or FAIL line in the output. Optional, but strongly recommended, as it makes failures self-explanatory. | `msg("dataset has 74 rows")` |

**What can go inside the parentheses?** Anything that Stata's `assert` command would accept:
- Comparisons: `==`, `!=`, `>`, `<`, `>=`, `<=`
- Logic: `&` (and), `|` (or), `!` (not)
- Functions: `mi()`, `inrange()`, `inlist()`, `strlen()`, etc.
- System macros: `c(N)`, `c(k)`, `_rc`
- Stored results: `r(mean)`, `e(r2)`, etc.

**Example**

```stata
statatest assert (c(N) == 74),   msg("dataset has 74 rows")
statatest assert (c(N) > 0),     msg("dataset is not empty")
statatest assert (!mi(mpg)),     msg("mpg has no missing values")
statatest assert (price > 0),    msg("price is positive for all rows")
```

---

### 2. `statatest assert_equal`: check that two things are exactly the same

**Syntax**

```stata
statatest assert_equal actual expected [, msg(string)]
```

| Argument | What it means | Example |
|---|---|---|
| `actual` | The value your code just produced. This is usually a stored result (like `r(N)` after `summarize`), a scalar you defined, or any expression Stata can evaluate to a number. | `r(N)`, `r(min)`, `myscalar` |
| `expected` | The exact number you expect `actual` to equal. Type the value directly. statatest checks that `actual == expected` with no rounding or tolerance. | `74`, `1990`, `0` |
| `msg(string)` | A short description in double quotes for the output line. Optional. | `msg("earliest year is 1990")` |

**Example**

```stata
summarize mpg, meanonly
local mpg_n = r(N)   // save r() before statatest clears it
statatest assert_equal `mpg_n' 74,   msg("summarize counted 74 observations")

scalar myscalar = 100
statatest assert_equal myscalar 100,   msg("scalar equals 100")
```

---

### 3. `statatest assert_approx`: check that two numbers are close enough

Real-world calculations involve floating-point numbers that are rarely *exactly* equal. Use this when you want to check that a result is close to an expected value, within some tolerance.

**Syntax**

```stata
statatest assert_approx actual expected [, tol(#)] [msg(string)]
```

| Argument | What it means | Example |
|---|---|---|
| `actual` | The value your code just produced, usually a stored result like `r(mean)` after `summarize`. | `r(mean)`, `r(max)` |
| `expected` | The number you expect `actual` to be close to. | `21.2973`, `0`, `2001.5` |
| `tol(#)` | The maximum gap allowed between `actual` and `expected`. If the difference is smaller than `tol`, the test passes. If you leave this out, the default tolerance is `0.0000001` (one ten-millionth). For checking means or regression coefficients, use something like `tol(0.001)`. | `tol(0.001)`, `tol(0.01)`, `tol(1e-8)` |
| `msg(string)` | A short description in double quotes for the output line. Optional. | `msg("mean mpg is about 21.30")` |

**Example**

```stata
summarize mpg, meanonly
local mpg_mean = r(mean)   // save r() before statatest clears it
statatest assert_approx `mpg_mean' 21.2973, tol(0.001) msg("mean mpg is about 21.30")
```

**When to use this instead of `assert_equal`:**
- Whenever you're checking a mean, regression coefficient, or any other computed statistic.
- Whenever the result involves division or a mathematical function.

---

### 4. `statatest expect_error`: assert a command fails with a specific error code

Use this when you want to verify that a command fails in the right way, not just that it fails.

**Syntax**

```stata
statatest expect_error command, rc(#) [msg(string)]
statatest expect_error "command, options", rc(#) [msg(string)]
```

| Argument | What it means | Example |
|---|---|---|
| `command` | The Stata command you expect to fail. Write it exactly as you would type it in the Command window. Do not add `capture` yourself; statatest handles that internally. | `use "/no_file.dta"`, `assert 1 == 2` |
| `rc(#)` | The error number you expect Stata to produce when the command fails. When Stata encounters an error, it always assigns a numeric code to it. Common codes: `9` = assertion is false, `111` = variable not found, `601` = file not found. You can find any command's error code by running it without `capture` and reading the number in the red error message. | `rc(9)`, `rc(111)`, `rc(601)` |
| `msg(string)` | A short description in double quotes for the output line. Optional. | `msg("missing file gives rc=601")` |

If the command you are testing has its own options (meaning it contains its own comma), wrap the entire command in double quotes so statatest can parse it correctly.

The command runs under `capture`. If the return code matches `rc(#)`, the test passes. If the command succeeds (`rc=0`) or fails with a different code, you get a FAIL line showing expected vs. actual.

**Example**

```stata
statatest expect_error use nonexistent_file, rc(601)  msg("use fails on missing file")
statatest expect_error assert 1 == 2,        rc(9)    msg("assert fails with rc=9")
statatest expect_error "tabulate rep78, missing", rc(9)
```

---

### 5. Domain-specific checks

These five commands give cleaner output than a generic `assert` for common survey data checks.

**Syntax**

```stata
statatest assert_nobs #                                        [, msg(string)]
statatest assert_varlist varname [varname ...]                 [, msg(string)]
statatest assert_nomissing varname [varname ...]               [, msg(string)]
statatest assert_unique varname [varname ...]                  [, msg(string)]
statatest assert_range varname, {min(#)|max(#)|min(#) max(#)} [msg(string)]
```

| Command | What it checks | How to use it |
|---|---|---|
| `assert_nobs #` | The dataset has exactly `#` rows. Replace `#` with the number you expect. | `statatest assert_nobs 74` |
| `assert_varlist varname [varname ...]` | All the variables you name actually exist in the current dataset. Useful right after importing data to confirm no column was silently dropped or renamed. | `statatest assert_varlist country year region` |
| `assert_nomissing varname [varname ...]` | None of the listed variables contain any missing (blank) values. List as many variable names as you like, separated by spaces. | `statatest assert_nomissing id age income` |
| `assert_unique varname [varname ...]` | No two rows share the same combination of values in the listed variables. For a single variable, every value must be distinct. For multiple variables, every combination must be distinct. | `statatest assert_unique respondent_id` or `statatest assert_unique country year` |
| `assert_range varname, {min(#)\|max(#)\|min(#) max(#)}` | Every non-missing value of the variable falls within the bounds you set. Missing values are skipped and do not cause failure. You must supply at least one of `min()` or `max()`. | `statatest assert_range age, min(0) max(120)` |

**Example**

```stata
sysuse auto, clear
statatest begin "data integrity"
  statatest assert_nobs 74
  statatest assert_nomissing make price mpg
  statatest assert_unique make
  statatest assert_range mpg,   min(0) max(100)
  statatest assert_range price, min(0)
  statatest assert_varlist make price mpg rep78 headroom
statatest end
```

---

### 6. Setup and teardown: test with a modified dataset, then restore

**Syntax**

```stata
statatest setup    [, msg(string)]
statatest teardown [, msg(string)]
```

| Command | What it does | When to use it |
|---|---|---|
| `statatest setup` | Takes a complete copy of the current dataset (all rows and variables) and saves it to a hidden temporary file. The data in memory is unchanged at this point. | Before you modify the data: call this right before a `keep if`, `drop`, or merge |
| `statatest teardown` | Replaces whatever is currently in memory with the snapshot that was saved by `setup`. Every change made since `setup` is undone. | After you are done testing the modified data and want to get back to the full dataset |

Only one snapshot is kept at a time. If you call `setup` a second time, it overwrites the first snapshot.

**Example**

```stata
sysuse auto, clear
statatest begin "foreign cars only"
  statatest setup              // saves a snapshot of the current dataset
  keep if foreign == 1
  statatest assert_nobs 22,    msg("22 foreign cars")
  statatest teardown           // restores the full dataset
  statatest assert_nobs 74,    msg("full dataset restored")
statatest end
```

---

### 7. Running a whole test file

If your tests live in a separate do-file, use `statatest run` to execute them all and get a session-level summary.

**Syntax**

```stata
statatest run "filename.do" [, strict]
```

| Argument | What it means | Example |
|---|---|---|
| `"filename.do"` | The path to the do-file you want to run, in double quotes. If the file is in the same folder you are working in, just use the filename. If it is elsewhere, give the full path. | `"test_analysis.do"` or `"/home/user/project/tests/test_analysis.do"` |
| `strict` | Optional. If you add `, strict` after the filename, Stata exits with an error if any test inside the file failed. Leave this out for interactive use; execution will continue and you can read the results. | `statatest run "test_analysis.do", strict` |

After `statatest run` finishes, the following results are stored and available to use in subsequent assertions:

| Stored result | What it contains | How you might use it |
|---|---|---|
| `r(pass)` | The total number of assertions that passed across all suites in the file | Informational |
| `r(fail)` | The total number of assertions that failed (`0` means everything passed) | `statatest assert (r(fail) == 0)` to fail the calling do-file if anything broke |
| `r(total)` | The total number of assertions that ran (pass + fail) | Useful for confirming all expected tests actually ran |
| `r(suites)` | The number of `statatest begin`/`end` blocks that ran inside the file | |

**Example**

```stata
// Run the test file, then check that nothing failed:
statatest run "test_mycommand.do"
assert r(fail) == 0

// Or: stop Stata immediately if any test fails:
statatest run "test_mycommand.do", strict
```

---

## An Example

Here is a full example that tests a custom command step by step.

```stata
// -------------------------------------------------------
// Define a simple command to test
// (You would normally have this in its own .ado file)
// -------------------------------------------------------
capture program drop mycenter
program define mycenter, rclass
    version 16
    syntax varname
    quietly summarize `varlist', meanonly
    generate double `varlist'_c = `varlist' - r(mean)
    return scalar mean = r(mean)
end

// -------------------------------------------------------
// Load data
// -------------------------------------------------------
sysuse auto, clear

// -------------------------------------------------------
// Test suite 1: does it produce the right output?
// -------------------------------------------------------
statatest begin "mycenter: basic behaviour"

  mycenter mpg           // run the command

  // The centred variable should have mean zero
  summarize mpg_c, meanonly
  local mpg_c_mean = r(mean)   // save r() before statatest clears it
  local mpg_c_min  = r(min)
  local mpg_c_max  = r(max)
  statatest assert_approx `mpg_c_mean' 0, tol(1e-8) msg("mean of centred variable is 0")

  // The new variable should exist
  capture confirm variable mpg_c
  statatest assert (_rc == 0), msg("mpg_c variable was created")

  // Some values should be positive, some negative (not all the same)
  statatest assert (`mpg_c_min' < 0), msg("some values are below the mean")
  statatest assert (`mpg_c_max' > 0), msg("some values are above the mean")

statatest end

// -------------------------------------------------------
// Test suite 2: what about bad input?
// -------------------------------------------------------
statatest begin "mycenter: error handling"

  capture mycenter nonexistent_var
  statatest assert (_rc != 0), msg("fails gracefully on missing variable")

statatest end
```

Expected output:

```
------------------------------------------------------------
statatest suite: mycenter: basic behaviour
------------------------------------------------------------
  PASS : mean of centred variable is 0
  PASS : mpg_c variable was created
  PASS : some values are below the mean
  PASS : some values are above the mean
------------------------------------------------------------
4 / 4 tests passed: ALL PASS [mycenter: basic behaviour]
------------------------------------------------------------
------------------------------------------------------------
statatest suite: mycenter: error handling
------------------------------------------------------------
  PASS : fails gracefully on missing variable
------------------------------------------------------------
1 / 1 tests passed: ALL PASS [mycenter: error handling]
------------------------------------------------------------
```

---

## Example Data: WHO TB Burden by Country

The nine suites below run against the WHO TB Burden Country dataset (5,120 country-year observations, 1990-2013). Each suite shows the exact Stata input, the output that appears in the Results window, and why statatest handles that particular check better than the native Stata alternative.

The full do-file is `logs/TB_burden_tests.do`. To run it, open Stata, `cd` to the repo root (the `Statatest/` folder), then:

```stata
do logs/TB_burden_tests.do
```

All paths in the do-file are relative to that root and work on Windows, Mac, and Linux. After importing the CSV the truncated variable names are renamed for clarity:

```stata
adopath + "adofiles"

import delimited "exampledata/TB_Burden_Country.csv", clear varnames(1)

rename countryorterritoryname            country
rename iso3charactercountryterritorycod   iso3
rename estimatedtotalpopulationnumber     pop
rename estimatedprevalenceoftballformsp   prev_rate
rename estimatedmortalityoftbcasesallfo   mort_rate
rename estimatednumberofdeathsfromtball   mort_n
rename estimatedincidenceallformsper100   inc_rate
rename v29                               inc_rate_lo
rename v30                               inc_rate_hi
rename estimatednumberofincidentcasesal   inc_n
rename estimatedhivinincidenttbpercent    hiv_pct
rename casedetectionrateallformspercent   cdr
```

---

### Suite 1: `assert_nobs` + `assert_varlist`: verify data structure on load

**Syntax**

```stata
statatest assert_nobs #                        [, msg(string)]
statatest assert_varlist varname [varname ...]  [, msg(string)]
```

**Input**

```stata
statatest begin "Suite 1: Data structure"
    statatest assert_nobs 5120
    statatest assert_varlist country iso3 region year pop inc_rate mort_rate hiv_pct cdr
statatest end
```

**Output**

```
------------------------------------------------------------
statatest suite: Suite 1: Data structure
------------------------------------------------------------
  PASS : 5120 == 5120 obs
  PASS : variables exist: country iso3 region year pop inc_rate mort_rate hiv_pct cdr
------------------------------------------------------------
2 / 2 tests passed: ALL PASS [Suite 1: Data structure]
------------------------------------------------------------
```

**Why statatest**

After import, the typical check is `count` followed by `describe`. Both print to the Results window; you read them, decide they look right, and move on. If a collaborator re-runs the do-file on a truncated file or a column was silently dropped during a re-export, nothing flags it. With `assert_nobs` and `assert_varlist`, the exact expectation is written in code. A different row count or a missing variable stops the run immediately with a clear FAIL message, no manual inspection required.

---

### Suite 2: `assert_nomissing`: completeness checks across multiple identifiers

**Syntax**

```stata
statatest assert_nomissing varname [varname ...]  [, msg(string)]
```

**Input**

```stata
statatest begin "Suite 2: Data completeness"
    statatest assert_nomissing country iso3 region year
statatest end
```

**Output**

```
------------------------------------------------------------
statatest suite: Suite 2: Data completeness
------------------------------------------------------------
  PASS : no missing in (country iso3 region year)
------------------------------------------------------------
1 / 1 tests passed: ALL PASS [Suite 2: Data completeness]
------------------------------------------------------------
```

**Why statatest**

The native alternative is:

```stata
count if mi(country)
count if mi(iso3)
count if mi(region)
count if mi(year)
```

This runs four commands and prints four numbers you have to read. `misstable summarize` condenses it but still requires visual inspection: a zero-missing result just shows nothing in the table. `assert !mi(country)` does fail on violation, but it halts execution and swallows the other checks. `assert_nomissing` covers any number of variables in one line, continues after a failure so all issues surface in one run, and names the offending variables in the failure message.

---

### Suite 3: `assert_unique`: confirm a key combination is unique

**Syntax**

```stata
statatest assert_unique varname [varname ...]  [, msg(string)]
```

Pass multiple variables to check a composite key. The test fails if any combination of values repeats.

**Input**

```stata
statatest begin "Suite 3: Uniqueness"
    statatest assert_unique iso3 year
statatest end
```

**Output**

```
------------------------------------------------------------
statatest suite: Suite 3: Uniqueness
------------------------------------------------------------
  PASS : (iso3 year) is a unique key
------------------------------------------------------------
1 / 1 tests passed: ALL PASS [Suite 3: Uniqueness]
------------------------------------------------------------
```

**Why statatest**

`isid iso3 year` does the same check, but if the key is not unique it throws a hard error (`r(459)`) and stops Stata. You cannot continue testing. `duplicates report iso3 year` reports counts but never fails. `assert_unique` wraps `duplicates tag` internally: on failure it reports how many non-unique rows exist and which variables make up the key, then continues to the next test so all integrity checks still run.

---

### Suite 4: `assert_range`: bounds on rates and years

**Syntax**

```stata
statatest assert_range varname, {min(#)|max(#)|min(#) max(#)}  [msg(string)]
```

At least one of `min()` or `max()` is required; both may be given together. Missing values in the variable are ignored; only non-missing values are checked against the bounds.

**Input**

```stata
statatest begin "Suite 4: Valid ranges"
    statatest assert_range year,     min(1990) max(2013) msg("years within 1990-2013")
    statatest assert_range inc_rate, min(0)               msg("incidence rate non-negative")
    statatest assert_range mort_rate, min(0)              msg("mortality rate non-negative")
    statatest assert_range hiv_pct,  min(0) max(100)      msg("HIV% in [0,100]")
    statatest assert_range cdr,      min(0)               msg("case detection rate non-negative")
statatest end
```

**Output**

```
------------------------------------------------------------
statatest suite: Suite 4: Valid ranges
------------------------------------------------------------
  PASS : years within 1990-2013
  PASS : incidence rate non-negative
  PASS : mortality rate non-negative
  PASS : HIV% in [0,100]
  PASS : case detection rate non-negative
------------------------------------------------------------
5 / 5 tests passed: ALL PASS [Suite 4: Valid ranges]
------------------------------------------------------------
```

**Why statatest**

The native approach runs `summarize` or `tabstat` per variable and reads the min/max columns. It requires no mistakes over five separate visual checks. To make it fail automatically requires five `assert` statements that each halt on the first violation:

```stata
assert year >= 1990 & year <= 2013    // halts here if any row fails
assert inc_rate >= 0 | mi(inc_rate)   // never reached if above fails
```

`assert_range` handles missing values correctly by default (non-missing values outside the bounds fail; missing values are ignored), checks both bounds in one call, reports the variable name and bound in the failure message, and continues past failures, so a single run reveals all out-of-range variables at once.

---

### Suite 5: `assert`: epidemiological consistency using stored results and locals

**Syntax**

```stata
statatest assert (expression) [, msg(string)]
```

The `expression` is evaluated at the moment the assertion runs, so any `r()` results, local macros, or scalars set by preceding commands are in scope. Combine with `quietly count if ...` or `quietly summarize ... if ...` to build multi-step consistency checks.

**Input**

```stata
statatest begin "Suite 5: Epidemiological consistency"
    // Aggregate comparison: mean incidence must exceed mean mortality globally
    quietly summarize inc_rate if !mi(inc_rate), meanonly
    local mean_inc  = r(mean)
    quietly summarize mort_rate if !mi(mort_rate), meanonly
    local mean_mort = r(mean)   // save r() before statatest clears it
    statatest assert (`mean_inc' > `mean_mort'), msg("mean incidence > mean mortality globally")

    // CI bounds must contain the point estimate in every row
    quietly count if inc_rate_lo > inc_rate & !mi(inc_rate_lo) & !mi(inc_rate)
    local n_lo_viol = r(N)   // save r() before statatest clears it
    statatest assert (`n_lo_viol' == 0), msg("incidence lower CI bound <= point estimate")

    quietly count if inc_rate_hi < inc_rate & !mi(inc_rate_hi) & !mi(inc_rate)
    local n_hi_viol = r(N)   // save r() before statatest clears it
    statatest assert (`n_hi_viol' == 0), msg("incidence upper CI bound >= point estimate")

    // Regional comparison
    quietly summarize inc_rate if region == "AFR", meanonly
    local afr_mean = r(mean)
    quietly summarize inc_rate if region == "EUR", meanonly
    local eur_mean = r(mean)   // save r() before statatest clears it
    statatest assert (`afr_mean' > `eur_mean'), msg("Africa mean incidence > Europe mean incidence")
statatest end
```

**Output**

```
------------------------------------------------------------
statatest suite: Suite 5: Epidemiological consistency
------------------------------------------------------------
  PASS : mean incidence > mean mortality globally
  PASS : incidence lower CI bound <= point estimate
  PASS : incidence upper CI bound >= point estimate
  PASS : Africa mean incidence > Europe mean incidence
------------------------------------------------------------
4 / 4 tests passed: ALL PASS [Suite 5: Epidemiological consistency]
------------------------------------------------------------
```

**Why statatest**

These checks require multi-step Stata logic: `summarize`, save a local, `summarize` again, compare. The usual approach is to write `display` statements and read the numbers. Using bare `assert` works but it crashes on the first false condition, so a violation in the CI bounds check would prevent the regional comparison from running. `statatest assert` wraps each condition independently: every check runs regardless of earlier failures, and the `msg()` label makes the failure self-explanatory without needing to trace back through the code.

One finding from running these checks on real data: 65 country-years had `inc_rate < mort_rate`. This is a legitimate estimation artefact for small territories with very low case counts, not a data error, but the test surfaced it immediately. The aggregate check (`mean_inc > mean_mort`) still passes because the effect disappears at the global level.

---

### Suite 6: `assert_equal` + `assert_approx`: exact vs. tolerance-based comparison

**Syntax**

```stata
statatest assert_equal  actual expected            [, msg(string)]
statatest assert_approx actual expected [, tol(#)] [msg(string)]
```

Use `assert_equal` for integers and exactly-representable values. Use `assert_approx` whenever the result is computed (means, ratios, regression output), as floating-point arithmetic rarely produces bit-for-bit equality. The default tolerance for `assert_approx` is `1e-7`.

**Input**

```stata
statatest begin "Suite 6: Summary statistics"
    summarize year, meanonly
    local yr_min  = r(min)    // save r() before statatest clears it
    local yr_max  = r(max)
    local yr_mean = r(mean)
    statatest assert_equal  `yr_min'  1990,     msg("earliest year is 1990")
    statatest assert_equal  `yr_max'  2013,     msg("latest year is 2013")
    statatest assert_approx `yr_mean' 2001.549, tol(0.01) msg("mean year ~2001.5 (slight panel imbalance)")
statatest end
```

**Output**

```
------------------------------------------------------------
statatest suite: Suite 6: Summary statistics
------------------------------------------------------------
  PASS : earliest year is 1990
  PASS : latest year is 2013
  PASS : mean year ~2001.5 (slight panel imbalance)
------------------------------------------------------------
3 / 3 tests passed: ALL PASS [Suite 6: Summary statistics]
------------------------------------------------------------
```

**Why statatest**

`assert r(min) == 1990` works for integer-valued results and halts on failure with no context. For `r(mean)`, floating-point representation makes exact equality fragile: `assert r(mean) == 2001.5` would fail (the actual mean is 2001.549 because the panel has slight imbalance). `assert_approx` documents the tolerance explicitly, making it clear that "close enough" is intentional rather than sloppy. When `assert_equal` fails, the output shows both the actual and expected values side by side, which is more useful than the cryptic `assertion is false` from bare `assert`.

---

### Suite 7: `setup` + `teardown`: test a subset, then restore

**Syntax**

```stata
statatest setup    [, msg(string)]
statatest teardown [, msg(string)]
```

`setup` snapshots the current dataset to a temp file; `teardown` restores it. Place assertions between them to test the modified data, then verify the restored state with further assertions after `teardown`.

**Input**

```stata
statatest begin "Suite 7: Setup and teardown"
    statatest setup
    keep if region == "AFR"
    statatest assert_nobs 1107,        msg("1107 African country-years")
    statatest assert_nomissing region, msg("region complete in Africa subset")
    statatest teardown
    statatest assert_nobs 5120,        msg("full 5,120-row dataset restored")
statatest end
```

**Output**

```
------------------------------------------------------------
statatest suite: Suite 7: Setup and teardown
------------------------------------------------------------
  [setup] dataset snapshot saved
  PASS : 1107 African country-years
  PASS : region complete in Africa subset
  [teardown] dataset restored
  PASS : full 5,120-row dataset restored
------------------------------------------------------------
3 / 3 tests passed: ALL PASS [Suite 7: Setup and teardown]
------------------------------------------------------------
```

**Why statatest**

`preserve` and `restore` achieve the same snapshot behaviour natively. The difference is that `preserve`/`restore` are invisible to the test framework: there is no pass/fail record of the restore happening, and you cannot assert the expected state after restore within the same reporting block. `statatest setup` and `statatest teardown` are part of the test narrative: the restore is timestamped in the output, and the `assert_nobs 5120` after `teardown` explicitly verifies that the full dataset came back, not just that no error was thrown.

---

### Suite 8: `expect_error`: assert a command fails with the right return code

**Syntax**

```stata
statatest expect_error command, rc(#) [msg(string)]
statatest expect_error "command, options", rc(#) [msg(string)]
```

The command runs under `capture`. The test passes only if the actual return code exactly matches `rc(#)`. If the command succeeds (`rc=0`) or fails with a different code, the output shows both the expected and actual codes. Wrap the command in quotes if it contains its own comma.

**Input**

```stata
statatest begin "Suite 8: expect_error"
    statatest expect_error assert 1 == 2,           rc(9)   msg("false assertion gives rc=9")
    statatest expect_error assert nosuchvar == 1,   rc(111) msg("unknown variable gives rc=111")
    statatest expect_error use "/no_such_file.dta", rc(601) msg("missing file gives rc=601")
statatest end
```

**Output**

```
------------------------------------------------------------
statatest suite: Suite 8: expect_error
------------------------------------------------------------
  PASS : false assertion gives rc=9
  PASS : unknown variable gives rc=111
  PASS : missing file gives rc=601
------------------------------------------------------------
3 / 3 tests passed: ALL PASS [Suite 8: expect_error]
------------------------------------------------------------
```

**Why statatest**

The native idiom is:

```stata
capture assert 1 == 2
assert _rc == 9
```

This is two lines, and the second `assert` halts if `_rc` is wrong. More importantly, it only checks "did something fail," not "did it fail in the right way." If `assert 1 == 2` were replaced by `assert 1 == 1`, `capture` would return `_rc = 0` and the subsequent `assert _rc == 9` would itself fail with rc=9, which is confusing. `expect_error` tests both conditions atomically: it fails with a clear message if the command unexpectedly succeeds (`expected rc(9), command succeeded`) or fails with the wrong code (`expected rc(9), got rc(111)`). This is especially valuable when testing input validation in custom ado-files.

---

### Suite 9: `statatest run`: batch-execute a separate test file

**Syntax**

```stata
statatest run "filename.do" [, strict]
```

Executes the do-file and aggregates pass/fail counts across all suites inside it. Returns `r(pass)`, `r(fail)`, `r(total)`, and `r(suites)`, making the results available for assertions in the calling do-file. Add `, strict` to exit non-zero if any test inside the file fails.

The sub-file (`sea_tests.do`) is written and run from the main do-file. Its content:

```stata
import delimited "TB_Burden_Country.csv", clear varnames(1)
rename estimatedincidenceallformsper100 inc_rate
rename casedetectionrateallformspercent cdr
keep if region == "SEA"

statatest begin "SEA region: South-East Asia checks"
  statatest assert_nobs 252
  statatest assert_nomissing region year
  statatest assert_range cdr, min(0)
  statatest assert_range inc_rate, min(0)
statatest end
```

**Input** (in the calling do-file)

```stata
statatest begin "Suite 9: statatest run (SEA sub-file)"
    statatest run "sea_tests.do"
    statatest assert (r(fail) == 0), msg("SEA sub-file: all tests pass")
statatest end
```

**Output**

```
------------------------------------------------------------
statatest suite: Suite 9: statatest run (SEA sub-file)
------------------------------------------------------------
============================================================
statatest run: sea_tests.do
============================================================
------------------------------------------------------------
statatest suite: SEA region: South-East Asia checks
------------------------------------------------------------
  PASS : 252 == 252 obs
  PASS : no missing in (region year)
  PASS : cdr >= 0
  PASS : inc_rate >= 0
------------------------------------------------------------
4 / 4 tests passed: ALL PASS [SEA region: South-East Asia checks]
------------------------------------------------------------
============================================================
4 / 4 tests passed across 1 suite(s): ALL PASS
============================================================
  PASS : SEA sub-file: all tests pass
------------------------------------------------------------
1 / 1 tests passed: ALL PASS [Suite 9: statatest run (SEA sub-file)]
------------------------------------------------------------
```

**Why statatest**

`do sea_tests.do` runs the file but gives back nothing you can act on: no `r()` scalars, no aggregate count, no way to fail a master do-file if a sub-test failed. Checking `_rc` after `do` only tells you whether the file crashed, not whether any assertion inside it failed. `statatest run` returns `r(pass)`, `r(fail)`, `r(total)`, and `r(suites)`, so the calling do-file can assert `r(fail) == 0` and fail hard if any sub-test broke. Add `, strict` to make `statatest run` itself exit non-zero on failure, which is what CI pipelines need to gate a merge.

---

## Saving results to a log file

When you run tests in batch or want to keep a record, save the output to a file:

```stata
capture log close
log using my_test_results.log, replace text

statatest begin "my suite"
  statatest assert (1 == 1), msg("sanity check")
statatest end

log close
```

The log file is plain text and can be opened in any text editor.

---

## Putting your tests in their own file

The recommended pattern is to keep your tests separate from your main code:

```
my_project/
├── mycommand.ado          ← the command you wrote
└── test_mycommand.do      ← the tests for it
```

Name your test file `test_` followed by the name of what you're testing. To run the tests:

```stata
do test_mycommand.do
```

Or from the command line (outside Stata):

```
stata -b do test_mycommand.do
```

---

## Quick reference card

| Command | What it does |
|---|---|
| `statatest begin "name"` | Start a test suite |
| `statatest assert (cond), msg("label")` | Pass if condition is true |
| `statatest assert_equal A B` | Pass if A equals B exactly |
| `statatest assert_approx A B, tol(#)` | Pass if A and B differ by less than # |
| `statatest assert_nomissing varlist` | Pass if no missing values |
| `statatest assert_unique varlist` | Pass if no duplicates |
| `statatest assert_range var, min(#) max(#)` | Pass if all values within bounds |
| `statatest assert_nobs #` | Pass if observation count equals # |
| `statatest assert_varlist names` | Pass if all variables exist |
| `statatest expect_error cmd, rc(#)` | Pass if command exits with that return code |
| `statatest setup` | Save a dataset snapshot |
| `statatest teardown` | Restore the saved snapshot |
| `statatest run "file.do"` | Run a test file, print session totals |
| `statatest end` | End the suite, print summary |
| `statatest end, strict` | Same, but exit with error if anything failed |

---

## Common mistakes

**"I get `command statatest not found`"**
The `.ado` files are not on Stata's search path. Re-read the Installation section and check that the files are in your PERSONAL ado folder.

**"My test always passes even when something is wrong"**
Make sure you are running the command you want to test *before* the assert. statatest checks whatever Stata's current state is at the moment the assert runs.

**"I'm checking a mean but getting FAIL even though the numbers look the same"**
Use `assert_approx` instead of `assert_equal` for any computed number. Floating-point results are almost never exactly equal.

**"Stata stops when a test fails"**
By default, statatest does NOT stop Stata when a test fails. It records the failure and continues. If Stata is stopping, something else in your do-file is producing an error. Try wrapping commands with `capture` if you expect them to fail.

---

## Getting help inside Stata

```stata
help statatest
```

---
