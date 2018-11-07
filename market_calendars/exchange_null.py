from pytz import timezone
from .core import Calendar
from market_calendars import MarketCalendar


class NullCalendar(MarketCalendar):
    aliases = ['null', 'Null']
    @property
    def name(self):
        return 'null'

    @property
    def tz(self):
        return timezone('Asia/Shanghai')

    @property
    def core_calendar(self):
        return Calendar('Null')