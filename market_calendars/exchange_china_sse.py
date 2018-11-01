from pytz import timezone
from market_calendars import MarketCalendar


class ChinaSSECalendar(MarketCalendar):
    aliases = ['China.SSE', 'china.sse']
    @property
    def name(self):
        return 'China.SSE'

    @property
    def tz(self):
        return timezone('Asia/Shanghai')

