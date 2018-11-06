# Fork of zipline from Quantopian. Licensed under MIT
import functools
import six
from abc import ABCMeta, abstractmethod
from .class_registry import RegisteryMeta
from .core import check_date, check_period, TimeUnits, DateGeneration, Schedule

MarketCalendarMeta = type('MarketCalendarMeta', (ABCMeta, RegisteryMeta), {})


def valid_output(func):
    """
    A decorator to ensure the return date is in chosen format('string' or 'datetime.datetime')
    """
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        return_data = func(*args, **kwargs)
        return_string = kwargs.get('return_string', False)
        if isinstance(return_data, list) or isinstance(return_data, Schedule):
            return [d.to_datetime() for d in return_data] if not return_string else [str(d) for d in return_data]
        else:
            return return_data.to_datetime() if not return_string else str(return_data)

    return wrapper


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

    @valid_output
    def holidays(self, start_date, end_date, **kwargs):
        start_date = check_date(start_date)
        end_date = check_date(end_date)
        include_weekends = kwargs.get('include_weekends', True)
        ret_list = self.core_calendar.holiday_dates_list(start_date, end_date, include_weekends)
        return ret_list

    @valid_output
    def biz_days(self, start_date, end_date, **kwargs):
        start_date = check_date(start_date)
        end_date = check_date(end_date)
        ret_list = self.core_calendar.biz_dates_list(start_date, end_date)
        return ret_list

    def is_biz_day(self, ref_date):
        ref_date = check_date(ref_date)
        return self.core_calendar.is_biz_day(ref_date)

    def is_holiday(self, ref_date):
        ref_date = check_date(ref_date)
        return self.core_calendar.is_holiday(ref_date)

    def is_weekend(self, ref_date):
        ref_date = check_date(ref_date)
        return self.core_calendar.is_weekend(ref_date.weekday())

    def is_end_of_month(self, ref_date):
        ref_date = check_date(ref_date)
        return self.core_calendar.is_end_of_month(ref_date)

    @valid_output
    def adjust_date(self, ref_date, **kwargs):
        ref_date = check_date(ref_date)
        convention = kwargs.get('convention', 0)
        return self.core_calendar.adjust_date(ref_date, convention)

    @valid_output
    def advance_date(self, ref_date, period, **kwargs):
        ref_date = check_date(ref_date)
        convention = kwargs.get('convention', 0)
        period = check_period(period)
        return self.core_calendar.advance_date(ref_date, period, convention)

    @valid_output
    def schedule(self, start_date, end_date, tenor, **kwargs):
        start_date = check_date(start_date)
        end_date = check_date(end_date)
        tenor = check_period(tenor)
        date_rule = kwargs.get('date_rule', 0)
        date_generation_rule = kwargs.get('date_generation_rule', 1)
        cal = self.core_calendar
        if tenor.units() == TimeUnits.BDays:
            schedule = []
            if date_generation_rule == DateGeneration.Forward:
                d = cal.adjust_date(start_date, date_rule)
                while d <= end_date:
                    schedule.append(d)
                    d = cal.advance_date(d, tenor, date_rule)
            elif date_generation_rule == DateGeneration.Backward:
                d = cal.adjust_date(end_date, date_rule)
                while d >= start_date:
                    schedule.append(d)
                    d = cal.advance_date(d, -tenor, date_rule)
                schedule = sorted(schedule)
        else:
            schedule = Schedule(start_date, end_date, tenor, cal, convention=date_rule,
                                date_generation_rule=date_generation_rule)

        return schedule
