cpdef int py_assert(condition, exception, str msg= *) except -1

cpdef int py_ensure_raise(exception, str msg= *) except -1

cpdef int py_warning(condition, warn_type, str msg= *)

cpdef bint is_close(double a, double b= *, double rel_tol= *, double abs_tol= *) nogil
