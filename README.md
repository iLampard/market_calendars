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

Note:
- 入参的日期为任意合法的string格式，输出的日期可以选择为datetime或者string格式。

  For functions in this package, the input date could be in any valid string format, the output date could be in either datetime or string format.


### 创建日历 Create a calendar object

```python

    import pandas_market_calendars as mcal

    # Create a calendar
    cal_sse = mcal.get_calendar('China.SSE')
    cal_nyse = mcal.get_calendar('NYSE')

    # Show available calendars
    print(mcal.get_calendar_names())
```


### 返回节假日列表 return holidays list



```python
    # return holidays in datetime format by default
    cal_sse.holidays('2018-09-20', '2018-10-10')
```

```
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
```

```python
    # return holidays in string format, by default including weekends
    cal_sse.holidays('2018-09-20', '2018-10-10', return_string=True)
```

```output
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
```

```python
    # return holidays in string format, excluding weekends
    cal_sse.holidays('2018-09-20', '2018-10-10', return_string=True, include_weekends=False)
```

```
    ['2018-09-24',
     '2018-10-01',
     '2018-10-02',
     '2018-10-03',
     '2018-10-04',
     '2018-10-05']
```


#### 返回交易日列表 return biz days list

```python
   # return biz days in datetime format
   cal_sse.biz_days('2015-05-20', '2015-06-01')
```

```
   [datetime.datetime(2015, 5, 20, 0, 0),
    datetime.datetime(2015, 5, 21, 0, 0),
    datetime.datetime(2015, 5, 22, 0, 0),
    datetime.datetime(2015, 5, 25, 0, 0),
    datetime.datetime(2015, 5, 26, 0, 0),
    datetime.datetime(2015, 5, 27, 0, 0),
    datetime.datetime(2015, 5, 28, 0, 0),
    datetime.datetime(2015, 5, 29, 0, 0),
    datetime.datetime(2015, 6, 1, 0, 0)]
```

```python
   # return biz days in string format
    cal_sse.biz_days('2015-05-20', '2015-06-01', return_string=True)
```

```
    ['2015-05-20',
     '2015-05-21',
     '2015-05-22',
     '2015-05-25',
     '2015-05-26',
     '2015-05-27',
     '2015-05-28',
     '2015-05-29',
     '2015-06-01']
```

#### 日期检验函数 date check functions

```python
   cal_sse.is_holiday('2016-10-01'), cal_sse.is_holiday('2014/9/21')
```

```
   (True, True)
```

```python
   cal_sse.is_weekend('2014-01-25'), cal_sse.is_weekend('2011/12/31')
```

```
   (True, True)
```

```python
   cal_sse.is_end_of_month('2011-12-30'), cal_sse.is_end_of_month('20120131')
```

```
   (True, True)
```


#### 日期调整函数 date adjusted functions

调整成交易日。

adjusted to biz-date.

```python
   cal_sse.adjust_date('20130131')
   cal_sse.adjust_date('20130131', return_string=True)
   cal_sse.adjust_date('2017/10/01')
   cal_sse.adjust_date('2017/10/01', convention=2)
```

```
   datetime.datetime(2013, 1, 31, 0, 0)
   '2013-01-31'
   datetime.datetime(2017, 10, 9, 0, 0)
   datetime.datetime(2017, 9, 29, 0, 0)
```

#### 日期加减函数 date advance function

经过加减，返回的是交易日。

Please note that advance_date returns a *biz-date*.

```python
   # add two bizdays
   cal_sse.advance_date('2017-04-27', '2b')
   # add two bizdays and return in string
   cal_sse.advance_date('20170427', '2b', return_string=True)
   # add one week and return in string
   cal_sse.advance_date('20170427', '1w', return_string=True)
   # add one month and return in string
   cal_sse.advance_date('20170427', '1m', return_string=True)
   # minus one week and return in string
   cal_sse.advance_date('20170427', '-1m', return_string=True)
```

```
   datetime.datetime(2017, 5, 2, 0, 0)
   '2017-05-02'
   '2017-05-04'
   '2017-05-31'
   '2017-03-27'
```

#### 日程函数 schedule function

```python
   # return a list of weekly dates from '2018-01-05' to '2018-02-01'
   cal_sse.schedule('2018-01-05', '2018-02-01', '1w', return_string=True, date_generation_rule=2)
   ['2018-01-05', '2018-01-12', '2018-01-19', '2018-01-26', '2018-02-01']
```

For more details please look at [tutorial-calendar](https://github.com/iLampard/market_calendars/blob/master/examples/tutorial_calendar.ipynb).


### Null Calendar

有时候用户需要处理一些不依赖于任何日历的问题，此时可以令日历名为*null*即可。注意此时的null calendar的假期仅包括周六日。

Uses can use null calendar to avoid any special holidays except weekends.

```python
   null_cal = mcal.get_calendar('null')
```

```python
   null_cal.is_holiday('2018-10-01'), null_cal.is_holiday('2018-10-06')
```

```
    (False, True)
```

```python
   null_cal.advance_date('2017-04-27', '2b', return_string=True)
   null_cal.advance_date('20180429', '1b')
```
```
   '2017-05-01'
   datetime.datetime(2018, 4, 30, 0, 0)
```

### Directly call core date functions

    如果用户想进行更复杂的操作，或者想进行不考虑任何假期(如双休日)，可以直接调用项目核心用cython写的*Date*。该部分代码的示例如下

    To avoid neither public holidays nor weekends, one can directly call *Date* functions, shown below.

#### Date
```python
   from market_calendars.core import Date, Period

   # create date object
    current_date = Date(2015, 7, 24)
```


```python
    # two days later
    current_date + 2
    # 1 month later
    current_date + '1M'
    current_date + Period('1M')
```

```
    Date(2015, 7, 26)
    Date(2015, 8, 24)
    Date(2015, 8, 24)
```

#### Conversion between Date and string
```python
    # Date to string
    str(current_date)
    current_date.strftime("%Y/%m/%d")
    current_date.strftime("%Y%m%d")
```

```
    '2015-07-24'
    '2015/07/24'
    '20150724'
```
```python
    # string to Date
    Date.strptime('20160115', '%Y%m%d')
    Date.strptime('2016-01-15', '%Y-%m-%d')
    # datetime to Date
    Date.from_datetime(dt.datetime(2015, 7, 24))
```
```
    Date(2016, 1, 15)
    Date(2016, 1, 15)
    Date(2015, 7, 24)
```


For more details please look at [tutorial-date](https://github.com/iLampard/market_calendars/blob/master/examples/tutorial_date.ipynb).




Future
------
This calendar is not compatible with pandas calendar yet, will try to improve it in the near future.

Besides, other market calendars will be added in future releases.
