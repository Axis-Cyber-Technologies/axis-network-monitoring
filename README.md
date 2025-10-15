# Axis Network Monitor – Axis Cyber Technologies

Axis Network Monitor (`os-axis-network-monitor`) delivers a setup wizard,
dependency automation, and an operational logging framework for building LAN/
WAN monitoring and policy orchestration on OPNsense.

## Key Capabilities

- **Onboarding wizard** – collects ClickHouse, Redis, and ingestion endpoints;
  runs prerequisite checks (packages, services, hardware) before enabling the
  plugin.
- **Dependency automation** – install/enable/start local Redis & Fluent Bit
  services directly from the UI or via `configctl`.
- **Activity logging** – structured JSON log stored at
  `/var/log/axisnetworkmonitor.log` with live viewer + clear button in the
  dashboard.
- **Dev sandbox assets** – Docker Compose stack (ClickHouse, Redis, Fluent Bit,
  FastAPI worker) for rapid experimentation.

## Repository Layout

```
Makefile                 Plugin metadata consumed by OPNsense tools
pkg-descr                Short description
pkg-plist                Files installed by the package
src/opnsense/            MVC controllers, models, views, configd actions
src/opnsense/scripts/    Helper scripts (dependency checks, toggle enable)
src/opnsense/www/js/     Knockout view models for wizard & logs
configs/                 Fluent Bit configs + parsers for local testing
services/                FastAPI + worker prototypes (analytics/approvals)
sql/                     ClickHouse schema definitions
docs/                    Deployment, dependencies, logging, dev stack, etc.
docker-compose.yml       Local analytics sandbox (ClickHouse/Redis/Fluent Bit)
```

## Prerequisites

### OPNsense Build Environment

Building packages must be done inside the official tools tree (FreeBSD/OPNsense
environment):

```sh
git clone https://github.com/opnsense/tools.git ~/tools
cd ~/tools
make update            # fetch base + ports
```

Clone this repository under `tools/plugins/net/os-axis-network-monitor`.

### Host Requirements

| Host OS | Purpose | Required tools |
|---------|---------|----------------|
| **Ubuntu 22.04+** | Clone/edit repo, sync with FreeBSD VM | `sudo apt install git build-essential python3 ca-certificates` |
| **macOS (12+)** | Clone/edit repo, sync with FreeBSD VM | `brew install git gnu-sed gnu-tar cmake` (use Rosetta/Intel shell if on Apple Silicon) |

> ⚠️ **Packaging must run inside the OPNsense/FreeBSD tools environment.**  
> Use a FreeBSD VM (or an actual OPNsense installation) to execute the `make`
> targets below; Ubuntu/macOS hosts are only for source management.

## Build & Package

```sh
# inside FreeBSD / OPNsense tools VM
cd ~/tools
make update
cd plugins
# repository should already be cloned here
make list                     # optional sanity check
make generate
cd net/os-axis-network-monitor
make clean package
```

Packages are emitted into `work/pkg/os-axis-network-monitor-*.pkg`.

### Rapid Iteration

For small tweaks you can copy the `src/opnsense` subtree onto a test firewall
and reload templates:

```sh
scp -r src/opnsense root@fw:/usr/local/www/opnsense/
ssh root@fw 'configctl template reload OPNsense.AxisNetworkMonitor'
```

Use `configctl axisnetworkmonitor enable-toggle enable|disable` to flip the
plugin state without reinstalling.

## Install on an OPNsense Appliance

1. Copy the `.pkg` file to the firewall (`scp` or SFTP).
2. Install via firmware shell:

   ```sh
   opnsense-shell pkg install ./os-axis-network-monitor-0.0.1.pkg
   ```

3. Open **Reporting → Axis Network Monitor**. The setup wizard will launch if
   prerequisites aren’t satisfied; once complete the dashboard displays the
   Activity Log and future widgets.

For a click-by-click guide aimed at non-technical administrators, see
`docs/USER_INSTALLATION.md`.

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
