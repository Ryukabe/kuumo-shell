#!/usr/bin/env bash
# kuumo: start / stop / restart kuumo-shell
set -u

DIR="${KUUMO_DIR:-$HOME/kuumo-shell}"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/kuumo-shell"
LOG="$LOG_DIR/kuumo.log"

start() {
    mkdir -p "$LOG_DIR"
    # -n: do nothing if this config is already running
    setsid -f qs -n -p "$DIR" >>"$LOG" 2>&1
    echo "kuumo: started (log: $LOG)"
}

stop() {
    if qs kill -p "$DIR" 2>/dev/null; then
        echo "kuumo: stopped"
    else
        echo "kuumo: not running"
    fi
}

case "${1:-}" in
    start)   start ;;
    stop)    stop ;;
    restart) stop; sleep 0.3; start ;;
    log)     tail -f "$LOG" ;;
    *)       echo "usage: kuumo {start|stop|restart|log}"; exit 1 ;;
esac