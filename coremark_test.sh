#!/bin/sh

echo "coremark  0x0 0x0 0x66 0 7 1 2000 > /tmp/run1.log"
coremark  0x0 0x0 0x66 0 7 1 2000 > /tmp/run1.log
echo "coremark  0x3415 0x3415 0x66 0 7 1 2000  > /tmp/run2.log"
coremark  0x3415 0x3415 0x66 0 7 1 2000  > /tmp/run2.log

echo Check run1.log and run2.log for results.
echo See readme.txt for run and reporting rules.

