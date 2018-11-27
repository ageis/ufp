#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from .base import BaseFormatter


class CountFormatter(BaseFormatter):
    """
    Formatter which displays a count of the entries matching filters
    """

    def format(self):
        print("{0} entries parsed".format(len(self.entries)))
