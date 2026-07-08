# SOMA Toolbox

An open-source MATLAB toolbox for the family of **Self-Organizing Migrating
Algorithms (SOMA)** — one unified interface, in the style of the MATLAB Global
Optimization Toolbox, for the classical variants (AllToOne, AllToAll,
AllToAllAdaptive, AllToRand) and the modern variants by the original authors
(SOMA T3A, SOMA Pareto, iSOMA).

Requires MATLAB R2021a or newer. No additional toolboxes are needed.

## Installation

Download the latest `SOMA Toolbox.mltbx` from the releases page and
double-click it in MATLAB, or run `matlab.addons.toolbox.installToolbox`.
To use the source directly instead, add the `toolbox` folder to your path:

```matlab
addpath('toolbox')
```

## Quick start

```matlab
opts = somaoptions('Variant','AllToOne', 'Seed',1);
[x, fval] = somamin(@(x) sum(x.^2), 10, -100, 100, opts)
```

`somamin(fun, nvars, lb, ub, options)` follows the MATLAB Global Optimization
Toolbox calling convention: row individuals, an options structure, and the
`[x, fval, exitflag, output]` contract. Choose the variant with
`somaoptions('Variant', ...)`; the default parameters of each variant are the
values published in its original paper. Set `opts.Seed` for repeatable runs.

For a guided introduction, open the **Getting Started** guide from the Add-On
Manager, or run `examples/GettingStarted.m`.

## Variants and references

| Variant (options.Variant) | Reference |
|---|---|
| `AllToOne`, `AllToAll`, `AllToAllAdaptive`, `AllToRand` | I. Zelinka, "SOMA — Self-Organizing Migrating Algorithm", in *New Optimization Techniques in Engineering*, Springer, 2004, pp. 167–217. [doi:10.1007/978-3-540-39930-8_7](https://doi.org/10.1007/978-3-540-39930-8_7) |
| `T3A` | Q. B. Diep, "Self-Organizing Migrating Algorithm Team To Team Adaptive — SOMA T3A", *IEEE CEC 2019*, pp. 1182–1187. [doi:10.1109/CEC.2019.8790202](https://doi.org/10.1109/CEC.2019.8790202) |
| `Pareto` | Q. B. Diep, I. Zelinka, S. Das, "Self-Organizing Migrating Algorithm Pareto", *MENDEL* 25(1):111–120, 2019. [doi:10.13164/mendel.2019.1.111](https://doi.org/10.13164/mendel.2019.1.111) |
| `iSOMA` | Q. B. Diep, T. C. Truong, S. Das, I. Zelinka, "Self-Organizing Migrating Algorithm with narrowing search space strategy for robot path planning", *Applied Soft Computing* 116:108270, 2022. [doi:10.1016/j.asoc.2021.108270](https://doi.org/10.1016/j.asoc.2021.108270) |

## License and citation

Released under the MIT license (see [LICENSE](LICENSE)). If you use
the SOMA Toolbox in your work, please cite the paper of the variant you used
(table above). Citation metadata for the toolbox itself is in
[CITATION.cff](CITATION.cff).
