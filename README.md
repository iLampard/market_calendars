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






