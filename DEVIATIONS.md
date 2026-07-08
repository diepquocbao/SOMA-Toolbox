# DEVIATIONS — documented differences from the original papers and reference code

Policy: every deliberate difference between this toolbox and the original
paper (or the author's reference implementation) is recorded here. Anything
not listed is intended to be faithful. If you find an undocumented difference,
please open an issue.

## Toolbox-wide

1. **Strict budget enforcement.** The reference implementations may overshoot
   `MaxFEs` by finishing the migration in progress. This toolbox never starts
   a jump path that would exceed `MaxFunctionEvaluations`, so
   `output.funccount <= MaxFunctionEvaluations` always holds (except when the
   budget is smaller than the initial population, which is evaluated once).
   The effect on results is negligible — at most a fraction of one migration's
   evaluations at the very end of a run.

2. **Row-individual data layout.** Populations are `PopulationSize`-by-`nvars`
   (rows are individuals), matching MATLAB Global Optimization Toolbox
   conventions. Several reference codes use the transposed layout; the
   algorithms are unchanged.

3. **Additional stopping criteria** (`MaxMigrations`, `MaxStallMigrations`
   with `FunctionTolerance`, `ObjectiveLimit`, and an output-function stop)
   are optional extensions. The defaults keep the papers' single criterion,
   `MaxFunctionEvaluations = 1e4 * nvars`.

4. **Boundary-handling options.** The published behavior — random
   reinitialization of out-of-bound components — is the default; `clip` and
   `reflect` are optional extensions.

## AllToOne

5. **The jump sequence includes t = 0** (`t = 0:Step:PathLength`), matching
   the reference code (the t = 0 point re-evaluates the individual's current
   position). Kept for fidelity with the code used in the published
   comparisons.

## T3A

6. **Defaults follow the paper, not the shared script.** The published
   settings (CEC 2019, Table I) are PopulationSize = 30, NJump = 45, m = 10,
   n = 4, k = 10; an earlier shared script used PopulationSize = 100 and
   n = 5. This toolbox defaults to the published values.

7. **The 2022 "V2" rewrite is intentionally not used.** It changed the PRT
   schedule constant (0.50 instead of the published 0.90), switched boundary
   handling to clipping, and altered the migrant/leader-coincidence check in a
   way inconsistent with both the paper and the 2020 reference code. This port
   follows the 2020 reference, which matches the paper.

## AllToAll, AllToAllAdaptive, AllToRand

8. **Implemented from the strategy descriptions** in Zelinka (2004); no
   reference code exists for these three classical variants.
   - **AllToAll** uses immediate (asynchronous) position updates: an
     individual moves as soon as a journey improves it, and later journeys use
     the updated positions. This reproduces the published SOMA-AllToAll
     baseline on the CEC2017 suite closely, whereas a synchronous (deferred)
     reading does not.
   - **AllToAllAdaptive** is the AllToAll topology with an adaptive PRT
     schedule (`PRT = 0.05 + 0.90 * FEs/MaxFEs`, as in T3A). "Adaptive" refers
     to adaptive control parameters.
   - **AllToRand** has each individual migrate toward one randomly chosen other
     individual per migration, with immediate updates.

   The jump sequence is `t = 0:Step:PathLength`, consistent with AllToOne.

## Pareto and iSOMA

9. **The soft (adaptive) PRT vector is the default.** Both papers present it
   as part of the proposed algorithm (Pareto Eq. 6; iSOMA Eq. 4). The
   `PRTVectorMode` option ("adaptive" or "binary") exposes both behaviors.
   The exact form was resolved against the published tables (CEC2017, D = 30,
   51 runs): the adaptive vector reproduces the published means well, and is
   kept as the default for consistency with the papers.

10. **iSOMA follows the reference code where it differs from the paper.** The
    published iSOMA results were produced by the reference implementation,
    which differs from the paper equations in three places, and only these
    values reproduce the published means:
    - PRT schedule `PRT = 0.10 + 0.90 * FEs/MaxFEs` (the paper's Eq. 5 states a
      constant 0.05);
    - the non-selected entry of the soft PRT vector is `0.5 * FEs/MaxFEs` (the
      paper's Eq. 4 states `FEs/MaxFEs`);
    - the partial-replacement counter is incremented per function evaluation.

    These are documented here because they contradict the stated equations;
    fidelity to the published *results* is the toolbox's reproduction claim.

11. **iSOMA migrant/leader coincidence** follows the reference implementation
    and the paper: when the migrant is the current best, the second best of
    the k sampled individuals is used as the leader.

12. **iSOMA partial replacement under a strict budget.** The 10% random
    reinitialization is skipped when fewer than 10% * PopulationSize
    evaluations remain in the budget (a consequence of deviation #1).
