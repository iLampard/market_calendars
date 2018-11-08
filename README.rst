<table>
<tr>
  <td>Latest Release</td>
  <td><img src="https://img.shields.io/pypi/v/market_calendars.svg" alt="latest release" /></td>
</tr>

<tr>
  <td>Python version</td>
  <td><img src="https://img.shields.io/badge/python-3.6-blue.svg"/></td>
  </tr>

</table>


market_calendars
=================


Overview
--------
本项目主要提供了上交所和纽交所的交易日历，以及相应的日期运算函数。

The package provides trading calendars with date math utilities
- current version includes China and NYSE calendars
- easy to incorporate other calendars

为了提高效率，本项目的底层日期运算以cython书写，该部分摘自[finance-python](https://github.com/alpha-miner/Finance-Python)， 高层API部分参考了[pandas_market_calendar](https://github.com/rsheftel/pandas_market_calendars/blob/master/)。

To accelerate date computations, the package applies cython in date math codes, which is extracted from [finance-python](https://github.com/alpha-miner/Finance-Python).
The framework of the package mainly refers to [pandas_market_calendar](https://github.com/rsheftel/pandas_market_calendars/blob/master/). Most credits go to these two packages.


Installation
------------

``pip install market_calendars``

用户如果是win-64位的编译器，会自动下载已经编译好的whl文件，如果是其他编译器，需要用户本地配置好C++编译器(如VS2015社区版)，用来编译cython写的那部分代码。

A compiled win-64bit wheel file has been uploaded(I used VS2015 community). For other platforms one has to set up cpp compilers when installing the package.


Quick Start
-----------
.. code:: python

    import pandas_market_calendars as mcal

    # Create a calendar
    cal_sse = mcal.get_calendar('China.SSE')

    # Show available calendars
    print(mcal.get_calendar_names())

.. code:: python
    # return holidays in datetime format by default
    cal_sse.holidays('2018-09-20', '2018-10-10')

.. parsed-literal::
    [datetime.datetime(2018, 9, 22, 0, 0),
     datetime.datetime(2018, 9, 23, 0, 0),
     datetime.datetime(2018, 9, 24, 0, 0),
     datetime.datetime(2018, 9, 29, 0, 0),
     datetime.datetime(2018, 9, 30, 0, 0),
     datetime.datetime(2018, 10, 1, 0, 0),
     datetime.datetime(2018, 10, 2, 0, 0),
     datetime.datetime(2018, 10, 3, 0, 0),
     datetime.datetime(2018, 10, 4, 0, 0),
     datetime.datetime(2018, 10, 5, 0, 0),
     datetime.datetime(2018, 10, 6, 0, 0),
     datetime.datetime(2018, 10, 7, 0, 0)]

.. code:: python
    # return holidays in string format, by default including weekends
    cal_sse.holidays('2018-09-20', '2018-10-10', return_string=True)

.. parsed-literal::
    ['2018-09-22',
     '2018-09-23',
     '2018-09-24',
     '2018-09-29',
     '2018-09-30',
     '2018-10-01',
     '2018-10-02',
     '2018-10-03',
     '2018-10-04',
     '2018-10-05',
     '2018-10-06',
     '2018-10-07']

.. code:: python
    # return holidays in string format, excluding weekends
    cal_sse.holidays('2018-09-20', '2018-10-10', return_string=True, include_weekends=False)

.. parsed-literal::
    ['2018-09-24',
     '2018-10-01',
     '2018-10-02',
     '2018-10-03',
     '2018-10-04',
     '2018-10-05']

.. code:: python
   # return biz days in datetime format
   cal_sse.biz_days('2015-05-20', '2015-06-01')

.. parsed-literal::
   [datetime.datetime(2015, 5, 20, 0, 0),
    datetime.datetime(2015, 5, 21, 0, 0),
    datetime.datetime(2015, 5, 22, 0, 0),
    datetime.datetime(2015, 5, 25, 0, 0),
    datetime.datetime(2015, 5, 26, 0, 0),
    datetime.datetime(2015, 5, 27, 0, 0),
    datetime.datetime(2015, 5, 28, 0, 0),
    datetime.datetime(2015, 5, 29, 0, 0),
    datetime.datetime(2015, 6, 1, 0, 0)]

.. code:: python
   # return biz days in string format
    cal_sse.biz_days('2015-05-20', '2015-06-01', return_string=True)

.. parsed-literal::
    ['2015-05-20',
     '2015-05-21',
     '2015-05-22',
     '2015-05-25',
     '2015-05-26',
     '2015-05-27',
     '2015-05-28',
     '2015-05-29',
     '2015-06-01']

.. code:: python
   cal_sse.is_holiday('2016-10-01'), cal_sse.is_holiday('2014/9/21')

.. parsed-literal::
   (True, True)

.. code:: python
   cal_sse.is_weekend('2014-01-25'), cal_sse.is_weekend('2011/12/31')

.. parsed-literal::
   (True, True)

.. code:: python
   cal_sse.is_end_of_month('2011-12-30'), cal_sse.is_end_of_month('20120131')

.. parsed-literal::
   (True, True)

.. code:: python
   cal_sse.adjust_date('20130131')
   cal_sse.adjust_date('20130131', return_string=True)
   cal_sse.adjust_date('2017/10/01')
   cal_sse.adjust_date('2017/10/01', convention=2)

.. parsed-literal::
   datetime.datetime(2013, 1, 31, 0, 0)
   '2013-01-31'
   datetime.datetime(2017, 10, 9, 0, 0)
   datetime.datetime(2017, 9, 29, 0, 0)

.. code:: python
   cal_sse.advance_date('20170427', '2b')
   cal_sse.advance_date('20170427', '2b', return_string=True)
   cal_sse.advance_date('20170427', '1w', return_string=True)
   cal_sse.advance_date('20170427', '1m', return_string=True)
   cal_sse.advance_date('20170427', '-1m', return_string=True)

.. parsed-literal::
   datetime.datetime(2017, 5, 2, 0, 0)
   '2017-05-02'
   '2017-05-04'
   '2017-05-31'
   '2017-03-27'

.. code:: python
   # return a list of weekly dates from '2018-01-05' to '2018-02-01'
   cal_sse.schedule('2018-01-05', '2018-02-01', '1w', return_string=True, date_generation_rule=2)
   ['2018-01-05', '2018-01-12', '2018-01-19', '2018-01-26', '2018-02-01']


For more details please look at [tutorial-calendar](https://github.com/iLampard/market_calendars/blob/master/examples/tutorial_calendar.ipynb).

Future
------
This calendar is not compatible with pandas calendar yet, will try to improve it in the near future.

Besides, other market calendars will be added in future releases.