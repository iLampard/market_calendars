from .calendar cimport Calendar
from .date cimport Date
from .period cimport Period


cdef class Schedule(object):

    cdef public _effective_date
    cdef public _termination_date
    cdef public Period _tenor
    cdef public Calendar _cal
    cdef public int _convention
    cdef public int _termination_convention
    cdef public int _rule
    cdef public list _dates
    cdef public list _is_regular
    cdef public bint _end_of_month
    cdef public Date _first_date
    cdef public Date _next_to_last_date
    cdef public Date _evaluation_date

    cpdef size_t size(self)
    cpdef bint is_regular(self, size_t i)
    cpdef Calendar calendar(self)
    cpdef Period tenor(self)
    cpdef bint end_of_month(self)