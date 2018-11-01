cdef class Period(object):

    cdef public int _length
    cdef public int _units

    cpdef Period normalize(self)
    cpdef int length(self)
    cpdef int units(self)