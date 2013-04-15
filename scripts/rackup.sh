#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
cd ../

if [ -f 'rackup.pid' ] && [ -d /proc/$(<'rackup.pid') ]; then
	echo "It seems rackup is already running, with pid" $(<rackup.pid) >&2
	exit 1
fi

rackup --pid rackup.pid >rackup.out 2>rackup.err &
disown %1
