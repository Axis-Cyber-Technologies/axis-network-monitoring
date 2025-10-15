# Axis Network Monitor Logging

All plugin lifecycle actions (setup wizard, dependency installation, config updates) are logged to `/var/log/axisnetworkmonitor.log`.

## Log Format
- Each line is JSON containing:
  - `ts` – ISO8601 UTC timestamp
  - `level` – INFO, NOTICE, WARNING, ERROR
  - `message` – human-readable summary
  - `context` – additional metadata (hostnames, actions, success flags)
- Entries are also mirrored to the system log via `syslog` (facility `user`).

## Viewing Logs
- Navigate to **Reporting → Axis Network Monitor** after setup; the Activity Log panel lets you filter by level, search text, and number of entries.
- Click **Refresh** to reload, **Clear Log** to truncate the file (also recorded as a log entry).
- API endpoints:
  - `GET /api/axisnetworkmonitor/logs/list?count=200&level=INFO&q=text`
  - `POST /api/axisnetworkmonitor/logs/clear`

## Rotation
Logs are written to `/var/log/axisnetworkmonitor.log`. Ensure your log rotation strategy captures this file (add to `newsyslog.conf.d` or external log management as needed).

## Extending
Call `\OPNsense\AxisNetworkMonitor\Logger::log($level, $message, $context)` anywhere in plugin/server scripts to record additional events. Use levels:
- `info` for normal operations (dependency installs, config updates)
- `notice` for high-level milestones (wizard completion, log clear)
- `warning` for recoverable issues (service not running)
- `error` for failed operations
