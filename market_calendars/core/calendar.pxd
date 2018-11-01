from .date cimport Date
from .period cimport Period

cdef class CalendarImpl(object):
    cdef bint isBizDay(self, Date date)
    cdef bint isWeekEnd(self, int weekDay)

cdef class Calendar(object):
    cdef public CalendarImpl _impl
    cdef public str name

    cpdef is_biz_day(self, Date d)
    cpdef is_holiday(self, Date d)
    cpdef is_weekend(self, int weekday)
    cpdef is_end_of_month(self, Date d)
    cpdef end_of_month(self, Date d)
    cpdef biz_days_between(self, Date from_date, Date to_date, bint include_first= *, bint include_last= *)
    cpdef adjust_date(self, Date d, int c= *)
    cpdef advance_date(self, Date d, Period period, int c= *, bint end_of_month= *)
    cpdef holiday_dates_list(self, Date from_date, Date to_date, bint include_weekends= *)
    cpdef biz_dates_list(self, Date from_date, Date to_date)
