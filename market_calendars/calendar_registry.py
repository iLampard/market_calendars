from .exchange_china_sse import ChinaSSECalendar
from .exchange_nyse import NYSEExchangeCalendar
from .exchange_null import NullCalendar
from .market_calendar import MarketCalendar


def get_calendar(name):
    """
    Retrieves an instance of an MarketCalendar whose name is given.
    :param name: The name of the MarketCalendar to be retrieved.
    :return: MarketCalendar of the desired calendar.
    """
    return MarketCalendar.factory(name)


def get_calendar_names():
    """All Market Calendar names and aliases that can be used in "factory"
        :return: list(str)
        """
    return MarketCalendar.calendar_names()
