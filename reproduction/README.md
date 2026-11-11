# Reproduction study — version 1.1.0

This folder holds the code and the per-run results behind the validation of the
toolbox: the reproduction of published CEC 2017 results, the comparison with
the 2005 reference code of the classical strategies, the timing study, and the
two engineering examples. Every statistic reported for version 1.1.0 can be
recomputed from here. The study of version 1.0.0 is kept in the `v1.0.0`
release.

## Contents

| Folder | Content |
|---|---|
| `experiments/` | `run_cec2017.m` (CEC 2017 study), `pareto_cosine.m` (Pareto with the cosine schedules printed in its article), `ref2005_run.m` and `ref2005_objective.m` (driver for the 2005 reference files), `cec_eval.m` and `cec_meta.m` (CEC dispatchers), `run_engineering.m` (PID and pressure-vessel examples), `run_speedup.m` (timing study) |
| `analysis/` | `run_statistics.m` and its helpers: `compareSamples.m` (one-standard-deviation check, two-sample z-test, two one-sided tests), `rsTest.m` (Wilcoxon rank-sum test and Vargha-Delaney A), `holm.m` (Holm adjustment) |
| `results/cec2017/` | per-run errors f(x) - f* on CEC 2017, n = 30, 3e5 evaluations; rows F1, F3-F30, columns runs with seeds 1-51. One file per variant of the toolbox, `Pareto_cosine.csv`, and `ref_*.csv` for the 2005 reference files |
| `results/engineering/` | every run of the PID and pressure-vessel examples (objective value, design, constraint values) and the run of the listed PID code |
| `results/speedup/` | every timing of the vectorization study and the description of the machine |
| `results/statistics/` | output of `run_statistics.m` |
| `published/` | published results used for comparison: means and standard deviations of Table 6 of Diep et al. (2022), and the per-run errors behind that table for AllToOne, AllToAllAdaptive (labelled SOMA AllToAll there), Pareto and T3A |

## Requirements

MATLAB R2021a or later; no additional toolbox. The results were produced with
MATLAB R2025b on Windows 11.

## Recomputing the statistics

From this folder, in MATLAB:

```matlab
addpath('analysis'); run_statistics
```

| Statistic | File in `results/statistics/` |
|---|---|
| Vectorization speed-up | `speedup_summary.csv` |
| Toolbox against published results | `repro_summary.csv`, per function `repro_comparison.csv` |
| Toolbox against the 2005 reference code | `crosscheck_summary.csv`, per function `crosscheck_comparison.csv` |
| Pareto: linear against cosine schedules | `pareto_schedules.csv` |
| Engineering examples | `engineering_summary.csv`, `results/engineering/pid_listing.csv` |

## Re-running the experiments

The scripts add the `toolbox` folder of this repository to the MATLAB path. All
runs are seeded; for the same seed and MATLAB version the toolbox gives
bit-identical runs.

- CEC 2017: `run_cec2017(cecRoot, outDir)`, where `cecRoot` holds the compiled
  CEC 2017 function `cec17_func` and its `input_data` folder, distributed by the
  organizers of the competition (not included). A subset can be run, for
  example `run_cec2017(cecRoot, outDir, {'Pareto'}, [5 7])`.
- 2005 reference code: the configurations `ref_*` call the MATLAB files
  `soma_all_to_all.m`, `soma_all_to_all_adaptive.m` and
  `soma_all_to_one_randomly.m` of the classical strategies, distributed from the
  SOMA home page. They carry no licence statement and are not included; place
  them on the MATLAB path. SHA-256 of the files used:
  - `soma_all_to_all.m` a844d5e8879548618d579b9843d04c21f6f1fc751cdfa55e0c131652bb4a298b
  - `soma_all_to_all_adaptive.m` 1b0fccde14a387d46c746468da6e55670828143a2c9a8858d88c8f4e057f698f
  - `soma_all_to_one_randomly.m` 975731203bcebf8d66facc6efc88ad1d320d32ab722e6202ce87248c1aa13202
- Engineering examples: `run_engineering(outDir)`.
- Timing: `run_speedup(outDir)`, on an otherwise idle machine.

## Licence

MIT, as the rest of the repository (see [LICENSE](../LICENSE)).

## Reference

Diep, Q.B., Truong, T.C., Das, S. and Zelinka, I. (2022), "Self-organizing
migrating algorithm with narrowing search space strategy for robot path
planning", Applied Soft Computing, Vol. 116, p. 108270.
