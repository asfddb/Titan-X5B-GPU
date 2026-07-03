# Titan X5-B Synthesis Report

## Overview
This report contains the synthesis results for the Titan X5-B GPU Top level module targeting a generic logic gate library using Yosys.

## Gate Distribution
![Gate Distribution](../docs/assets/synth_pie.svg)

## Metrics
- **Total Logic Cells:** 3,030,603
- **Flip-Flops:** ~530,000

## Competitive Comparison
| GPU Core | Gate Count | License |
| :--- | :--- | :--- |
| **Titan X5-B** | **~3,030K** | Dual-License (Commercial) |
| Mali-400 MP1 | ~250K | Proprietary |
| PowerVR Series8XE | ~300K | Proprietary |
| Vortex | ~150K | Open Source (Academic) |

*Note: Due to its size, this GPU will not fit on low-end FPGAs like the Artix-7, but can be scaled for large Virtex Ultrascale+ or Stratix 10 devices.*
