#!/bin/bash
PIDFILE=/tmp/ng-server.pid

cd $(dirname '$0')
if [ -f "$PIDFILE" ]; then
	kill $(<"$PIDFILE")
	rm "$PIDFILE"
fi
unset JRUBY_OPTS
exec jruby --ng-server >/tmp/ng-server.log 2>&1 &
echo -n $! > /tmp/ng-server.pid
