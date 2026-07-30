#!/usr/bin/env python3
"""Die-area budget for a Titan X7 GPU on the GT2N 2 nm PDK.

Every per-block figure below is MEASURED -- Yosys mapping onto GT2N
standard cells, elvt/w31/tt. Sources are the logs under syn/gt2n/results/
and the tables in docs/GT2N_2NM_SYNTHESIS.md. Nothing here is scaled from
another node or estimated from a formula.

What this is NOT: a floorplan. It sums standard-cell area only. A real die
adds routing overhead, clock tree, power grid, memory controllers, PHYs,
pads and whitespace -- typically pushing utilisation to 60-80%, so divide
by ~0.7 for a realistic die. That correction is applied at the end and
labelled.

Run:  python syn/gt2n/die_budget.py [num_lanes]
"""

import sys

# ---------------------------------------------------------------- measured
# (block, um^2, how it was measured)
FMA_LANE      = 476.85    # titan_x7_fp32_fma_pipe, aggressive -D 200
TENSOR_PE     = 283.29    # titan_x7_tensor_pe, aggressive, after sticky fix
REGFILE_BANK  = 37398.80  # titan_x7_regfile_banked, svt/w31 -- FLOPS, no SRAM
                          # 64 regs x 8 warps x 8 lanes x 32b = 131,072 bits

# Measured area vs configuration, same module, svt/w31 (syn/gt2n/results/
# regfile_config_sweep.txt). Note 64x4 and 32x8 cost the SAME: area tracks
# TOTAL CAPACITY, not how it is divided between warps and registers. That is
# what makes the register pool work -- the scheduler can choose the split at
# runtime without changing the silicon.
REGFILE_CONFIGS = {
    (64, 8): 37398.80,
    (64, 4): 20079.08,
    (32, 8): 20079.08,
    (32, 4): 11532.96,
}

# titan_x7_regfile_banked geometry, from its parameters:
#   NUM_WARPS=8 x NUM_REGS=64 entries, LANES=8 x 32 bits each
RF_BITS       = 8 * 64 * 8 * 32          # 131,072 bits
RF_LANES      = 8                        # lanes served by one such file

# Reference die sizes, for scale only.
RETICLE_MM2   = 858     # ~26 x 33 mm, the hard limit for one exposure
H100_MM2      = 814
AD102_MM2     = 609     # RTX 4090

# A compiled SRAM bitcell is roughly an order of magnitude denser than a
# flip-flop for the same bit. GT2N ships NO memory compiler, so this is the
# one number here that is NOT measured -- it is a stated assumption used
# only to show what an SRAM macro would change. Flagged in the output.
SRAM_DENSITY_GAIN = 10.0


def budget(lanes, regs=64, warps=8):
    lanes_per_rf = RF_LANES
    n_rf = lanes / lanes_per_rf
    rf_area = REGFILE_CONFIGS[(regs, warps)]

    fma_um2 = lanes * FMA_LANE
    tensor_um2 = lanes * TENSOR_PE
    rf_flop_um2 = n_rf * rf_area
    rf_sram_um2 = rf_flop_um2 / SRAM_DENSITY_GAIN

    return dict(
        lanes=lanes,
        fma=fma_um2 / 1e6,
        tensor=tensor_um2 / 1e6,
        rf_flop=rf_flop_um2 / 1e6,
        rf_sram=rf_sram_um2 / 1e6,
        rf_bits=n_rf * regs * warps * 8 * 32,
        regs=regs, warps=warps,
    )


def show(b):
    total_flop = b["fma"] + b["tensor"] + b["rf_flop"]
    total_sram = b["fma"] + b["tensor"] + b["rf_sram"]
    util = 0.70

    print(f"\nTITAN X7 die budget on GT2N 2 nm -- {b['lanes']:,} lanes")
    print("=" * 66)
    print("all per-block areas MEASURED by Yosys on GT2N cells (elvt/w31/tt)\n")

    print(f"  {'block':<34}{'mm^2':>10}{'share':>10}")
    print("  " + "-" * 54)
    for name, v in (("FP32 FMA lanes", b["fma"]),
                    ("tensor PEs", b["tensor"]),
                    ("register files (FLOPS, as built)", b["rf_flop"])):
        print(f"  {name:<34}{v:>10.2f}{100*v/total_flop:>9.1f}%")
    print("  " + "-" * 54)
    print(f"  {'TOTAL cell area':<34}{total_flop:>10.2f}")
    print(f"  {'/ 70% utilisation -> die':<34}{total_flop/util:>10.2f}"
          f"   <- realistic")

    print(f"\n  vs reference dies:")
    for name, mm2 in (("reticle limit", RETICLE_MM2),
                      ("H100", H100_MM2),
                      ("RTX 4090 (AD102)", AD102_MM2)):
        pct = 100 * (total_flop / util) / mm2
        verdict = "FITS" if pct <= 100 else "DOES NOT FIT"
        print(f"    {name:<20}{mm2:>5} mm^2   {pct:>7.1f}% of it   {verdict}")

    print(f"\n  The register file is {100*b['rf_flop']/total_flop:.0f}% of the"
          f" area and holds {b['rf_bits']/8/1024/1024:.1f} MiB.")
    print(f"  It is flip-flops because GT2N has NO SRAM and no memory"
          f" compiler.")
    print(f"\n  ASSUMPTION (not measured): a compiled SRAM bitcell is ~{SRAM_DENSITY_GAIN:.0f}x")
    print(f"  denser than a flop for storage. On that assumption:")
    print(f"    register files -> {b['rf_sram']:>8.2f} mm^2")
    print(f"    TOTAL cell area -> {total_sram:>8.2f} mm^2")
    print(f"    die at 70% util -> {total_sram/util:>8.2f} mm^2"
          f"   ({100*(total_sram/util)/AD102_MM2:.1f}% of a 4090 die)")


if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 20000
    r = int(sys.argv[2]) if len(sys.argv) > 2 else 64
    w = int(sys.argv[3]) if len(sys.argv) > 3 else 8
    show(budget(n, r, w))
    print()
