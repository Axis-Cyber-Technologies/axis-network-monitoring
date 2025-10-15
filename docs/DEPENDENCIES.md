# Axis Network Monitor Dependencies

The plugin relies on several external services and packages. The setup wizard
verifies their availability and blocks completion until required components are
installed and healthy.

## Required Components

| Component | Purpose | Notes |
|-----------|---------|-------|
| `clickhouse` | Stores analytics, reports, and policy audit logs | Install via Axis repo (or run externally). The wizard can test `/ping` before saving. |
| `redis`/`os-redis` | Approval queue and cache | Community plugin `os-redis` satisfies this dependency. The wizard auto-detects it and can ping Redis. |
| `fluent-bit` | Collects OPNsense telemetry and forwards to ClickHouse | Install via Axis repo or manage externally; the wizard can hit the metrics endpoint to confirm it is up. |
| Axis pkg repo (`/usr/local/etc/pkg/repos/axis.conf`) | Supplies signed packages for ClickHouse/Fluent Bit if not in upstream repos | Optional but recommended for automated updates. |

## Optional / Future Integrations

- `ntopng`, `suricata` – leveraged when present; the wizard marks them as
  optional in future revisions.
- AI connectors (ChatGPT, local LLM gateways) – configured post-setup.

## Installation Workflow

1. Add the Axis repository fingerprint (see `docs/DEPLOYMENT.md`).
2. From the wizard prerequisites table you can click **Install**, **Enable**, or
   **Start** to run the same commands the plugin executes via configd. When
   automating manually:
   ```sh
   pkg install clickhouse redis fluent-bit
   sysrc redis_enable=YES fluent_bit_enable=YES
   service redis start
   service fluent-bit start
   ```
3. Configure Fluent Bit using the provided templates in `configs/fluent-bit/`.
4. Re-run the plugin wizard prerequisites step; all rows should turn **Ready**.

## Hardware Profiles

| Profile | CPU (cores) | Memory | Storage | Suggested Use |
|---------|-------------|--------|---------|----------------|
| Minimum | 2 | 4 GB | 40 GB | Labs, PoC, <50 endpoints |
| Recommended | 4 | 8 GB | 120 GB | SMB / branch deployments |
| Enterprise | 8 | 16 GB | 240 GB | Campus, MSP, heavy analytics |

The wizard reads `hw.model`, `hw.ncpu`, and `hw.physmem` to estimate your
current firewall capabilities and highlights the best matching profile. Upgrade
resources if the reported hardware falls below the minimum specification.

During setup you will see the live hardware snapshot alongside buttons to
install/enable/start any missing services. Resolve all warnings until the
prerequisite step reports **Ready** before advancing to configuration.

To toggle the plugin later, run `configctl axisnetworkmonitor enable-toggle
enable` (or `disable`), which mirrors the wizard switch by stopping/starting
local services and updating the boot flags.
