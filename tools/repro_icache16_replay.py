import os, sys
ROOT = r"C:\Titan-X5B-GPU"
sys.path.insert(0, os.path.join(ROOT, "tb"))
sys.path.insert(0, os.path.join(ROOT, "compiler"))
os.environ["TITAN_ICACHE"] = "1"
os.environ["TITAN_SM"] = "x5"
os.environ["TITAN_DEFINES"] = ("TITAN_ICACHE_LINE_BYTES=16,"
                               "TITAN_ICACHE_SETS=256,TITAN_ID_TRACE")
import compute_runner as cr
import test_compute_kernels as T

OUT = os.path.join(os.path.dirname(__file__), "w5trace2.txt")

_real = cr.run
def spy(*a, **k):
    res = _real(*a, **k)
    with open(OUT, "w", encoding="utf-8", errors="replace") as f:
        f.write(res.log)
    print("result words:", [hex(w) for w in res.words])
    print("log lines:", len(res.log.splitlines()), "->", OUT)
    return res
cr.run = spy
T.cr.run = spy

try:
    T.test_predicates_are_per_warp()
    print("TEST PASSED")
except AssertionError as e:
    print("TEST FAILED (expected):", str(e)[:200])
