# Axis Network Monitor – Setup & Usage Guide (Non-Technical)

This guide walks administrators through configuring and using the Axis Network
Monitor plugin after it has been installed.

## 1. Open the Plugin Page
1. Log in to the OPNsense web interface.
2. Navigate to **Reporting → Axis Network Monitor** in the left menu.
   - If the plugin was just installed, the setup wizard opens automatically.
   - If you see the dashboard instead, click **Launch Setup Wizard** (top right)
     to revisit the wizard at any time.

## 2. Complete the Setup Wizard
The wizard has five steps; all mandatory checks must pass before you can finish.

### Step 1 – Preflight Checks
- Click **Re-check Requirements** to verify:
  - Required packages (`clickhouse`, `redis`, `fluent-bit`) are installed.
  - Services are running and enabled at boot.
  - Firewall hardware meets minimum specs.
- Use the action buttons next to each dependency (Install/Start/Enable/Stop) to
  fix issues. The plugin runs the necessary commands for you.
- If a dependency is already present, click **Apply to form** to pre-fill the
  later wizard steps with the detected defaults (e.g. `127.0.0.1:6379`).
- Review the detected hardware profile and compare it to the recommended tiers.

### Step 2 – General Settings
- **Display Name**: title shown on the dashboard (default: Axis Network Monitor).
- **Enable services on completion**: leave checked to turn the plugin on after
  setup; uncheck if you want to set it up but keep services off for now.
- **Start services automatically on boot**: controls whether Redis and Fluent
  Bit are enabled at startup.

### Step 3 – ClickHouse Connection
- Provide the hostname/IP, port, database, username, and password for your
  ClickHouse analytics server (defaults appear if a local instance is detected).
- Tick **Use TLS** if the server requires HTTPS.
- Click **Test Connection** to confirm credentials before continuing.

### Step 4 – Redis Connection
- Enter credentials for the Redis instance handling approval queues (defaults
  appear automatically when the community `os-redis` plugin is installed).
- Toggle **Use TLS** for secure connections.
- Optionally mark whether Fluent Bit telemetry agents are already deployed and
  add notes to track external setup tasks.
- Click **Test Connection** to verify Redis responds (expects `PONG`).

### Step 5 – Summary
- Review all values. If something looks wrong, click **Back** to adjust.
- Click **Finish Setup**. The plugin saves settings and enables services if you
  left the checkbox on in Step 2.

## 3. Day-to-Day Use
After completing the wizard you land on the Axis Network Monitor dashboard.

### Activity Log
- Displays a rolling list of plugin actions (installs, dependency commands,
  configuration updates).
- Filter by level (INFO/NOTICE/WARNING/ERROR), search keywords, or limit the
  number of entries.
- **Refresh** reloads the latest entries, **Clear Log** erases the log file
  (action is itself recorded).

### Dependency Panel
- Reopen the wizard to re-run preflight checks and adjust settings later.
- The plugin will continue to monitor requirements; revisit if services were
  stopped manually or hardware changes.

## 4. Enabling / Disabling the Plugin
- Use the **Enable services** toggle in Step 2 of the wizard or click the gear
  icon in the top-right corner of the dashboard and select **Enable/Disable**.
- When enabled, the plugin ensures Redis and Fluent Bit are installed, enabled
  at boot, and started. When disabled, it stops and disables those services.

## 5. Updating Settings Later
- Return to **Reporting → Axis Network Monitor** and click **Launch Setup
  Wizard**.
- Make your changes; on the final step press **Finish Setup** to save.

## 6. Troubleshooting Tips
- **Preflight errors**: follow the instructions on the first wizard step or
  consult `docs/DEPENDENCIES.md` for manual commands.
- **Logs empty**: trigger a dependency check or configuration save, then press
  **Refresh**.
- **Want to start/stop services manually**: run `configctl axisnetworkmonitor
  enable-toggle enable` (or `disable`) via SSH.

For support contact Axis Cyber Technologies at `contact@axiscyber.com` or
`info@axiscyber.com`.
