def is_pow2(n):
    """Check if a number is a power of 2."""
    return (n != 0) and (n & (n - 1)) == 0
