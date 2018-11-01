import unittest
import copy
import tempfile
import os
import pickle
from market_calendar.core import Date, Calendar, Period
from market_calendar.core import BizDayConventions, Months, Weekdays


class TestCalendar(unittest.TestCase):
    def test_wrong_input_holiday_center(self):
        with self.assertRaises(ValueError):
            _ = Calendar('NulCalendar')

    def test_calendar_construction_is_insensitive_of_case(self):
        cal1 = Calendar('NullCalendar')
        cal2 = Calendar('nullcalendar')
        should_be_true = cal1 == cal2
        self.assertTrue(should_be_true)

        calto_be_different = Calendar('China.SSE')
        should_be_false = cal1 == calto_be_different
        self.assertFalse(should_be_false)

    def test_basic_functions(self):

        test_date = Date(2015, 7, 11)
        cal = Calendar('China.SSE')
        self.assertTrue(cal.is_weekend(test_date.weekday()), "{0} is expected to be a weekend".format(test_date))
        test_date = Date(2015, 7, 13)
        self.assertTrue(not cal.is_weekend(test_date.weekday()), "{0} is expected not to be a weekend".format(test_date))

        test_date = Date(2015, 5, 29)
        cal = Calendar('China.SSE')
        self.assertTrue(cal.is_end_of_month(test_date), "{0} is expected to be a end of month".format(test_date))

        test_date = Date(2015, 5, 1)
        cal = Calendar('China.SSE')
        end_of_month = cal.end_of_month(test_date)
        self.assertEqual(end_of_month, Date(2015, 5, 29),
                         "The month end of 2015/5 is expected to be {0}".format(Date(2015, 5, 29)))

        biz_dates1 = cal.biz_days_between(Date(2015, 1, 1), Date(2015, 12, 31), True, False)
        biz_dates2 = cal.biz_days_between(Date(2015, 12, 31), Date(2015, 1, 1), False, True)
        self.assertEqual(biz_dates1, biz_dates2)

    def test_null_calendar(self):
        cal = Calendar("Null")

        test_date = Date(2015, 1, 1)
        self.assertTrue(cal.is_biz_day(test_date))
        self.assertTrue(not cal.is_holiday(test_date))
        self.assertTrue(cal.is_weekend(Weekdays.Saturday))
        self.assertTrue(cal.is_weekend(Weekdays.Sunday))
        self.assertTrue(not cal.is_weekend(Weekdays.Friday))

    def test_china_sse(self):
        # China Shanghai Securities Exchange holiday list in the year 2014
        expected_hol = [Date(2014, 1, 1), Date(2014, 1, 31),
                        Date(2014, 2, 3), Date(2014, 2, 4), Date(2014, 2, 5), Date(2014, 2, 6),
                        Date(2014, 4, 7),
                        Date(2014, 5, 1), Date(2014, 5, 2),
                        Date(2014, 6, 2),
                        Date(2014, 9, 8),
                        Date(2014, 10, 1), Date(2014, 10, 2), Date(2014, 10, 3), Date(2014, 10, 6), Date(2014, 10, 7),
                        # China Shanghai Securities Exchange holiday list in the year 2015
                        Date(2015, 1, 1), Date(2015, 1, 2),
                        Date(2015, 2, 18), Date(2015, 2, 19), Date(2015, 2, 20), Date(2015, 2, 23), Date(2015, 2, 24),
                        Date(2015, 4, 6),
                        Date(2015, 5, 1),
                        Date(2015, 6, 22),
                        Date(2015, 9, 3), Date(2015, 9, 4),
                        Date(2015, 10, 1), Date(2015, 10, 2), Date(2015, 10, 5), Date(2015, 10, 6), Date(2015, 10, 7),
                        # China Shanghai Securities Exchange holiday list in the year 2016
                        Date(2016, 1, 1),
                        Date(2016, 2, 8), Date(2016, 2, 9), Date(2016, 2, 10), Date(2016, 2, 11), Date(2016, 2, 12),
                        Date(2016, 4, 4),
                        Date(2016, 5, 2),
                        Date(2016, 6, 9), Date(2016, 6, 10),
                        Date(2016, 9, 15), Date(2016, 9, 16),
                        Date(2016, 10, 3), Date(2016, 10, 4), Date(2016, 10, 5), Date(2016, 10, 6), Date(2016, 10, 7),
                        # China Shanghai Securities Exchange holiday list in the year 2017
                        Date(2017, 1, 1), Date(2017, 1, 2),
                        Date(2017, 1, 27), Date(2017, 1, 28), Date(2017, 1, 29), Date(2017, 1, 30), Date(2017, 1, 31),
                        Date(2017, 2, 1), Date(2017, 2, 2),
                        Date(2017, 4, 2), Date(2017, 4, 3), Date(2017, 4, 4),
                        Date(2017, 5, 1),
                        Date(2017, 5, 28), Date(2017, 5, 29), Date(2017, 5, 30),
                        Date(2017, 10, 1), Date(2017, 10, 2), Date(2017, 10, 3), Date(2017, 10, 4), Date(2017, 10, 5),
                        Date(2017, 10, 6), Date(2017, 10, 7), Date(2017, 10, 8),
                        # China Shanghai Securities Exchange holiday list in the year 2018
                        Date(2018, 1, 1),
                        Date(2018, 2, 15), Date(2018, 2, 16), Date(2018, 2, 17), Date(2018, 2, 18), Date(2018, 2, 19),
                        Date(2018, 2, 20), Date(2018, 2, 21),
                        Date(2018, 4, 5), Date(2018, 4, 6), Date(2018, 4, 7),
                        Date(2018, 4, 29), Date(2018, 4, 30), Date(2018, 5, 1),
                        Date(2018, 6, 16), Date(2018, 6, 17), Date(2018, 6, 18),
                        Date(2018, 9, 22), Date(2018, 9, 23), Date(2018, 9, 24),
                        Date(2018, 10, 1), Date(2018, 10, 2), Date(2018, 10, 3), Date(2018, 10, 4), Date(2018, 10, 5),
                        Date(2018, 10, 6), Date(2018, 10, 7)]

        cal = Calendar('China.SSE')

        for day in expected_hol:
            self.assertEqual(cal.is_holiday(day), True, "{0} is expected to be a holiday in {1}".format(day, cal))
            self.assertEqual(cal.is_biz_day(day), False,
                             "{0} is expected not to be a working day in {1} ".format(day, cal))

    def testChinaIB(self):

        # China Inter Bank working weekend list in the year 2014
        expected_working_week_end = [Date(2014, 1, 26),
                                     Date(2014, 2, 8),
                                     Date(2014, 5, 4),
                                     Date(2014, 9, 28),
                                     Date(2014, 10, 11),
                                     # China Inter Bank working weekend list in the year 2015
                                     Date(2015, 1, 4),
                                     Date(2015, 2, 15),
                                     Date(2015, 2, 28),
                                     Date(2015, 9, 6),
                                     Date(2015, 10, 10),
                                     # China Inter Bank working weekend list in the year 2016
                                     Date(2016, 2, 6),
                                     Date(2016, 2, 14),
                                     Date(2016, 6, 12),
                                     Date(2016, 9, 18),
                                     Date(2016, 10, 8),
                                     Date(2016, 10, 9),
                                     # China Inter Bank working weekend list in the year 2017
                                     Date(2017, 1, 22),
                                     Date(2017, 2, 4),
                                     Date(2017, 4, 1),
                                     Date(2017, 5, 27),
                                     Date(2017, 9, 30),
                                     # China Inter Bank working weekend list in the year 2018
                                     Date(2018, 2, 11),
                                     Date(2018, 2, 24),
                                     Date(2018, 4, 8),
                                     Date(2018, 4, 28),
                                     Date(2018, 9, 29),
                                     Date(2018, 9, 30)]

        cal = Calendar('China.IB')

        for day in expected_working_week_end:
            self.assertEqual(cal.is_holiday(day), False, "{0} is not expected to be a holiday in {1}".format(day, cal))
            self.assertEqual(cal.is_biz_day(day), True, "{0} is expected to be a working day in {1} ".format(day, cal))

    def test_adjust_date(self):
        # April 30, 2005 is a working day under IB, but a holiday under SSE
        reference_date = Date(2005, Months.April, 30)

        sse_cal = Calendar('China.SSE')
        ib_cal = Calendar('China.IB')

        biz_day_conv = BizDayConventions.Unadjusted
        self.assertEqual(sse_cal.adjust_date(reference_date, biz_day_conv), reference_date)
        self.assertEqual(ib_cal.adjust_date(reference_date, biz_day_conv), reference_date)

        biz_day_conv = BizDayConventions.Following
        self.assertEqual(sse_cal.adjust_date(reference_date, biz_day_conv), Date(2005, Months.May, 9))
        self.assertEqual(ib_cal.adjust_date(reference_date, biz_day_conv), Date(2005, Months.April, 30))

        biz_day_conv = BizDayConventions.ModifiedFollowing
        self.assertEqual(sse_cal.adjust_date(reference_date, biz_day_conv), Date(2005, Months.April, 29))
        self.assertEqual(ib_cal.adjust_date(reference_date, biz_day_conv), Date(2005, Months.April, 30))

    def test_advance_date(self):
        reference_date = Date(2014, 1, 31)
        sse_cal = Calendar('China.SSE')
        ib_cal = Calendar('China.IB')

        biz_day_conv = BizDayConventions.Following

        # test null period
        self.assertEqual(sse_cal.advance_date(reference_date, Period('0b'), biz_day_conv), Date(2014, 2, 7))

        # test negative period
        self.assertEqual(sse_cal.advance_date(reference_date, Period('-5b'), biz_day_conv), Date(2014, 1, 24))

        # The difference is caused by Feb 8 is SSE holiday but a working day for IB market
        self.assertEqual(sse_cal.advance_date(reference_date, Period('2b'), biz_day_conv), Date(2014, 2, 10))
        self.assertEqual(sse_cal.advance_date(reference_date, Period('2d'), biz_day_conv), Date(2014, 2, 7))
        self.assertEqual(ib_cal.advance_date(reference_date, Period('2b'), biz_day_conv), Date(2014, 2, 8))
        self.assertEqual(ib_cal.advance_date(reference_date, Period('2d'), biz_day_conv), Date(2014, 2, 7))

        biz_day_conv = BizDayConventions.ModifiedFollowing
        # May 31, 2014 is a holiday
        self.assertEqual(sse_cal.advance_date(reference_date, Period('4m'), biz_day_conv, True), Date(2014, 5, 30))

    def test_date_list(self):

        from_date = Date(2014, 1, 31)
        to_date = Date(2014, 2, 28)
        sse_cal = Calendar('China.SSE')
        ib_cal = Calendar('China.IB')

        benchmark_hol = [Date(2014, 1, 31), Date(2014, 2, 3), Date(2014, 2, 4), Date(2014, 2, 5), Date(2014, 2, 6)]
        sse_hol_list = sse_cal.holiday_dates_list(from_date, to_date, False)
        self.assertEqual(sse_hol_list, benchmark_hol)
        ib_hol_list = ib_cal.holiday_dates_list(from_date, to_date, False)
        self.assertEqual(ib_hol_list, benchmark_hol)

        sse_hol_list = sse_cal.holiday_dates_list(from_date, to_date, True)
        benchmark_hol = [Date(2014, 1, 31), Date(2014, 2, 1), Date(2014, 2, 2), Date(2014, 2, 3), Date(2014, 2, 4),
                         Date(2014, 2, 5), Date(2014, 2, 6), Date(2014, 2, 8), Date(2014, 2, 9), Date(2014, 2, 15),
                         Date(2014, 2, 16), Date(2014, 2, 22), Date(2014, 2, 23)]
        self.assertEqual(sse_hol_list, benchmark_hol)
        ib_hol_list = ib_cal.holiday_dates_list(from_date, to_date, True)
        benchmark_hol = [Date(2014, 1, 31), Date(2014, 2, 1), Date(2014, 2, 2), Date(2014, 2, 3), Date(2014, 2, 4),
                         Date(2014, 2, 5), Date(2014, 2, 6), Date(2014, 2, 9), Date(2014, 2, 15), Date(2014, 2, 16),
                         Date(2014, 2, 22), Date(2014, 2, 23)]
        self.assertEqual(ib_hol_list, benchmark_hol)

        sse_working_day_list = sse_cal.biz_dates_list(from_date, to_date)
        d = from_date
        while d <= to_date:
            if sse_cal.is_biz_day(d):
                self.assertTrue(d in sse_working_day_list and d not in sse_hol_list)
            d += 1

        ib_working_day_list = ib_cal.biz_dates_list(from_date, to_date)
        d = from_date
        while d <= to_date:
            if ib_cal.is_biz_day(d):
                self.assertTrue(d in ib_working_day_list and d not in ib_hol_list)
            d += 1

    def test_calendar_with_date_convention(self):
        sse_cal = Calendar('China.SSE')

        reference_date = Date(2015, 2, 14)
        test_date = sse_cal.adjust_date(reference_date, BizDayConventions.HalfMonthModifiedFollowing)
        self.assertEqual(test_date, Date(2015, 2, 13))

        reference_date = Date(2014, 2, 4)
        test_date = sse_cal.adjust_date(reference_date, BizDayConventions.ModifiedPreceding)
        self.assertEqual(test_date, Date(2014, 2, 7))

        reference_date = Date(2014, 2, 3)
        test_date = sse_cal.adjust_date(reference_date, BizDayConventions.Nearest)
        self.assertEqual(test_date, Date(2014, 2, 7))

        reference_date = Date(2014, 2, 2)
        test_date = sse_cal.adjust_date(reference_date, BizDayConventions.Nearest)
        self.assertEqual(test_date, Date(2014, 1, 30))

        with self.assertRaises(ValueError):
            _ = sse_cal.adjust_date(reference_date, -1)

    def test_calendar_deep_copy(self):
        sse_cal = Calendar('China.SSE')
        copied_cal = copy.deepcopy(sse_cal)

        self.assertEqual(sse_cal, copied_cal)

    def test_calendar_pickle(self):
        sse_cal = Calendar('China.SSE')

        f = tempfile.NamedTemporaryFile('w+b', delete=False)
        pickle.dump(sse_cal, f)
        f.close()

        with open(f.name, 'rb') as f2:
            pickled_cal = pickle.load(f2)
            self.assertEqual(sse_cal, pickled_cal)

        os.unlink(f.name)
