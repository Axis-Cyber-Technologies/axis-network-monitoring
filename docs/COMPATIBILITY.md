# Compatibility Matrix

| Component | Tested Version | Notes |
|-----------|----------------|-------|
| OPNsense Core | 25.7.5 (tag `25.7.5`, 2025-10-07) | Latest stable release as of Oct 2025. Use `stable/25.7` branch from `opnsense/tools` during builds. |
| OPNsense Plugins Tree | 25.7.5 (tag `25.7.5`, 2025-10-08) | Place this plugin under `net/os-axis-network-monitor` when cloning the plugins repo. |

The existing “hello world” MVC components rely only on OPNsense Base APIs available since 24.7. They have been verified to build and render on 25.7.5.

## Verifying Against Future Releases

1. Pull the corresponding `stable/<major.minor>` branches for both `opnsense/core` and `opnsense/plugins`.
2. Re-run the packaging steps (`make generate && make package`) using the updated toolchain.
3. Execute the plugin UI smoke test:
   - Install the generated package on a sandbox firewall running the target version.
   - Browse to **Reporting → Axis Network Monitor** and confirm the greeting renders.

If any MVC or menu APIs change in later releases, update the controller and menu XML files accordingly before shipping a new package.
