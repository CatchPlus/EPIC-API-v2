#!/bin/bash

cd "`dirname "$0"`"/../
#if ! [ -f epic.rb ]; then
#	echo "Run this script from the top level directory." >&2
#	exit 1
#fi
for i in src/epic*.rb; do
	echo -n "${i}..."
	ruby -I src $i && echo " OK"
done
