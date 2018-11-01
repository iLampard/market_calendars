from simpleutils import add_parent_path

add_parent_path(__file__, 3)

from simpleutils import TestRunner
from simpleutils import CustomLogger
from market_calendar.tests.test_core_period import TestPeriod
from market_calendar.tests.test_core_date import TestDate
from market_calendar.tests.test_core_calendar import TestCalendar
from market_calendar.tests.test_core_schedule import TestSchedule

if __name__ == '__main__':
    logger = CustomLogger('market_calendar_test', 'info')
    test_runner = TestRunner([TestPeriod,
                              TestDate,
                              TestCalendar,
                              TestSchedule],
                             logger)
    test_runner.run()
