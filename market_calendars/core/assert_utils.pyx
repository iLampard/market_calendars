import warnings
from libc.math cimport fabs
from libc.math cimport fmax

cpdef int py_assert(condition, exception, str msg="") except -1:
    if not condition:
        raise exception(msg)
    return 0

cpdef int py_ensure_raise(exception, str msg="") except -1:
    raise exception(msg)

cpdef int py_warning(condition, warn_type, str msg=""):
    if not condition:
        warnings.warn(msg, warn_type)
    return 0

cpdef bint is_close(double a, double b=0., double rel_tol=1e-09, double abs_tol=1e-12) nogil:
    return fabs(a - b) <= fmax(rel_tol * fmax(fabs(a), fabs(b)), abs_tol)
