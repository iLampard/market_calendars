import pytz
import unittest
from datetime import datetime as dt
from market_calendars.exchange_china_sse import ChinaSSECalendar


class TestChinaSSECalendar(unittest.TestCase):
    def setUp(self):
        self.cal = ChinaSSECalendar()

    def test_time_zone(self):
        self.assertEquals(ChinaSSECalendar().tz, pytz.timezone('Asia/Shanghai'))
        self.assertEquals(ChinaSSECalendar().name, 'China.SSE')

    def test_holidays(self):
        holidays = self.cal.holidays('2018-01-01', '2018-10-12', include_weekends=False)
        expected = [dt(2018, 1, 1, 0, 0), dt(2018, 2, 15, 0, 0), dt(2018, 2, 16, 0, 0), dt(2018, 2, 19, 0, 0),
                    dt(2018, 2, 20, 0, 0), dt(2018, 2, 21, 0, 0), dt(2018, 4, 5, 0, 0), dt(2018, 4, 6, 0, 0),
                    dt(2018, 4, 30, 0, 0), dt(2018, 5, 1, 0, 0), dt(2018, 6, 18, 0, 0), dt(2018, 9, 24, 0, 0),
                    dt(2018, 10, 1, 0, 0), dt(2018, 10, 2, 0, 0), dt(2018, 10, 3, 0, 0), dt(2018, 10, 4, 0, 0),
                    dt(2018, 10, 5, 0, 0)]
        self.assertEquals(holidays, expected)

        holidays = self.cal.holidays('2017/01/01', '2017/10/12', include_weekends=False, return_string=True)
        expected = ['2017-01-02', '2017-01-27', '2017-01-30', '2017-01-31', '2017-02-01', '2017-02-02', '2017-04-03',
                    '2017-04-04', '2017-05-01', '2017-05-29', '2017-05-30', '2017-10-02', '2017-10-03', '2017-10-04',
                    '2017-10-05', '2017-10-06']

        self.assertEquals(holidays, expected)

    def test_biz_days(self):
        biz_days = self.cal.biz_days('2016-04-20', '2016-05-10')
        expected = [dt(2016, 4, 20, 0, 0), dt(2016, 4, 21, 0, 0),
                    dt(2016, 4, 22, 0, 0), dt(2016, 4, 25, 0, 0),
                    dt(2016, 4, 26, 0, 0), dt(2016, 4, 27, 0, 0),
                    dt(2016, 4, 28, 0, 0), dt(2016, 4, 29, 0, 0),
                    dt(2016, 5, 3, 0, 0), dt(2016, 5, 4, 0, 0),
                    dt(2016, 5, 5, 0, 0), dt(2016, 5, 6, 0, 0),
                    dt(2016, 5, 9, 0, 0), dt(2016, 5, 10, 0, 0)]
        self.assertEquals(biz_days, expected)

        biz_days = self.cal.biz_days('20160430', '20160510', return_string=True)
        expected = ['2016-05-03', '2016-05-04', '2016-05-05', '2016-05-06', '2016-05-09', '2016-05-10']
        self.assertEquals(biz_days, expected)

    def test_is_holiday(self):
        self.assertTrue(self.cal.is_holiday('2016-10-01'))
        self.assertTrue(self.cal.is_holiday('20170501'))
        self.assertTrue(self.cal.is_holiday('2014/9/21'))

    def test_is_biz_day(self):
        self.assertTrue(self.cal.is_biz_day('2014-09-22'))
        self.assertTrue(self.cal.is_biz_day('20140130'))

    def test_is_weekend(self):
        self.assertTrue(self.cal.is_weekend('2014-01-25'))
        self.assertTrue(self.cal.is_weekend('2011/12/31'))

    def test_is_end_of_month(self):
        self.assertTrue(self.cal.is_end_of_month('2011-12-30'))
        self.assertTrue(self.cal.is_end_of_month('20120131'))

    def test_adjust_date(self):
        self.assertEquals(self.cal.adjust_date('20130131', return_string=True), '2013-01-31')
        self.assertEquals(self.cal.adjust_date('20170930'), dt(2017, 10, 9))
        self.assertEquals(self.cal.adjust_date('2017/10/01', convention=2), dt(2017, 9, 29))

    def test_advance_date(self):
        self.assertEquals(self.cal.advance_date('20170427', '2b', return_string=True), '2017-05-02')
        self.assertEquals(self.cal.advance_date('20170427', '1w', return_string=True), '2017-05-04')
        self.assertEquals(self.cal.advance_date('20180429', '1b'), dt(2018, 5, 2))

    def test_schedule(self):
        calculated = self.cal.schedule('2018-01-01', '2018-02-01', '3b', date_generation_rule=1)
        expected = [dt(2018, 1, 3, 0, 0), dt(2018, 1, 8, 0, 0), dt(2018, 1, 11, 0, 0), dt(2018, 1, 16, 0, 0),
                    dt(2018, 1, 19, 0, 0), dt(2018, 1, 24, 0, 0), dt(2018, 1, 29, 0, 0), dt(2018, 2, 1, 0, 0)]
        self.assertEquals(calculated, expected)

        calculated = self.cal.schedule('2018-01-05', '2018-02-01', '1w', return_string=True, date_generation_rule=2)
        expected = ['2018-01-05', '2018-01-12', '2018-01-19', '2018-01-26', '2018-02-01']
        self.assertEquals(calculated, expected)
