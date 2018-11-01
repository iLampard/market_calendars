from .calendar cimport Calendar
from .date cimport Date
from .period cimport Period
from .enums._bizday_conventions cimport BizDayConventions
from .enums._time_units cimport TimeUnits
from .enums._date_generation cimport DateGeneration
from .assert_utils cimport py_assert

cdef class Schedule(object):
    def __init__(self,
                 Date effective_date,
                 Date termination_date,
                 Period tenor,
                 Calendar calendar,
                 int convention=BizDayConventions.Following,
                 int termination_convention=BizDayConventions.Following,
                 int date_generation_rule=DateGeneration.Forward,
                 bint end_of_month=False,
                 Date first_date=None,
                 Date next_to_last_date=None,
                 Date evaluation_date=None):

        cdef int i
        cdef size_t date_len
        cdef Calendar null_calendar
        cdef Date eval_date
        cdef int y
        cdef int periods
        cdef Date seed
        cdef Date temp
        cdef Date exit_date

        # Initialize private data
        self._effective_date = effective_date
        self._termination_date = termination_date
        self._tenor = tenor
        self._cal = calendar
        self._convention = convention
        self._termination_convention = termination_convention
        self._rule = date_generation_rule
        self._dates = []
        self._is_regular = []

        if tenor < Period("1M"):
            self._end_of_month = False
        else:
            self._end_of_month = end_of_month

        if not first_date or first_date == effective_date:
            self._first_date = None
        else:
            self._first_date = first_date

        if not next_to_last_date or next_to_last_date == termination_date:
            self._next_to_last_date = None
        else:
            self._next_to_last_date = next_to_last_date

        if not evaluation_date:
            self._evaluation_date = Date.today_date()
        else:
            self._evaluation_date = evaluation_date

        # in many cases (e.g. non-expired bonds) the effective date is not
        # really necessary. In these cases a decent placeholder is enough
        if not effective_date and not first_date and date_generation_rule == DateGeneration.Backward:
            # evalDate = Settings.evaluationDate
            eval_date = self._evaluation_date
            py_assert(eval_date < termination_date, ValueError, "null effective date")
            if next_to_last_date:
                y = int((next_to_last_date - eval_date) / 366) + 1
                effective_date = next_to_last_date - Period(length=y, units=TimeUnits.Years)
            else:
                y = int((termination_date - eval_date) / 366) + 1
                effective_date = termination_date - Period(length=y, units=TimeUnits.Years)
        else:
            py_assert(effective_date, ValueError, "null effective date")

        py_assert(effective_date < termination_date, ValueError, "effective date ({0}) "
                                                                 "later than or equal to termination date ({1}"
        .format(effective_date, termination_date))

        if tenor.length() == 0:
            self._rule = DateGeneration.Zero
        else:
            py_assert(tenor.length() > 0, ValueError, "non positive tenor ({0:d}) not allowed".format(tenor.length()))

        if self._first_date:
            if self._rule == DateGeneration.Backward or self._rule == DateGeneration.Forward:
                py_assert(effective_date < self._first_date < termination_date, ValueError,
                            "first date ({0}) out of effective-termination date range [{1}, {2})"
                            .format(self._first_date, effective_date, termination_date))
                # we should ensure that the above condition is still
                # verified after adjustment
            elif self._rule == DateGeneration.Zero:
                raise ValueError("first date incompatible with {0:d} date generation rule".format(self._rule))
            else:
                raise ValueError("unknown rule ({0:d})".format(self._rule))

        if self._next_to_last_date:
            if self._rule == DateGeneration.Backward or self._rule == DateGeneration.Forward:
                py_assert(effective_date < self._next_to_last_date < termination_date, ValueError,
                            "next to last date ({0}) out of effective-termination date range [{1}, {2})"
                            .format(self._next_to_last_date, effective_date, termination_date))
                # we should ensure that the above condition is still
                # verified after adjustment
            elif self._rule == DateGeneration.Zero:
                raise ValueError("next to last date incompatible with {0:d} date generation rule".format(self._rule))
            else:
                raise ValueError("unknown rule ({0:d})".format(self._rule))

        # calendar needed for endOfMonth adjustment
        null_calendar = Calendar("Null")
        periods = 1

        if self._rule == DateGeneration.Zero:
            self._tenor = Period(length=0, units=TimeUnits.Years)
            self._dates.extend([effective_date, termination_date])
            self._is_regular.append(True)
        elif self._rule == DateGeneration.Backward:
            self._dates.append(termination_date)
            seed = termination_date
            if self._next_to_last_date:
                self._dates.insert(0, self._next_to_last_date)
                temp = null_calendar.advance_date(seed,
                                                Period(length=-periods * self._tenor.length(),
                                                       units=self._tenor.units()),
                                                convention, self._end_of_month)
                if temp != self._next_to_last_date:
                    self._is_regular.insert(0, False)
                else:
                    self._is_regular.insert(0, True)
                seed = self._next_to_last_date

            exit_date = effective_date
            if self._first_date:
                exit_date = self._first_date

            while True:
                temp = null_calendar.advance_date(seed,
                                                Period(length=-periods * self._tenor.length(),
                                                       units=self._tenor.units()),
                                                convention, self._end_of_month)
                if temp < exit_date:
                    if self._first_date and self._cal.adjust_date(self._dates[0], convention) != self._cal.adjust_date(
                            self._first_date, convention):
                        self._dates.insert(0, self._first_date)
                        self._is_regular.insert(0, False)
                    break
                else:
                    # skip dates that would result in duplicates
                    # after adjustment
                    if self._cal.adjust_date(self._dates[0], convention) != self._cal.adjust_date(temp, convention):
                        self._dates.insert(0, temp)
                        self._is_regular.insert(0, True)
                    periods += 1

            if self._cal.adjust_date(self._dates[0], convention) != self._cal.adjust_date(effective_date, convention):
                self._dates.insert(0, effective_date)
                self._is_regular.insert(0, False)

        elif self._rule == DateGeneration.Forward:
            self._dates.append(effective_date)

            seed = self._dates[-1]

            if self._first_date:
                self._dates.append(self._first_date)
                temp = null_calendar.advance_date(seed,
                                                Period(length=periods * self._tenor.length(),
                                                       units=self._tenor.units()),
                                                convention, self._end_of_month)
                if temp != self._first_date:
                    self._is_regular.append(False)
                else:
                    self._is_regular.append(True)
                seed = self._first_date

            exit_date = termination_date
            if self._next_to_last_date:
                exit_date = self._next_to_last_date

            while True:
                temp = null_calendar.advance_date(seed,
                                                Period(length=periods * self._tenor.length(),
                                                       units=self._tenor.units()),
                                                convention, self._end_of_month)
                if temp > exit_date:
                    if self._next_to_last_date and self._cal.adjust_date(self._dates[-1],
                                                                        convention) != self._cal.adjust_date(
                        self._next_to_last_date, convention):
                        self._dates.append(self._next_to_last_date)
                        self._is_regular.append(False)
                    break
                else:
                    # skip dates that would result in duplicates
                    # after adjustment
                    if self._cal.adjust_date(self._dates[-1], convention) != self._cal.adjust_date(temp, convention):
                        self._dates.append(temp)
                        self._is_regular.append(True)
                    periods += 1

            if self._cal.adjust_date(self._dates[-1], termination_convention) != self._cal.adjust_date(termination_date,
                                                                                                     termination_convention):
                self._dates.append(termination_date)
                self._is_regular.append(False)
        else:
            raise ValueError("unknown rule ({0:d})".format(self._rule))

        # adjustments
        if self._end_of_month and self._cal.is_end_of_month(seed):
            # adjust to end of month
            if convention == BizDayConventions.Unadjusted:
                for i in range(len(self._dates) - 1):
                    self._dates[i] = Date.end_of_month(self._dates[i])
            else:
                for i in range(len(self._dates) - 1):
                    self._dates[i] = self._cal.end_of_month(self._dates[i])

            if termination_convention != BizDayConventions.Unadjusted:
                self._dates[0] = self._cal.end_of_month(self._dates[0])
                self._dates[-1] = self._cal.end_of_month(self._dates[-1])
            else:
                if self._rule == DateGeneration.Backward:
                    self._dates[-1] = Date.end_of_month(self._dates[-1])
                else:
                    self._dates[0] = Date.end_of_month(self._dates[0])
        else:
            for i in range(len(self._dates) - 1):
                self._dates[i] = self._cal.adjust_date(self._dates[i], convention)

            if termination_convention != BizDayConventions.Unadjusted:
                self._dates[-1] = self._cal.adjust_date(self._dates[-1], termination_convention)

        # Final safety checks to remove extra next-to-last date, if
        # necessary.  It can happen to be equal or later than the end
        # date due to EOM adjustments (see the Schedule test suite
        # for an example).

        date_len = len(self._dates)

        if date_len >= 2 and self._dates[date_len - 2] >= self._dates[-1]:
            self._is_regular[date_len - 2] = (self._dates[date_len - 2] == self._dates[-1])
            self._dates[date_len - 2] = self._dates[-1]
            self._dates.pop()
            self._is_regular.pop()

        if len(self._dates) >= 2 and self._dates[1] <= self._dates[0]:
            self._is_regular[1] = (self._dates[1] == self._dates[0])
            self._dates[1] = self._dates[0]
            self._dates = self._dates[1:]
            self._is_regular = self._is_regular[1:]

        py_assert(len(self._dates) >= 1, ValueError, "degenerate single date ({0}) schedule\n"
                                                       "seed date: {1}\n"
                                                       "exit date: {2}\n"
                                                       "effective date: {3}\n"
                                                       "first date: {4}\n"
                                                       "next to last date: {5}\n"
                                                       "termination date: {6}\n"
                                                       "generation rule: {7}\n"
                                                       "end of month: {8}\n"
        .format(self._dates[0],
                seed, exit_date,
                effective_date,
                first_date,
                next_to_last_date,
                termination_date,
                self._rule, self._end_of_month))

    cpdef size_t size(self):
        return len(self._dates)

    cpdef Calendar calendar(self):
        return self._cal

    cpdef Period tenor(self):
        return self._tenor

    cpdef bint end_of_month(self):
        return self._end_of_month

    cpdef bint is_regular(self, size_t i):
        return self._is_regular[i - 1]

    def __getitem__(self, item):
        return self._dates[item]

    def __deepcopy__(self, memo):
        return Schedule(self._effective_date,
                        self._termination_date,
                        self._tenor,
                        self._cal,
                        self._convention,
                        self._termination_convention,
                        self._rule,
                        self._end_of_month,
                        self._first_date,
                        self._next_to_last_date,
                        self._evaluation_date)

    def __reduce__(self):
        d = {}

        return Schedule, (self._effective_date,
                          self._termination_date,
                          self._tenor,
                          self._cal,
                          self._convention,
                          self._termination_convention,
                          self._rule,
                          self._end_of_month,
                          self._first_date,
                          self._next_to_last_date,
                          self._evaluation_date), d

    def __setstate__(self, state):
        pass

    def __richcmp__(self, Schedule other, int op):
        if op == 2:
            return self._effective_date == other._effective_date \
                   and self._termination_date == other._termination_date \
                   and self._tenor == other._tenor \
                   and self._cal == other._cal \
                   and self._convention == other._convention \
                   and self._termination_convention == other._termination_convention \
                   and self._rule == other._rule \
                   and self._end_of_month == other._end_of_month \
                   and self._first_date == other._first_date \
                   and self._next_to_last_date == other._next_to_last_date \
                   and self._evaluation_date == other._evaluation_date
