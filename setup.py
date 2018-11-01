from setuptools import setup
from setuptools import find_packages
from distutils.cmd import Command
from distutils.extension import Extension
import os
import sys
import io
import subprocess
import platform
import numpy as np
from Cython.Build import cythonize
import Cython.Compiler.Options

Cython.Compiler.Options.annotate = True

if "--line_trace" in sys.argv:
    line_trace = True
    print("Build with line trace enabled ...")
    sys.argv.remove("--line_trace")
else:
    line_trace = False

PACKAGE = "market_calendars"
NAME = "market_calendars"
VERSION = "0.1.1"
DESCRIPTION = "market_calendars " + VERSION
AUTHOR = "iLampard"
URL = 'https://github.com/iLampard/market_calendars'


def git_version():
    from subprocess import Popen, PIPE
    gitproc = Popen(['git', 'rev-parse', 'HEAD'], stdout=PIPE)
    (stdout, _) = gitproc.communicate()
    return stdout.strip()


class test(Command):
    description = "test the distribution prior to install"

    user_options = [
        ('test-dir=', None,
         "directory that contains the test definitions"),
    ]

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        if sys.platform == 'win32':
            command = "coverage run market_calendars/tests/test_main.py& coverage report& coverage html"
        else:
            command = "coverage run market_calendars/tests/test_main.py; coverage report; coverage html"
        process = subprocess.Popen(command, shell=True)
        process.wait()


class version_build(Command):
    description = "test the distribution prior to install"

    user_options = [
        ('test-dir=', None,
         "directory that contains the test definitions"),
    ]

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        git_ver = git_version()[:10]
        configFile = 'market_calendars/__init__.py'

        file_handle = open(configFile, 'r')
        lines = file_handle.readlines()
        newFiles = []
        for line in lines:
            if line.startswith('__version__'):
                line = line.split('+')[0].rstrip()
                line = line + " + \"-" + git_ver + "\"\n"
            newFiles.append(line)
        file_handle.close()
        os.remove(configFile)
        file_handle = open(configFile, 'w')
        file_handle.writelines(newFiles)
        file_handle.close()


if sys.version_info > (3, 0, 0):
    requirements = "requirements/py3.txt"
else:
    requirements = "requirements/py2.txt"

ext_modules = ['market_calendars/core/enums/time_units.pyx',
               'market_calendars/core/enums/weekdays.pyx',
               'market_calendars/core/enums/months.pyx',
               'market_calendars/core/enums/bizday_conventions.pyx',
               'market_calendars/core/enums/date_generation.pyx', ]


def generate_extensions(ext_modules, line_trace=False):
    extensions = []

    if line_trace:
        print("define cython trace to True ...")
        define_macros = [('CYTHON_TRACE', 1), ('CYTHON_TRACE_NOGIL', 1)]
    else:
        define_macros = []

    for pyxfile in ext_modules:
        ext = Extension(name='.'.join(pyxfile.split('/'))[:-4],
                        sources=[pyxfile],
                        define_macros=define_macros)
        extensions.append(ext)
    return extensions


if platform.system() != "Windows":
    import multiprocessing

    n_cpu = multiprocessing.cpu_count()
else:
    n_cpu = 0

ext_modules_settings = cythonize(generate_extensions(ext_modules, line_trace),
                                 compiler_directives={'embedsignature': True, 'linetrace': line_trace},
                                 nthreads=n_cpu)

setup(
    name=NAME,
    version=VERSION,
    description=DESCRIPTION,
    author=AUTHOR,
    url=URL,
    packages=find_packages(),
    include_package_data=False,
    install_requires=io.open(requirements, encoding='utf8').read(),
    classifiers=[],
    cmdclass={"test": test,
              "version_build": version_build},
    ext_modules=ext_modules_settings,
    include_dirs=[np.get_include()],
)
