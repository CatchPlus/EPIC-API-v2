#!/bin/bash

if ! [ -f epic.rb ]; then
	echo "Run this script from the top level directory." >&2
	exit 1
fi
for i in epic*.rb; do
	echo -n "${i}..."
	ruby $i && echo " OK"
done
