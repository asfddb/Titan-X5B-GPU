#!/usr/bin/env python3
"""Regression suite — runs all tests with multiple seeds."""
import subprocess
import sys
import argparse
import random
import os

TESTS = [
    "test_alu_ops",
    "test_crossbar_routing",
    "test_cache_coherence",
    "test_texture_sampling",
    "test_display_timing",
    "test_system",
    "test_graphics_pipeline",
]

def run_test(test_name, seed, verbose=False):
    env = os.environ.copy()
    env["RANDOM_SEED"] = str(seed)
    cmd = ["python", "-m", "pytest", f"../tb/{test_name}.py",
            f"--cocotb-make-module={test_name}", "-v"]
    result = subprocess.run(cmd, env=env, capture_output=True, text=True)
    if verbose:
        print(result.stdout)
    return result.returncode == 0

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seeds", type=int, default=10)
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    total = 0
    passed = 0
    for test in TESTS:
        for s in range(args.seeds):
            seed = random.randint(0, 2**32-1)
            total += 1
            ok = run_test(test, seed, args.verbose)
            if ok:
                passed += 1
                print(f"  ✅ {test} seed={seed}")
            else:
                print(f"  ❌ {test} seed={seed}")

    print(f"\nRegression: {passed}/{total} passed")
    sys.exit(0 if passed == total else 1)

if __name__ == "__main__":
    main()
