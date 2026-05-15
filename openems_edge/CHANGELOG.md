# Changelog

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
