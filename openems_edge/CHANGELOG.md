# Changelog

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
