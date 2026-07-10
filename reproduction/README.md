# Reproduction study — data and scripts

This folder contains the data and scripts behind the validation section of the
SOMA Toolbox paper: the reproduction of published CEC 2017 results for five
variants, the two engineering examples, and the vectorization timing study.
Every number reported in the paper's tables can be regenerated from here.

## Layout

| Folder | Contents |
|---|---|
| `benchmarks/` | The harness: runner scripts, comparison script, CEC dispatchers. |
| `PublishedResults/` | Published reference numbers. `published_CEC2017_D30_all.csv` holds mean and standard deviation for AllToOne, AllToAll, Pareto, T3A, and iSOMA on CEC 2017 (D = 30, 51 runs), transcribed from Table 6 of Diep et al., *Applied Soft Computing* 116 (2022) 108270. |
| `ToolboxResults/` | Measured results. `toolbox_CEC2017_D30_51runs.csv` (raw toolbox runs), `comparison_CEC2017_D30.csv` (per-function comparison: means, standard deviations, z-statistic, p-value, reproduction verdict), `pareto_binary_CEC2017_D30.csv` (PRTVectorMode probe), `vectorized_speedup.csv`, `engineering_pid.csv` / `engineering_vessel.csv` (+ best designs), and `convergence_CEC2017_D30.mat` (median convergence curves). |

## Reproduction protocol

CEC 2017 functions F1 and F3–F30 (F2 was withdrawn by the organizers),
dimension 30, MaxFEs = 1e4 x 30, 51 independent runs per function (seeds 1–51),
errors below 1e-8 recorded as zero. Each variant runs through the public
`somamin` interface with its published default parameters. A function counts as
reproduced if a two-sample z-test computed from the published and measured
summary statistics does not reject equality of means at the 5% level, or if the
measured mean lies within one published standard deviation of the reported
mean.

## The CEC 2017 suite is not redistributed

The IEEE CEC test functions are distributed by the competition organizers
(P. N. Suganthan et al.) under their own terms and are deliberately not bundled
here — the toolbox itself depends on base MATLAB only. To rerun the study,
obtain the official CEC 2017 MATLAB package and arrange it as:

```
<cecRoot>/
  CEC2017/
    cec17_func.mex*      % compiled for your platform
    input_data/          % shift/rotation data from the official package
```

The thin dispatchers `cec_eval.m` / `cec_meta.m` in `benchmarks/` connect the
suite to `somamin` (the CEC MEX uses column individuals; `somamin` uses row
individuals — the adapter transposes).

## Regenerating the paper's numbers

```matlab
cd reproduction/benchmarks

% Table "Reproduction of published CEC 2017 results" (~ days of CPU; resumable)
runFullReproCEC17('<cecRoot>');        % writes ../ToolboxResults/toolbox_CEC2017_D30_51runs.csv
compareToPublished();                  % writes ../ToolboxResults/comparison_CEC2017_D30.csv

% PRTVectorMode probe on the four outlying Pareto cells (resumable)
runParetoBinary('<cecRoot>');

% Convergence figure data (median of 15 runs on F1, F7, F16)
generateConvergenceFig([], [], '<cecRoot>');

% Engineering examples (PID + pressure vessel) — base MATLAB only, minutes
runEngineeringExamples();

% Vectorized-vs-scalar timing table — base MATLAB only, run on an idle machine
measureVectorizedSpeedup();
```

`compareToPublished`, `runEngineeringExamples`, and `measureVectorizedSpeedup`
need no CEC installation. All long CEC runs append one row per
(variant, function) as they go and skip rows already present, so they can be
interrupted and relaunched safely.
