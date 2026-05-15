# Changelog

## 0.2.0

- **Bundle the OpenEMS UI inside this add-on.** Multi-stage Docker build now pulls the Angular SPA from `openems/ui-edge:2026.5.0` and serves it via an nginx front on port 8766. nginx reverse-proxies `/openems-edge` to the WebSocket controller (8764) and `/rest` to the REST controller (8084). No separate UI add-on needed.
- Ingress now points at the UI (port 8766) instead of the raw Felix Web Console, so the sidebar opens the friendly UI. The Felix console is still reachable directly at `:8765/system/console`.
- Watchdog probes nginx on 8766 (always up after entrypoint completes) rather than Felix on 8765.

## 0.1.5

- Move default ports off the commonly-contested 8080/8085 onto 8765 (Felix Web Console / OpenEMS UI) and 8764 (OpenEMS WebSocket).
- Inject `-Dorg.osgi.service.http.port=8765` via `JAVA_TOOL_OPTIONS` in the launch wrapper so Felix Jetty actually binds to the new port after the privilege drop. (The standard OSGi system property is honored by Apache Felix HTTP.)
- Watchdog now probes the Felix port (8765) rather than the websocket port, since the websocket controller is only created once the user configures one.

## 0.1.4

- Fix container restart loop after dropping privileges. The launch wrapper script created by `mktemp` was mode `0600`, so the `openems` user couldn't read it after `su`. Now `chmod 755` so the dropped-privilege shell can open and exec it.

## 0.1.3

- Drop the AppArmor `deny /etc/shadow*` rule. `useradd` writes to `/etc/shadow` when creating the `openems` user on first boot; with the deny rule in place the call failed and the add-on fell back to running as root.
- Remove the temporary mkdir diagnostics now that the cause (overly tight AppArmor profile) is fixed.

## 0.1.2

- Broaden AppArmor profile to the standard HA add-on pattern (`capability,`, `network,`, `signal,`, broad file rules) since the specific-capability profile still produced `mkdir: Permission denied`.
- Add diagnostic output to `run.sh` (`id`, `ls /data`, mount info) so the failure mode is visible if the mkdir still fails.

## 0.1.1

- Fix `mkdir: Permission denied` on `/data` by declaring the AppArmor capabilities needed by the entrypoint (chown, dac_override, setuid/setgid, etc.). The previous profile inherited no capabilities, so even root was blocked from creating dirs on the bind-mounted volume.

## 0.1.0

- Initial release
- Wraps upstream `openems/edge:2026.5.0` image
- Persistent config and data via `/data` volume
- Custom bundle support via `/data/bundles`
- Felix Web Console accessible via Open Web UI button (port 8080)
- Runs as non-root `openems` user
- Custom AppArmor profile scoped to the entrypoint commands, Java runtime, OpenEMS launchers, and persistent data paths
- Watchdog health check on WebSocket port 8085
