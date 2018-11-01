# Fork of zipline from Quantopian. Licensed under MIT

import six
from abc import ABCMeta, abstractmethod
from .class_registry import RegisteryMeta
from .core import Date, check_date, Calendar

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

    @property
    @abstractmethod
    def core_calendar(self):
        """
        Calendar object implemented in core folder
        :return: core.Calendar
        """
        raise NotImplementedError()

    def holidays(self, start_date, end_date, **kwargs):
        start_date = check_date(start_date)
        end_date = check_date(end_date)
        include_weekends = kwargs.get('include_weekends', True)
        return_string = kwargs.get('return_string', False)
        if not return_string:
            return [d.to_datetime() for d in
                    self.core_calendar.holiday_dates_list(start_date, end_date, include_weekends)]
        else:
            return [str(d) for d in self.core_calendar.holiday_dates_list(start_date, end_date, include_weekends)]

    def biz_days(self, start_date, end_date, **kwargs):
        start_date = check_date(start_date)
        end_date = check_date(end_date)
        include_weekends = kwargs.get('include_weekends', True)
        return_string = kwargs.get('return_string', False)
        if not return_string:
            return [d.to_datetime() for d in self.core_calendar.biz_day_list(start_date, end_date, include_weekends)]
        else:
            return [str(d) for d in self.core_calendar.biz_day_list(start_date, end_date, include_weekends)]

    def is_biz_day(self, ref_date):
        return self.core_calendar.is_biz_day(ref_date)

    def is_holiday(self, ref_date):
        return self.core_calendar.is_holiday(ref_date)

    def is_weekend(self, ref_date):
        return self.core_calendar.is_weekend(ref_date)

    def is_end_of_month(self, ref_date):
        return self.core_calendar.is_end_of_month(ref_date)

    def advance_date(self, ref_date, period):
        return self.core_calendar.advance(ref_date, period)
