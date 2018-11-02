import unittest
import copy
import pickle
import tempfile
import os
from market_calendars.core import (Period,
                                   TimeUnits)


class TestPeriod(unittest.TestCase):
    def test_basic_arithmic(self):
        # test bad normalize
        test_priod = Period(length=1, units=TimeUnits.Years)
        test_priod._units = 10
        with self.assertRaises(TypeError):
            test_priod.normalize()

        # test plus method
        p1 = Period(length=0, units=TimeUnits.Days)
        p2 = Period(length=10, units=TimeUnits.Months)
        calculated = p1 + p2
        self.assertEqual(p2, calculated, "added value {0} should be equal to {1}".format(calculated, p2))

        p1 = Period(length=2, units=TimeUnits.Years)
        p2 = Period(length=13, units=TimeUnits.Months)
        calculated = p1 + p2
        expected = Period(length=37, units=TimeUnits.Months)
        self.assertEqual(expected, calculated, "added value {0} should be equal to {1}".format(calculated, expected))

        p2 = Period(length=2, units=TimeUnits.Weeks)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2 = Period(length=2, units=TimeUnits.BDays)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2 = Period(length=2, units=TimeUnits.Days)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2._units = 10
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p1 = Period(length=13, units=TimeUnits.Months)
        p2 = Period(length=2, units=TimeUnits.Years)
        calculated = p1 + p2
        expected = Period(length=37, units=TimeUnits.Months)
        self.assertEqual(expected, calculated, "added value {0} should be equal to {1}".format(calculated, expected))

        p2 = Period(length=2, units=TimeUnits.Weeks)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2 = Period(length=2, units=TimeUnits.BDays)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2 = Period(length=2, units=TimeUnits.Days)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2._units = 10
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p1 = Period(length=2, units=TimeUnits.Weeks)
        p2 = Period(length=7, units=TimeUnits.Days)
        calculated = p1 + p2
        expected = Period(length=21, units=TimeUnits.Days)
        self.assertEqual(expected, calculated, "added value {0} should be equal to {1}".format(calculated, expected))

        p2 = Period(length=2, units=TimeUnits.Months)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2 = Period(length=2, units=TimeUnits.BDays)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2 = Period(length=2, units=TimeUnits.Years)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2._units = 10
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p1 = Period(length=7, units=TimeUnits.Days)
        p2 = Period(length=2, units=TimeUnits.Weeks)
        calculated = p1 + p2
        expected = Period(length=21, units=TimeUnits.Days)
        self.assertEqual(expected, calculated, "added value {0} should be equal to {1}".format(calculated, expected))

        p2 = Period(length=2, units=TimeUnits.Months)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2 = Period(length=2, units=TimeUnits.BDays)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2 = Period(length=2, units=TimeUnits.Years)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2._units = 10
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p1 = Period(length=7, units=TimeUnits.BDays)

        p2 = Period(length=2, units=TimeUnits.Months)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2 = Period(length=2, units=TimeUnits.Days)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2 = Period(length=2, units=TimeUnits.Weeks)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2 = Period(length=2, units=TimeUnits.Years)
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2._units = 10
        with self.assertRaises(ValueError):
            _ = p1 + p2

        p2 = Period(length=2, units=TimeUnits.BDays)
        self.assertEqual(p1 + p2, Period('9B'))

        # test negative operator
        p1 = Period(length=-13, units=TimeUnits.Weeks)
        p2 = -p1
        self.assertEqual(p2, Period(length=13, units=TimeUnits.Weeks))

        # test less operator
        p1 = Period(length=0, units=TimeUnits.Days)
        p2 = Period(length=-3, units=TimeUnits.BDays)
        self.assertTrue(p2 < p1)

        # test sub operator
        p1 = Period(length=0, units=TimeUnits.Days)
        p2 = Period(length=-3, units=TimeUnits.BDays)
        self.assertEqual(p1 - p2, Period('3b'))

        # test string representation
        p1 = Period(length=12, units=TimeUnits.Months)
        self.assertEqual("1Y", p1.__str__())

    def test_comparing_operators(self):
        p1 = Period(length=0, units=TimeUnits.Days)
        p2 = Period(length=1, units=TimeUnits.Days)
        self.assertTrue(p1 < p2)

        p1 = Period(length=13, units=TimeUnits.Months)
        p2 = Period(length=1, units=TimeUnits.Years)
        self.assertTrue(not p1 < p2)

        p1 = Period(length=1, units=TimeUnits.Years)
        p2 = Period(length=13, units=TimeUnits.Months)
        self.assertTrue(p1 < p2)

        p1 = Period(length=13, units=TimeUnits.Days)
        p2 = Period(length=2, units=TimeUnits.Weeks)
        self.assertTrue(p1 < p2)

        p1 = Period(length=2, units=TimeUnits.Weeks)
        p2 = Period(length=13, units=TimeUnits.Days)
        self.assertTrue(not p1 < p2)

        p1 = Period(length=1, units=TimeUnits.Years)
        p2 = Period(length=56, units=TimeUnits.Weeks)
        self.assertTrue(p1 < p2)

        p1 = Period(length=56, units=TimeUnits.Weeks)
        p2 = Period(length=1, units=TimeUnits.Years)
        self.assertTrue(not p1 < p2)

        p1 = Period(length=21, units=TimeUnits.Weeks)
        p2 = Period(length=5, units=TimeUnits.Months)

        with self.assertRaises(ValueError):
            _ = p1 < p2

        p1 = Period(length=21, units=TimeUnits.BDays)
        with self.assertRaises(ValueError):
            _ = p1 < p2

        # test not equal operator
        p1 = Period(length=1, units=TimeUnits.Days)
        p2 = Period(length=1, units=TimeUnits.Days)
        self.assertTrue(not p1 != p2)

        p2 = Period(length=1, units=TimeUnits.Years)
        self.assertTrue(p1 != p2)

        # test greater than operator
        p1 = Period(length=1, units=TimeUnits.Days)
        p2 = Period(length=2, units=TimeUnits.Days)
        self.assertEqual(p1 < p2, not p1 > p2)

    def test_years_months_algebra(self):
        one_year = Period(length=1, units=TimeUnits.Years)
        six_months = Period(length=6, units=TimeUnits.Months)
        three_months = Period(length=3, units=TimeUnits.Months)

        n = 4
        flag = one_year / n == three_months
        self.assertTrue(flag, "division error: {0} / {1:d}"
                              " not equal to {2}".format(one_year, n, three_months))

        n = 2
        flag = one_year / n == six_months
        self.assertTrue(flag, "division error: {0} / {1:d}"
                              " not equal to {2}".format(one_year, n, six_months))

        sum_ = three_months
        sum_ += six_months
        flag = sum_ == Period(length=9, units=TimeUnits.Months)
        self.assertTrue(flag, "sum error: {0}"
                              " + {1}"
                              " != {2}".format(three_months, six_months, Period(length=9, units=TimeUnits.Months)))

        sum_ += one_year
        flag = sum_ == Period(length=21, units=TimeUnits.Months)
        self.assertTrue(flag, "sum error: {0}"
                              " + {1}"
                              " + {2}"
                              " != {3}".format(three_months, six_months, one_year,
                                               Period(length=21, units=TimeUnits.Months)))

        twelve_months = Period(length=12, units=TimeUnits.Months)
        flag = twelve_months.length() == 12
        self.assertTrue(flag, "normalization error: TwelveMonths.length"
                              " is {0:d}"
                              " instead of 12".format(twelve_months.length()))
        flag = twelve_months.units() == TimeUnits.Months
        self.assertTrue(flag, "normalization error: TwelveMonths.units"
                              " is {0:d}"
                              " instead of {1:d}".format(twelve_months.units(), TimeUnits.Months))

        normalized_twelve_months = Period(length=12, units=TimeUnits.Months)
        normalized_twelve_months = normalized_twelve_months.normalize()
        flag = normalized_twelve_months.length() == 1
        self.assertTrue(flag, "normalization error: TwelveMonths.length"
                              " is {0:d}"
                              " instead of 1".format(twelve_months.length()))
        flag = normalized_twelve_months.units() == TimeUnits.Years
        self.assertTrue(flag, "normalization error: TwelveMonths.units"
                              " is {0:d}"
                              " instead of {1:d}".format(twelve_months.units(), TimeUnits.Years))

        thirty_days = Period(length=30, units=TimeUnits.Days)
        normalized_thirty_days = thirty_days.normalize()
        flag = normalized_thirty_days.units() == TimeUnits.Days
        self.assertTrue(flag, "normalization error: ThirtyDays.units"
                              " is {0:d}"
                              " instead of {1:d}".format(normalized_thirty_days.units(), TimeUnits.Days))

        thirty_bdays = Period(length=30, units=TimeUnits.BDays)
        normalized_thirty_b_days = thirty_bdays.normalize()
        flag = normalized_thirty_b_days.units() == TimeUnits.BDays
        self.assertTrue(flag, "normalization error: ThirtyBDays.units"
                              " is {0:d}"
                              " instead of {1:d}".format(normalized_thirty_b_days.units(), TimeUnits.BDays))

    def test_weeksdays_algebra(self):
        two_weeks = Period(length=2, units=TimeUnits.Weeks)
        one_week = Period(length=1, units=TimeUnits.Weeks)
        three_days = Period(length=3, units=TimeUnits.Days)
        one_day = Period(length=1, units=TimeUnits.Days)

        n = 2
        flag = two_weeks / n == one_week
        self.assertTrue(flag, "division error: {0} / {1:d}"
                              " not equal to {2}".format(two_weeks, n, one_week))

        n = 7
        flag = one_week / 7 == one_day
        self.assertTrue(flag, "division error: {0} / {1:d}"
                              " not equal to {2}".format(one_week, n, one_day))

        sum_ = three_days
        sum_ += one_day
        flag = sum_ == Period(length=4, units=TimeUnits.Days)
        self.assertTrue(flag, "sum_ error: {0}"
                              " + {1}"
                              " != {2}".format(three_days, one_day, Period(length=4, units=TimeUnits.Days)))

        sum_ += one_week
        flag = sum_ == Period(length=11, units=TimeUnits.Days)
        self.assertTrue(flag, "sum_ error: {0}"
                              " + {1}"
                              " + {2}"
                              " != {3}".format(three_days, one_day, one_week, Period(length=11, units=TimeUnits.Days)))

        seven_days = Period(length=7, units=TimeUnits.Days)
        flag = seven_days.length() == 7
        self.assertTrue(flag, "normalization error: seven_days.length"
                              " is {0:d}"
                              " instead of 7".format(seven_days.length()))
        flag = seven_days.units() == TimeUnits.Days
        self.assertTrue(flag, "normalization error: seven_days.units"
                              " is {0:d}"
                              " instead of {1:d}".format(seven_days.units(), TimeUnits.Days))

        normalized_seven_days = seven_days.normalize()
        flag = normalized_seven_days.length() == 1
        self.assertTrue(flag, "normalization error: normalized_seven_days.length"
                              " is {0:d}"
                              " instead of 1".format(normalized_seven_days.length()))
        flag = normalized_seven_days.units() == TimeUnits.Weeks
        self.assertTrue(flag, "normalization error: TwelveMonths.units"
                              " is {0:d}"
                              " instead of {1:d}".format(normalized_seven_days.units(), TimeUnits.Weeks))

    def test_period_deep_copy(self):
        p1 = Period('36m')
        p2 = copy.deepcopy(p1)

        self.assertEqual(p1, p2)

    def test_period_pickle(self):
        p1 = Period('36m')

        f = tempfile.NamedTemporaryFile('w+b', delete=False)
        pickle.dump(p1, f)
        f.close()

        with open(f.name, 'rb') as f2:
            pickled_period = pickle.load(f2)
            self.assertEqual(p1, pickled_period)

        os.unlink(f.name)
