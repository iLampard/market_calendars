import unittest
import copy
import tempfile
import pickle
import os
import datetime as dt
from market_calendars.core import (Date,
                                  Period,
                                  Weekdays)


class TestDate(unittest.TestCase):
    def test_date_input_with_serial_number(self):
        serial_number = 45678
        test_date = Date(serial_number=serial_number)
        self.assertEqual(test_date.serial_number, serial_number)

    def test_date_input_with_serial_number_and_notnull_year_month_day(self):
        serial_number = 45678
        _ = Date(year=2015, serial_number=serial_number)

    def test_date_input_without_complete_information_on_year_month_day(self):
        year = 2015
        month = None
        day = 18
        with self.assertRaises(TypeError):
            _ = Date(year=year, month=month, day=day)

    def test_basic_functions(self):
        year = 2015
        month = 7
        day = 24
        str_repr = "{0}-{1:02d}-{2:02d}".format(year, month, day)
        inner_repr = "Date({0}, {1}, {2})".format(year, month, day)

        test_date = Date(year, month, day)
        self.assertEqual(str(test_date), str_repr, "date string:\n"
                                                   "expected:   {0:s}\n"
                                                   "calculated: {1:s}".format(str_repr, str(test_date)))

        self.assertEqual(repr(test_date), inner_repr, "date representation:\n"
                                                      "expected:   {0:s}\n"
                                                      "calculated: {1:s}".format(inner_repr, repr(test_date)))

        self.assertEqual(test_date.year(), year, "date year:\n"
                                                 "expected:   {0:d}\n"
                                                 "calculated: {1:d}".format(year, test_date.year()))

        self.assertEqual(test_date.month(), month, "date month:\n"
                                                   "expected:   {0:d}\n"
                                                   "calculated: {1:d}".format(month, test_date.month()))

        self.assertEqual(test_date.day_of_month(), day, "date day:\n"
                                                      "expected:   {0:d}\n"
                                                      "calculated: {1:d}".format(day, test_date.day_of_month()))

        self.assertEqual(test_date.day_of_year(), test_date - Date(2015, 1, 1) + 1, "date day:\n"
                                                                                  "expected:   {0:d}\n"
                                                                                  "calculated: {1:d}"
                         .format(test_date - Date(2015, 1, 1) + 1, test_date.day_of_year()))
        self.assertEqual(test_date.weekday(), 6, "date weekday:\n"
                                                 "expected:   {0:d}\n"
                                                 "calculated: {1:d}".format(5, test_date.weekday()))

        self.assertEqual(test_date.to_datetime(), dt.datetime(year, month, day), "date datetime representation\n"
                                                                                "expected:   {0}\n"
                                                                                "calculated: {1}".format(
            dt.datetime(year, month, day), test_date.to_datetime()))

        serial_number = test_date.serial_number
        serial_date = Date(serial_number=serial_number)

        self.assertEqual(serial_date, test_date, "date excel serial number representation\n"
                                                 "expected:   {0:d}"
                                                 "calculated: {1:d}".format(serial_date.serial_number,
                                                                            test_date.serial_number))

        # test comparisons
        previous_date = test_date - 1
        self.assertTrue(previous_date < test_date, "{0} is not earlier than {1}".format(previous_date, test_date))
        self.assertFalse(previous_date >= test_date,
                         "{0} should not be later than or equal to {1}".format(previous_date, test_date))
        self.assertTrue((previous_date + 1) == test_date,
                        "{0} plus one day should be equal to {1}".format(previous_date, test_date))

        # check static members
        self.assertEqual(Date.min_date(), Date(1901, 1, 1), "min date is wrong")
        self.assertEqual(Date.max_date(), Date(2199, 12, 31), "max date is wrong")
        self.assertEqual(Date.end_of_month(test_date), Date(year, month, 31), "end of month is wrong")
        self.assertTrue(Date.is_end_of_month(Date(year, month, 31)), "{0} should be the end of month")
        self.assertEqual(Date.next_weekday(test_date, test_date.weekday()), test_date,
                         "{0}'s next same week day should be {1}"
                         .format(test_date, test_date))
        expected_date = dt.date.today()
        expected_date = dt.datetime(expected_date.year, expected_date.month, expected_date.day)
        self.assertEqual(Date.today_date().to_datetime(), expected_date, "today's date\n"
                                                                       "expected:   {0}\n"
                                                                       "calculated: {1}".format(expected_date,
                                                                                                Date.today_date()))

        # nth-week day
        with self.assertRaises(ValueError):
            _ = Date.nth_weekday(0, Weekdays.Friday, 1, 2015)

        with self.assertRaises(ValueError):
            _ = Date.nth_weekday(6, Weekdays.Friday, 1, 2015)

        self.assertEqual(Date.nth_weekday(3, Weekdays.Wednesday, 8, 2015), Date(2015, 8, 19))

        # check plus/sub

        three_weeks_after = test_date + '3W'
        expected_date = test_date + 21
        self.assertEqual(three_weeks_after, expected_date, "date + 3w period\n"
                                                        "expected:   {0}\n"
                                                        "calculated: {1}".format(expected_date, three_weeks_after))

        three_months_before = test_date - "3M"
        expected_date = Date(year, month - 3, day)
        self.assertEqual(three_months_before, expected_date, "date - 3m period\n"
                                                          "expected:   {0}\n"
                                                          "calculated: {1}".format(expected_date, three_months_before))

        three_months_before = test_date - Period("3M")
        expected_date = Date(year, month - 3, day)
        self.assertEqual(three_months_before, expected_date, "date - 3m period\n"
                                                          "expected:   {0}\n"
                                                          "calculated: {1}".format(expected_date, three_months_before))

        three_months_after = test_date + "3m"
        expected_date = Date(year, month + 3, day)
        self.assertEqual(three_months_after, expected_date, "date + 3m period\n"
                                                         "expected:   {0}\n"
                                                         "calculated: {1}".format(expected_date, three_months_after))

        one_year_and_two_months_before = test_date - "14m"
        expected_date = Date(year - 1, month - 2, day)
        self.assertEqual(one_year_and_two_months_before, expected_date, "date - 14m period\n"
                                                                  "expected:   {0}\n"
                                                                  "calculated: {1}".format(expected_date,
                                                                                           three_months_before))

        one_year_and_two_months_before = test_date + "14m"
        expected_date = Date(year + 1, month + 2, day)
        self.assertEqual(one_year_and_two_months_before, expected_date, "date + 14m period\n"
                                                                  "expected:   {0}\n"
                                                                  "calculated: {1}".format(expected_date,
                                                                                           three_months_before))

        five_months_after = test_date + "5m"
        expected_date = Date(year, month + 5, day)
        self.assertEqual(five_months_after, expected_date, "date + 5m period\n"
                                                        "expected:   {0}\n"
                                                        "calculated: {1}".format(expected_date, five_months_after))

    def test_date_advance_out_of_bounds(self):
        test_date = Date(2199, 12, 30)
        with self.assertRaises(ValueError):
            _ = test_date + '1w'

        test_date = Date(1901, 1, 1)
        with self.assertRaises(ValueError):
            _ = test_date - '1w'

    def test_consistency(self):
        min_date = Date.min_date().serial_number + 1
        max_date = Date.max_date().serial_number

        dyold = Date.from_excel_serial_number(min_date - 1).day_of_year()
        dold = Date.from_excel_serial_number(min_date - 1).day_of_month()
        mold = Date.from_excel_serial_number(min_date - 1).month()
        yold = Date.from_excel_serial_number(min_date - 1).year()
        wdold = Date.from_excel_serial_number(min_date - 1).weekday()

        for i in range(min_date, max_date + 1):
            t = Date.from_excel_serial_number(i)
            serial = t.serial_number
            self.assertEqual(serial, i, "inconsistent serial number:\n"
                                        "   original:      {0:d}\n"
                                        "   serial number: {1:d}".format(i, serial))

            dy = t.day_of_year()
            d = t.day_of_month()
            m = t.month()
            y = t.year()
            wd = t.weekday()

            flag = (dy == dyold + 1) or \
                   (dy == 1 and dyold == 365 and not Date.is_leap(yold)) or \
                   (dy == 1 and dyold == 366 and Date.is_leap(yold))

            self.assertTrue(flag, "wrong day of year increment: \n"
                                  "    date: {0}\n"
                                  "    day of year: {1:d}\n"
                                  "    previous:    {2:d}".format(t, dy, dyold))

            dyold = dy

            flag = (d == dold + 1 and m == mold and y == yold) or \
                   (d == 1 and m == mold + 1 and y == yold) or \
                   (d == 1 and m == 1 and y == yold + 1)

            self.assertTrue(flag, "wrong day,month,year increment: \n"
                                  "    date: {0}\n"
                                  "    year,month,day: {1:d}, {2:d}, {3:d}\n"
                                  "    previous:       {4:d}, {5:d}, {6:d}".format(t, y, m, d, yold, mold, dold))
            dold = d
            mold = m
            yold = y

            self.assertTrue(d >= 1, "invalid day of month: \n"
                                    "    date:  {0}\n"
                                    "    day: {1:d}".format(t, d))

            flag = (m == 1 and d <= 31) or \
                   (m == 2 and d <= 28) or \
                   (m == 2 and d == 29 and Date.is_leap(y)) or \
                   (m == 3 and d <= 31) or \
                   (m == 4 and d <= 30) or \
                   (m == 5 and d <= 31) or \
                   (m == 6 and d <= 30) or \
                   (m == 7 and d <= 31) or \
                   (m == 8 and d <= 31) or \
                   (m == 9 and d <= 30) or \
                   (m == 10 and d <= 31) or \
                   (m == 11 and d <= 30) or \
                   (m == 12 and d <= 31)

            self.assertTrue(flag, "invalid day of month: \n"
                                  "    date:  {0}\n"
                                  "    day: {1:d}".format(t, d))

            flag = (wd == (wdold + 1)) or (wd == 1 or wdold == 7)

            self.assertTrue(flag, "invalid weekday: \n"
                                  "    date:  {0}\n"
                                  "    weekday:  {1:d}\n"
                                  "    previous: {2:d}".format(t, wd, wdold))
            wdold = wd

            s = Date(y, m, d)
            serial = s.serial_number

            self.assertTrue(serial == i, "inconsistent serial number:\n"
                                         "    date:          {0}\n"
                                         "    serial number: {1:d}\n"
                                         "    cloned date:   {2}\n"
                                         "    serial number: {3:d}".format(t, i, s, serial))

    def test_ios_dates(self):
        input_date = "2006-01-15"
        d = Date.parse_iso(input_date)
        flag = d.day_of_month() == 15 and \
               d.month() == 1 and \
               d.year() == 2006

        self.assertTrue(flag, "Iso date failed\n"
                              " input date:    {0}\n"
                              " day of month:  {1:d}\n"
                              " month:         {2:d}\n"
                              " year:          {3:d}".format(input_date, d.day_of_month(), d.month(), d.year()))

    def test_parse_dates(self):
        input_date = "2006-01-15"
        d = Date.strptime(input_date, "%Y-%m-%d")
        flag = d == Date(2006, 1, 15)

        self.assertTrue(flag, "date parsing failed\n"
                              " input date:    {0:s}\n"
                              " parsed:        {1}".format(input_date, d))

        input_date = "12/02/2012"
        d = Date.strptime(input_date, "%m/%d/%Y")
        flag = d == Date(2012, 12, 2)

        self.assertTrue(flag, "date parsing failed\n"
                              " input date:    {0:s}\n"
                              " parsed:        {1}".format(input_date, d))

        d = Date.strptime(input_date, "%d/%m/%Y")
        flag = d == Date(2012, 2, 12)

        self.assertTrue(flag, "date parsing failed\n"
                              " input date:    {0:s}\n"
                              " parsed:        {1}".format(input_date, d))

        input_date = "20011002"
        d = Date.strptime(input_date, "%Y%m%d")
        flag = d == Date(2001, 10, 2)

        self.assertTrue(flag, "date parsing failed\n"
                              " input date:    {0:s}\n"
                              " parsed:        {1}".format(input_date, d))

    def test_date_deep_copy(self):
        benchmark_date = Date(2016, 1, 2)
        copied_date = copy.deepcopy(benchmark_date)

        self.assertEqual(benchmark_date, copied_date)

    def test_date_pickle(self):
        benchmark_date = Date(2016, 1, 2)

        f = tempfile.NamedTemporaryFile('w+b', delete=False)
        pickle.dump(benchmark_date, f)
        f.close()

        with open(f.name, 'rb') as f2:
            pickled_date = pickle.load(f2)
            self.assertEqual(benchmark_date, pickled_date)

        os.unlink(f.name)
