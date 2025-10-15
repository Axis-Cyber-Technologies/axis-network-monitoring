# Axis Network Monitor – User Installation Guide

These instructions explain how a non-technical administrator can install and
activate the Axis Network Monitor plugin on an OPNsense appliance once a signed
package is available.

## Prerequisites
- OPNsense 25.7.5 (or later) firewall with web access.
- An administrator account with permission to install firmware packages.
- The Axis Network Monitor plugin package file (e.g.
  `os-axis-network-monitor-0.0.1.pkg`) provided by Axis Cyber Technologies.
- Optional: SSH access for faster uploads (`scp`).

## Step 1 – Upload the Plugin Package
### Option A: Using the Web Interface
1. Log in to OPNsense.
2. Navigate to **System → Firmware → Packages**.
3. Click **Upload** (upper-right corner).
4. Choose the provided `os-axis-network-monitor-*.pkg` file and press
   **Upload**. The file is placed in `/root/` on the appliance.

### Option B: Using SCP (faster)
From your computer:
```sh
scp os-axis-network-monitor-0.0.1.pkg \
    <admin-user>@<firewall-ip>:/root/
```
Replace `<admin-user>` with your login (e.g. `root` or another admin account)
and `<firewall-ip>` with the firewall’s address (e.g. `192.168.10.1`).

## Step 2 – Install the Package
1. In the OPNsense web UI go to **System → Firmware → Packages**.
2. Open the **Manual install** tab.
3. Enter the full file path, usually `/root/os-axis-network-monitor-0.0.1.pkg`.
4. Click **Install**. Confirm the prompt; the plugin is added to the system.

Alternatively, if you have SSH access you can run:
```sh
pkg install /root/os-axis-network-monitor-0.0.1.pkg
```

## Step 3 – Launch the Setup Wizard
1. After installation, navigate to **Reporting → Axis Network Monitor**.
2. The setup wizard appears automatically if prerequisites are missing.
3. Work through the steps:
   - **Preflight** – verifies required packages/services/hardware.
   - **General** – choose the display name and enable/disable toggle.
   - **ClickHouse / Redis** – enter connectivity details.
   - **Summary** – review and finish.
4. On completion the dashboard shows the Activity Log panel.

## Step 4 – Enabling or Disabling Later
- Toggle the switch at the top of the Axis Network Monitor page; the plugin
  will start/stop its local services automatically.
- You can also use the command line (`System → Firmware → SSH` must be enabled):
  ```sh
  configctl axisnetworkmonitor enable-toggle enable
  configctl axisnetworkmonitor enable-toggle disable
  ```

## Step 5 – Updating the Plugin
1. Obtain the newer `.pkg` file from Axis Cyber Technologies.
2. Repeat **Step 1** (upload) and **Step 2** (install). OPNsense automatically
   replaces the previous version.
3. No additional configuration is needed—the settings stored in `config.xml`
   remain intact.

## Troubleshooting
- **Package refuses to install** – make sure you uploaded the correct version
  for your OPNsense release (currently tested on 25.7.5).
- **Wizard shows missing dependencies** – follow the guidance on the Preflight
  step or consult `docs/DEPENDENCIES.md` for manual install commands.
- **Log viewer empty** – perform an action (e.g. run the dependency checks) and
  refresh; entries appear in `/var/log/axisnetworkmonitor.log`.

For assistance contact Axis Cyber Technologies at
`contact@axiscyber.com` or `info@axiscyber.com`.
