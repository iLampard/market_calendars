from ._date_generation cimport DateGeneration as dg

cpdef enum DateGeneration:
    Zero = dg.Zero
    Backward = dg.Backward
    Forward = dg.Forward
