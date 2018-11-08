from pytz import timezone
from .core import Calendar
from market_calendars import MarketCalendar


class ChinaSSECalendar(MarketCalendar):
    aliases = ['China.SSE', 'china.sse', 'China.sse']
    @property
    def name(self):
        return 'China.SSE'

    @property
    def tz(self):
        return timezone('Asia/Shanghai')

    @property
    def core_calendar(self):
        return Calendar('China.SSE')