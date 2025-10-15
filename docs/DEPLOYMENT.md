# Installing & Updating `os-axis-network-monitor`

This guide shows how to build, sign, host, and install the plugin so that future
updates deliver through OPNsense’s regular firmware workflow.

## 1. Prepare a Build Host

Use an OPNsense-compatible FreeBSD environment (the official
[`opnsense/tools`](https://github.com/opnsense/tools) VM is recommended).

```sh
git clone https://github.com/opnsense/tools.git ~/tools
cd ~/tools
make update  # fetches sources and ports tree
```

Clone your plugin inside the tools tree so the relative paths match the ports
layout:

```sh
cd ~/tools/plugins/net
git clone git@github.com:Axis-Cyber-Technologies/axis-network-monitoring.git \
  os-axis-network-monitor
```

## 2. Build the Package

From the plugin directory:

```sh
cd ~/tools/plugins/net/os-axis-network-monitor
make clean package
```

The build leaves the signed package artifacts in `work/pkg/`. Keep the entire
directory; it contains:

- `os-axis-network-monitor-<ver>.pkg`
- `meta` and `packagesite.pkg` (repository metadata)

## 3. Sign the Repository

If you do not already have one, create an RSA key-pair for package signing:

```sh
mkdir -p ~/pkg-keys
openssl genrsa -out ~/pkg-keys/axis-repo.key 4096
openssl rsa -in ~/pkg-keys/axis-repo.key -pubout > ~/pkg-keys/axis-repo.pub
```

Now sign the repository metadata:

```sh
cd work/pkg
pkg repo . ~/pkg-keys/axis-repo.key
```

Copy `~/pkg-keys/axis-repo.pub` to a safe location—you will deploy the public
part to every firewall.

## 4. Host the Repository

Upload the entire `work/pkg/` directory contents to HTTPS storage you control.
The directory layout must stay intact:

```
https://updates.axiscyber.com/opnsense/
  ├── meta
  ├── packagesite.pkg
  ├── packagesite.sig
  └── os-axis-network-monitor-0.0.1.pkg
```

Any static host (S3, nginx, GitHub Pages) works as long as the files remain
unchanged.

## 5. Register the Repository on OPNsense

On every firewall, create `/usr/local/etc/pkg/repos/axis.conf`:

```ini
Axis: {
  url: "https://updates.axiscyber.com/opnsense/",
  signature_type: "FINGERPRINTS",
  fingerprints: "/usr/local/etc/pkg/fingerprints/axis",
  enabled: yes,
  priority: 10
}
```

Install the public key fingerprint:

```sh
mkdir -p /usr/local/etc/pkg/fingerprints/axis/trusted
cp axis-repo.pub /usr/local/etc/pkg/fingerprints/axis/trusted/
```

Force pkg to trust and fetch the repository:

```sh
pkg update -f
```

## 6. Install and Update

Install the plugin like any other package:

```sh
pkg install os-axis-network-monitor
```

Future releases just require bumping `PORTVERSION`, running `make clean package`
and `pkg repo` again, then syncing the hosted `work/pkg/` directory. OPNsense
will automatically detect the higher version during firmware checks and offer
the upgrade.

## 7. Automate (Optional)

A simple release script can wrap the workflow:

```sh
#!/bin/sh
set -e
cd ~/tools/plugins/net/os-axis-network-monitor
make clean package
cd work/pkg
pkg repo . ~/pkg-keys/axis-repo.key
rsync -avz . user@updates.axiscyber.com:/var/www/opnsense/
```

Adjust paths and upload method to match your infrastructure.
