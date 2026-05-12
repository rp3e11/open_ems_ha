# OpenEMS Edge — Home Assistant Add-on

Runs [OpenEMS Edge](https://openems.github.io/openems.io/openems/latest/edge/architecture.html) in the same Supervisor container that hosts your Home Assistant install. Pairs with the [ha_openems](https://github.com/Lamarqe/ha_openems) HACS integration for read/write control of the energy management system from HA.

## What this is (and isn't)

- **Is**: a thin wrapper around the upstream `openems/edge:latest` image, with `/var/opt/openems/{config,data}` redirected into HA's persistent `/data` volume so your configuration survives add-on updates.
- **Isn't**: OpenEMS Backend or OpenEMS UI. Edge talks to `ha_openems` directly over its WebSocket on port 8085; you don't need the Angular UI unless you want the original web interface as well.

## Install

1. Add this repo: Settings → Add-ons → Add-on Store → ⋮ → Repositories → paste the repo URL.
2. Install **OpenEMS Edge** from the list.
3. Start it. Initial boot takes ~30 s while OSGi resolves bundles.
4. Open the Felix console at `http://<HA-host>:8080/system/console` (default credentials: `admin` / `admin` — **change immediately** under Configuration → Users).
5. Configure components per the OpenEMS [Getting Started guide](https://openems.github.io/openems.io/openems/latest/gettingstarted.html).

## Pair with `ha_openems`

After OpenEMS Edge is running and you have at least a `Scheduler` and a few components configured:

1. Install the `ha_openems` integration via HACS.
2. Add the integration in Settings → Devices & Services.
3. Hostname: `localhost` (or your HA host's LAN IP if HACS runs elsewhere).
4. Username: `x`, Password: `user` (default OpenEMS local read access) — adjust to match what you configured in the Felix console.
5. Connection type: **Direct edge WebSocket (port 8085)**.

## Resource footprint

- ~400–600 MB RAM steady state on a real-world config; budget at least 1 GB headroom.
- Java 21 (bundled in the upstream image) — no host-side Java install needed.
- Two TCP ports on the host: 8080 (admin console) and 8085 (WebSocket).

## Caveats

- The add-on uses `host_network: true` so OpenEMS can see any Modbus-TCP / SunSpec devices on the local LAN without NAT. Disable and use explicit `ports:` if you need to keep it isolated, but expect to lose autodiscovery of some hardware.
- This add-on does **not** sandbox OpenEMS — it has the same network access as HA itself. Don't expose ports 8080/8085 to the internet.
- First boot creates `/data/config` and `/data/data`. Both are inside the add-on's persistent volume; backing them up means backing up the add-on via the standard HA snapshot mechanism.
- If the upstream `openems/edge` image changes its launcher path, `run.sh` may need a new entry in its candidate list. Failures will be loud and the log will list `/opt/openems` for you.

## Build locally

If you don't want to publish a prebuilt image, the add-on will be built on the user's HA host the first time it's installed. That takes ~5 minutes on a Pi 4 (mostly the `FROM openems/edge:latest` pull).
