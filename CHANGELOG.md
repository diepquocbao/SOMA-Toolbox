# Changelog

All notable changes to the SOMA Toolbox are recorded here.

## [1.1.0] — 2026-11-11

### Changed
- **AllToAll and AllToAllAdaptive follow the strategy definitions.** In
  AllToAll every journey of an individual within a migration starts from the
  same position; in AllToAllAdaptive each journey starts from the best position
  found so far (Zelinka, in *Self-Organizing Migrating Algorithm: Methodology
  and Implementation*, Springer, 2016, Sec. 5). Version 1.0.0 shipped the
  adaptive strategy under the name AllToAll, and its AllToAllAdaptive used an
  adaptive PRT schedule that has no source. Code that relied on the old
  AllToAll behaviour should now select `'AllToAllAdaptive'`.
- **Pareto follows the code that produced its published tables:** linear
  schedules `PRT = 0.05 + 0.90*t` and `Step = 0.50 - 0.30*t` (the paper prints
  cosine forms with the same end values) and acceptance of strictly better
  positions only. See DEVIATIONS.md, item 13.
- The pressure-vessel example uses the penalty coefficient 1e9 of the
  accompanying article.
- `reproduction/` holds the validation study of this version: the per-run
  results, the published per-run results used for the distribution tests, and
  the scripts that run the experiments and compute the statistics. The study of
  version 1.0.0 remains in the `v1.0.0` release.

### Added
- Conformance tests (`tests/test_classical_strategies.m`) that compare every
  path evaluated by AllToOne, AllToAll, AllToAllAdaptive and AllToRand with the
  strategy definition (36 tests in total).

### Validation
- Against the published CEC 2017 results (five variants, 145 function-variant
  cells): the mean lies within one published standard deviation in 142 cells and
  a test of equivalence (margin one published standard deviation) passes in 139.
- Against the 2005 MATLAB reference code of the classical strategies (AllToAll,
  AllToAllAdaptive, AllToRand; 87 cells): the mean lies within one standard
  deviation in every cell.

## [1.0.0] — 2026-07-10

First public release.

### Added
- Unified interface `somamin(fun, nvars, lb, ub, options)` with the
  companion functions `somaoptions` and `somaplotbestf`, following the
  MATLAB Global Optimization Toolbox calling convention.
- Seven variants selectable through `somaoptions('Variant', ...)`: AllToOne,
  AllToAll, AllToAllAdaptive, AllToRand, T3A, Pareto, and iSOMA. Each variant
  uses the parameter values published in its original paper.
- `PRTVectorMode` option ("adaptive" or "binary") for Pareto and iSOMA.
- Common options for all variants: population size, stopping criteria
  (function evaluations, migrations, objective limit, stall), boundary
  handling (reinitialize, clip, reflect), vectorized objectives, a fixed
  seed for repeatable runs, and display, output, and plot callbacks.
- Getting Started guide, per-function documentation in the MATLAB Help
  browser, and three worked examples: a basic tour, PID controller tuning,
  and constrained pressure-vessel design.
- Automated test suite covering the public interface and every variant.
- `reproduction/` folder with the published baselines, measured results, and
  the scripts that regenerate the reproduction study (141 of 145 published
  CEC 2017 function–variant cells recovered across five variants).

### Notes
- The entry point is named `somamin` rather than `soma` because MATLAB ships
  a built-in demo named `soma`; the name also echoes `fminsearch`/`fminunc`.
- Any deliberate difference between a variant and its source paper is
  documented in [DEVIATIONS.md](DEVIATIONS.md).
