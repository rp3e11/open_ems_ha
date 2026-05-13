# OpenEMS Edge — Documentation

## How it works

This add-on wraps the upstream `openems/edge` Docker image. The directories `/var/opt/openems/config` and `/var/opt/openems/data` are symlinked into Home Assistant's persistent `/data` volume, so your configuration survives add-on updates and restarts.

The Felix Web Console is accessible via the **OpenEMS** sidebar entry (ingress) or directly at `http://<HA-host>:8080/system/console`. Note that ingress provides a convenience path through HA authentication, but the console remains directly reachable on port 8080 on the host network — ingress does not isolate it.

## Initial setup

1. Start the add-on. Initial boot takes ~30 s while OSGi resolves bundles.
2. Click **Open Web UI** on the add-on page to open the Felix Web Console (default credentials: `admin` / `admin` — **change them immediately** under Configuration > Users).
3. Configure components per the OpenEMS [Getting Started guide](https://openems.github.io/openems.io/openems/latest/gettingstarted.html).

## Pairing with ha_openems

After OpenEMS Edge is running and you have at least a `Scheduler` and a few components configured:

1. Install the `ha_openems` integration via HACS.
2. Add the integration in Settings > Devices & Services.
3. Hostname: `localhost` (or your HA host's LAN IP if HACS runs elsewhere).
4. Username: `x`, Password: `user` (default OpenEMS local read access) — adjust to match what you configured in the Felix console.
5. Connection type: **Direct edge WebSocket (port 8085)**.

## Custom bundles

You can drop additional Felix `.jar` bundles into `/data/bundles` (inside the add-on's persistent volume). On every boot, the runtime bundle directory is synchronized with `/data/bundles` — new JARs are copied in, and removed or renamed JARs are cleaned up. This directory is private to this add-on and persists across updates.

## Resource footprint

- ~400-600 MB RAM steady state on a real-world config; budget at least 1 GB headroom.
- Java 21 (bundled in the upstream image) — no host-side Java install needed.
- Two TCP ports on the host: 8080 (Felix Web Console) and 8085 (WebSocket for ha_openems).

## Caveats

- The add-on uses `host_network: true` so OpenEMS can see any Modbus-TCP / SunSpec devices on the local LAN without NAT.
- This add-on does **not** sandbox OpenEMS — it has the same network access as HA itself. Don't expose ports 8080/8085 to the internet.
- First boot creates `/data/config` and `/data/data` inside the add-on's persistent volume.
- If the upstream `openems/edge` image changes its launcher path, `run.sh` will log the failure with a directory listing for diagnosis.
