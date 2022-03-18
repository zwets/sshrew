#!/bin/sh
#
# This script is invoked by the remote client upon logging in,
# passing it the host name and listening port.
# The script reports the incoming connection in ./connect.log,
# then sleeps with periodic checks that the client is still there.
# Upon exit, this script reports the disconnection in the log.

HOST="${1:-}"
PORT="${2:-}"
LOG="$(dirname "$0")/connect.log"

# Seconds between liveness tests
INTERVAL=30

on_exit() {
    echo "$(date --rfc-3339=s) <<< $HOST disconnected" >>"$LOG"
}

trap on_exit EXIT

echo "$(date --rfc-3339=s) >>> $HOST connected" >>"$LOG"

nc -z 127.0.0.1 $PORT && echo "$(date --rfc-3339=s) --- $HOST on $PORT (pid $$)" >>"$LOG"

while nc -z 127.0.0.1 $PORT; do 
    /usr/bin/sleep $INTERVAL
done

echo "$(date --rfc-3339=s) <<< $HOST not reachable on $PORT" >>"$LOG"

exit 0
