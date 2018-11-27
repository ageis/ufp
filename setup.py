#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from fnmatch import fnmatchcase
from sys import stderr, exit, version_info, executable
from distutils.util import get_platform, convert_path
from distutils.command.install import install as _install
from os import path, listdir
from io import open
from re import match
from setuptools import find_packages, setup, Command

from distro import linux_distribution

plat = get_platform()
distro = linux_distribution()[0]

if version_info < (3, 4):
    stderr.write('This module requires at least Python 3.4\n')
    exit(1)

# check linux platform
if plat != 'linux-x86_64':
    stderr.write("This won't work on %s\n" % plat)
    exit(1)

if not match(r'(Debian GNU/Linux|Ubuntu)', distro):
    stderr.write("This program is meant for Debian GNU/Linux variants.\n")
    exit(1)

here = path.abspath(path.dirname(__file__))

with open(path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

standard_exclude = ('*.pyc', '*~', '.*', '*.bak', '*.swp*')
standard_exclude_directories = ('.*', './build', './dist', 'EGG-INFO',
                                '*.egg-info', 'tests', 'requirements',
                                '__pycache__')


def find_package_data(where='.',
                      package='',
                      exclude=standard_exclude,
                      exclude_directories=standard_exclude_directories,
                      only_in_packages=True,
                      show_ignored=False):
    out = {}
    stack = [(convert_path(where), '', package, only_in_packages)]
    while stack:
        where, prefix, package, only_in_packages = stack.pop(0)
        for name in listdir(where):
            fn = path.join(where, name)
            if path.isdir(fn):
                bad_name = False
                for pattern in exclude_directories:
                    if (fnmatchcase(name, pattern)
                            or fn.lower() == pattern.lower()):
                        bad_name = True
                        if show_ignored:
                            print("Directory %s ignored by pattern %s" %
                                  (fn, pattern))
                        break
                if bad_name:
                    continue
                if path.isfile(path.join(fn, '__init__.py')):
                    if not package:
                        new_package = name
                    else:
                        new_package = package + '.' + name
                    stack.append((fn, '', new_package, False))
                else:
                    stack.append((fn, prefix + name + '/', package,
                                  only_in_packages))
            elif package or not only_in_packages:
                # is a file
                bad_name = False
                for pattern in exclude:
                    if (fnmatchcase(name, pattern)
                            or fn.lower() == pattern.lower()):
                        bad_name = True
                        if show_ignored:
                            print("File %s ignored by pattern %s" % (fn,
                                                                     pattern))
                        break
                if bad_name:
                    continue
                out.setdefault(package, []).append(prefix + name)
    return out


class PyTest(Command):
    user_options = []

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        from subprocess import call
        import sys
        errno = call([executable, 'runtests.py'])
        raise SystemExit(errno)


setup(
    name="ufp",
    version="0.0.1",
    author="Igor Vuk",
    author_email="igor.vuk@nimium.hr",
    maintainer='Kevin Gallagher',
    maintainer_email='kevingallagher@gmail.com',
    description="The Uncomplicated Firewall (ufw) log parser",
    long_description=long_description,
    long_description_content_type="text/markdown",
    license='BSD',
    url='https://github.com/ivuk/ufp',
    packages=find_packages(where='src'),
    package_dir={
        'ufp': 'src/ufp',
        'ufp.parser': 'src/ufp/parser',
        'ufp.formatter': 'src/ufp/formatter'
    },
    include_package_data=True,
    keywords=['ufw', 'firewall', 'parser', 'iptables', 'logs'],
    classifiers=[
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Topic :: System :: Networking :: Firewalls",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)",
        "Intended Audience :: End Users/Desktop",
        "Intended Audience :: Developers",
        "Operating System :: OS Independent",
        "Intended Audience :: System Administrators",
        'Topic :: System :: Monitoring', 'Environment :: Console'
    ],
    # py_modules=packages,
    python_requires='>=2.7,!=3.0,!=3.1,!=3.4,!=3.5,!=3.4,>=3.6,<=3.7.2',
    extras_require={},
    package_data=find_package_data(
        where='src/ufp',
        package='ufp',
        only_in_packages=True,
        show_ignored=True),
    # data_files=data_files,
    platforms=['Linux'],
    scripts=['src/ufp.py'],
    zip_safe=False,
    entry_points={'console_scripts': ['ufp=ufp.cli']},
    install_requires=['ufw >=0.35'],
    setup_requires=['pytest-runner'],
    tests_require=['pytest'],
    cmdclass={
        'test': PyTest,
        'install': _install
    })
