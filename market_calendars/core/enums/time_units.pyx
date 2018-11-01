from ._time_units cimport TimeUnits as tu

cpdef enum TimeUnits:
    BDays = tu.BDays
    Days = tu.Days
    Weeks = tu.Weeks
    Months = tu.Months
    Years = tu.Years
