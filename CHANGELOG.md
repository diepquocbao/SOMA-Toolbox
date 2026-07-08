# Changelog

All notable changes to the SOMA Toolbox are recorded here.

## [Unreleased]

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

### Notes
- The entry point is named `somamin` rather than `soma` because MATLAB ships
  a built-in demo named `soma`; the name also echoes `fminsearch`/`fminunc`.
- Any deliberate difference between a variant and its source paper is
  documented in [DEVIATIONS.md](DEVIATIONS.md).
