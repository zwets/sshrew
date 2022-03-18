#!/bin/sh
#
# This script is invoked by the remote client upon logging in,
# passing its host name and listening port.
# The script reports the incoming connection in connection.log,
# and writes pid and port to client.{pid,port}.
# Then it sleeps with periodic checks that the client is still
# there, exiting when this is no longer the case.

# Seconds between liveness tests
INTERVAL=30

# Directory for logging connection PIDs and ports
RUN_DIR="$(realpath -e "$(dirname "$0")")"

# Parse arguments
CLIENT="${1:-}"
PORT="${2:-}"
[ -n "$CLIENT" ] && [ -n "$PORT" ] || exit 1

# File names
LOG_FILE="${RUN_DIR}/connection.log"
PID_FILE="${RUN_DIR}/.${CLIENT}.pid"
PORT_FILE="${RUN_DIR}/${CLIENT}.port"

# Function to write timestamped line to LOG_FILE
log() {
    echo "$(date --rfc-3339=s) $*" >>"$LOG_FILE"
}

# Trap exit to clean up
on_exit() {
    rm -f "$PID_FILE" "$PORT_FILE"
    log "<<< $CLIENT exiting [$$]"
}
trap on_exit EXIT

# Main

log ">>> $CLIENT incoming for $PORT [$$]"

# Check for existing process
if [ -f "$PID_FILE" ]; then
    OLD_PID="$(cat "$PID_FILE")"
    if pgrep -cs $OLD_PID -u sshrew >/dev/null; then
    	log "... $CLIENT killing existing process $OLD_PID"
    	kill $OLD_PID
    else
        log "... $CLIENT removing stale pid file for process $OLD_PID"
    fi
    rm -f "$PID_FILE"
fi

# Write new pid and port files
echo "$$" >"$PID_FILE"
echo "$PORT" >"$PORT_FILE"

# Log state
nc -z 127.0.0.1 $PORT && log "+++ $CLIENT listening on $PORT [$$]"

# Loop sleeping and checking
while nc -z 127.0.0.1 $PORT; do 
    /usr/bin/sleep $INTERVAL
done

# No longer connected
log "--- $CLIENT not reachable on $PORT [$$]" >>"$LOG_FILE"

exit 0
