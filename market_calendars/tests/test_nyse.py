import pytz
import unittest
from datetime import datetime as dt
from market_calendars.exchange_nyse import NYSEExchangeCalendar


class TestNYSECalendar(unittest.TestCase):
    def setUp(self):
        self.cal = NYSEExchangeCalendar()

    def test_time_zone(self):
        self.assertEquals(NYSEExchangeCalendar().tz, pytz.timezone('America/New_York'))
        self.assertEquals(NYSEExchangeCalendar().name, 'NYSE')

    def test_holidays(self):
        holidays = self.cal.holidays('2018-01-01', '2018-10-12', include_weekends=False)
        expected = [dt(2018, 1, 1, 0, 0), dt(2018, 1, 15, 0, 0),
                    dt(2018, 2, 19, 0, 0), dt(2018, 3, 30, 0, 0),
                    dt(2018, 5, 28, 0, 0), dt(2018, 7, 4, 0, 0),
                    dt(2018, 9, 3, 0, 0)]

        self.assertEquals(holidays, expected)

        holidays = self.cal.holidays('2016-01-01', '2016-10-12', include_weekends=False, return_string=True)
        expected = ['2016-01-01', '2016-01-18', '2016-02-15', '2016-03-25', '2016-05-30', '2016-07-04', '2016-09-05']

        self.assertEquals(holidays, expected)

    def test_biz_days(self):
        biz_days = self.cal.biz_days('2017-04-20', '2017-05-05', return_string=True)
        expected = ['2017-04-20', '2017-04-21', '2017-04-24', '2017-04-25',
                    '2017-04-26', '2017-04-27', '2017-04-28', '2017-05-01',
                    '2017-05-02', '2017-05-03', '2017-05-04', '2017-05-05']
        self.assertEquals(biz_days, expected)

        biz_days = self.cal.biz_days('20160520', '20160610', return_string=True)
        expected = ['2016-05-20', '2016-05-23', '2016-05-24', '2016-05-25',
                    '2016-05-26', '2016-05-27', '2016-05-31', '2016-06-01',
                    '2016-06-02', '2016-06-03', '2016-06-06', '2016-06-07',
                    '2016-06-08', '2016-06-09', '2016-06-10']
        self.assertEquals(biz_days, expected)

    def test_is_holiday(self):
        self.assertTrue(self.cal.is_holiday('2018-01-15'))
        self.assertTrue(self.cal.is_holiday('20140418'))
        self.assertTrue(self.cal.is_holiday('2012/7/4'))

    def test_is_biz_day(self):
        self.assertTrue(self.cal.is_biz_day('2018-1-2'))
        self.assertTrue(self.cal.is_biz_day('20140422'))
        self.assertTrue(self.cal.is_biz_day('2012-7-5'))

    def test_is_weekend(self):
        self.assertTrue(self.cal.is_weekend('2014-04-19'))
        self.assertTrue(self.cal.is_weekend('2011/12/31'))

    def test_is_end_of_month(self):
        self.assertTrue(self.cal.is_end_of_month('2012-05-31'))

    def test_adjust_date(self):
        self.assertEquals(self.cal.adjust_date('20130131', return_string=True), '2013-01-31')
        self.assertEquals(self.cal.adjust_date('20171123'), dt(2017, 11, 24))
        self.assertEquals(self.cal.adjust_date('2017/12/25', convention=2), dt(2017,12, 22))

    def test_advance_date(self):
        self.assertEquals(self.cal.advance_date('20170427', '2b', return_string=True), '2017-05-01')
        self.assertEquals(self.cal.advance_date('20151125', '1b', return_string=True), '2015-11-27')
        self.assertEquals(self.cal.advance_date('20151224', '1w'), dt(2015, 12, 31))

    def test_schedule(self):
        calculated = self.cal.schedule('2018-01-01', '2018-02-01', '3b', date_generation_rule=2)
        expected = [dt(2018, 1, 2, 0, 0), dt(2018, 1, 5, 0, 0), dt(2018, 1, 10, 0, 0), dt(2018, 1, 16, 0, 0),
                    dt(2018, 1, 19, 0, 0), dt(2018, 1, 24, 0, 0), dt(2018, 1, 29, 0, 0), dt(2018, 2, 1, 0, 0)]
        self.assertEquals(calculated, expected)

        calculated = self.cal.schedule('2018-01-05', '2018-02-01', '1w', return_string=True, date_generation_rule=2)
        expected = ['2018-01-05', '2018-01-12', '2018-01-19', '2018-01-26', '2018-02-01']
        self.assertEquals(calculated, expected)
