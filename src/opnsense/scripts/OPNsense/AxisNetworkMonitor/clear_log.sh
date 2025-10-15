#!/bin/sh
LOG_FILE="/var/log/axisnetworkmonitor.log"
: > "$LOG_FILE"
/usr/bin/logger -t axisnetworkmonitor "Log file cleared"
