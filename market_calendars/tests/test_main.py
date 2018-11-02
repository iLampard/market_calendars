from simpleutils import add_parent_path

add_parent_path(__file__, 3)

from simpleutils import TestRunner
from simpleutils import CustomLogger
from market_calendars.tests.test_core_period import TestPeriod
from market_calendars.tests.test_core_date import TestDate
from market_calendars.tests.test_core_calendar import TestCalendar
from market_calendars.tests.test_core_schedule import TestSchedule
from market_calendars.tests.test_china_sse import TestChinaSSECalendar
from market_calendars.tests.test_nyse import TestNYSECalendar

if __name__ == '__main__':
    logger = CustomLogger('market_calendars_test', 'info')
    test_runner = TestRunner([TestPeriod,
                              TestDate,
                              TestCalendar,
                              TestSchedule,
                              TestChinaSSECalendar,
                              TestNYSECalendar],
                             logger)
    test_runner.run()
