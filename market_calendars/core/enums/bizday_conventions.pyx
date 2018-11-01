from ._bizday_conventions cimport BizDayConventions as bdc

cpdef enum BizDayConventions:
    Following = bdc.Following
    ModifiedFollowing = bdc.ModifiedFollowing
    Preceding = bdc.Preceding
    ModifiedPreceding = bdc.ModifiedPreceding
    Unadjusted = bdc.Unadjusted
    HalfMonthModifiedFollowing = bdc.HalfMonthModifiedFollowing
    Nearest = bdc.Nearest
