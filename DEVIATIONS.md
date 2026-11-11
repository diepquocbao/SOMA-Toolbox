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

8. **Strategy definitions and reference code.** The three strategies follow
   the definitions of Zelinka in *Self-Organizing Migrating Algorithm:
   Methodology and Implementation* (Springer, 2016), Section 5, and agree
   statistically with the MATLAB reference files of the classical strategies
   distributed from the SOMA home page (`soma_all_to_all.m`,
   `soma_all_to_all_adaptive.m`, `soma_all_to_one_randomly.m`, October 2005)
   on the CEC2017 suite (D = 30, 51 runs).
   - **AllToAll**: every individual travels toward every other individual, and
     all its journeys within a migration start from the same position; it then
     takes the best position found on any journey.
   - **AllToAllAdaptive**: the same topology, but each journey starts from the
     best position found so far. This is the strategy behind the baseline
     labelled "SOMA AllToAll" in the published SOMA T3A, SOMA Pareto and iSOMA
     comparisons. *Version 1.0.0 shipped this strategy under the name
     AllToAll, and its AllToAllAdaptive used an adaptive PRT schedule that has
     no source; version 1.1.0 corrects both.*
   - **AllToRand**: every individual travels toward one randomly chosen other
     individual per migration.

   Differences from the 2005 reference files, none of which changes results
   statistically: the reference code redraws a PRT vector that has no active
   coordinate; its all-to-all target loop visits one individual twice and skips
   another; its random target is not exactly uniform (the last individual has
   half the probability of the others). The jump sequence is
   `t = 0:Step:PathLength`, consistent with AllToOne.

## Pareto and iSOMA

9. **The soft (adaptive) PRT vector is the default.** Both papers present it
   as part of the proposed algorithm (Pareto Eq. 6; iSOMA Eq. 4), and the code
   that produced their published tables uses it; the later public releases of
   the code disable it. The `PRTVectorMode` option ("adaptive" or "binary")
   exposes both behaviors.

13. **Pareto follows the code that produced its published tables.** The Pareto
    paper prints cosine schedules, `PRT = 0.50 + 0.45*cos(pi*t + pi)` and
    `Step = 0.35 + 0.15*cos(pi*t)` with `t = FEs/MaxFEs` (Eqs. 4-5). The 2019
    code of its CEC2017 experiments uses linear schedules with the same end
    values, `PRT = 0.05 + 0.90*t` and `Step = 0.50 - 0.30*t`, and accepts a new
    position only if it is strictly better. Only the code values reproduce the
    published results (within one published standard deviation on 28 of 29
    functions, against 23 for the cosine forms). *Version 1.0.0 used the cosine
    forms; version 1.1.0 uses the linear ones.*

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
