#!/bin/bash -l

cd "`dirname "$0"`"/../
#if ! [ -f epic.rb ]; then
#	echo "Run this script from the top level directory." >&2
#	exit 1
#fi

#export JRUBY_OPTS=$(
#  echo -n $(
#    for i in $JRUBY_OPTS; do
#      echo $i;
#    done |
#    grep -v -- --1.9
#  )
#)

rvm use ruby-1.9.2
rm -rf .yardoc/
yard server --reload
