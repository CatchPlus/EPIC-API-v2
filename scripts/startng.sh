#!/bin/bash
PIDFILE=/tmp/ng-server.pid

if [ $SHLVL -ne 1 ]; then
	echo "WARNING: This script is supposed to be sourced, not executed." >&2
fi
if ! [ -f epic.rb ]; then
	echo "ERROR: Run this script from the top level directory." >&2
	exit 1
fi
if [ -f "$PIDFILE" ]; then
	kill $(<"$PIDFILE")
	rm "$PIDFILE"
fi

EPIC_JRUBY_OPTS="$JRUBY_OPTS"
unset JRUBY_OPTS
jruby --ng-server >/tmp/ng-server.log 2>&1 &
echo -n $! > /tmp/ng-server.pid
export JRUBY_OPTS="$EPIC_JRUBY_OPTS --ng"
unset EPIC_JRUBY_OPTS
