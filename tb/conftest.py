# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""pytest configuration for the Titan testbenches."""


def pytest_configure(config):
    config.addinivalue_line(
        "markers",
        "slow: whole-GPU simulations that take minutes "
        "(the design runs at roughly 90 clock cycles per wall second). "
        "run_regression.py's `compute` suite runs `-m 'not slow'`.")
