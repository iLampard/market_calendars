cdef class Date(object):

    cdef public int __serial_number__
    cdef public int _year
    cdef public int _month
    cdef public int _day

    cpdef int day_of_month(self)

    cpdef int day_of_year(self)

    cpdef int year(self)

    cpdef int month(self)

    cpdef int weekday(self)

    cpdef to_datetime(self)

    cdef _calculate_date(self, int year, int month, int day)


cpdef check_date(date)