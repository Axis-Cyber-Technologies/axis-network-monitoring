# Axis Network Monitor (Hello World)

This repository contains the skeleton for an OPNsense plugin named
`os-axis-network-monitor`. At the moment it only exposes a **Hello World**
page so that you can validate the packaging and installation workflow before
building richer LAN/WAN monitoring capabilities.

## Repository Layout

```
Makefile               Port definition consumed by the OPNsense build system
pkg-descr              One-line package description
pkg-plist              Files installed by the package
src/
  opnsense/
    mvc/
      app/
        controllers/
          OPNsense/
            AxisNetworkMonitor/
              GeneralController.php   UI controller rendering the page
              Navigation/Menu.xml     Adds the entry to the OPNsense menu tree
              acl.xml                 Declares the UI privilege name
        views/
          OPNsense/
            AxisNetworkMonitor/
              general/
                index.volt            Volt template printing “Hello World”
```

## Local Build & Test

1. Place the plugin directory under the official OPNsense plugins tree
   (e.g. `/usr/tools/plugins/net/os-axis-network-monitor`) or clone this repo
   next to the other plugins.
2. From the root of the plugins tree run `make list` once to ensure the
   toolchain is available, then build just this plugin:

   ```sh
   make generate
   cd net/os-axis-network-monitor
   make package
   ```

   The resulting package (`os-axis-network-monitor-*.pkg`) will be placed in
   `work/pkg/`.

## Installation on an OPNsense Appliance

1. Copy the generated `.pkg` file to your OPNsense firewall (for example with
   `scp`).
2. Install it using the firmware CLI:

   ```sh
   opnsense-shell pkg install ./os-axis-network-monitor-0.0.1.pkg
   ```

3. Log in to the web UI, navigate to **Reporting → Axis Network Monitor**, and
   you should see the “Hello World” page.

To iterate quickly during development you may also copy the `src/opnsense`
subtree straight into `/usr/local/www/opnsense/` on a test box and run
`configctl template reload OPNsense.AxisNetworkMonitor` afterwards, but the
packaging approach above mirrors how the plugin will be distributed once it is
ready.

## Installing & Updating on Real Firewalls

Follow `docs/DEPLOYMENT.md` for a full walkthrough on:

- Preparing an OPNsense-compatible build host
- Generating and signing the package
- Hosting a custom package repository
- Registering the repository on each firewall to receive updates automatically

## Development Sandbox

Use `docker-compose.yml` to spin up a local ClickHouse + Redis + Fluent Bit +
FastAPI stack that exercises the analytics pipeline. See
`docs/DEVELOPMENT_STACK.md` for instructions.

## Approval Workflow Prototype

Redis-backed queue design and worker scaffolding live under `docs/redis/` and
`services/workers/`. Start the compose stack and consult `docs/redis/WORKERS.md`
to experiment with automated approvals and policy-change auditing.

## Setup Wizard

Navigate to **Reporting → Axis Network Monitor** to launch the new KnockoutJS
setup wizard. It collects ClickHouse, Redis, and ingestion parameters and
persists them via the plugin’s settings API before unlocking the main landing
page. The first step verifies prerequisites (packages, services, hardware); if
anything is missing consult `docs/DEPENDENCIES.md` for installation guidance.

## Activity Logs

Operational actions (wizard, dependency management, config changes) are written
to `/var/log/axisnetworkmonitor.log`. Use the Activity Log panel on the landing
page or refer to `docs/LOGGING.md` for API access and retention guidance.

## Enabling / Disabling

The *Enabled* toggle in the setup wizard automatically manages local
dependencies:

- Turning it **on** installs (if needed), enables, and starts the local Redis
  and Fluent Bit services, and marks them to start on boot.
- Turning it **off** stops those services, disables their boot flags, and
  updates the plugin config accordingly.

You can also trigger the same behaviour via `configctl
axisnetworkmonitor enable-toggle enable|disable`.

## Version Compatibility

Refer to `docs/COMPATIBILITY.md` for the latest OPNsense core/plugins release
tags this repository has been tested against (currently 25.7.5).

For questions or support contact Axis Cyber Technologies at
`contact@axiscyber.com` or `info@axiscyber.com`.
