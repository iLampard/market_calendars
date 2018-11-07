from .enums._time_units cimport TimeUnits
from .enums._bizday_conventions cimport BizDayConventions
from .enums._months cimport Months
from .enums._weekdays cimport Weekdays
from .date cimport Date
from .period cimport Period

cdef class Calendar(object):
    def __init__(self, str holCenter):
        holCenter = holCenter.lower()
        try:
            self._impl = _holDict[holCenter]()
        except KeyError:
            raise ValueError("{0} is not a valid description of a holiday center".format(holCenter))
        self.name = holCenter

    cpdef is_biz_day(self, Date d):
        return self._impl.isBizDay(d)

    cpdef is_holiday(self, Date d):
        return not self._impl.isBizDay(d)

    cpdef is_weekend(self, int weekday):
        return self._impl.isWeekEnd(weekday)

    cpdef is_end_of_month(self, Date d):
        return d.month() != self.adjust_date(d + 1).month()

    cpdef end_of_month(self, Date d):
        return self.adjust_date(Date.end_of_month(d), BizDayConventions.Preceding)

    cpdef biz_days_between(self, Date from_date, Date to_date, bint include_first=True, bint include_last=False):
        cdef int wd = 0
        cdef Date d

        if from_date != to_date:
            if from_date < to_date:
                d = from_date
                while d < to_date:
                    if self.is_biz_day(d):
                        wd += 1
                    d += 1
                if self.is_biz_day(to_date):
                    wd += 1
            elif from_date > to_date:
                d = to_date
                while d < from_date:
                    if self.is_biz_day(d):
                        wd += 1
                    d += 1
                if self.is_biz_day(from_date):
                    wd += 1
            if self.is_biz_day(from_date) and not include_first:
                wd -= 1
            if self.is_biz_day(to_date) and not include_last:
                wd -= 1
        return wd

    cpdef adjust_date(self, Date d, int c=BizDayConventions.Following):

        cdef Date d1
        cdef Date d2

        if c == BizDayConventions.Unadjusted:
            return d
        d1 = d

        if c == BizDayConventions.Following or c == BizDayConventions.ModifiedFollowing or \
                c == BizDayConventions.HalfMonthModifiedFollowing:
            while self.is_holiday(d1):
                d1 += 1
            if c == BizDayConventions.ModifiedFollowing or c == BizDayConventions.HalfMonthModifiedFollowing:
                if d1.month() != d.month():
                    return self.adjust_date(d, BizDayConventions.Preceding)
                if c == BizDayConventions.HalfMonthModifiedFollowing:
                    if d.day_of_month() <= 15 < d1.day_of_month():
                        return self.adjust_date(d, BizDayConventions.Preceding)
        elif c == BizDayConventions.Preceding or c == BizDayConventions.ModifiedPreceding:
            while self.is_holiday(d1):
                d1 -= 1
            if c == BizDayConventions.ModifiedPreceding and d1.month() != d.month():
                return self.adjust_date(d, BizDayConventions.Following)
        elif c == BizDayConventions.Nearest:
            d2 = d
            while self.is_holiday(d1) and self.is_holiday(d2):
                d1 += 1
                d2 -= 1

            if self.is_holiday(d1):
                return d2
            else:
                return d1
        else:
            raise ValueError("unknown business-day convention")
        return d1

    cpdef advance_date(self, Date d, Period period, int c=BizDayConventions.Following, bint end_of_month=False):

        cdef int n
        cdef int units
        cdef Date d1

        n = period.length()
        units = period.units()

        if n == 0:
            return self.adjust_date(d, c)
        elif units == TimeUnits.BDays:
            d1 = d
            if n > 0:
                while n > 0:
                    d1 += 1
                    while self.is_holiday(d1):
                        d1 += 1
                    n -= 1
            else:
                while n < 0:
                    d1 -= 1
                    while self.is_holiday(d1):
                        d1 -= 1
                    n += 1
            return d1
        elif units == TimeUnits.Days or units == TimeUnits.Weeks:
            d1 = d + period
            return self.adjust_date(d1, c)
        else:
            d1 = d + period
            if end_of_month and self.is_end_of_month(d):
                return self.end_of_month(d1)
            return self.adjust_date(d1, c)

    cpdef holiday_dates_list(self, Date from_date, Date to_date, bint include_weekends=True):
        cdef list result = []
        cdef Date d = from_date

        while d <= to_date:
            if self.is_holiday(d) and (include_weekends or not self.is_weekend(d.weekday())):
                result.append(d)
            d += 1
        return result

    cpdef biz_dates_list(self, Date from_date, Date to_date):
        cdef list result = []
        cdef Date d = from_date

        while d <= to_date:
            if self.is_biz_day(d):
                result.append(d)
            d += 1
        return result

    def __richcmp__(self, right, int op):
        if op == 2:
            return self._impl == right._impl

    def __deepcopy__(self, memo):
        return Calendar(self.name)

    def __reduce__(self):
        d = {}

        return Calendar, (self.name,), d

    def __setstate__(self, state):
        pass

cdef class CalendarImpl(object):
    cdef bint isBizDay(self, Date date):
        pass

    cdef bint isWeekEnd(self, int weekDay):
        pass

cdef set sse_holDays = {Date(2005, 1, 3),
                        Date(2005, 2, 7),
                        Date(2005, 2, 8),
                        Date(2005, 2, 9),
                        Date(2005, 2, 10),
                        Date(2005, 2, 11),
                        Date(2005, 2, 14),
                        Date(2005, 2, 15),
                        Date(2005, 4, 4),
                        Date(2005, 5, 2),
                        Date(2005, 5, 3),
                        Date(2005, 5, 4),
                        Date(2005, 5, 5),
                        Date(2005, 5, 6),
                        Date(2005, 6, 9),
                        Date(2005, 9, 15),
                        Date(2005, 10, 3),
                        Date(2005, 10, 4),
                        Date(2005, 10, 5),
                        Date(2005, 10, 6),
                        Date(2005, 10, 7),
                        Date(2006, 1, 2),
                        Date(2006, 1, 3),
                        Date(2006, 1, 26),
                        Date(2006, 1, 27),
                        Date(2006, 1, 30),
                        Date(2006, 1, 31),
                        Date(2006, 2, 1),
                        Date(2006, 2, 2),
                        Date(2006, 2, 3),
                        Date(2006, 4, 4),
                        Date(2006, 5, 1),
                        Date(2006, 5, 2),
                        Date(2006, 5, 3),
                        Date(2006, 5, 4),
                        Date(2006, 5, 5),
                        Date(2006, 6, 9),
                        Date(2006, 9, 15),
                        Date(2006, 10, 2),
                        Date(2006, 10, 3),
                        Date(2006, 10, 4),
                        Date(2006, 10, 5),
                        Date(2006, 10, 6),
                        Date(2007, 1, 1),
                        Date(2007, 1, 2),
                        Date(2007, 1, 3),
                        Date(2007, 2, 19),
                        Date(2007, 2, 20),
                        Date(2007, 2, 21),
                        Date(2007, 2, 22),
                        Date(2007, 2, 23),
                        Date(2007, 4, 4),
                        Date(2007, 5, 1),
                        Date(2007, 5, 2),
                        Date(2007, 5, 3),
                        Date(2007, 5, 4),
                        Date(2007, 5, 7),
                        Date(2007, 10, 1),
                        Date(2007, 10, 2),
                        Date(2007, 10, 3),
                        Date(2007, 10, 4),
                        Date(2007, 10, 5),
                        Date(2007, 12, 31),
                        Date(2008, 1, 1),
                        Date(2008, 2, 6),
                        Date(2008, 2, 7),
                        Date(2008, 2, 8),
                        Date(2008, 2, 11),
                        Date(2008, 2, 12),
                        Date(2008, 4, 4),
                        Date(2008, 5, 1),
                        Date(2008, 5, 2),
                        Date(2008, 6, 9),
                        Date(2008, 9, 15),
                        Date(2008, 9, 29),
                        Date(2008, 9, 30),
                        Date(2008, 10, 1),
                        Date(2008, 10, 2),
                        Date(2008, 10, 3),
                        Date(2009, 1, 1),
                        Date(2009, 1, 2),
                        Date(2009, 1, 26),
                        Date(2009, 1, 27),
                        Date(2009, 1, 28),
                        Date(2009, 1, 29),
                        Date(2009, 1, 30),
                        Date(2009, 4, 6),
                        Date(2009, 5, 1),
                        Date(2009, 5, 28),
                        Date(2009, 5, 29),
                        Date(2009, 10, 1),
                        Date(2009, 10, 2),
                        Date(2009, 10, 5),
                        Date(2009, 10, 6),
                        Date(2009, 10, 7),
                        Date(2009, 10, 8),
                        Date(2010, 1, 1),
                        Date(2010, 2, 15),
                        Date(2010, 2, 16),
                        Date(2010, 2, 17),
                        Date(2010, 2, 18),
                        Date(2010, 2, 19),
                        Date(2010, 4, 5),
                        Date(2010, 5, 3),
                        Date(2010, 6, 14),
                        Date(2010, 6, 15),
                        Date(2010, 6, 16),
                        Date(2010, 9, 22),
                        Date(2010, 9, 23),
                        Date(2010, 9, 24),
                        Date(2010, 10, 1),
                        Date(2010, 10, 4),
                        Date(2010, 10, 5),
                        Date(2010, 10, 6),
                        Date(2010, 10, 7),
                        Date(2011, 1, 3),
                        Date(2011, 2, 2),
                        Date(2011, 2, 3),
                        Date(2011, 2, 4),
                        Date(2011, 2, 7),
                        Date(2011, 2, 8),
                        Date(2011, 4, 4),
                        Date(2011, 4, 5),
                        Date(2011, 5, 2),
                        Date(2011, 6, 6),
                        Date(2011, 9, 12),
                        Date(2011, 10, 3),
                        Date(2011, 10, 4),
                        Date(2011, 10, 5),
                        Date(2011, 10, 6),
                        Date(2011, 10, 7),
                        Date(2012, 1, 2),
                        Date(2012, 1, 3),
                        Date(2012, 1, 23),
                        Date(2012, 1, 24),
                        Date(2012, 1, 25),
                        Date(2012, 1, 26),
                        Date(2012, 1, 27),
                        Date(2012, 4, 2),
                        Date(2012, 4, 3),
                        Date(2012, 4, 4),
                        Date(2012, 4, 30),
                        Date(2012, 5, 1),
                        Date(2012, 6, 22),
                        Date(2012, 10, 1),
                        Date(2012, 10, 2),
                        Date(2012, 10, 3),
                        Date(2012, 10, 4),
                        Date(2012, 10, 5),
                        Date(2013, 1, 1),
                        Date(2013, 1, 2),
                        Date(2013, 1, 3),
                        Date(2013, 2, 11),
                        Date(2013, 2, 12),
                        Date(2013, 2, 13),
                        Date(2013, 2, 14),
                        Date(2013, 2, 15),
                        Date(2013, 4, 4),
                        Date(2013, 4, 5),
                        Date(2013, 4, 29),
                        Date(2013, 4, 30),
                        Date(2013, 5, 1),
                        Date(2013, 6, 10),
                        Date(2013, 6, 11),
                        Date(2013, 6, 12),
                        Date(2013, 9, 19),
                        Date(2013, 9, 20),
                        Date(2013, 10, 1),
                        Date(2013, 10, 2),
                        Date(2013, 10, 3),
                        Date(2013, 10, 4),
                        Date(2013, 10, 7),
                        Date(2014, 1, 1),
                        Date(2014, 1, 31),
                        Date(2014, 2, 3),
                        Date(2014, 2, 4),
                        Date(2014, 2, 5),
                        Date(2014, 2, 6),
                        Date(2014, 4, 7),
                        Date(2014, 5, 1),
                        Date(2014, 5, 2),
                        Date(2014, 6, 2),
                        Date(2014, 9, 8),
                        Date(2014, 10, 1),
                        Date(2014, 10, 2),
                        Date(2014, 10, 3),
                        Date(2014, 10, 6),
                        Date(2014, 10, 7),
                        Date(2015, 1, 1),
                        Date(2015, 1, 2),
                        Date(2015, 2, 18),
                        Date(2015, 2, 19),
                        Date(2015, 2, 20),
                        Date(2015, 2, 23),
                        Date(2015, 2, 24),
                        Date(2015, 4, 6),
                        Date(2015, 5, 1),
                        Date(2015, 6, 22),
                        Date(2015, 9, 3),
                        Date(2015, 9, 4),
                        Date(2015, 10, 1),
                        Date(2015, 10, 2),
                        Date(2015, 10, 5),
                        Date(2015, 10, 6),
                        Date(2015, 10, 7),
                        Date(2016, 1, 1),
                        Date(2016, 2, 8),
                        Date(2016, 2, 9),
                        Date(2016, 2, 10),
                        Date(2016, 2, 11),
                        Date(2016, 2, 12),
                        Date(2016, 4, 4),
                        Date(2016, 5, 1),
                        Date(2016, 5, 2),
                        Date(2016, 6, 9),
                        Date(2016, 6, 10),
                        Date(2016, 9, 15),
                        Date(2016, 9, 16),
                        Date(2016, 10, 3),
                        Date(2016, 10, 4),
                        Date(2016, 10, 5),
                        Date(2016, 10, 6),
                        Date(2016, 10, 7),
                        Date(2017, 1, 2),
                        Date(2017, 1, 27),
                        Date(2017, 1, 30),
                        Date(2017, 1, 31),
                        Date(2017, 2, 1),
                        Date(2017, 2, 2),
                        Date(2017, 4, 3),
                        Date(2017, 4, 4),
                        Date(2017, 5, 1),
                        Date(2017, 5, 29),
                        Date(2017, 5, 30),
                        Date(2017, 10, 2),
                        Date(2017, 10, 3),
                        Date(2017, 10, 4),
                        Date(2017, 10, 5),
                        Date(2017, 10, 6),
                        Date(2018, 1, 1),
                        Date(2018, 2, 15),
                        Date(2018, 2, 16),
                        Date(2018, 2, 19),
                        Date(2018, 2, 20),
                        Date(2018, 2, 21),
                        Date(2018, 4, 5),
                        Date(2018, 4, 6),
                        Date(2018, 4, 30),
                        Date(2018, 5, 1),
                        Date(2018, 6, 18),
                        Date(2018, 9, 24),
                        Date(2018, 10, 1),
                        Date(2018, 10, 2),
                        Date(2018, 10, 3),
                        Date(2018, 10, 4),
                        Date(2018, 10, 5)}

cdef set nyse_holidays = {
    Date(1900, 1, 1), Date(1900, 2, 12), Date(1900, 2, 22),
    Date(1900, 4, 13), Date(1900, 5, 30), Date(1900, 7, 4),
    Date(1900, 9, 3), Date(1900, 10, 12), Date(1900, 11, 6),
    Date(1900, 11, 29), Date(1900, 12, 25), Date(1901, 1, 1),
    Date(1901, 2, 12), Date(1901, 2, 22), Date(1901, 4, 5),
    Date(1901, 5, 30), Date(1901, 7, 4), Date(1901, 9, 2),
    Date(1901, 10, 12), Date(1901, 11, 5), Date(1901, 11, 28),
    Date(1901, 12, 25), Date(1902, 1, 1), Date(1902, 2, 12),
    Date(1902, 2, 22), Date(1902, 3, 28), Date(1902, 5, 30),
    Date(1902, 7, 4), Date(1902, 9, 1), Date(1902, 10, 13),
    Date(1902, 11, 4), Date(1902, 11, 27), Date(1902, 12, 25),
    Date(1903, 1, 1), Date(1903, 2, 12), Date(1903, 2, 23),
    Date(1903, 4, 10), Date(1903, 5, 30), Date(1903, 7, 4),
    Date(1903, 9, 7), Date(1903, 10, 12), Date(1903, 11, 3),
    Date(1903, 11, 26), Date(1903, 12, 25), Date(1904, 1, 1),
    Date(1904, 2, 12), Date(1904, 2, 22), Date(1904, 4, 1),
    Date(1904, 5, 30), Date(1904, 7, 4), Date(1904, 9, 5),
    Date(1904, 10, 12), Date(1904, 11, 8), Date(1904, 11, 24),
    Date(1904, 12, 26), Date(1905, 1, 2), Date(1905, 2, 13),
    Date(1905, 2, 22), Date(1905, 4, 21), Date(1905, 5, 30),
    Date(1905, 7, 4), Date(1905, 9, 4), Date(1905, 10, 12),
    Date(1905, 11, 7), Date(1905, 11, 30), Date(1905, 12, 25),
    Date(1906, 1, 1), Date(1906, 2, 12), Date(1906, 2, 22),
    Date(1906, 4, 13), Date(1906, 5, 30), Date(1906, 7, 4),
    Date(1906, 9, 3), Date(1906, 10, 12), Date(1906, 11, 6),
    Date(1906, 11, 29), Date(1906, 12, 25), Date(1907, 1, 1),
    Date(1907, 2, 12), Date(1907, 2, 22), Date(1907, 3, 29),
    Date(1907, 5, 30), Date(1907, 7, 4), Date(1907, 9, 2),
    Date(1907, 10, 12), Date(1907, 11, 5), Date(1907, 11, 28),
    Date(1907, 12, 25), Date(1908, 1, 1), Date(1908, 2, 12),
    Date(1908, 2, 22), Date(1908, 4, 17), Date(1908, 5, 30),
    Date(1908, 7, 4), Date(1908, 9, 7), Date(1908, 10, 12),
    Date(1908, 11, 3), Date(1908, 11, 26), Date(1908, 12, 25),
    Date(1909, 1, 1), Date(1909, 2, 12), Date(1909, 2, 22),
    Date(1909, 4, 9), Date(1909, 5, 31), Date(1909, 7, 5),
    Date(1909, 9, 6), Date(1909, 10, 12), Date(1909, 11, 2),
    Date(1909, 11, 25), Date(1909, 12, 25), Date(1910, 1, 1),
    Date(1910, 2, 12), Date(1910, 2, 22), Date(1910, 3, 25),
    Date(1910, 5, 30), Date(1910, 7, 4), Date(1910, 9, 5),
    Date(1910, 10, 12), Date(1910, 11, 8), Date(1910, 11, 24),
    Date(1910, 12, 26), Date(1911, 1, 2), Date(1911, 2, 13),
    Date(1911, 2, 22), Date(1911, 4, 14), Date(1911, 5, 30),
    Date(1911, 7, 4), Date(1911, 9, 4), Date(1911, 10, 12),
    Date(1911, 11, 7), Date(1911, 11, 30), Date(1911, 12, 25),
    Date(1912, 1, 1), Date(1912, 2, 12), Date(1912, 2, 22),
    Date(1912, 4, 5), Date(1912, 5, 30), Date(1912, 7, 4),
    Date(1912, 9, 2), Date(1912, 10, 12), Date(1912, 11, 5),
    Date(1912, 11, 28), Date(1912, 12, 25), Date(1913, 1, 1),
    Date(1913, 2, 12), Date(1913, 2, 22), Date(1913, 3, 21),
    Date(1913, 5, 30), Date(1913, 7, 4), Date(1913, 9, 1),
    Date(1913, 10, 13), Date(1913, 11, 4), Date(1913, 11, 27),
    Date(1913, 12, 25), Date(1914, 1, 1), Date(1914, 2, 12),
    Date(1914, 2, 23), Date(1914, 4, 10), Date(1914, 5, 30),
    Date(1914, 7, 4), Date(1914, 9, 7), Date(1914, 10, 12),
    Date(1914, 11, 3), Date(1914, 11, 26), Date(1914, 12, 25),
    Date(1915, 1, 1), Date(1915, 2, 12), Date(1915, 2, 22),
    Date(1915, 4, 2), Date(1915, 5, 31), Date(1915, 7, 5),
    Date(1915, 9, 6), Date(1915, 10, 12), Date(1915, 11, 2),
    Date(1915, 11, 25), Date(1915, 12, 25), Date(1916, 1, 1),
    Date(1916, 2, 12), Date(1916, 2, 22), Date(1916, 4, 21),
    Date(1916, 5, 30), Date(1916, 7, 4), Date(1916, 9, 4),
    Date(1916, 10, 12), Date(1916, 11, 7), Date(1916, 11, 30),
    Date(1916, 12, 25), Date(1917, 1, 1), Date(1917, 2, 12),
    Date(1917, 2, 22), Date(1917, 4, 6), Date(1917, 5, 30),
    Date(1917, 7, 4), Date(1917, 9, 3), Date(1917, 10, 12),
    Date(1917, 11, 6), Date(1917, 11, 29), Date(1917, 12, 25),
    Date(1918, 1, 1), Date(1918, 2, 12), Date(1918, 2, 22),
    Date(1918, 3, 29), Date(1918, 5, 30), Date(1918, 7, 4),
    Date(1918, 9, 2), Date(1918, 10, 12), Date(1918, 11, 5),
    Date(1918, 11, 28), Date(1918, 12, 25), Date(1919, 1, 1),
    Date(1919, 2, 12), Date(1919, 2, 22), Date(1919, 4, 18),
    Date(1919, 5, 30), Date(1919, 7, 4), Date(1919, 9, 1),
    Date(1919, 10, 13), Date(1919, 11, 4), Date(1919, 11, 27),
    Date(1919, 12, 25), Date(1920, 1, 1), Date(1920, 2, 12),
    Date(1920, 2, 23), Date(1920, 4, 2), Date(1920, 5, 31),
    Date(1920, 7, 5), Date(1920, 9, 6), Date(1920, 10, 12),
    Date(1920, 11, 2), Date(1920, 11, 25), Date(1920, 12, 25),
    Date(1921, 1, 1), Date(1921, 2, 12), Date(1921, 2, 22),
    Date(1921, 3, 25), Date(1921, 5, 30), Date(1921, 7, 4),
    Date(1921, 9, 5), Date(1921, 10, 12), Date(1921, 11, 8),
    Date(1921, 11, 24), Date(1921, 12, 26), Date(1922, 1, 2),
    Date(1922, 2, 13), Date(1922, 2, 22), Date(1922, 4, 14),
    Date(1922, 5, 30), Date(1922, 7, 4), Date(1922, 9, 4),
    Date(1922, 10, 12), Date(1922, 11, 7), Date(1922, 11, 30),
    Date(1922, 12, 25), Date(1923, 1, 1), Date(1923, 2, 12),
    Date(1923, 2, 22), Date(1923, 3, 30), Date(1923, 5, 30),
    Date(1923, 7, 4), Date(1923, 9, 3), Date(1923, 10, 12),
    Date(1923, 11, 6), Date(1923, 11, 29), Date(1923, 12, 25),
    Date(1924, 1, 1), Date(1924, 2, 12), Date(1924, 2, 22),
    Date(1924, 4, 18), Date(1924, 5, 30), Date(1924, 7, 4),
    Date(1924, 9, 1), Date(1924, 10, 13), Date(1924, 11, 4),
    Date(1924, 11, 27), Date(1924, 12, 25), Date(1925, 1, 1),
    Date(1925, 2, 12), Date(1925, 2, 23), Date(1925, 4, 10),
    Date(1925, 5, 30), Date(1925, 7, 4), Date(1925, 9, 7),
    Date(1925, 10, 12), Date(1925, 11, 3), Date(1925, 11, 26),
    Date(1925, 12, 25), Date(1926, 1, 1), Date(1926, 2, 12),
    Date(1926, 2, 22), Date(1926, 4, 2), Date(1926, 5, 31),
    Date(1926, 7, 5), Date(1926, 9, 6), Date(1926, 10, 12),
    Date(1926, 11, 2), Date(1926, 11, 25), Date(1926, 12, 25),
    Date(1927, 1, 1), Date(1927, 2, 12), Date(1927, 2, 22),
    Date(1927, 4, 15), Date(1927, 5, 30), Date(1927, 7, 4),
    Date(1927, 9, 5), Date(1927, 10, 12), Date(1927, 11, 8),
    Date(1927, 11, 24), Date(1927, 12, 26), Date(1928, 1, 2),
    Date(1928, 2, 13), Date(1928, 2, 22), Date(1928, 4, 6),
    Date(1928, 5, 30), Date(1928, 7, 4), Date(1928, 9, 3),
    Date(1928, 10, 12), Date(1928, 11, 6), Date(1928, 11, 29),
    Date(1928, 12, 25), Date(1929, 1, 1), Date(1929, 2, 12),
    Date(1929, 2, 22), Date(1929, 3, 29), Date(1929, 5, 30),
    Date(1929, 7, 4), Date(1929, 9, 2), Date(1929, 10, 12),
    Date(1929, 11, 1), Date(1929, 11, 5), Date(1929, 11, 28),
    Date(1929, 11, 29), Date(1929, 12, 25), Date(1930, 1, 1),
    Date(1930, 2, 12), Date(1930, 2, 22), Date(1930, 4, 18),
    Date(1930, 5, 30), Date(1930, 7, 4), Date(1930, 9, 1),
    Date(1930, 10, 13), Date(1930, 11, 4), Date(1930, 11, 27),
    Date(1930, 12, 25), Date(1931, 1, 1), Date(1931, 2, 12),
    Date(1931, 2, 23), Date(1931, 4, 3), Date(1931, 5, 30),
    Date(1931, 7, 4), Date(1931, 9, 7), Date(1931, 10, 12),
    Date(1931, 11, 3), Date(1931, 11, 26), Date(1931, 12, 25),
    Date(1932, 1, 1), Date(1932, 2, 12), Date(1932, 2, 22),
    Date(1932, 3, 25), Date(1932, 5, 30), Date(1932, 7, 4),
    Date(1932, 9, 5), Date(1932, 10, 12), Date(1932, 11, 8),
    Date(1932, 11, 24), Date(1932, 12, 26), Date(1933, 1, 2),
    Date(1933, 2, 13), Date(1933, 2, 22), Date(1933, 3, 6),
    Date(1933, 3, 7), Date(1933, 3, 8), Date(1933, 3, 9),
    Date(1933, 3, 10), Date(1933, 3, 11), Date(1933, 3, 12),
    Date(1933, 3, 13), Date(1933, 3, 14), Date(1933, 4, 14),
    Date(1933, 5, 30), Date(1933, 7, 4), Date(1933, 9, 4),
    Date(1933, 10, 12), Date(1933, 11, 7), Date(1933, 11, 30),
    Date(1933, 12, 25), Date(1934, 1, 1), Date(1934, 2, 12),
    Date(1934, 2, 22), Date(1934, 3, 30), Date(1934, 5, 30),
    Date(1934, 7, 4), Date(1934, 9, 3), Date(1934, 10, 12),
    Date(1934, 11, 6), Date(1934, 11, 12), Date(1934, 11, 29),
    Date(1934, 12, 25), Date(1935, 1, 1), Date(1935, 2, 12),
    Date(1935, 2, 22), Date(1935, 4, 19), Date(1935, 5, 30),
    Date(1935, 7, 4), Date(1935, 9, 2), Date(1935, 10, 12),
    Date(1935, 11, 5), Date(1935, 11, 11), Date(1935, 11, 28),
    Date(1935, 12, 25), Date(1936, 1, 1), Date(1936, 2, 12),
    Date(1936, 2, 22), Date(1936, 4, 10), Date(1936, 5, 30),
    Date(1936, 7, 4), Date(1936, 9, 7), Date(1936, 10, 12),
    Date(1936, 11, 3), Date(1936, 11, 11), Date(1936, 11, 26),
    Date(1936, 12, 25), Date(1937, 1, 1), Date(1937, 2, 12),
    Date(1937, 2, 22), Date(1937, 3, 26), Date(1937, 5, 31),
    Date(1937, 7, 5), Date(1937, 9, 6), Date(1937, 10, 12),
    Date(1937, 11, 2), Date(1937, 11, 11), Date(1937, 11, 25),
    Date(1937, 12, 25), Date(1938, 1, 1), Date(1938, 2, 12),
    Date(1938, 2, 22), Date(1938, 4, 15), Date(1938, 5, 30),
    Date(1938, 7, 4), Date(1938, 9, 5), Date(1938, 10, 12),
    Date(1938, 11, 8), Date(1938, 11, 11), Date(1938, 11, 24),
    Date(1938, 12, 26), Date(1939, 1, 2), Date(1939, 2, 13),
    Date(1939, 2, 22), Date(1939, 4, 7), Date(1939, 5, 30),
    Date(1939, 7, 4), Date(1939, 9, 4), Date(1939, 10, 12),
    Date(1939, 11, 7), Date(1939, 11, 11), Date(1939, 11, 23),
    Date(1939, 12, 25), Date(1940, 1, 1), Date(1940, 2, 12),
    Date(1940, 2, 22), Date(1940, 3, 22), Date(1940, 5, 30),
    Date(1940, 7, 4), Date(1940, 9, 2), Date(1940, 10, 12),
    Date(1940, 11, 5), Date(1940, 11, 11), Date(1940, 11, 21),
    Date(1940, 12, 25), Date(1941, 1, 1), Date(1941, 2, 12),
    Date(1941, 2, 22), Date(1941, 4, 11), Date(1941, 5, 30),
    Date(1941, 7, 4), Date(1941, 9, 1), Date(1941, 10, 13),
    Date(1941, 11, 4), Date(1941, 11, 11), Date(1941, 11, 20),
    Date(1941, 12, 25), Date(1942, 1, 1), Date(1942, 2, 12),
    Date(1942, 2, 23), Date(1942, 4, 3), Date(1942, 5, 30),
    Date(1942, 7, 4), Date(1942, 9, 7), Date(1942, 10, 12),
    Date(1942, 11, 3), Date(1942, 11, 11), Date(1942, 11, 26),
    Date(1942, 12, 25), Date(1943, 1, 1), Date(1943, 2, 12),
    Date(1943, 2, 22), Date(1943, 4, 23), Date(1943, 5, 31),
    Date(1943, 7, 5), Date(1943, 9, 6), Date(1943, 10, 12),
    Date(1943, 11, 2), Date(1943, 11, 11), Date(1943, 11, 25),
    Date(1943, 12, 25), Date(1944, 1, 1), Date(1944, 2, 12),
    Date(1944, 2, 22), Date(1944, 4, 7), Date(1944, 5, 30),
    Date(1944, 7, 4), Date(1944, 9, 4), Date(1944, 10, 12),
    Date(1944, 11, 7), Date(1944, 11, 11), Date(1944, 11, 23),
    Date(1944, 12, 25), Date(1945, 1, 1), Date(1945, 2, 12),
    Date(1945, 2, 22), Date(1945, 3, 30), Date(1945, 5, 30),
    Date(1945, 7, 4), Date(1945, 8, 15), Date(1945, 8, 16),
    Date(1945, 9, 3), Date(1945, 10, 12), Date(1945, 11, 6),
    Date(1945, 11, 12), Date(1945, 11, 22), Date(1945, 12, 24),
    Date(1945, 12, 25), Date(1946, 1, 1), Date(1946, 2, 12),
    Date(1946, 2, 22), Date(1946, 4, 19), Date(1946, 5, 30),
    Date(1946, 7, 4), Date(1946, 9, 2), Date(1946, 10, 12),
    Date(1946, 11, 5), Date(1946, 11, 11), Date(1946, 11, 28),
    Date(1946, 12, 25), Date(1947, 1, 1), Date(1947, 2, 12),
    Date(1947, 2, 22), Date(1947, 4, 4), Date(1947, 5, 30),
    Date(1947, 7, 4), Date(1947, 9, 1), Date(1947, 10, 13),
    Date(1947, 11, 4), Date(1947, 11, 11), Date(1947, 11, 27),
    Date(1947, 12, 25), Date(1948, 1, 1), Date(1948, 2, 12),
    Date(1948, 2, 23), Date(1948, 3, 26), Date(1948, 5, 31),
    Date(1948, 7, 5), Date(1948, 9, 6), Date(1948, 10, 12),
    Date(1948, 11, 2), Date(1948, 11, 11), Date(1948, 11, 25),
    Date(1948, 12, 25), Date(1949, 1, 1), Date(1949, 2, 12),
    Date(1949, 2, 22), Date(1949, 4, 15), Date(1949, 5, 30),
    Date(1949, 7, 4), Date(1949, 9, 5), Date(1949, 10, 12),
    Date(1949, 11, 8), Date(1949, 11, 11), Date(1949, 11, 24),
    Date(1949, 12, 26), Date(1950, 1, 2), Date(1950, 2, 13),
    Date(1950, 2, 22), Date(1950, 4, 7), Date(1950, 5, 30),
    Date(1950, 7, 4), Date(1950, 9, 4), Date(1950, 10, 12),
    Date(1950, 11, 7), Date(1950, 11, 11), Date(1950, 11, 23),
    Date(1950, 12, 25), Date(1951, 1, 1), Date(1951, 2, 12),
    Date(1951, 2, 22), Date(1951, 3, 23), Date(1951, 5, 30),
    Date(1951, 7, 4), Date(1951, 9, 3), Date(1951, 10, 12),
    Date(1951, 11, 6), Date(1951, 11, 12), Date(1951, 11, 22),
    Date(1951, 12, 25), Date(1952, 1, 1), Date(1952, 2, 12),
    Date(1952, 2, 22), Date(1952, 4, 11), Date(1952, 5, 30),
    Date(1952, 7, 4), Date(1952, 9, 1), Date(1952, 10, 13),
    Date(1952, 11, 4), Date(1952, 11, 11), Date(1952, 11, 27),
    Date(1952, 12, 25), Date(1953, 1, 1), Date(1953, 2, 12),
    Date(1953, 2, 23), Date(1953, 4, 3), Date(1953, 5, 30),
    Date(1953, 7, 4), Date(1953, 9, 7), Date(1953, 10, 12),
    Date(1953, 11, 3), Date(1953, 11, 11), Date(1953, 11, 26),
    Date(1953, 12, 25), Date(1954, 1, 1), Date(1954, 2, 22),
    Date(1954, 4, 16), Date(1954, 5, 31), Date(1954, 7, 5),
    Date(1954, 9, 6), Date(1954, 11, 2), Date(1954, 11, 25),
    Date(1954, 12, 24), Date(1955, 1, 1), Date(1955, 2, 22),
    Date(1955, 4, 8), Date(1955, 5, 30), Date(1955, 7, 4),
    Date(1955, 9, 5), Date(1955, 11, 8), Date(1955, 11, 24),
    Date(1955, 12, 26), Date(1956, 1, 2), Date(1956, 2, 22),
    Date(1956, 3, 30), Date(1956, 5, 30), Date(1956, 7, 4),
    Date(1956, 9, 3), Date(1956, 11, 6), Date(1956, 11, 22),
    Date(1956, 12, 24), Date(1956, 12, 25), Date(1957, 1, 1),
    Date(1957, 2, 22), Date(1957, 4, 19), Date(1957, 5, 30),
    Date(1957, 7, 4), Date(1957, 9, 2), Date(1957, 11, 5),
    Date(1957, 11, 28), Date(1957, 12, 25), Date(1958, 1, 1),
    Date(1958, 2, 22), Date(1958, 4, 4), Date(1958, 5, 30),
    Date(1958, 7, 4), Date(1958, 9, 1), Date(1958, 11, 4),
    Date(1958, 11, 27), Date(1958, 12, 25), Date(1958, 12, 26),
    Date(1959, 1, 1), Date(1959, 2, 23), Date(1959, 3, 27),
    Date(1959, 5, 30), Date(1959, 7, 3), Date(1959, 9, 7),
    Date(1959, 11, 3), Date(1959, 11, 26), Date(1959, 12, 25),
    Date(1960, 1, 1), Date(1960, 2, 22), Date(1960, 4, 15),
    Date(1960, 5, 30), Date(1960, 7, 4), Date(1960, 9, 5),
    Date(1960, 11, 8), Date(1960, 11, 24), Date(1960, 12, 26),
    Date(1961, 1, 2), Date(1961, 2, 22), Date(1961, 3, 31),
    Date(1961, 5, 29), Date(1961, 5, 30), Date(1961, 7, 4),
    Date(1961, 9, 4), Date(1961, 11, 7), Date(1961, 11, 23),
    Date(1961, 12, 25), Date(1962, 1, 1), Date(1962, 2, 22),
    Date(1962, 4, 20), Date(1962, 5, 30), Date(1962, 7, 4),
    Date(1962, 9, 3), Date(1962, 11, 6), Date(1962, 11, 22),
    Date(1962, 12, 25), Date(1963, 1, 1), Date(1963, 2, 22),
    Date(1963, 4, 12), Date(1963, 5, 30), Date(1963, 7, 4),
    Date(1963, 9, 2), Date(1963, 11, 5), Date(1963, 11, 25),
    Date(1963, 11, 28), Date(1963, 12, 25), Date(1964, 1, 1),
    Date(1964, 2, 21), Date(1964, 3, 27), Date(1964, 5, 29),
    Date(1964, 7, 3), Date(1964, 9, 7), Date(1964, 11, 3),
    Date(1964, 11, 26), Date(1964, 12, 25), Date(1965, 1, 1),
    Date(1965, 2, 22), Date(1965, 4, 16), Date(1965, 5, 31),
    Date(1965, 7, 5), Date(1965, 9, 6), Date(1965, 11, 2),
    Date(1965, 11, 25), Date(1965, 12, 24), Date(1966, 1, 1),
    Date(1966, 2, 22), Date(1966, 4, 8), Date(1966, 5, 30),
    Date(1966, 7, 4), Date(1966, 9, 5), Date(1966, 11, 8),
    Date(1966, 11, 24), Date(1966, 12, 26), Date(1967, 1, 2),
    Date(1967, 2, 22), Date(1967, 3, 24), Date(1967, 5, 30),
    Date(1967, 7, 4), Date(1967, 9, 4), Date(1967, 11, 7),
    Date(1967, 11, 23), Date(1967, 12, 25), Date(1968, 1, 1),
    Date(1968, 2, 12), Date(1968, 2, 22), Date(1968, 4, 9),
    Date(1968, 4, 12), Date(1968, 5, 30), Date(1968, 6, 12),
    Date(1968, 6, 19), Date(1968, 6, 26), Date(1968, 7, 4),
    Date(1968, 7, 5), Date(1968, 7, 10), Date(1968, 7, 17),
    Date(1968, 7, 24), Date(1968, 7, 31), Date(1968, 8, 7),
    Date(1968, 8, 14), Date(1968, 8, 21), Date(1968, 8, 28),
    Date(1968, 9, 2), Date(1968, 9, 11), Date(1968, 9, 18),
    Date(1968, 9, 25), Date(1968, 10, 2), Date(1968, 10, 9),
    Date(1968, 10, 16), Date(1968, 10, 23), Date(1968, 10, 30),
    Date(1968, 11, 5), Date(1968, 11, 5), Date(1968, 11, 11),
    Date(1968, 11, 20), Date(1968, 11, 28), Date(1968, 12, 4),
    Date(1968, 12, 11), Date(1968, 12, 18), Date(1968, 12, 25),
    Date(1968, 12, 25), Date(1969, 1, 1), Date(1969, 2, 10),
    Date(1969, 2, 21), Date(1969, 3, 31), Date(1969, 4, 4),
    Date(1969, 5, 30), Date(1969, 7, 4), Date(1969, 7, 21),
    Date(1969, 9, 1), Date(1969, 11, 27), Date(1969, 12, 25),
    Date(1970, 1, 1), Date(1970, 2, 23), Date(1970, 3, 27),
    Date(1970, 7, 3), Date(1970, 9, 7), Date(1970, 11, 26),
    Date(1970, 12, 25), Date(1971, 1, 1), Date(1971, 2, 15),
    Date(1971, 4, 9), Date(1971, 5, 31), Date(1971, 7, 5),
    Date(1971, 9, 6), Date(1971, 11, 25), Date(1971, 12, 24),
    Date(1972, 1, 1), Date(1972, 2, 21), Date(1972, 3, 31),
    Date(1972, 5, 29), Date(1972, 7, 4), Date(1972, 9, 4),
    Date(1972, 11, 7), Date(1972, 11, 7), Date(1972, 11, 7),
    Date(1972, 11, 7), Date(1972, 11, 23), Date(1972, 12, 25),
    Date(1972, 12, 28), Date(1973, 1, 1), Date(1973, 1, 25),
    Date(1973, 2, 19), Date(1973, 4, 20), Date(1973, 5, 28),
    Date(1973, 7, 4), Date(1973, 9, 3), Date(1973, 11, 22),
    Date(1973, 12, 25), Date(1974, 1, 1), Date(1974, 2, 18),
    Date(1974, 4, 12), Date(1974, 5, 27), Date(1974, 7, 4),
    Date(1974, 9, 2), Date(1974, 11, 28), Date(1974, 12, 25),
    Date(1975, 1, 1), Date(1975, 2, 17), Date(1975, 3, 28),
    Date(1975, 5, 26), Date(1975, 7, 4), Date(1975, 9, 1),
    Date(1975, 11, 27), Date(1975, 12, 25), Date(1976, 1, 1),
    Date(1976, 2, 16), Date(1976, 4, 16), Date(1976, 5, 31),
    Date(1976, 7, 5), Date(1976, 9, 6), Date(1976, 11, 2),
    Date(1976, 11, 2), Date(1976, 11, 2), Date(1976, 11, 2),
    Date(1976, 11, 25), Date(1976, 12, 24), Date(1977, 1, 1),
    Date(1977, 2, 21), Date(1977, 4, 8), Date(1977, 5, 30),
    Date(1977, 7, 4), Date(1977, 7, 14), Date(1977, 9, 5),
    Date(1977, 11, 24), Date(1977, 12, 26), Date(1978, 1, 2),
    Date(1978, 2, 20), Date(1978, 3, 24), Date(1978, 5, 29),
    Date(1978, 7, 4), Date(1978, 9, 4), Date(1978, 11, 23),
    Date(1978, 12, 25), Date(1979, 1, 1), Date(1979, 2, 19),
    Date(1979, 4, 13), Date(1979, 5, 28), Date(1979, 7, 4),
    Date(1979, 9, 3), Date(1979, 11, 22), Date(1979, 12, 25),
    Date(1980, 1, 1), Date(1980, 2, 18), Date(1980, 4, 4),
    Date(1980, 5, 26), Date(1980, 7, 4), Date(1980, 9, 1),
    Date(1980, 11, 4), Date(1980, 11, 4), Date(1980, 11, 4),
    Date(1980, 11, 4), Date(1980, 11, 27), Date(1980, 12, 25),
    Date(1981, 1, 1), Date(1981, 2, 16), Date(1981, 4, 17),
    Date(1981, 5, 25), Date(1981, 7, 3), Date(1981, 9, 7),
    Date(1981, 11, 26), Date(1981, 12, 25), Date(1982, 1, 1),
    Date(1982, 2, 15), Date(1982, 4, 9), Date(1982, 5, 31),
    Date(1982, 7, 5), Date(1982, 9, 6), Date(1982, 11, 25),
    Date(1982, 12, 24), Date(1983, 1, 1), Date(1983, 2, 21),
    Date(1983, 4, 1), Date(1983, 5, 30), Date(1983, 7, 4),
    Date(1983, 9, 5), Date(1983, 11, 24), Date(1983, 12, 26),
    Date(1984, 1, 2), Date(1984, 2, 20), Date(1984, 4, 20),
    Date(1984, 5, 28), Date(1984, 7, 4), Date(1984, 9, 3),
    Date(1984, 11, 22), Date(1984, 12, 25), Date(1985, 1, 1),
    Date(1985, 2, 18), Date(1985, 4, 5), Date(1985, 5, 27),
    Date(1985, 7, 4), Date(1985, 9, 2), Date(1985, 9, 27),
    Date(1985, 11, 28), Date(1985, 12, 25), Date(1986, 1, 1),
    Date(1986, 2, 17), Date(1986, 3, 28), Date(1986, 5, 26),
    Date(1986, 7, 4), Date(1986, 9, 1), Date(1986, 11, 27),
    Date(1986, 12, 25), Date(1987, 1, 1), Date(1987, 2, 16),
    Date(1987, 4, 17), Date(1987, 5, 25), Date(1987, 7, 3),
    Date(1987, 9, 7), Date(1987, 11, 26), Date(1987, 12, 25),
    Date(1988, 1, 1), Date(1988, 2, 15), Date(1988, 4, 1),
    Date(1988, 5, 30), Date(1988, 7, 4), Date(1988, 9, 5),
    Date(1988, 11, 24), Date(1988, 12, 26), Date(1989, 1, 2),
    Date(1989, 2, 20), Date(1989, 3, 24), Date(1989, 5, 29),
    Date(1989, 7, 4), Date(1989, 9, 4), Date(1989, 11, 23),
    Date(1989, 12, 25), Date(1990, 1, 1), Date(1990, 2, 19),
    Date(1990, 4, 13), Date(1990, 5, 28), Date(1990, 7, 4),
    Date(1990, 9, 3), Date(1990, 11, 22), Date(1990, 12, 25),
    Date(1991, 1, 1), Date(1991, 2, 18), Date(1991, 3, 29),
    Date(1991, 5, 27), Date(1991, 7, 4), Date(1991, 9, 2),
    Date(1991, 11, 28), Date(1991, 12, 25), Date(1992, 1, 1),
    Date(1992, 2, 17), Date(1992, 4, 17), Date(1992, 5, 25),
    Date(1992, 7, 3), Date(1992, 9, 7), Date(1992, 11, 26),
    Date(1992, 12, 25), Date(1993, 1, 1), Date(1993, 2, 15),
    Date(1993, 4, 9), Date(1993, 5, 31), Date(1993, 7, 5),
    Date(1993, 9, 6), Date(1993, 11, 25), Date(1993, 12, 24),
    Date(1994, 1, 1), Date(1994, 2, 21), Date(1994, 4, 1),
    Date(1994, 4, 27), Date(1994, 5, 30), Date(1994, 7, 4),
    Date(1994, 9, 5), Date(1994, 11, 24), Date(1994, 12, 26),
    Date(1995, 1, 2), Date(1995, 2, 20), Date(1995, 4, 14),
    Date(1995, 5, 29), Date(1995, 7, 4), Date(1995, 9, 4),
    Date(1995, 11, 23), Date(1995, 12, 25), Date(1996, 1, 1),
    Date(1996, 2, 19), Date(1996, 4, 5), Date(1996, 5, 27),
    Date(1996, 7, 4), Date(1996, 9, 2), Date(1996, 11, 28),
    Date(1996, 12, 25), Date(1997, 1, 1), Date(1997, 2, 17),
    Date(1997, 3, 28), Date(1997, 5, 26), Date(1997, 7, 4),
    Date(1997, 9, 1), Date(1997, 11, 27), Date(1997, 12, 25),
    Date(1998, 1, 1), Date(1998, 1, 19), Date(1998, 2, 16),
    Date(1998, 4, 10), Date(1998, 5, 25), Date(1998, 7, 3),
    Date(1998, 9, 7), Date(1998, 11, 26), Date(1998, 12, 25),
    Date(1999, 1, 1), Date(1999, 1, 18), Date(1999, 2, 15),
    Date(1999, 4, 2), Date(1999, 5, 31), Date(1999, 7, 5),
    Date(1999, 9, 6), Date(1999, 11, 25), Date(1999, 12, 24),
    Date(2000, 1, 1), Date(2000, 1, 17), Date(2000, 2, 21),
    Date(2000, 4, 21), Date(2000, 5, 29), Date(2000, 7, 4),
    Date(2000, 9, 4), Date(2000, 11, 23), Date(2000, 12, 25),
    Date(2001, 1, 1), Date(2001, 1, 15), Date(2001, 2, 19),
    Date(2001, 4, 13), Date(2001, 5, 28), Date(2001, 7, 4),
    Date(2001, 9, 3), Date(2001, 9, 11), Date(2001, 9, 12),
    Date(2001, 9, 13), Date(2001, 9, 14), Date(2001, 9, 15),
    Date(2001, 9, 16), Date(2001, 11, 22), Date(2001, 12, 25),
    Date(2002, 1, 1), Date(2002, 1, 21), Date(2002, 2, 18),
    Date(2002, 3, 29), Date(2002, 5, 27), Date(2002, 7, 4),
    Date(2002, 9, 2), Date(2002, 11, 28), Date(2002, 12, 25),
    Date(2003, 1, 1), Date(2003, 1, 20), Date(2003, 2, 17),
    Date(2003, 4, 18), Date(2003, 5, 26), Date(2003, 7, 4),
    Date(2003, 9, 1), Date(2003, 11, 27), Date(2003, 12, 25),
    Date(2004, 1, 1), Date(2004, 1, 19), Date(2004, 2, 16),
    Date(2004, 4, 9), Date(2004, 5, 31), Date(2004, 6, 11),
    Date(2004, 7, 5), Date(2004, 9, 6), Date(2004, 11, 25),
    Date(2004, 12, 24), Date(2005, 1, 1), Date(2005, 1, 17),
    Date(2005, 2, 21), Date(2005, 3, 25), Date(2005, 5, 30),
    Date(2005, 7, 4), Date(2005, 9, 5), Date(2005, 11, 24),
    Date(2005, 12, 26), Date(2006, 1, 2), Date(2006, 1, 16),
    Date(2006, 2, 20), Date(2006, 4, 14), Date(2006, 5, 29),
    Date(2006, 7, 4), Date(2006, 9, 4), Date(2006, 11, 23),
    Date(2006, 12, 25), Date(2007, 1, 1), Date(2007, 1, 2),
    Date(2007, 1, 15), Date(2007, 2, 19), Date(2007, 4, 6),
    Date(2007, 5, 28), Date(2007, 7, 4), Date(2007, 9, 3),
    Date(2007, 11, 22), Date(2007, 12, 25), Date(2008, 1, 1),
    Date(2008, 1, 21), Date(2008, 2, 18), Date(2008, 3, 21),
    Date(2008, 5, 26), Date(2008, 7, 4), Date(2008, 9, 1),
    Date(2008, 11, 27), Date(2008, 12, 25), Date(2009, 1, 1),
    Date(2009, 1, 19), Date(2009, 2, 16), Date(2009, 4, 10),
    Date(2009, 5, 25), Date(2009, 7, 3), Date(2009, 9, 7),
    Date(2009, 11, 26), Date(2009, 12, 25), Date(2010, 1, 1),
    Date(2010, 1, 18), Date(2010, 2, 15), Date(2010, 4, 2),
    Date(2010, 5, 31), Date(2010, 7, 5), Date(2010, 9, 6),
    Date(2010, 11, 25), Date(2010, 12, 24), Date(2011, 1, 1),
    Date(2011, 1, 17), Date(2011, 2, 21), Date(2011, 4, 22),
    Date(2011, 5, 30), Date(2011, 7, 4), Date(2011, 9, 5),
    Date(2011, 11, 24), Date(2011, 12, 26), Date(2012, 1, 2),
    Date(2012, 1, 16), Date(2012, 2, 20), Date(2012, 4, 6),
    Date(2012, 5, 28), Date(2012, 7, 4), Date(2012, 9, 3),
    Date(2012, 10, 29), Date(2012, 10, 30), Date(2012, 11, 22),
    Date(2012, 12, 25), Date(2013, 1, 1), Date(2013, 1, 21),
    Date(2013, 2, 18), Date(2013, 3, 29), Date(2013, 5, 27),
    Date(2013, 7, 4), Date(2013, 9, 2), Date(2013, 11, 28),
    Date(2013, 12, 25), Date(2014, 1, 1), Date(2014, 1, 20),
    Date(2014, 2, 17), Date(2014, 4, 18), Date(2014, 5, 26),
    Date(2014, 7, 4), Date(2014, 9, 1), Date(2014, 11, 27),
    Date(2014, 12, 25), Date(2015, 1, 1), Date(2015, 1, 19),
    Date(2015, 2, 16), Date(2015, 4, 3), Date(2015, 5, 25),
    Date(2015, 7, 3), Date(2015, 9, 7), Date(2015, 11, 26),
    Date(2015, 12, 25), Date(2016, 1, 1), Date(2016, 1, 18),
    Date(2016, 2, 15), Date(2016, 3, 25), Date(2016, 5, 30),
    Date(2016, 7, 4), Date(2016, 9, 5), Date(2016, 11, 24),
    Date(2016, 12, 26), Date(2017, 1, 2), Date(2017, 1, 16),
    Date(2017, 2, 20), Date(2017, 4, 14), Date(2017, 5, 29),
    Date(2017, 7, 4), Date(2017, 9, 4), Date(2017, 11, 23),
    Date(2017, 12, 25), Date(2018, 1, 1), Date(2018, 1, 15),
    Date(2018, 2, 19), Date(2018, 3, 30), Date(2018, 5, 28),
    Date(2018, 7, 4), Date(2018, 9, 3), Date(2018, 11, 22),
    Date(2018, 12, 25), Date(2019, 1, 1), Date(2019, 1, 21),
    Date(2019, 2, 18), Date(2019, 4, 19), Date(2019, 5, 27),
    Date(2019, 7, 4), Date(2019, 9, 2), Date(2019, 11, 28),
    Date(2019, 12, 25), Date(2020, 1, 1), Date(2020, 1, 20),
    Date(2020, 2, 17), Date(2020, 4, 10), Date(2020, 5, 25),
    Date(2020, 7, 3), Date(2020, 9, 7), Date(2020, 11, 26),
    Date(2020, 12, 25), Date(2021, 1, 1), Date(2021, 1, 18),
    Date(2021, 2, 15), Date(2021, 4, 2), Date(2021, 5, 31),
    Date(2021, 7, 5), Date(2021, 9, 6), Date(2021, 11, 25),
    Date(2021, 12, 24), Date(2022, 1, 1), Date(2022, 1, 17),
    Date(2022, 2, 21), Date(2022, 4, 15), Date(2022, 5, 30),
    Date(2022, 7, 4), Date(2022, 9, 5), Date(2022, 11, 24),
    Date(2022, 12, 26), Date(2023, 1, 2), Date(2023, 1, 16),
    Date(2023, 2, 20), Date(2023, 4, 7), Date(2023, 5, 29),
    Date(2023, 7, 4), Date(2023, 9, 4), Date(2023, 11, 23),
    Date(2023, 12, 25), Date(2024, 1, 1), Date(2024, 1, 15),
    Date(2024, 2, 19), Date(2024, 3, 29), Date(2024, 5, 27),
    Date(2024, 7, 4), Date(2024, 9, 2), Date(2024, 11, 28),
    Date(2024, 12, 25), Date(2025, 1, 1), Date(2025, 1, 20),
    Date(2025, 2, 17), Date(2025, 4, 18), Date(2025, 5, 26),
    Date(2025, 7, 4), Date(2025, 9, 1), Date(2025, 11, 27),
    Date(2025, 12, 25), Date(2026, 1, 1), Date(2026, 1, 19),
    Date(2026, 2, 16), Date(2026, 4, 3), Date(2026, 5, 25),
    Date(2026, 7, 3), Date(2026, 9, 7), Date(2026, 11, 26),
    Date(2026, 12, 25), Date(2027, 1, 1), Date(2027, 1, 18),
    Date(2027, 2, 15), Date(2027, 3, 26), Date(2027, 5, 31),
    Date(2027, 7, 5), Date(2027, 9, 6), Date(2027, 11, 25),
    Date(2027, 12, 24), Date(2028, 1, 1), Date(2028, 1, 17),
    Date(2028, 2, 21), Date(2028, 4, 14), Date(2028, 5, 29),
    Date(2028, 7, 4), Date(2028, 9, 4), Date(2028, 11, 23),
    Date(2028, 12, 25), Date(2029, 1, 1), Date(2029, 1, 15),
    Date(2029, 2, 19), Date(2029, 3, 30), Date(2029, 5, 28),
    Date(2029, 7, 4), Date(2029, 9, 3), Date(2029, 11, 22),
    Date(2029, 12, 25), Date(2030, 1, 1), Date(2030, 1, 21),
    Date(2030, 2, 18), Date(2030, 4, 19), Date(2030, 5, 27),
    Date(2030, 7, 4), Date(2030, 9, 2), Date(2030, 11, 28),
    Date(2030, 12, 25)}


cdef class ChinaSseImpl(CalendarImpl):
    def __init__(self):
        pass

    cdef bint isBizDay(self, Date date):
        cdef int w = date.weekday()
        if self.isWeekEnd(w) or date in sse_holDays:
            return False
        return True

    cdef bint isWeekEnd(self, int weekDay):
        return weekDay == Weekdays.Saturday or weekDay == Weekdays.Sunday

    def __richcmp__(self, right, int op):
        if op == 2:
            return isinstance(right, ChinaSseImpl)


cdef class NYSEImpl(CalendarImpl):
    def __init__(self):
        pass

    cdef bint isBizDay(self, Date date):
        cdef int w = date.weekday()
        if self.isWeekEnd(w) or date in nyse_holidays:
            return False
        return True

    cdef bint isWeekEnd(self, int weekDay):
        return weekDay == Weekdays.Saturday or weekDay == Weekdays.Sunday

    def __richcmp__(self, right, int op):
        if op == 2:
            return isinstance(right, NYSEImpl)


cdef set ib_working_weekends = {
    # 2005
    Date.western_style(5, Months.February, 2005),
    Date.western_style(6, Months.February, 2005),
    Date.western_style(30, Months.April, 2005),
    Date.western_style(8, Months.May, 2005),
    Date.western_style(8, Months.October, 2005),
    Date.western_style(9, Months.October, 2005),
    Date.western_style(31, Months.December, 2005),
    # 2006
    Date.western_style(28, Months.January, 2006),
    Date.western_style(29, Months.April, 2006),
    Date.western_style(30, Months.April, 2006),
    Date.western_style(30, Months.September, 2006),
    Date.western_style(30, Months.December, 2006),
    Date.western_style(31, Months.December, 2006),
    # 2007
    Date.western_style(17, Months.February, 2007),
    Date.western_style(25, Months.February, 2007),
    Date.western_style(28, Months.April, 2007),
    Date.western_style(29, Months.April, 2007),
    Date.western_style(29, Months.September, 2007),
    Date.western_style(30, Months.September, 2007),
    Date.western_style(29, Months.December, 2007),
    # 2008
    Date.western_style(2, Months.February, 2008),
    Date.western_style(3, Months.February, 2008),
    Date.western_style(4, Months.May, 2008),
    Date.western_style(27, Months.September, 2008),
    Date.western_style(28, Months.September, 2008),
    # 2009
    Date.western_style(4, Months.January, 2009),
    Date.western_style(24, Months.January, 2009),
    Date.western_style(1, Months.February, 2009),
    Date.western_style(31, Months.May, 2009),
    Date.western_style(27, Months.September, 2009),
    Date.western_style(10, Months.October, 2009),
    # 2010
    Date.western_style(20, Months.February, 2010),
    Date.western_style(21, Months.February, 2010),
    Date.western_style(12, Months.June, 2010),
    Date.western_style(13, Months.June, 2010),
    Date.western_style(19, Months.September, 2010),
    Date.western_style(25, Months.September, 2010),
    Date.western_style(26, Months.September, 2010),
    Date.western_style(9, Months.October, 2010),
    # 2011
    Date.western_style(30, Months.January, 2011),
    Date.western_style(12, Months.February, 2011),
    Date.western_style(2, Months.April, 2011),
    Date.western_style(8, Months.October, 2011),
    Date.western_style(9, Months.October, 2011),
    Date.western_style(31, Months.December, 2011),
    # 2012
    Date.western_style(21, Months.January, 2012),
    Date.western_style(29, Months.January, 2012),
    Date.western_style(31, Months.March, 2012),
    Date.western_style(1, Months.April, 2012),
    Date.western_style(28, Months.April, 2012),
    Date.western_style(29, Months.September, 2012),
    # 2013
    Date.western_style(5, Months.January, 2013),
    Date.western_style(6, Months.January, 2013),
    Date.western_style(16, Months.February, 2013),
    Date.western_style(17, Months.February, 2013),
    Date.western_style(7, Months.April, 2013),
    Date.western_style(27, Months.April, 2013),
    Date.western_style(28, Months.April, 2013),
    Date.western_style(8, Months.June, 2013),
    Date.western_style(9, Months.June, 2013),
    Date.western_style(22, Months.September, 2013),
    Date.western_style(29, Months.September, 2013),
    Date.western_style(12, Months.October, 2013),
    # 2014
    Date.western_style(26, Months.January, 2014),
    Date.western_style(8, Months.February, 2014),
    Date.western_style(4, Months.May, 2014),
    Date.western_style(28, Months.September, 2014),
    Date.western_style(11, Months.October, 2014),
    # 2015
    Date.western_style(4, Months.January, 2015),
    Date.western_style(15, Months.February, 2015),
    Date.western_style(28, Months.February, 2015),
    Date.western_style(6, Months.September, 2015),
    Date.western_style(10, Months.October, 2015),
    # 2016
    Date.western_style(6, Months.February, 2016),
    Date.western_style(14, Months.February, 2016),
    Date.western_style(12, Months.June, 2016),
    Date.western_style(18, Months.September, 2016),
    Date.western_style(8, Months.October, 2016),
    Date.western_style(9, Months.October, 2016),
    # 2017
    Date.western_style(22, Months.January, 2017),
    Date.western_style(4, Months.February, 2017),
    Date.western_style(1, Months.April, 2017),
    Date.western_style(27, Months.May, 2017),
    Date.western_style(30, Months.September, 2017),
    # 2018
    Date.western_style(11, Months.February, 2018),
    Date.western_style(24, Months.February, 2018),
    Date.western_style(8, Months.April, 2018),
    Date.western_style(28, Months.April, 2018),
    Date.western_style(29, Months.September, 2018),
    Date.western_style(30, Months.September, 2018),
}

cdef ChinaSseImpl _sseImpl = ChinaSseImpl()

cdef class ChinaIBImpl(CalendarImpl):
    def __init__(self):
        pass

    cpdef bint isBizDay(self, Date date):
        return _sseImpl.isBizDay(date) or date in ib_working_weekends

    cpdef bint isWeekEnd(self, int weekDay):
        return weekDay == Weekdays.Saturday or weekDay == Weekdays.Sunday

    def __richcmp__(self, right, int op):
        if op == 2:
            return isinstance(right, ChinaIBImpl)

cdef class NullCalendar(CalendarImpl):
    def __init__(self):
        pass

    cdef bint isBizDay(self, Date date):
        cdef int w = date.weekday()
        if self.isWeekEnd(w):
            return False
        return True

    cdef bint isWeekEnd(self, int weekDay):
        return weekDay == Weekdays.Saturday or weekDay == Weekdays.Sunday

    def __richcmp__(self, right, int op):
        if op == 2:
            return isinstance(right, NullCalendar)

cdef class ChinaCFFEXImpl(CalendarImpl):
    def __init__(self):
        pass

    cdef bint isBizDay(self, Date date):
        return _sseImpl.isBizDay(date)

    cdef bint isWeekEnd(self, int weekDay):
        return _sseImpl.isWeekEnd(weekDay)

    def __richcmp__(self, right, int op):
        if op == 2:
            return isinstance(right, ChinaCFFEXImpl)

cdef int EasterMonday[299]
EasterMonday[:] = [
    98, 90, 103, 95, 114, 106, 91, 111, 102,  # 1901-1909
    87, 107, 99, 83, 103, 95, 115, 99, 91, 111,  # 1910-1919
    96, 87, 107, 92, 112, 103, 95, 108, 100, 91,  # 1920-1929
    111, 96, 88, 107, 92, 112, 104, 88, 108, 100,  # 1930-1939
    85, 104, 96, 116, 101, 92, 112, 97, 89, 108,  # 1940-1949
    100, 85, 105, 96, 109, 101, 93, 112, 97, 89,  # 1950-1959
    109, 93, 113, 105, 90, 109, 101, 86, 106, 97,  # 1960-1969
    89, 102, 94, 113, 105, 90, 110, 101, 86, 106,  # 1970-1979
    98, 110, 102, 94, 114, 98, 90, 110, 95, 86,  # 1980-1989
    106, 91, 111, 102, 94, 107, 99, 90, 103, 95,  # 1990-1999
    115, 106, 91, 111, 103, 87, 107, 99, 84, 103,  # 2000-2009
    95, 115, 100, 91, 111, 96, 88, 107, 92, 112,  # 2010-2019
    104, 95, 108, 100, 92, 111, 96, 88, 108, 92,  # 2020-2029
    112, 104, 89, 108, 100, 85, 105, 96, 116, 101,  # 2030-2039
    93, 112, 97, 89, 109, 100, 85, 105, 97, 109,  # 2040-2049
    101, 93, 113, 97, 89, 109, 94, 113, 105, 90,  # 2050-2059
    110, 101, 86, 106, 98, 89, 102, 94, 114, 105,  # 2060-2069
    90, 110, 102, 86, 106, 98, 111, 102, 94, 114,  # 2070-2079
    99, 90, 110, 95, 87, 106, 91, 111, 103, 94,  # 2080-2089
    107, 99, 91, 103, 95, 115, 107, 91, 111, 103,  # 2090-2099
    88, 108, 100, 85, 105, 96, 109, 101, 93, 112,  # 2100-2109
    97, 89, 109, 93, 113, 105, 90, 109, 101, 86,  # 2110-2119
    106, 97, 89, 102, 94, 113, 105, 90, 110, 101,  # 2120-2129
    86, 106, 98, 110, 102, 94, 114, 98, 90, 110,  # 2130-2139
    95, 86, 106, 91, 111, 102, 94, 107, 99, 90,  # 2140-2149
    103, 95, 115, 106, 91, 111, 103, 87, 107, 99,  # 2150-2159
    84, 103, 95, 115, 100, 91, 111, 96, 88, 107,  # 2160-2169
    92, 112, 104, 95, 108, 100, 92, 111, 96, 88,  # 2170-2179
    108, 92, 112, 104, 89, 108, 100, 85, 105, 96,  # 2180-2189
    116, 101, 93, 112, 97, 89, 109, 100, 85, 105  # 2190-2199
]

cdef class WestenImpl(CalendarImpl):
    cdef bint isWeekEnd(self, int weekDay):
        return weekDay == Weekdays.Saturday or weekDay == Weekdays.Sunday

    cdef int easterMonday(self, int year):
        return EasterMonday[year - 1901]

cdef class TargetImpl(WestenImpl):
    def __init__(self):
        pass

    cdef bint isBizDay(self, Date date):
        cdef int w = date.weekday()
        cdef int d = date.day_of_month()
        cdef int dd = date.day_of_year()
        cdef int m = date.month()
        cdef int y = date.year()
        cdef int em = self.easterMonday(y)

        if (self.isWeekEnd(w)
                or (d == 1 and m == Months.January)
                or (dd == em - 3 and y >= 2000)
                or (dd == em and y >= 2000)
                or (d == 1 and m == Months.May and y >= 2000)
                or (d == 25 and m == Months.December)
                or (d == 26 and m == Months.December and y >= 2000)
                or (d == 31 and m == Months.December and (y == 1998 or y == 1999 or y == 2001))):
            return False
        return True

    def __richcmp__(self, right, int op):
        if op == 2:
            return isinstance(right, TargetImpl)

cdef dict _holDict = {'china.sse': ChinaSseImpl,
                      'china.ib': ChinaIBImpl,
                      'china.cffex': ChinaCFFEXImpl,
                      'target': TargetImpl,
                      'null': NullCalendar,
                      'nullcalendar': NullCalendar,
                      'nyse': NYSEImpl}
