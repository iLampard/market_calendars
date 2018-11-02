import pytz
import unittest
from datetime import datetime as dt
from market_calendars.exchange_nyse import NYSEExchangeCalendar


class TestNYSECalendar(unittest.TestCase):
    def test_time_zone(self):
        self.assertEquals(NYSEExchangeCalendar().tz, pytz.timezone('America/New_York'))
        self.assertEquals(NYSEExchangeCalendar().name, 'NYSE')

    def test_holidays(self):
        cal = NYSEExchangeCalendar()
        holidays = cal.holidays('2018-01-01', '2018-10-12', include_weekends=False)
        expected = [dt(2018, 1, 1, 0, 0), dt(2018, 1, 15, 0, 0),
                    dt(2018, 2, 19, 0, 0), dt(2018, 3, 30, 0, 0),
                    dt(2018, 5, 28, 0, 0), dt(2018, 7, 4, 0, 0),
                    dt(2018, 9, 3, 0, 0)]

        self.assertEquals(holidays, expected)

        holidays = cal.holidays('2016-01-01', '2016-10-12', include_weekends=False, return_string=True)
        expected = ['2016-01-01', '2016-01-18', '2016-02-15', '2016-03-25', '2016-05-30', '2016-07-04', '2016-09-05']

        self.assertEquals(holidays, expected)
