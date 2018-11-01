# Fork of zipline from Quantopian. Licensed under MIT

import six
from abc import ABCMeta, abstractmethod
from .class_registry import RegisteryMeta

MarketCalendarMeta = type('MarketCalendarMeta', (ABCMeta, RegisteryMeta), {})


class MarketCalendar(six.with_metaclass(MarketCalendarMeta)):
    """
    An MarketCalendar represents the timing information of a single market or exchange.
    Unless otherwise noted all times are in UTC and use Pandas data structures.
    """

    def __init__(self):
        pass

    @classmethod
    def factory(cls, name):
        """
        :param name: The name of the MarketCalendar to be retrieved.
        :return: MarketCalendar of the desired calendar.
        """
        return cls._regmeta_instance_factory(name)

    @classmethod
    def calendar_names(cls):
        """All Market Calendar names and aliases that can be used in "factory"
        :return: list(str)
        """
        return [cal for cal in cls._regmeta_classes() if cal != 'MarketCalendar']

    @property
    @abstractmethod
    def name(self):
        """
        Name of the market
        :return: string name
        """
        raise NotImplementedError()

    @property
    @abstractmethod
    def tz(self):
        """
        Time zone for the market.
        :return: timezone
        """
        raise NotImplementedError()


