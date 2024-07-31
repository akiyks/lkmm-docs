#!/bin/sh
#
# Run the first round of pdflatex.
# It is assumed to be used together with runlatex.sh and invoked from
# 'make' command.
#
# Usage: sh runfirstlatex.sh file[.tex]
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, you can access it online at
# http://www.gnu.org/licenses/gpl-2.0.html.
#
# Copyright (C) IBM Corporation, 2012-2019
# Copyright (C) Facebook, 2019
# Copyright (C) Akira Yokosawa, 2016, 2023
#
# Authors: Paul E. McKenney <paulmck@us.ibm.com>
#          Akira Yokosawa <akiyks@gmail.com>

if test -z "$1"
then
	echo No latex file specified, aborting.
	exit 1
fi

basename=`echo $1 | sed -e 's/\.tex$//'`

: ${LATEX:=pdflatex}

echo "$LATEX 1 for $basename.pdf"
$LATEX $LATEX_OPT $basename > /dev/null 2>&1 < /dev/null
exitcode=$?
if grep -q 'LaTeX Warning: You have requested' $basename.log
then
	grep -A 4 'LaTeX Warning: You have requested' $basename.log
	echo "### Incompatible package(s) detected. See $basename.log for details. ###"
	echo "### See items 9 and 10 in perfbook's FAQ-BUILD.txt for how to update.          ###"
	exit 1
fi
if grep -q 'LaTeX Error:' $basename.log
then
	echo "----- !!! Fatal latex error !!! -----"
	grep -B 5 -A 8 'LaTeX Error:' $basename.log
	echo "----- See $basename.log for the full log. -----"
	exit 2
fi
if grep -q 'pdfTeX error:' $basename.log
then
	echo "----- !!! Fatal pdfTeX error !!! -----"
	grep -B 10 -A 8 '!pdfTeX error:' $basename.log
	echo "----- See $basename.log for the full log. -----"
	exit 2
fi
if grep -q '! Emergency stop.' $basename.log
then
	grep -B 10 -A 5 '! Emergency stop.' $basename.log
	echo "----- Fatal latex error, see $basename.log for details. -----"
	exit 2
fi
if [ $exitcode -ne 0 ]; then
	tail -n 20 $basename.log
	echo "\n!!! $LATEX aborted !!!"
	exit $exitcode
fi
grep 'LaTeX Warning:' $basename.log > $basename-warning.log
touch $basename-first.log
exit 0
