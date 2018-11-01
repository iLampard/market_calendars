import datetime as dt
import six
import cython
from libc.math cimport floor
from .enums._time_units cimport TimeUnits
from .assert_utils cimport py_assert
from .period cimport Period

@cython.boundscheck(False)
@cython.wraparound(False)
cdef inline int month_length(int month, bint isLeap):
    return MONTH_LEAP_LENGTH[month - 1] if isLeap else MONTH_LENGTH[month - 1]

@cython.boundscheck(False)
@cython.wraparound(False)
cdef inline int month_offset(int month, bint isLeap):
    return MONTH_LEAP_OFFSET[month - 1] if isLeap else MONTH_OFFSET[month - 1]

@cython.boundscheck(False)
@cython.wraparound(False)
cdef Date advance(Date date, int n, int units):
    cdef int d
    cdef int m
    cdef int y
    cdef int added_year
    cdef int month_left
    cdef int length
    cdef int leap_flag

    if units == TimeUnits.Days or units == TimeUnits.BDays:
        return Date(serial_number=date.__serial_number__ + n)
    elif units == TimeUnits.Weeks:
        return Date(serial_number=date.__serial_number__ + 7 * n)
    elif units == TimeUnits.Months:
        d = date._day
        m = date._month + n
        y = date._year
        added_year = int(floor(m / 12.))
        month_left = m % 12
        if month_left == 0:
            month_left = 12
            added_year -= 1
        y += added_year
        leap_flag = Date.is_leap(y)

        py_assert(1900 < y < 2200, ValueError, 'year {0:d} is out of bound. It must be in [1901, 2199]'.format(y))

        length = MONTH_LEAP_LENGTH[month_left - 1] if leap_flag else MONTH_LENGTH[month_left - 1]
        if d > length:
            d = length

        return Date(y, month_left, d)
    elif units == TimeUnits.Years:
        d = date._day
        m = date._month
        y = date._year + n
        leap_flag = Date.is_leap(y)

        if y <= 1900 or y >= 2200:
            return Date(1900, 1, 1)

        if d == 29 and m == 2 and not leap_flag:
            d = 28

        return Date(y, m, d)

cdef class Date(object):
    @cython.cdivision(True)
    def __init__(self, int year=0, int month=0, int day=0, int serial_number=0):
        cdef int leap
        cdef int y
        cdef int m
        cdef int d

        if serial_number:
            self.__serial_number__ = serial_number

            y = (int(serial_number / 365)) + 1900
            if serial_number <= YEAR_OFFSET[y - 1900]:
                y -= 1

            d = serial_number - YEAR_OFFSET[y - 1900]
            m = int(d / 30) + 1
            leap = Date.is_leap(y)
            while d <= month_offset(m, leap):
                m -= 1

            py_assert(1900 < y < 2200, ValueError, 'year {0:d} is out of bound. It must be in [1901, 2199]'.format(y))
            self._year = y
            self._month = m
            self._day = d - month_offset(m, leap)
            return
        elif serial_number and (year or month or day):
            raise ValueError("When serial number is offered, no year or month or day number should be entered")
        elif not (year and month and day):
            raise ValueError("year: {0}, month: {1}, day: {2} can't be null value included".format(year, month, day))

        self._calculate_date(year, month, day)

    cpdef int day_of_month(self):
        return self._day

    cpdef int day_of_year(self):
        return self.__serial_number__ - YEAR_OFFSET[self.year() - 1900]

    cpdef int year(self):
        return self._year

    cpdef int month(self):
        return self._month

    cpdef int weekday(self):
        cdef int w
        w = self.__serial_number__ % 7
        return 7 if w == 0 else w

    cpdef to_datetime(self):
        return dt.datetime(self.year(), self.month(), self.day_of_month())

    @property
    def serial_number(self):
        return self.__serial_number__

    def __richcmp__(Date self, Date other, int op):
        if op == 0:
            return self.__serial_number__ < other.__serial_number__
        elif op == 1:
            return self.__serial_number__ <= other.__serial_number__
        elif op == 2:
            return self.__serial_number__ == other.__serial_number__
        elif op == 3:
            return self.__serial_number__ != other.__serial_number__
        elif op == 4:
            return self.__serial_number__ > other.__serial_number__
        elif op == 5:
            return self.__serial_number__ >= other.__serial_number__

    def __add__(self, period):
        if isinstance(period, Period):
            return advance(self, period.length(), period.units())
        elif isinstance(period, int):
            return Date(serial_number=self.__serial_number__ + period)
        else:
            period = Period(period)
            return advance(self, period.length(), period.units())

    def __sub__(self, period):
        if isinstance(period, Period):
            return advance(self, -period.length(), period.units())
        elif isinstance(period, int):
            return Date(serial_number=self.__serial_number__ - period)
        elif isinstance(period, Date):
            return self.__serial_number__ - period.__serial_number__
        else:
            period = Period(period)
            return advance(self, -period.length(), period.units())

    def __hash__(self):
        return self.__serial_number__

    def __str__(self):
        cdef int d
        cdef int m
        cdef int y
        d = self.day_of_month()
        m = self.month()
        y = self.year()
        return "{0:d}-{1:02d}-{2:02d}".format(y, m, d)

    def __repr__(self):
        cdef int d
        cdef int m
        cdef int y
        d = self.day_of_month()
        m = self.month()
        y = self.year()
        return "Date({0:d}, {1:d}, {2:d})".format(y, m, d)

    @staticmethod
    def min_date():
        return Date(1901, 1, 1)

    @staticmethod
    def max_date():
        return Date(2199, 12, 31)

    @staticmethod
    def end_of_month(Date date):
        cdef int m
        cdef int y
        m = date.month()
        y = date.year()
        return Date(y, m, month_length(m, Date.is_leap(y)))

    @staticmethod
    def is_end_of_month(Date date):
        cdef int m
        cdef int y
        m = date.month()
        y = date.year()
        return date.day_of_month() == month_length(m, Date.is_leap(y))

    @staticmethod
    def next_weekday(Date date, int day_of_week):
        cdef int wd = date.weekday()
        return date + ((7 if wd > day_of_week else 0) - wd + day_of_week)

    @staticmethod
    def nth_weekday(int nth, int day_of_week, int m, int y):
        py_assert(nth > 0, ValueError, "zeroth day of week in a given (month, year) is undefined")
        py_assert(nth < 6, ValueError, "no more than 5 weekday in a given (month, year)")

        cdef int skip
        cdef int first

        first = Date(y, m, 1).weekday()
        skip = nth - (1 if day_of_week >= first else 0)
        return Date(y, m, (1 + day_of_week + skip * 7) - first)

    @staticmethod
    def today_date():
        today = dt.date.today()
        return Date(today.year, today.month, today.day)

    @staticmethod
    def is_leap(year):
        return YEAR_IS_LEAP[year - 1900]

    @staticmethod
    def from_excel_serial_number(serial_number):
        return Date(serial_number=serial_number)

    @staticmethod
    def from_datetime(date_time):
        return Date(date_time.year, date_time.month, date_time.day)

    @staticmethod
    def parse_iso(date_str):
        return Date(int(date_str[0:4]), int(date_str[5:7]), int(date_str[8:10]))

    @staticmethod
    def strptime(str date_str, str date_format='%Y-%m-%d'):
        pydt = dt.datetime.strptime(date_str, date_format)
        return Date(pydt.year, pydt.month, pydt.day)

    @staticmethod
    def western_style(int day, int month, int year):
        return Date(year, month, day)

    def __deepcopy__(self, memo):
        return Date(self._year, self._month, self._day)

    def __reduce__(self):
        d = {}

        return Date, (self._year, self._month, self._day), d

    def __setstate__(self, state):
        pass

    cdef _calculate_date(self, int year, int month, int day):
        cdef int length
        cdef int offset
        cdef int is_leap

        is_leap = Date.is_leap(year)

        length = month_length(month, is_leap)
        offset = month_offset(month, is_leap)

        self.__serial_number__ = day + offset + YEAR_OFFSET[year - 1900]
        self._day = day
        self._month = month
        self._year = year

cpdef check_date(date):
    if isinstance(date, six.string_types):
        return Date.parse_iso(date)
    else:
        return Date.from_datetime(date)

cdef bint YEAR_IS_LEAP[301]
cdef int YEAR_OFFSET[301]

YEAR_IS_LEAP[:] = [
    # 1900 is leap in agreement with Excel's bug
    # 1900 is out of valid date range anyway
    # 1900-1909
    True, False, False, False, True, False, False, False, True, False,
    # 1910-1919
    False, False, True, False, False, False, True, False, False, False,
    # 1920-1929
    True, False, False, False, True, False, False, False, True, False,
    # 1930-1939
    False, False, True, False, False, False, True, False, False, False,
    # 1940-1949
    True, False, False, False, True, False, False, False, True, False,
    # 1950-1959
    False, False, True, False, False, False, True, False, False, False,
    # 1960-1969
    True, False, False, False, True, False, False, False, True, False,
    # 1970-1979
    False, False, True, False, False, False, True, False, False, False,
    # 1980-1989
    True, False, False, False, True, False, False, False, True, False,
    # 1990-1999
    False, False, True, False, False, False, True, False, False, False,
    # 2000-2009
    True, False, False, False, True, False, False, False, True, False,
    # 2010-2019
    False, False, True, False, False, False, True, False, False, False,
    # 2020-2029
    True, False, False, False, True, False, False, False, True, False,
    # 2030-2039
    False, False, True, False, False, False, True, False, False, False,
    # 2040-2049
    True, False, False, False, True, False, False, False, True, False,
    # 2050-2059
    False, False, True, False, False, False, True, False, False, False,
    # 2060-2069
    True, False, False, False, True, False, False, False, True, False,
    # 2070-2079
    False, False, True, False, False, False, True, False, False, False,
    # 2080-2089
    True, False, False, False, True, False, False, False, True, False,
    # 2090-2099
    False, False, True, False, False, False, True, False, False, False,
    # 2100-2109
    False, False, False, False, True, False, False, False, True, False,
    # 2110-2119
    False, False, True, False, False, False, True, False, False, False,
    # 2120-2129
    True, False, False, False, True, False, False, False, True, False,
    # 2130-2139
    False, False, True, False, False, False, True, False, False, False,
    # 2140-2149
    True, False, False, False, True, False, False, False, True, False,
    # 2150-2159
    False, False, True, False, False, False, True, False, False, False,
    # 2160-2169
    True, False, False, False, True, False, False, False, True, False,
    # 2170-2179
    False, False, True, False, False, False, True, False, False, False,
    # 2180-2189
    True, False, False, False, True, False, False, False, True, False,
    # 2190-2199
    False, False, True, False, False, False, True, False, False, False,
    # 2200
    False
]

YEAR_OFFSET[:] = [
    # 1900-1909
    0, 366, 731, 1096, 1461, 1827, 2192, 2557, 2922, 3288,
    # 1910-1919
    3653, 4018, 4383, 4749, 5114, 5479, 5844, 6210, 6575, 6940,
    # 1920-1929
    7305, 7671, 8036, 8401, 8766, 9132, 9497, 9862, 10227, 10593,
    # 1930-1939
    10958, 11323, 11688, 12054, 12419, 12784, 13149, 13515, 13880, 14245,
    # 1940-1949
    14610, 14976, 15341, 15706, 16071, 16437, 16802, 17167, 17532, 17898,
    # 1950-1959
    18263, 18628, 18993, 19359, 19724, 20089, 20454, 20820, 21185, 21550,
    # 1960-1969
    21915, 22281, 22646, 23011, 23376, 23742, 24107, 24472, 24837, 25203,
    # 1970-1979
    25568, 25933, 26298, 26664, 27029, 27394, 27759, 28125, 28490, 28855,
    # 1980-1989
    29220, 29586, 29951, 30316, 30681, 31047, 31412, 31777, 32142, 32508,
    # 1990-1999
    32873, 33238, 33603, 33969, 34334, 34699, 35064, 35430, 35795, 36160,
    # 2000-2009
    36525, 36891, 37256, 37621, 37986, 38352, 38717, 39082, 39447, 39813,
    # 2010-2019
    40178, 40543, 40908, 41274, 41639, 42004, 42369, 42735, 43100, 43465,
    # 2020-2029
    43830, 44196, 44561, 44926, 45291, 45657, 46022, 46387, 46752, 47118,
    # 2030-2039
    47483, 47848, 48213, 48579, 48944, 49309, 49674, 50040, 50405, 50770,
    # 2040-2049
    51135, 51501, 51866, 52231, 52596, 52962, 53327, 53692, 54057, 54423,
    # 2050-2059
    54788, 55153, 55518, 55884, 56249, 56614, 56979, 57345, 57710, 58075,
    # 2060-2069
    58440, 58806, 59171, 59536, 59901, 60267, 60632, 60997, 61362, 61728,
    # 2070-2079
    62093, 62458, 62823, 63189, 63554, 63919, 64284, 64650, 65015, 65380,
    # 2080-2089
    65745, 66111, 66476, 66841, 67206, 67572, 67937, 68302, 68667, 69033,
    # 2090-2099
    69398, 69763, 70128, 70494, 70859, 71224, 71589, 71955, 72320, 72685,
    # 2100-2109
    73050, 73415, 73780, 74145, 74510, 74876, 75241, 75606, 75971, 76337,
    # 2110-2119
    76702, 77067, 77432, 77798, 78163, 78528, 78893, 79259, 79624, 79989,
    # 2120-2129
    80354, 80720, 81085, 81450, 81815, 82181, 82546, 82911, 83276, 83642,
    # 2130-2139
    84007, 84372, 84737, 85103, 85468, 85833, 86198, 86564, 86929, 87294,
    # 2140-2149
    87659, 88025, 88390, 88755, 89120, 89486, 89851, 90216, 90581, 90947,
    # 2150-2159
    91312, 91677, 92042, 92408, 92773, 93138, 93503, 93869, 94234, 94599,
    # 2160-2169
    94964, 95330, 95695, 96060, 96425, 96791, 97156, 97521, 97886, 98252,
    # 2170-2179
    98617, 98982, 99347, 99713, 100078, 100443, 100808, 101174, 101539, 101904,
    # 2180-2189
    102269, 102635, 103000, 103365, 103730, 104096, 104461, 104826, 105191, 105557,
    # 2190-2199
    105922, 106287, 106652, 107018, 107383, 107748, 108113, 108479, 108844, 109209,
    # 2200
    109574
]

cdef int MONTH_LENGTH[12]
cdef int MONTH_LEAP_LENGTH[12]
cdef int MONTH_OFFSET[13]
cdef int MONTH_LEAP_OFFSET[13]

MONTH_LENGTH[:] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
MONTH_LEAP_LENGTH[:] = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

MONTH_OFFSET[:] = [0, 31, 59, 90, 120, 151,  # Jan - Jun
                   181, 212, 243, 273, 304, 334,  # Jun - Dec
                   365]
MONTH_LEAP_OFFSET[:] = [0, 31, 60, 91, 121, 152,  # Jan - Jun
                        182, 213, 244, 274, 305, 335,  # Jun - Dec
                        366]
