# Titan X6 compute kernel: canonical row-major matrix multiplication.
#
# Compiled by compiler/titan_compiler.py:
#   scalar backend -> SM integer pipeline (int32 elements)
#   tensor backend -> 16x16x16 WMMA tiles on the FP8/INT8 tensor core array
#
# A: MxK, B: KxN, C: MxN (row-major, flat)

def matmul(A, B, C, M, N, K):
    """C = A @ B"""
    for i in range(M):
        for j in range(N):
            acc = 0
            for k in range(K):
                acc = acc + A[i * K + k] * B[k * N + j]
            C[i * N + j] = acc
