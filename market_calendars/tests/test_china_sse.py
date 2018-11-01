import pytz
import unittest
from datetime import datetime as dt
from market_calendars.exchange_china_sse import ChinaSSECalendar


class TestChinaSSECalendar(unittest.TestCase):
    def test_time_zone(self):
        self.assertEquals(ChinaSSECalendar().tz, pytz.timezone('Asia/Shanghai'))
        self.assertEquals(ChinaSSECalendar().name, 'China.SSE')

    def test_holidays(self):
        cal = ChinaSSECalendar()
        holidays = cal.holidays('2018-01-01', '2018-10-12', include_weekends=False)
        expected = [dt(2018, 1, 1, 0, 0), dt(2018, 2, 15, 0, 0), dt(2018, 2, 16, 0, 0), dt(2018, 2, 19, 0, 0),
                    dt(2018, 2, 20, 0, 0), dt(2018, 2, 21, 0, 0), dt(2018, 4, 5, 0, 0), dt(2018, 4, 6, 0, 0),
                    dt(2018, 4, 30, 0, 0), dt(2018, 5, 1, 0, 0), dt(2018, 6, 18, 0, 0), dt(2018, 9, 24, 0, 0),
                    dt(2018, 10, 1, 0, 0), dt(2018, 10, 2, 0, 0), dt(2018, 10, 3, 0, 0), dt(2018, 10, 4, 0, 0),
                    dt(2018, 10, 5, 0, 0)]
        self.assertEquals(holidays, expected)

        holidays = cal.holidays('2017-01-01', '2017-10-12', include_weekends=False, return_string=True)
        expected = ['2017-01-02', '2017-01-27', '2017-01-30', '2017-01-31', '2017-02-01', '2017-02-02', '2017-04-03',
                    '2017-04-04', '2017-05-01', '2017-05-29', '2017-05-30', '2017-10-02', '2017-10-03', '2017-10-04',
                    '2017-10-05', '2017-10-06']

        self.assertEquals(holidays, expected)

