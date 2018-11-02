from pytz import timezone
from .core import Calendar
from market_calendars import MarketCalendar


class NYSEExchangeCalendar(MarketCalendar):
    aliases = ['NYSE', 'NASDAQ', 'BATS']

    @property
    def name(self):
        return 'NYSE'

    @property
    def tz(self):
        return timezone('America/New_York')

    @property
    def core_calendar(self):
        return Calendar('nyse')
