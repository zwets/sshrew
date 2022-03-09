#!/bin/bash

LOG="$(dirname "$0")/connect.log"
HOST="${1:-}"
PORT="${2:-}"
INTERVAL=30

on_exit() {
    echo "$(date --rfc-3339=s) <<< $HOST disconnected" >>"$LOG"
}

trap on_exit EXIT

echo "$(date --rfc-3339=s) >>> $HOST connected" >>"$LOG"

while nc -z 127.0.0.1 $PORT; do
    [ $((N++%5)) -ne 0 ] || echo "$(date --rfc-3339=s) --- $HOST on $PORT (pid $$)" >>"$LOG"
   /usr/bin/sleep $INTERVAL
done

echo "$(date --rfc-3339=s) <<< $HOST not reachable on $PORT" >>"$LOG"

exit 0
